#!/usr/bin/env python3
"""Merge Clang '-ftime-trace' files into a single trace.

Clang time traces use the Chrome Trace Event format and cannot be combined by
concatenation, so all matching '*.json' files found in a build directory are
merged into one trace: every file gets its own trace id (process) and a
'process_name' metadata event derived from the file name. The result can be
opened in an interactive viewer, e.g. https://www.speedscope.app,
https://ui.perfetto.dev or chrome://tracing.
"""

import json
import os
import sys


def main():
    if len(sys.argv) != 3:
        sys.stderr.write("usage: {} <build_dir> <output_file>\n".format(sys.argv[0]))
        return 1

    build_dir = os.path.realpath(sys.argv[1])
    output_file = os.path.realpath(sys.argv[2])

    events = []
    traces = 0
    next_pid = 1
    for base, _, files in os.walk(build_dir):
        for name in sorted(files):
            if not name.endswith(".json"):
                continue
            path = os.path.join(base, name)
            try:
                with open(path, encoding="utf-8", errors="replace") as trace_file:
                    trace = json.load(trace_file)
            except (OSError, ValueError) as exception:
                sys.stderr.write("skipping '{}': {}\n".format(path, exception))
                continue
            if not isinstance(trace, dict) or "traceEvents" not in trace:
                continue
            # command line arguments of the compiler, for reference
            arguments = trace.get("args", {}).get("detail")
            for event in trace["traceEvents"]:
                if event.get("ph") == "M" and event.get("name") == "process_name":
                    continue
                event["pid"] = next_pid
                events.append(event)
            # appended last so that it is not overridden by the metadata of
            # the time trace itself, which always names the process 'clang'
            events.append(
                {
                    "name": "process_name",
                    "ph": "M",
                    "pid": next_pid,
                    "tid": 0,
                    "args": {"name": name + (": " + arguments if arguments else "")},
                }
            )
            traces = traces + 1
            next_pid = next_pid + 1

    if traces == 0:
        sys.stderr.write("no time traces found in '{}'\n".format(build_dir))
        return 1

    with open(output_file, "w", encoding="utf-8") as out_file:
        json.dump({"traceEvents": events}, out_file)
    print("merged {} time traces into '{}'".format(traces, output_file))
    return 0


if __name__ == "__main__":
    sys.exit(main())
