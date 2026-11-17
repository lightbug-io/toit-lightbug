// Tests sparkline scaling and history layout.
// Run as part of the RH2 motion host test suite.

import ...examples.motion.display as plot

main:
  if plot.PLOT-POINTS != 96: throw "Insufficient plot history"
  quiet := plot.plot-y 0 0.03
  if quiet != plot.PLOT-HEIGHT: throw "Stationary noise lifts the baseline"
  if (plot.plot-y 0 2.0) >= quiet: throw "Activity scale is inverted"
  if (plot.plot-y 3 0.0) != plot.PLOT-HEIGHT or (plot.plot-y 3 1.0) != 0: throw "Regularity scale"
  if (plot.plot-y 0 3.0) - (plot.plot-y 0 30.0) < 12: throw "RMS scale compresses meaningful motion"
  if (plot.plot-y 0 40.0) != 0 or (plot.plot-y 0 80.0) != 0: throw "Full-scale clipping"
  if (catch: plot.plot-y 0 float.NAN) == null: throw "Accepted invalid plot value"
  print "Point plot range and stationary scale tests passed"
