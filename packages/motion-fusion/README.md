# Motion fusion

A hardware-independent quaternion complementary attitude filter, with small
vector/quaternion helpers and optional magnetic yaw feedback. MIT licensed;
no package dependencies. This is a transparent starting point for motion
processing, not a navigation or position estimator.

We intend to publish `motion-fusion` as an independent Toit package if API review and hardware validation support it. It is currently a local path dependency and is not yet available in the Toit registry.

```toit
import motion-fusion show Fusion Vector3 GRAVITY

filter := Fusion
filter.reset (Vector3 0 0 GRAVITY) // Measured acceleration while stationary.
q := filter.update acceleration gyro 0.01
linear := filter.linear-acceleration acceleration
```

Inputs must share a **right-handed body frame**, using m/s² for accelerometer
specific force, rad/s for angular velocity, seconds for dt, and microtesla for
optional `--magnetic`. Supply sensor time intervals, not task wake intervals.
Valid dt is `(0, 0.1]` seconds. Calibrate and subtract gyro bias beforehand.
Non-finite accelerometer/gyro data throws; an unusable optional magnetic input
is skipped. Invalid/nonpositive quaternion norms are rejected.

`Quaternion` is normalized and uses Hamilton `(w,x,y,z)`. `rotate` maps body
vectors into world; `up` is world +Z expressed in body coordinates. World +Z
points upward; magnetic feedback aligns world +X to magnetic north, making
+Y west. Stationary specific force is +g. `linear-acceleration` rotates
specific force then subtracts world +g. Without magnetic feedback, yaw is
arbitrary and drifts. `reset` seeds tilt from stationary gravity, including the
upside-down case. It does not learn gyro bias.

`Fusion` integrates gyro with normalized first-order quaternion updates.
Proportional gravity feedback (default gain 2.0/s) is accepted within 15% of g.
This reduces impact correction but cannot reject all sustained acceleration.
`acceleration-used` reports whether gravity feedback was eligible in the latest
update. No integral feedback or automatic bias learning is hidden in the filter.

Optional magnetic feedback (default gain 1.0/s) corrects **yaw only**, toward
horizontal magnetic north. Calibrate hard/soft iron, rotate into body axes, and
align timestamps before supplying it. The illustrative 20–70 uT norm gate and
5 uT horizontal minimum reject some unsuitable fields, not all disturbances.
No declination correction is applied. `magnetic-used` reports accepted feedback.
Gains apply over the supplied dt of each update; supplying magnetics on only one
in ten IMU updates lowers its effective correction rate accordingly. Retune or
explicitly align/resample the streams if accurate heading matters.

`AxisMap 2 -1 3` maps native `(x,y,z)` to `(y,-x,z)`. Only proper signed axis
permutations are accepted: duplicate/out-of-range axes and reflections throw.
Convert a sensor's native handedness separately before using `AxisMap` for
mounting rotations. For example, the LIS2MDL has [left-handed native axes](https://community.st.com/mems-sensors-48/lis2mdl-axis-directions-37653);
its board-specific conversion into the IMU frame may require a single sign
change. That conversion belongs before the shared mounting rotation, not in a
reflection applied to gyro data. For arbitrary mounting angles, use a quaternion
or full rotation matrix.

Small public types are `Vector3` (`length`, `finite`, `plus`, `minus`, `cross`,
`scaled`), `Quaternion`, `AxisMap`, and `Fusion`. Values are immutable except for
filter state. The API creates small objects; assess GC/CPU on constrained targets.
It is not an EKF, full Mahony implementation, or a copy of a vendor AHRS library.
Gravity gating, gains, and integration order are deliberately visible in source.

Run the host demo or tests:

```sh
cd examples
jag pkg install
jag toit run tilt.toit
cd ../tests
jag pkg install
jag toit run fusion-test.toit
```

Synthetic tests check tilt initialization, inverted gravity, body-to-world
rotation signs, yaw integration, gravity/magnetic convergence, rejection gates,
and axis handedness. Hardware drift, magnetic interference, and highly dynamic
motion need separate validation. For publishing, copy this directory into its own Git repository, regenerate
example/test lockfiles, and follow the
[Toit publishing guide](https://docs.toit.io/language/package/pkgguide/).
