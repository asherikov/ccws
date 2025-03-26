<table>
  <tr>
    <th>CI status</th>
    <td align="center">
        <a href="https://github.com/asherikov/ccws/actions?query=workflow%3A.github%2Fworkflows%2Fmaster.yml+branch%3Amaster">
        <img src="https://github.com/asherikov/ccws/actions/workflows/master.yml/badge.svg" alt="Build Status">
        </a>
    </td>
  </tr>
</table>


Introduction
============

`CCWS` is a development environment for ROS, which integrates functionality of
traditional `catkin` workspaces and CI pipelines in order to facilitate
(cross-)compilation, testing, linting, documetation and binary package
generation. It is intended to be used both as a CI/CD backbone and a working
environment for developers. Note that `CCWS` is not intended to be a complete
solution, but rather a basis for development of a vendor-specific workflow.

`CCWS` is ROS version agnostic, and should work in most cases for both ROS1 and
ROS2.


Features
--------

- Build profiles -- sets of configurations for build process, e.g., cmake
  toolchain, colcon configuration, environment variables, etc. Profiles do not
  conflict with each other and can be used in parallel without using separate
  clones of the workspace and packages.

- Execution profiles -- simple shell mixins that are intended to modify run
  time environment, e.g., execute nodes in `valgrind`, alter node crash
  handling, etc.

- A number of features implemented via build profiles:
    - Cross compilation to several common platforms.

    - Documentation generation for the whole workspace or selected packages
      using `doxygen`, similar to <https://github.com/mikepurvis/catkin_tools_document>.

    - Linting with `clang-tidy` and `scan_build`.

    - Various static checks as in <https://github.com/sscpac/statick>, in
      particular:
        - `cppcheck`
        - `catkin_lint` <https://github.com/fkie/catkin_lint>
        - `yamllint`
        - `shellcheck`

    - Binary debian package generation.

- Package template which demonstrates how to use some of the features.

- The number of parallel jobs can be selected based on available RAM instead of
  CPU cores, since RAM is likely to be the limiting factor.

- Based entirely on `make` and shell scripts. All scripts and configurations
  are kept in the workspace and easy to adjust for specific needs.


Build profiles
--------------

Profile configurations are located in `ccws/profiles/build`, `common`
subdirectory contains default parameters, which can be overriden by specific
profiles:
- [default] `reldebug` -- default compiler, cmake build type is
  `RelWithDebInfo`
- `scan_build` -- static checks with `scan_build` and `clang-tidy`.
  `clang-tidy` parameters are defined in cmake toolchain and must be enabled in
  packages as shown in package template `CMakeLists`. This profile also uses
  `clang` compiler.
- `thread_sanitizer` -- compilation with thread sanitizer.
- `addr_undef_sanitizers` -- compilation with address and undefined behavior
  sanitizers.
- `static_checks` -- static checkers and their configuration.
- `doxygen` -- doxygen and its configuration.
- `cross_raspberry_pi` -- cross-compilation for Raspberry Pi.
- `cross_jetson_xavier` -- cross-compilation for Jetson Xavier.
- `cross_jetson_nano` -- cross-compilation for Jetson Nano.
- `clangd` -- collects compilation commands from another profile and generates
  clangd configuration file in the workspace root.
- `deb` -- debian package generation (see below).


Execution profiles
------------------

Execution profiles set environment variables that can be used in launch scripts
to alter run time behavior as demonstrated in
`ccws/pkg_template/catkin/launch/bringup.launch`, currently available profiles
are:
- `common` -- a set of common ROS parameters, e.g., `ROS_HOME`, it is
  automatically included in binary packages.
- `test` -- sets `CCWS_NODE_CRASH_ACTION` variable so that nodes that respect
  it become `required`, i.e., termination of such nodes would result in crash
  of test scripts and can thus be easily detected.
- `valgrind` -- sets `CCWS_NODE_LAUNCH_PREFIX` to `valgrind` and some variables
  that control behavior of `valgrind`.
- `core_pattern` -- sets core pattern to save core files in the artifacts
  directory.
- `address_sanitizer` -- helper for `addr_undef_sanitizers` profile.

Execution profiles have no effect on build process and are taken into account
in `*test*` targets or debian packages. `test` execution profile is always used
in tests and additional profiles can be provided with `EXEC_PROFILE="<profile1>
<profile2>"`. These targets load profiles using `setup.bash` script located in
the root folder of `CCWS`, which can also be used manually, e.g., `source
setup.bash [<build_profile> [<exec_profile1> ...]]`. Note that the setup script
always includes `common` profile, and uses `test` execution profile if no other
execution profiles are specified.


Dependencies
------------

Dependencies can be installed using `make bp_install_build
BUILD_PROFILE=<profile>[,<profile>...]`, which is going to install the
following tools and profile specific dependencies:
- `colcon`
- `yq` -- <https://github.com/asherikov/wshandler> dependency
- `cmake`
- `ccache` -- can be disabled in cmake toolchains
- `wget`



Usage
=====

See `.ccws/test_main.mk` for command usage hints.


Initial setup
-------------

- Override developer and vendor specific parameters by adding them to
  `make/config.mk`, available parameters can be found in the top section of
  `Makefile`.
- Install dependencies using `make bp_install_build BUILD_PROFILE=<profile>`
  targets, cross compilation profiles would require some extra steps as
  described below. In some minimalistic environments you may need to run
  `./ccws/scripts/bootstrap.sh` before using `bp_install_build` target in order to
  install `make` and other utils.
- Clone packages in `src` subdirectory, or create new using `make new PKG=<pkg>`.


Compilation
-----------

- `make build PKG="<pkg>"` where `<pkg>` is one or more space separated package
  names.
- `make <pkg>` -- a shortcut for `make build`, but `<pkg>` can be a substring
  of package name. All packages matching the given substring will be built.
- The number of jobs can be overriden with `JOBS=X` parameter.
- `make build PKG=<pkg> BUILD_PROFILE=scan_build` overrides default profile.


Running
-------

- Source `setup.bash <profile>` to be able to use packages. Setup scripts
  generated by `colcon` can also be used directly, e.g.,
  `install/<profile>/local_setup.sh`, but in this case some of `CCWS`
  functionality won't be available.


Testing
-------
- `make test PKG=<pkg>` test with `colcon`, or `make wstest` to test all.
- `make ctest PKG=<pkg>` bypass `colcon` and run `ctest` directly or `make
  wsctest` to test all.


Documentation
-------------
- `make BUILD_PROFILE=doxygen`, `firefox artifacts/doxygen/index.html`
- See example at <https://asherikov.github.io/ccws/>


Debian package generation
-------------------------

### Overview

`CCWS` takes a somewhat uncommon approach to binary package generation which is
a middle ground between traditional ROS (1 package = 1 deb) and docker
containers: all packages built in the workspace are packed together into a
single debian 'superpackage'. Unlike `bloom` `CCWS` generates binary packages
directly instead of generating source packages first.

Binary package generation is implemented as a build profile mixin that can be
overlayed over an arbitrary build profile: `make <pkg>
BUILD_PROFILE=deb,reldebug`.

`CCWS` approach has a number of advantages:

- Binary compatibility issues are minimized compared to traditional ROS
  approach:
    - no need to worry about compatibilities between multiple standalone binary
      packages and perform ABI checks;

    - if base ROS packages are included, it is also possible to avoid binary
      incompatibilities between syncs of the same ROS release (those actually
      happen).

- Package repository management can be sloppier compared to ROS when it comes
  to tags, versions, git submodules, etc, e.g., there is no need to maintain
  release repos for all packages.

- Debian 'superpackages' are easier to handle than both standalone packages and
  docker containers, e.g., they can be generated by developers from their
  working branches and easily copied and installed on the target.

- Debian packages have some advantages over docker containers in general:
    - Zero overhead during execution.

    - Straightforward access to hardware.

    - Easy installation of system services, udev rules, configs, etc.

- Multiple variants of binary 'superpackage' can be installed simultaneously if
  they are built using different `VERSION` parameter. Note that it alters
  installation path, so some workspace packages that are being "smart" with
  `cmake` may require cleaning build directory if they have been built earlier.


### Building packages

Generally, it is necessary to install packages to the filesystem root during
compilation in order to get all paths right in `catkin` `cmake` files and
properly install system files. `CCWS` avoids this using `proot` similarly to
cross-compilation profiles.


Cross-compilation
-----------------

Here `<profile>` stands for `cross_raspberry_pi`, `cross_jetson_xavier`,
`cross_jetson_nano`. Cross-compilation make targets can be found in
`ccws/make/cross.mk` and `ccws/profiles/<profile>/targets.mk`

Note on `cross_jetson_xavier` and `cross_jetson_nano`: these profiles require
Ubuntu 18.04 / ROS melodic and install `nvcc`, you may want to do this in a
container.

The general workflow is documented below, for more technical details see
`ccws/doc/cross-compilation.md` and `CCWS` CI test in `.ccws/test_cross.mk`:

1. Install profile dependencies with `make bp_install_build
   BUILD_PROFILE=<profile>`
2. Obtain system image:
    - `cross_raspberry_pi` -- `bp_install_build` target automatically
      downloads standard image;
    - `cross_jetson_xavier`, `cross_jetson_nano` -- `CCWS` does not obtain
      these images automatically, you have to manualy copy system partition
      image to `ccws/profiles/cross_jetson_xavier/system.img`.
3. Initialize source repositories:
    - `make wsinit REPOS="https://github.com/asherikov/staticoma.git"`
    - [when building all ROS packages] add ROS dependencies of all your
      packages to the workspace `make dep_to_repolist ROS_DISTRO=melodic`,
      or a specific package
      `make dep_to_repolist PKG=<pkg> ROS_DISTRO=melodic`;
    - fetch all packages `make wsupdate`.
4. Install system dependencies of packages in your workspace to the system
   image: `make cross_install PKG=staticoma BUILD_PROFILE=<profile> ROS_DISTRO=<distro>`
5. Compile packages:
    - mount sysroot with `make cross_mount BUILD_PROFILE=<profile>`
    - build packages, e.g. `make staticoma BUILD_PROFILE=<profile>` or build and
      generate deb package `make deb PKG=staticoma BUILD_PROFILE=<profile>`
    - unmount sysroot when done with `make cross_umount BUILD_PROFILE=<profile>`


Using `CCWS` docker
===================

A docker image with preinstalled `CCWS` and dependencies is available for
testing, but it is recommended to build a tailored image using
`ccws/examples/Dockerfile` as an example.

The image can be used in the following way:

- `docker pull asherikov/ccws`
- `mkdir tmp_ws` # sources, build, install, cache will go here
- `docker run --rm -ti -v ./tmp_ws:/ccws/workspace asherikov/ccws bash`
- `make wsinit REPOS="https://github.com/asherikov/qpmad.git"`
- `...`


Extending `CCWS`
================

`CCWS` functionality can be extended in multiple ways:
- by adding new build profiles, e.g., `make bp_new
  BUILD_PROFILE=vendor_static_checks,static_checks`, all profiles starting with
  `vendor` prefix are ignored by git;
- by adding execution profiles;
- `make` targets can be added by creating a
  `ccws/profiles/build/vendor/<filename>.mk` file;
- common `cmake` toolchain suffix can be added to
  `ccws/profiles/build/vendor/toolchain_suffix.cmake`.


Known issues
============

- Segmentation fault during cross-compilation or debian package generation
  indside docker containers (both require `proot`): presumably due to `seccomp`
  Linux feature, which can be disabled with `--security-opt seccomp:unconfined`
  docker parameter. Disabling `seccomp` for `proot` with `PROOT_NO_SECCOMP=1`
  seems to be unnecessary.

- Programs compiled with sanitizers (`addr_undef_sanitizers` or
  `thread_sanitizer` build profiles) output `2: AddressSanitizer:DEADLYSIGNAL`
  or `FATAL: ThreadSanitizer: unexpected memory mapping` when executed: the
  reason is tightened memory security with ASLR (address space layout
  randomization) in modern Linux kernels, see
  <https://github.com/google/sanitizers/issues/1614>. The issue can be
  alleviated by setting `sudo sysctl vm.mmap_rnd_bits=28`.

- Some of ROS2 core packages cannot be built with `CCWS` due to cmake misuse,
  e.g., see <https://github.com/ament/google_benchmark_vendor/issues/17>.

- `proot` segfault while building on arm64 in Ubuntu 22, e.g., while building
  debian packages. Newer version of `proot` has to be used, see
  <https://github.com/proot-me/proot/issues/312>.


Related software
================

- <https://github.com/ros-industrial/industrial_ci> -- ROS specific CI scripts,
  noninteractive, "one-shot" design, no sanitizers, emulated cross compilation.
- <https://github.com/ros-tooling/cross_compile/> -- emulated cross compilation
  for ROS and ROS2.
- <https://github.com/HesselM/rpicross_notes> -- cross compilation for
  Raspberry Pi done in a different way.
- <https://github.com/ros-tooling/action-ros-ci> -- `github` action that covers
  some of `CCWS` functionality.
- <https://github.com/ros-infrastructure/ros_buildfarm>,
  <http://wiki.ros.org/buildfarm> -- the core of ROS packaging infrastructure.
  Complicated, specialized on handling of individual packages rather than
  workspaces, not suitable for quick field redeployments.
- <https://github.com/colcon/colcon-bundle> provides functionality similar to
  'superpackages' allowing to pack install space into a single archive.
  Naturally, it does not provide all the package features like dependencies,
  install scripts, etc. Moreover, it does not rely on chroot-like environment
  to ensure correct paths.


TODO
====

- Fuzzing <https://github.com/rosin-project/ros2_fuzz>,
  <https://github.com/sslab-gatech/RoboFuzz>,
  <https://github.com/AFLplusplus/AFLplusplus>,
  <https://github.com/google/clusterfuzzlite>.
- Investigate generation of debug and development packages.
- Reproducible builds <https://reproducible-builds.org/>.
- Replace `ccache` with <https://github.com/mbitsnbites/buildcache>.
- Integrate <https://github.com/oclint/oclint>
- <https://github.com/ejfitzgerald/clang-tidy-cache> or
  <https://github.com/mbitsnbites/buildcache> can be used to cache `clang-tidy`
  runs.
- <https://github.com/mrtazz/checkmake> might be useful for makefile linting.
- Cache cmake checks with <https://github.com/cristianadam/cmake-checks-cache>,
  <https://github.com/polysquare/cmake-forward-cache> might be useful too.
- Shell formatter <https://github.com/mvdan/sh>.
- <https://github.com/myint/cppclean> might be useful for unnecessary header
  detection, but looks stale.
- <https://github.com/include-what-you-use/include-what-you-use>
- Build time analysis with clang <https://github.com/aras-p/ClangBuildAnalyzer>
  and / or <https://github.com/jrmadsen/compile-time-perf>.
- Potential replacement for `scan_build`
  <https://github.com/Ericsson/codechecker> with extra checks and caching.
- <https://github.com/sscpac/statick> is not going to be used, but some of its
  linters can be integrated.
- Source code spellcheck <https://github.com/myint/scspell>.
- <https://github.com/jordansissel/fpm> -- generic binary package generator,
  potential replacement for `dpkg-deb`.
- <https://github.com/git-afsantos/haros> -- ROS-aware static analysis, might
  have issues with non `catkin_make` build environments.
- <https://github.com/Tencent/TscanCode> -- C++ static analysis tool.
- <https://github.com/DLu/roscompile/tree/main/roscompile> -- linter for catkin
  packages.
- Use <https://libguestfs.org/> or <https://github.com/alperakcan/fuse-ext2>
  instead of loop devices, to avoid using sudo. There are some issues in Ubuntu
  though, bug 759725, see <https://libguestfs.org/guestfs-faq.1.html>.
  `guestfs` is too slow to be practical.
- Distributed compilation support with <https://github.com/distcc/distcc> can
  be useful.
- Add memory sanitizer profile as an alternative to `valgrind`, `gcc` doesn't
  support it currently.
- Add code coverage profile.
- Execution profile with <https://github.com/yugr/libdebugme> to automatically
  start debugger on a signal.
- <https://github.com/yugr/valgrind-preload> as an alternative to `valgrind`
  execution profile -- an overkill in general case though.
- Control symbol visibility and verify with
  <https://github.com/yugr/ShlibVisibilityChecker>.
- Add `CodeQL` profile (<https://github.com/github/codeql>).
- cmake 3.21: `--output-junit <file> = Output test results to JUnit XML file.`
