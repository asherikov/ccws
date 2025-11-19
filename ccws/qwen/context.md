# Development context

## Source space

- Packages with source code are located in subdirectories of
  /ccws/workspace/src, which is called source space.
- When searching for packages always start in the source space.

## Framework

- Packages should be built, tested, and created using ccws framework as
  documented in /ccws/README.md.
- All ccws commands should be executed in /ccws directory.
- All ccws dependencies are preinstalled.
- Packages should be verified using ccws as follows:
    - run static analysis using static\_checks profile, fix detected issues;
    - install package dependencies using dep\_install make target;
    - build package using reldebug build profile;
    - run tests if they are present in the package.

# Rules for code generation

- States of a state machine should not make assumptions on preceding or
  following states.
- Do not add logging messages unless requested to do so.
- Use 4 spaces for indentation in all file types by default, but preserve
  indentation and formatting in existing files.


@/ccws/README.md
