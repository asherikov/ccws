Introduction
============

`CCWS` is a development environment for ROS, which integrates functionalities
of traditional workspaces and CI pipelines in order to facilitate
(cross-)compilation, testing, linting, documetation generation, binary package
generation. It is intended to be used both as a CI/CD backbone and a working
environment for developers.

`CCWS` is in an alpha stage of development and has not been tested with ROS2
yet, but is not conceptually limited to ROS1.


Features
--------

- Build profiles -- sets of configurations for build process, e.g., cmake
  toolchain, colcon configuration, environment variables, etc. Profiles do not
  conflict with each other and can be used simultaneously without using
  separate clones of the workspace and packages.

- Documentation generation for the whole workspace using `doxygen`, similar to
  https://github.com/mikepurvis/catkin_tools_document, but `doxygen`
  configuration and index html page are exposed and kept in the workspace.
  Example -> https://asherikov.github.io/ccws/example_staticoma/index.html

- Various static checks as in https://github.com/sscpac/statick, but with more
  flexibility (see `make/static_checks.mk`), in particular:
    - `cppcheck`
    - `catkin_lint` https://github.com/fkie/catkin_lint
    - `yamllint`
    - `shellcheck`
    - `clang-tidy` and `scan_build` via build profile, see below.

- Package template which demonstrates how to use some of the features.

- The number of parallel jobs can be selected based on available RAM instead of
  CPU cores, since RAM is more likely to be the limiting factor.

- Based entirely on `make` and shell scripts. All scripts are kept in the
  workspace and easy to adjust for specific needs.

- Cross-compilation support.

- Binary debian package generation.


Profiles
--------

Profile configurations are located in `profiles`, currently availabale profiles are
- `reldebug` -- default profile, default compiler, cmake build type is
  `RelWithDebInfo`
- `scan_build` -- static checks with `scan_build` and `clang-tidy`.
  `clang-tidy` parameters are defined in cmake toolchain and must be enabled in
  packages as shown in package template. This profile also uses `clang` compiler.
- `thread_sanitizer` -- compilation with thread sanitizer.
- `addr_undef_sanitizers` -- compilation with address and undefined behavior
  sanitizers.
- `cross_raspberry_pi` -- cross-compilation for Raspberry Pi.
- `cross_jetson_xavier` -- cross-compilation for Jetson Xavier.

All profiles use `ccache`, but it can be disabled in cmake toolchains.

`common` subdirectory contains default parameters, which may be overriden by
build profiles.


Dependencies
------------

Dependencies can be installed using `make install PROFILE=<profile>`, which is
going to install some of the following:


### Required
- `colcon`
- `wstool` -- it provides much more advanced features than `vcstool` which does
  not maintain package states locally.
- `cmake`

Some packages are not strictly required, but installed by default:
- `doxygen`
- `ccache`
- `wget`


### Static checks
- static checkers, see `install_static_checkers` target in `make/static_checks.mk`



Usage
=====

Demo workspace is available in a branch of this repository ->
https://github.com/asherikov/ccws/tree/example_staticoma


Initial setup
-------------

- Edit `make/config.mk` and `profiles/common/config.bash` to specify
  developer-dependent worskpace parameters.
- Install dependencies using `make install PROFILE=<profile>` targets.
- Clone packages in `src` subdirectory, or create new using `make new PKG=<pkg>`.


Compilation
-----------

- `make build PKG="<pkg>"` where `<pkg>` is one or more space separated package
  names.
- `make <pkg>` -- a shortcut for `make build`, but `<pkg>` can be a substring
  of package name. All packages matching the given substring will be built.
- The number of jobs can be overriden with `JOBS=X` parameter.
- `make build PKG=<pkg> PROFILE=scan_build` overrides default profile.


Running
-------

- Source `setup.bash <profile>` to be able to use packages. Setup scripts
  generated by `colcon` can also be used directly, e.g.,
  `install/<profile>/local_setup.sh`, but in this case some of CCWS
  functionality won't be available.


Testing
-------
- `make test PKG=<pkg>` test with `colcon`.
- `make ctest PKG=<pkg>` bypass colcon and run `ctest` directly.


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
  when it comes to tags, versions, etc, e.g., there is no need to maintain
  release repos for all packages.

- Debian 'superpackages' are easier to manage than both standalone packages and
  docker containers, e.g. they can be generated by developers from their
  working branches and easily copied over network to be installed on the
  target;

- Debian packages have some advantages over docker in general as well:
    - Zero overhead during execution.

    - Straightforward access to hardware.

    - Easy installation of system services, udev rules, configs, etc.


### Building packages

In order to get all paths right in ROS cmake files and properly install system
files we have to install to the host root, we avoid this using proot similarly
to cross-compilation profiles.

Profile build data should be cleared (e.g., with `make wsclean`) before
building binary package, unless you are rebuilding the same package.


Cross-compilation
-----------------

Here `<profile>` stands for `cross_raspberry_pi` or `cross_xavier_jetson`.
Cross-compilation make targets can be found in `make/cross.mk` and
`profiles/<profile>/targets.mk`

Note on `cross_xavier_jetson`: This profile requires Ubuntu 18.04 / ROS melodic
and installs `nvcc`, you may want to do this in a docker.


1. Install profile dependencies with `make install PROFILE=<profile>`
2. Obtain system image:
    - `cross_raspberry_pi` -- use `make fetch PROFILE=cross_raspberry_pi` to
      download and prepare standard image;
    - `cross_xavier_jetson` -- copy APP partition image to
      `profiles/cross_xavier_jetson/system.img`.
3. Initialize source repositories:
    - make wsinit REPOS="https://github.com/asherikov/staticoma.git"
    - [when building all ROS packages] add ROS dependencies of all your
      packages to the workspace `make wsdep_to_rosinstall ROS_DISTRO=melodic`,
      or a specific package
      `make dep_to_rosinstall PKG=<pkg> ROS_DISTRO=melodic`;
    - fetch all packages `make wsupdate`.
4. Install system dependencies of packages in your workspace to the system
   image: `make cross_dep_install PKG=staticoma PROFILE=<profile>`
5. Compile packages:
    - mount sysroot with `make cross_mount PROFILE=<profile>`
    - build packages, e.g. `make staticoma PROFILE=<profile>` or build and
      generate deb package `make deb PKG=staticoma PROFILE=<profile>`
    - unmount sysroot when done with `make cross_umount PROFILE=<profile>`

See `doc/cross-compilation.md` for more technical details.



Related software
================

Related projects:
- https://github.com/ros-industrial/industrial_ci
- https://github.com/git-afsantos/haros
- https://github.com/DLu/roscompile
- https://github.com/asherikov/catkin_workspace [deprecated]
- https://github.com/ros-tooling/cross_compile/
- https://github.com/mikepurvis/catkin_tools_document
