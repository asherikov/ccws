# Development context

## Source space

- Package repositories are located in subdirectories of /ccws/workspace/src,
  which is called "source space".
- When searching for packages always start in the source space.

## Framework

- Packages should be created, built, tested, and analysed using ccws framework
  as documented in /ccws/README.md.
- All ccws commands should be executed with make in /ccws directory.
- All ccws dependencies are preinstalled.
- Perform builds using a specific ccws profile by passing its name with
  BUILD\_PROFILE parameter to make.
- ccws takes care of proper compilation and static analysis configuration, do
  not bypass it.
- Do not execute static analysis tools or compilers without ccws assistance.
- Packages should be verified using ccws as follows:
    - run static analysis using static\_checks profile, fix detected issues;
    - install package dependencies using dep\_install make target;
    - build package using reldebug build profile;
    - run tests if they are present in the package.

# Rules for code generation

- Be concise:
    - Do not insert output or logging statements.
    - Comment lines should not exceed 10% of a file.
    - Produce minimal necessary modifications when implementing features.
    - Reuse existing code instead of coyping it.
- States of a state machine should not make assumptions on preceding or
  following states.
- Use 4 spaces for indentation in all file types by default, but preserve
  indentation and formatting in existing files.

## Shell scripts

- Use `env` in shebang.
- Always use upper case and curly braces in variable names.
- Always set pipefail option and fail on error.
