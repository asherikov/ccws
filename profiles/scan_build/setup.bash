#!/bin/bash -x
# shellcheck disable=SC1090

# fail on error
set -e
set -o pipefail

##########################################################################################

#CCW_ROS_DISTRO=`ls /opt/ros/`
CCW_ROS_DISTRO="melodic"
export CCW_ROS_DISTRO
CCW_PROFILE="scan_build"
export CCW_PROFILE

source "./profiles/common/setup.bash"

# shellcheck disable=SC2001
EXCEPTIONS=$(echo ${CCW_STATIC_PATH_EXCEPTIONS} | sed "s/ / --exclude /g")

#apt install clang-tools-10
CCW_BUILD_WRAPPER="\
scan-build-10 \
--use-cc=/usr/bin/clang-10 \
--use-c++=/usr/bin/clang++-10 \
-o ${CCW_ARTIFACTS_DIR}/clang_static_analysis \
--status-bugs \
--exclude ${CCW_WORKSPACE_DIR}/build \
--exclude /usr/include/ \
--exclude /usr/src/ \
--exclude /opt/ros/ \
${EXCEPTIONS} \
-enable-checker core.CallAndMessage \
-enable-checker core.DivideZero \
-enable-checker core.DynamicTypePropagation \
-enable-checker core.NonNullParamChecker \
-enable-checker core.NullDereference \
-enable-checker core.StackAddressEscape \
-enable-checker core.UndefinedBinaryOperatorResult \
-enable-checker core.VLASize \
-enable-checker core.uninitialized.ArraySubscript \
-enable-checker core.uninitialized.Assign \
-enable-checker core.uninitialized.Branch \
-enable-checker core.uninitialized.CapturedBlockVariable \
-enable-checker core.uninitialized.UndefReturn \
-enable-checker cplusplus.InnerPointer \
-enable-checker cplusplus.Move \
-enable-checker cplusplus.NewDelete \
-enable-checker cplusplus.NewDeleteLeaks \
-enable-checker deadcode.DeadStores \
-enable-checker nullability.NullPassedToNonnull \
-enable-checker nullability.NullReturnedFromNonnull \
-enable-checker nullability.NullableDereferenced \
-enable-checker nullability.NullablePassedToNonnull \
-enable-checker nullability.NullableReturnedFromNonnull \
-enable-checker optin.cplusplus.UninitializedObject \
-enable-checker optin.mpi.MPI-Checker \
-enable-checker optin.performance.GCDAntipattern \
-enable-checker optin.performance.Padding \
-enable-checker optin.portability.UnixAPI \
-enable-checker security.FloatLoopCounter \
-enable-checker security.insecureAPI.DeprecatedOrUnsafeBufferHandling \
-enable-checker security.insecureAPI.UncheckedReturn \
-enable-checker security.insecureAPI.getpw \
-enable-checker security.insecureAPI.gets \
-enable-checker security.insecureAPI.mkstemp \
-enable-checker security.insecureAPI.mktemp \
-enable-checker security.insecureAPI.vfork \
-enable-checker unix.API \
-enable-checker unix.Malloc \
-enable-checker unix.MallocSizeof \
-enable-checker unix.MismatchedDeallocator \
-enable-checker unix.Vfork \
-enable-checker unix.cstring.BadSizeArg \
-enable-checker unix.cstring.NullArg \
-enable-checker valist.CopyToSelf \
-enable-checker valist.Uninitialized \
-enable-checker valist.Unterminated"

export CCW_BUILD_WRAPPER

##########################################################################################
set +e
