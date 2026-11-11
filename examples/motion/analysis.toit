// Calculates time-domain features, autocorrelation and spectral power.
// Used by acquisition.toit to report motion windows.

import math
import .settings as settings
import motion-fusion show Vector3

SAMPLE-RATE ::= settings.SAMPLE-RATE * 1.0
WINDOW-SIZE ::= 256
WINDOW-HOP ::= 128
// Example noise floors, not thresholds separating horse gaits.
MIN-RHYTHM-RMS ::= 0.15
ZERO-HYSTERESIS ::= 0.1
PEAK-FLOOR ::= 0.3

/** One immutable-after-queueing window; acquisition overlaps successive windows. */
class Window:
  vertical/List := List WINDOW-SIZE: 0.0
  count/int := 0
  linear-energy/float := 0.0
  svm-sum/float := 0.0
  correction-count/int := 0
  magnetic-count/int := 0
  first-sample/int
  generation/int
  constructor .first-sample .generation:

  add linear/Vector3 svm/float corrected/bool --magnetic-used/bool=false -> bool:
    if count == WINDOW-SIZE: throw "WINDOW_FULL"
    vertical[count] = linear.z
    count++
    linear-energy += linear.x * linear.x + linear.y * linear.y + linear.z * linear.z
    svm-sum += svm
    if corrected: correction-count++
    if magnetic-used: magnetic-count++
    return count == WINDOW-SIZE

/** Features describe a waveform. No mapping to gait labels is implied. */
class Features:
  spectrum-enabled/bool
  vector-rms/float
  vertical-rms/float
  vertical-variance/float
  mean-svm/float
  zero-crossings-hz/float
  peak-hz/float?
  peak-interval-cv/float?
  autocorrelation-hz/float?
  regularity/float?
  fft-hz/float?
  low-power/float?
  high-power/float?

  constructor window/Window --with-spectrum/bool=true --with-autocorrelation/bool=true
      --with-peaks/bool=true --spectrum-plan/Plan?=null:
    spectrum-enabled = with-spectrum
    if window.count != WINDOW-SIZE: throw "INCOMPLETE_WINDOW"
    mean := (window.vertical.reduce --initial=0.0: | a b | a + b) / WINDOW-SIZE
    centered := window.vertical.map: it - mean
    vertical-variance = centered.reduce --initial=0.0: | sum x | sum + x * x
    vertical-variance /= WINDOW-SIZE
    vertical-rms = vertical-variance.sqrt
    vector-rms = (window.linear-energy / WINDOW-SIZE).sqrt
    mean-svm = window.svm-sum / WINDOW-SIZE
    zero-crossings-hz = crossing-rate_ centered
    peaks := with-peaks and vertical-rms >= MIN-RHYTHM-RMS ? (peak-intervals_ centered) : []
    peak-hz = null
    peak-interval-cv = null
    if peaks.size >= 2:
      interval := (peaks.reduce --initial=0.0: | a b | a + b) / peaks.size
      variance := (peaks.reduce --initial=0.0: | sum x | sum + (x - interval) * (x - interval)) / peaks.size
      peak-hz = SAMPLE-RATE / interval
      peak-interval-cv = variance.sqrt / interval
    rhythm := with-autocorrelation ? (autocorrelation_ centered vertical-rms) : [null, null]
    autocorrelation-hz = rhythm[0]
    regularity = rhythm[1]
    fft-hz = null
    low-power = null
    high-power = null
    if with-spectrum:
      psd := spectrum-plan == null ? (periodogram centered SAMPLE-RATE) : (spectrum-plan.compute centered)
      if vertical-rms >= MIN-RHYTHM-RMS:
        fft-hz = dominant-frequency psd SAMPLE-RATE WINDOW-SIZE 0.5 5.0
      low-power = band-power psd SAMPLE-RATE WINDOW-SIZE 0.5 3.0
      high-power = band-power psd SAMPLE-RATE WINDOW-SIZE 3.0 10.0

  /** Stable CSV field order used by the RH2 session and host tests. */
  stringify -> string:
    return "$vector-rms,$vertical-rms,$vertical-variance,$mean-svm,$zero-crossings-hz,$peak-hz,$peak-interval-cv,$autocorrelation-hz,$regularity,$fft-hz,$low-power,$high-power"

HEADER ::= "vector_rms_m_s2,vertical_ac_rms_m_s2,vertical_variance_m2_s4,mean_svm_m_s2,zcr_crossings_s,peak_hz,peak_interval_cv,acf_hz,acf_regularity,fft_hz,power_0p5_3_m2_s4,power_3_10_m2_s4"

crossing-rate_ samples/List -> float:
  sign := 0
  crossings := 0
  samples.do: | x |
    next := x > ZERO-HYSTERESIS ? 1 : (x < -ZERO-HYSTERESIS ? -1 : sign)
    if sign != 0 and next != sign: crossings++
    sign = next
  return crossings * SAMPLE-RATE / (samples.size - 1)

// Local mean + standard deviation follows changing activity. Refractory time
// and local maxima suppress ringing, but these events are not verified strikes.
peak-intervals_ samples/List -> List:
  intervals := []
  mean := samples[0]
  variance := 0.0
  last := -WINDOW-SIZE
  alpha := 1.0 - (math.exp (-1.0 / (SAMPLE-RATE * 0.5)))
  for i := 1; i < samples.size - 1; i++:
    x := samples[i]
    delta := x - mean
    mean += alpha * delta
    variance = (1 - alpha) * (variance + alpha * delta * delta)
    // Comparing squares avoids a square root at every sample.
    margin := x - mean
    if margin > PEAK-FLOOR and margin * margin > variance and x > samples[i - 1] and x >= samples[i + 1] and
        i - last >= (SAMPLE-RATE * 0.15).to-int:
      if last >= 0: intervals.add (i - last).to-float
      last = i
  return intervals

// Use overlap-normalized correlation and the first strong local maximum, not
// the largest multiple of the same period. Retain the score as a quality hint.
autocorrelation_ samples/List rms/float -> List:
  if rms < MIN-RHYTHM-RMS: return [null, null]
  // Average before decimation so the 0.5–5 Hz rhythm search operates at
  // 26 Hz. This suppresses higher-frequency impacts and cuts the number of
  // correlation products substantially; it is not a general-purpose filter.
  factor := 4
  rate := SAMPLE-RATE / factor
  reduced := List (samples.size / factor): | i |
    j := i * factor
    (samples[j] + samples[j + 1] + samples[j + 2] + samples[j + 3]) / factor
  first := (rate / 5).to-int
  last := (rate / 0.5).to-int
  values := List (last + 2): 0.0
  // Prefix energies normalize each lag exactly for its overlapping samples.
  energies := List (reduced.size + 1): 0.0
  reduced.size.repeat: | i | energies[i + 1] = energies[i] + reduced[i] * reduced[i]
  for lag := first - 1; lag <= last + 1; lag++:
    aa := energies[reduced.size - lag]
    bb := energies[reduced.size] - energies[lag]
    dot := 0.0
    for i := 0; i < reduced.size - lag; i++:
      dot += reduced[i] * reduced[i + lag]
    values[lag] = aa * bb > 1e-12 ? dot / (aa * bb).sqrt : 0.0
    yield
  best := -1
  for lag := first; lag <= last; lag++:
    if values[lag] >= 0.4 and values[lag] > values[lag - 1] and values[lag] >= values[lag + 1]:
      if best < 0 or values[lag] > values[best]: best = lag
  if best < 0: return [null, null]
  // Prefer an earlier near-equivalent peak to an integer multiple of the period.
  for lag := first; lag < best; lag++:
    if values[lag] >= 0.9 * values[best] and values[lag] > values[lag - 1] and values[lag] >= values[lag + 1]:
      best = lag
      break
  // Parabolic interpolation reduces the four-sample lag quantization error.
  curvature := values[best - 1] - 2 * values[best] + values[best + 1]
  offset := curvature.abs > 1e-12 ? (0.5 * (values[best - 1] - values[best + 1]) / curvature) : 0.0
  offset = max -0.5 (min 0.5 offset)
  frequency := rate / (best + offset)
  if not 0.5 <= frequency <= 5.0: return [null, null]
  return [frequency, max 0.0 (min 1.0 values[best])]


/** Convenience one-shot API; repeated callers should retain a Plan. */
periodogram samples/List rate/float -> List:
  return (Plan samples.size rate).compute samples

/** Single-reporter workspace. Reuses buffers and precomputes the Hann window. */
class Plan:
  size_/int
  rate_/float
  weights_/List
  real_/List
  imag_/List
  energy_/float := 0.0

  constructor size/int rate/float:
    if size < 8 or (size & (size - 1)) != 0: throw "FFT_SIZE_MUST_BE_POWER_OF_TWO"
    if not rate.is-finite or rate <= 0: throw "INVALID_RATE"
    size_ = size
    rate_ = rate
    weights_ = List size: 0.5 - 0.5 * (math.cos (2 * math.PI * it / (size - 1)))
    weights_.do: energy_ += it * it
    real_ = List size: 0.0
    imag_ = List size: 0.0

  /** One-sided, demeaned, Hann-windowed PSD in signal^2/Hz. */
  compute samples/List -> List:
    if samples.size != size_: throw "FFT_PLAN_SIZE_MISMATCH"
    mean := (samples.reduce --initial=0.0: | a b | a + b) / size_
    size_.repeat: | i |
      real_[i] = (samples[i] - mean) * weights_[i]
      imag_[i] = 0.0
    fft_ real_ imag_
    return List (size_ / 2 + 1): | k |
      factor := k == 0 or k == size_ / 2 ? 1.0 : 2.0
      factor * (real_[k] * real_[k] + imag_[k] * imag_[k]) / (rate_ * energy_)

// Iterative radix-2 FFT. Work buffers are local; no native ESP-DSP dependency.
fft_ real/List imag/List:
  n := real.size
  j := 0
  n.repeat: | i |
    if i < j:
      swap := real[i]
      real[i] = real[j]
      real[j] = swap
    bit := n >> 1
    while bit > 0 and (j & bit) != 0:
      j ^= bit
      bit >>= 1
    j ^= bit
  width := 2
  while width <= n:
    half := width / 2
    step-real := math.cos (-2 * math.PI / width)
    step-imag := math.sin (-2 * math.PI / width)
    start := 0
    while start < n:
      wr := 1.0
      wi := 0.0
      half.repeat: | k |
        a := start + k
        b := a + half
        tr := wr * real[b] - wi * imag[b]
        ti := wr * imag[b] + wi * real[b]
        real[b] = real[a] - tr
        imag[b] = imag[a] - ti
        real[a] += tr
        imag[a] += ti
        next-wr := wr * step-real - wi * step-imag
        wi = wr * step-imag + wi * step-real
        wr = next-wr
      start += width
      if start % 64 == 0: yield
    // Toit's tasks share execution time with sampling and V3 handling.
    yield
    width *= 2

/** Integrates PSD bins in the half-open band [low, high). */
band-power psd/List rate/float size/int low/float high/float -> float:
  power := 0.0
  psd.size.repeat: | k |
    hz := k * rate / size
    if low <= hz < high: power += psd[k] * rate / size
  return power

/** Strongest bin in the search band; this can be a harmonic of stride rate. */
dominant-frequency psd/List rate/float size/int low/float high/float -> float?:
  best := -1
  psd.size.repeat: | k |
    hz := k * rate / size
    if low <= hz <= high and (best < 0 or psd[k] > psd[best]): best = k
  if best < 0 or psd[best] < 1e-12: return null
  return best * rate / size
