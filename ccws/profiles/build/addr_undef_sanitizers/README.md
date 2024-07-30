Notes:

- Needs extra permissions when running in docker:
  https://stackoverflow.com/questions/49735926/address-sanitizer-with-gcc-fails-on-ubuntu-17-10-docker-container

- Leaks are checked on termination of the process which means that if the
  return status of the process is not taken into account errors do not result
  in a failure. It looks like `rostest` ignores statuses of all nodes except
  the test itself.
