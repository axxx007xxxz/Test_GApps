# Test_GApps

**GApps for Android devices**


Build
-------------------

You can compile your GApps package with GNU make

_make distclean_
- Remove output directory

_make gapps_arm_
- Compile signed flashable GApps for arm

_make gapps_arm64_
- Compile signed flashable GApps for arm64

_make gapps_x86_
- Compile signed flashable GApps for x86 (NOT supported atm)


Thanks and credits
-------------------

gmrt
- Mounting of /system script and initial list for gapps

harryyoud, flex1911, raymanfx, deadman96385, jrior001, haggertk, arco
- Throrough testing

jrizzoli
- Initial build scripts and build system

luca020400
- Fixing my makefiles

mikeioannina
- The name for MindTheGapps

syphyr
- Showing me how to repack libs in PrebuiltGmsCore