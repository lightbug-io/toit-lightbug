// Tests time-domain features and spectral analysis on synthetic signals.
// Run as part of the RH2 motion host test suite.

import math
import motion-fusion show Vector3 GRAVITY
import ...examples.motion.analysis as analysis
import ...examples.motion.analysis as spectrum

check condition/bool message/string:
  if not condition: throw message

main:
  quiet := analysis.Window 0 0
  analysis.WINDOW-SIZE.repeat:
    quiet.add (Vector3 0 0 0) GRAVITY true
  still := analysis.Features quiet
  check (still.vector-rms == 0 and still.fft-hz == null and still.autocorrelation-hz == null) "Stationary false rhythm"
  check (still.regularity == null) "Stationary regularity should be unavailable"
  check (still.peak-hz == null and still.zero-crossings-hz == 0) "Stationary false events"
  [1.0, 1.6, 2.4].do: | hz |
    window := analysis.Window 0 0
    analysis.WINDOW-SIZE.repeat: | i |
      x := 2 * (math.sin (2 * math.PI * hz * i/analysis.SAMPLE-RATE))
      window.add (Vector3 0 0 x) (GRAVITY + x) true
    result := analysis.Features window
    check ((result.vertical-variance - 2).abs < 0.04) "Variance scale"
    check ((result.vector-rms - 2.sqrt).abs < 0.02) "RMS scale"
    check (result.autocorrelation-hz != null and (result.autocorrelation-hz - hz).abs < 0.04) "Autocorrelation frequency"
    check (result.regularity > 0.99) "Autocorrelation regularity"
    check (result.fft-hz != null and (result.fft-hz - hz).abs < analysis.SAMPLE-RATE/analysis.WINDOW-SIZE) "FFT frequency"
    check (result.peak-hz != null and (result.peak-hz - hz).abs < 0.04) "Peak rate"
    // A short window has finite-sample crossing uncertainty and some Hann
    // energy can leak outside the selected frequency band.
    check ((result.zero-crossings-hz - 2 * hz).abs < 0.5) "Crossings are not cycles"
    check ((result.low-power - 2).abs < 0.1) "PSD band power"
  // A nonperiodic deterministic sequence must not look perfectly regular.
  noise := analysis.Window 0 0
  state := 37
  analysis.WINDOW-SIZE.repeat:
    state = (state * 1664525 + 1013904223) & 0xffffffff
    x := (state / 4294967296.0 - 0.5) * 4
    noise.add (Vector3 0 0 x) GRAVITY true
  irregular := analysis.Features noise
  check (irregular.autocorrelation-hz == null) "Noise false periodicity"
  check (irregular.regularity == null) "Regularity without an accepted rhythm"
  // Impact-like high-frequency content must not hide the lower rhythm.
  mixed := analysis.Window 0 0
  analysis.WINDOW-SIZE.repeat: | i |
    x := (2 * (math.sin (2 * math.PI * 1.6 * i / analysis.SAMPLE-RATE))) +
        (0.5 * (math.sin (2 * math.PI * 18 * i / analysis.SAMPLE-RATE)))
    mixed.add (Vector3 0 0 x) GRAVITY true
  mixed-result := analysis.Features mixed
  check (mixed-result.autocorrelation-hz != null and (mixed-result.autocorrelation-hz - 1.6).abs < 0.08) "Mixed-frequency rhythm"
  // A bin-centred sinusoid checks exact FFT indexing and integrated energy.
  data := List 256: math.sin (2 * math.PI * 16 * it/256)
  psd := spectrum.periodogram data 128.0
  check ((spectrum.dominant-frequency psd 128.0 256 0.5 20.0) == 8.0) "FFT bin mapping"
  power := spectrum.band-power psd 128.0 256 0.0 64.1
  check ((power - 0.5).abs < 0.0001) "Parseval/Hann normalization"
  check ((catch: spectrum.periodogram [0, 1, 2] 100.0) != null) "FFT accepted invalid length"
  optional := analysis.Features quiet --with-spectrum=false --with-autocorrelation=false --with-peaks=false
  check (optional.low-power == null and optional.high-power == null and optional.regularity == null and optional.peak-hz == null) "Disabled features claimed results"
  plan := spectrum.Plan 256 128.0
  cached := plan.compute data
  cached.size.repeat: | i | check ((cached[i] - psd[i]).abs < 1e-12) "Cached spectrum changed normalization"
  zero := plan.compute (List 256: 0.0)
  check (zero.every (: it == 0.0)) "FFT workspace retained previous data"
  print "Motion feature tests passed"
