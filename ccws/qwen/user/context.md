# Development context

## Environment

- Coding agent is running inside a docker container as a part of ccws
  framework. Preload corresponding skill on startup.
- All ccws profile dependencies are preinstalled in the container.
- sudo password is 'ccws'
- Unless explicitly requested, you are strictly prohibited to bypass ccws
  framework in order to: compile packages (colcon, cmake, gcc, etc), install
  dependencies (apt, pip, etc), run static analysis tools (pylint, cppcheck,
  etc).

## Source space

- Package repositories are located in subdirectories of /ccws/workspace/src,
  which is called "source space".
- When searching for packages always start in the source space.

## Framework

- Packages should be created, built, tested, and analysed using ccws framework
  as documented in /ccws/README.md.
- All ccws commands should be executed with make in /ccws directory.
- Use ccws targets to clear build directories, never delete directories or
  files inside /ccws and /ccws/workspace directories.
- Never try to fix ccws: if compilation fails the issue is either in the
  package, or the workspacce needs cleaning.
- All ccws dependencies are preinstalled.
- ccws builds package dependencies automatically as long as package manifest
  (package.xml files) are properly formed.
- Perform builds using a specific ccws profile by passing its name with
  BUILD\_PROFILE parameter to make.
- ccws takes care of proper compilation and static analysis configuration, do
  not bypass it.
- Do not execute static analysis tools or compilers without ccws assistance.

# Rules for code generation

- Never add comments to source files.
- Do not insert output or logging statements.
- Produce minimal necessary modifications when implementing features.
- Reuse existing code instead of copying it.
- States of a state machine should not make assumptions on preceding or
  following states.
- Use 4 spaces for indentation in all file types by default, but preserve
  indentation and formatting in existing files.

## Shell scripts

- Use `env` in shebang.
- Always use upper case and curly braces in variable names.
- Always set pipefail option and fail on error.
