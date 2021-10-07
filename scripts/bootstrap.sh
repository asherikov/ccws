#!/bin/sh

# some utils must be installed before CCWS installation targets can be used
env DEBIAN_FRONTEND=noninteractive apt --yes --no-install-recommends install make lsb-release sudo
