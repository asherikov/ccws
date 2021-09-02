<table>
  <tr>
    <th>CI status</th>
    <td align="center">
        <a href="https://github.com/asherikov/ccws/actions?query=workflow%3A.github%2Fworkflows%2Fmaster.yml+branch%3Amaster">
        <img src="https://github.com/asherikov/ccws/workflows/.github/workflows/master.yml/badge.svg?branch=master" alt="Build Status">
        </a>
    </td>
  </tr>
</table>


Introduction
============

`CCWS` is a development environment for ROS, which integrates functionalities
of traditional workspaces and CI pipelines in order to facilitate
(cross-)compilation, testing, linting, documetation, and binary package
generation. It is intended to be used both as a CI/CD backbone and a working
environment for developers. Note, however, that `CCWS` is not really meant to
be a ready to use solution, but rather a basis for development of a
vendor-specific workflow.

`CCWS` is in an alpha stage of development and has not been tested with ROS2
yet, but is not conceptually limited to ROS1.


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
      using `doxygen`, similar to https://github.com/mikepurvis/catkin_tools_document.

    - Linting with `clang-tidy` and `scan_build`.

    - Various static checks as in https://github.com/sscpac/statick, in
      particular:
        - `cppcheck`
        - `catkin_lint` https://github.com/fkie/catkin_lint
        - `yamllint`
        - `shellcheck`

- Binary debian package generation.

- Package template which demonstrates how to use some of the features.

- The number of parallel jobs can be selected based on available RAM instead of
  CPU cores, since RAM is more likely to be the limiting factor.

- Based entirely on `make` and shell scripts. All scripts and configurations
  are kept in the workspace and easy to adjust for specific needs.


Build profiles
--------------

Profile configurations are located in `profiles/build`, `common` subdirectory
contains default parameters, which can be overriden by specific profiles:
- [default] `reldebug` -- default compiler, cmake build type is
  `RelWithDebInfo`
- `scan_build` -- static checks with `scan_build` and `clang-tidy`.
  `clang-tidy` parameters are defined in cmake toolchain and must be enabled in
  packages as shown in package template `CMakeLists`. This profile also uses
  `clang` compiler.
- `thread_sanitizer` -- compilation with thread sanitizer.
- `addr_undef_sanitizers` -- compilation with address and undefined behavior
  sanitizers.
- `static_checkers` -- static checkers and their configuration.
- `doxygen` -- doxygen and its configuration.
- `cross_raspberry_pi` -- cross-compilation for Raspberry Pi.
- `cross_jetson_xavier` -- cross-compilation for Jetson Xavier.
- `cross_jetson_nano` -- cross-compilation for Jetson Nano.


Execution profiles
------------------

Execution profiles set environment variables that can be used in launch scripts
to alter run time behavior as demonstrated in `pkg_template/catkin/launch/bringup.launch`,
currently available profiles are:
- `common` -- a set of common ROS parameters, e.g., `ROS_HOME`, it is
  automatically included in binary packages.
- `test` -- sets `CCWS_NODE_CRASH_ACTION` variable so that nodes that respect
  it become `required`, i.e., termination of such nodes would result in crash
  of test scripts and can thus be easily detected.
- `valgrind` -- sets `CCWS_NODE_LAUNCH_PREFIX` to `valgrind` and some variables
  that control behavior of `valgrind`.

Execution profiles have no effect on build process and are taken into account
only in `*test*` targets, where `test` execution profile is always used and
additional profiles can be provided with `EXEC_PROFILE="<profile1>
<profile2>"`. These targets load profiles using `setup.bash` script located in
the root folder of `CCWS`, which can also be used manually, e.g., `source
setup.bash [<build_profile> [<exec_profile1> ...]]`. Note that the setup
script always includes `common` profile, and uses `test` execution profile if
no other execution profiles are specified.


Dependencies
------------

Dependencies can be installed using `make bprof_install_build
BUILD_PROFILE=<profile>`, which is going to install the following tools and
profile specific dependencies:
- `colcon`
- `wstool` -- much more suitable for `CCWS` workflow than `vcstool` which does
  not maintain repository states.
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
- Install dependencies using `make bprof_install_build BUILD_PROFILE=<profile>`
  targets, cross compilation profiles would require some extra steps as
  described below.
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
- `make doxall`, `firefox artifacts/doxygen/index.html`


Debian package generation
-------------------------

### Overview

`CCWS` takes a rather uncommon approach to binary package generation which is a
middle ground between traditional ROS approach (1 package = 1 deb) and docker
containers: all packages built in the workspace are packaged together into a
single debian 'superpackage'. It is assumed that base ROS packages are included
in the workspace, although it is not strictly necessary.

This approach has a number of advantages:

- Binary compatibility issues are minimized compared to traditional ROS
  approach:
    - no need to worry about compatibilities between multiple small standalone
      binary packages and perform ABI checks;

    - if ROS packages are included, it is also possible to avoid binary
      incompatibilities between syncs of the same ROS release (those actually
      happen).

- This approach allows for somewhat sloppier package management compared to ROS
  when it comes to tags, versions, git submodules, etc, e.g., there is no need
  to maintain release repos for all packages.

- Debian 'superpackages' are easier to manage than both standalone packages and
  docker containers, e.g. they can be generated by developers from their
  working branches and easily copied over network to be installed on the
  target;

- Debian packages have some advantages over docker in general as well:
    - Zero overhead during execution.

    - Straightforward access to hardware.

    - Easy installation of system services, udev rules, configs, etc.

- Modification of `CCWS` global version set in `make/config.mk` allows to
  generate packages that can be installed in parallel.


### Building packages

In order to get all paths right in ROS cmake files and properly install system
files we have to install to the host root, we avoid this using proot similarly
to cross-compilation profiles.

Profile build data should be cleared (e.g., with `make wsclean`) before
building binary package, unless you are rebuilding the same package.


Cross-compilation
-----------------

Here `<profile>` stands for `cross_raspberry_pi`, `cross_jetson_xavier`,
`cross_jetson_nano`. Cross-compilation make targets can be found in
`make/cross.mk` and `profiles/<profile>/targets.mk`

Note on `cross_jetson_xavier` and `cross_jetson_nano`: these profiles require
Ubuntu 18.04 / ROS melodic and install `nvcc`, you may want to do this in a
container.

1. Install profile dependencies with `make bprof_install_build
   BUILD_PROFILE=<profile>`
2. Obtain system image:
    - `cross_raspberry_pi` -- `bprof_install_build` target automatically
      downloads standard image;
    - `cross_jetson_xavier`, `cross_jetson_nano` -- `CCWS` does not obtain
      these images automatically, you have to manualy copy system partition
      image to `profiles/cross_jetson_xavier/system.img`.
3. Initialize source repositories:
    - `make wsinit REPOS="https://github.com/asherikov/staticoma.git"`
    - [when building all ROS packages] add ROS dependencies of all your
      packages to the workspace `make wsdep_to_rosinstall ROS_DISTRO=melodic`,
      or a specific package
      `make dep_to_rosinstall PKG=<pkg> ROS_DISTRO=melodic`;
    - fetch all packages `make wsupdate`.
4. Install system dependencies of packages in your workspace to the system
   image: `make bprof_install_host PKG=staticoma BUILD_PROFILE=<profile>`
5. Compile packages:
    - mount sysroot with `make cross_mount BUILD_PROFILE=<profile>`
    - build packages, e.g. `make staticoma BUILD_PROFILE=<profile>` or build and
      generate deb package `make deb PKG=staticoma BUILD_PROFILE=<profile>`
    - unmount sysroot when done with `make cross_umount BUILD_PROFILE=<profile>`

See `doc/cross-compilation.md` for more technical details and
`.ccws/test_cross.mk` for examples.


Extending `CCWS`
================

`CCWS` functionality can be extended in multiple ways:
- by adding new build profiles, e.g., `make bprof_new
  BUILD_PROFILE=vendor_static_checks BASE_BUILD_PROFILE=static_checks`, all
  profiles starting with `vendor` prefix are ignored by git;
- by adding execution profiles;
- `make` targets can be added by creating a
  `profiles/build/vendor/<filename>.mk` file;
- common `cmake` toolchain suffix can be added to
  `profiles/build/vendor/toolchain_suffix.cmake`.

`show_vendor_files` target can be used to list all vendor specific files.


Related software
================

- https://github.com/ros-industrial/industrial_ci -- ROS specific CI scripts,
  noninteractive, "one-shot" design, no sanitizers, emulated cross compilation.
- https://github.com/ros-tooling/cross_compile/ -- emulated cross compilation
  for ROS and ROS2.
- https://github.com/HesselM/rpicross_notes -- cross compilation for Raspberry
  Pi done in a different way.


TODO
====

- Replace `ccache` with https://github.com/mbitsnbites/buildcache.
- Integrate https://github.com/oclint/oclint
- https://github.com/ejfitzgerald/clang-tidy-cache or
  https://github.com/mbitsnbites/buildcache can be used to cache `clang-tidy`
  runs.
- https://github.com/mrtazz/checkmake might be useful for makefile linting.
- Cache cmake checks with https://github.com/cristianadam/cmake-checks-cache,
  https://github.com/polysquare/cmake-forward-cache might be useful too.
- Shell formatter https://github.com/mvdan/sh.
- https://github.com/myint/cppclean might be useful for unnecessary header
  detection, but looks stale.
- https://github.com/include-what-you-use/include-what-you-use
- Build time analysis with clang https://github.com/aras-p/ClangBuildAnalyzer.
- Potential replacement for `scan_build`
  https://github.com/Ericsson/codechecker with extra checks and caching.
- https://github.com/sscpac/statick is not going to be used, but some of its
  linters can be integrated.
- Source code spellcheck https://github.com/myint/scspell.
- https://github.com/jordansissel/fpm -- generic binary package generator,
  potential replacement for `dpkg-deb`.
- https://github.com/git-afsantos/haros -- ROS-aware static analysis, might
  have issues with non `catkin_make` build environments.
- https://github.com/DLu/roscompile/tree/main/roscompile -- linter for catkin
  packages.
- Use https://libguestfs.org/ or https://github.com/alperakcan/fuse-ext2
  instead of loop devices, to avoid using sudo.
- Distributed compilation support with https://github.com/distcc/distcc can be
  useful.
- Add memory sanitizer profile as an alternative to `valgrind`, `gcc` doesn't
  support it currently.
- Add code coverage profile.
