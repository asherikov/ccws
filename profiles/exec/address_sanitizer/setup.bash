#!/bin/bash -x

# to be used together with `addr_undef_sanitizers` build profile
# see addr_undef_sanitizers/setup.bash for more information

##########################################################################################

# https://stackoverflow.com/questions/48833176/get-location-of-libasan-from-gcc-clang
LD_PRELOAD=$(gcc -print-file-name=libasan.so)
export LD_PRELOAD

##########################################################################################
