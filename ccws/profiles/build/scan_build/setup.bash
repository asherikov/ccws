#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################
CCWS_PRIMARY_BUILD_PROFILE=${CCWS_PRIMARY_BUILD_PROFILE:-"$(basename "$(dirname "${BASH_SOURCE[0]}")")"}
source "$(dirname "${BASH_SOURCE[0]}")/../${1:-"clang_tidy"}/setup.bash" "${@:2}" ""

CCWS_STATIC_DIR_EXCEPTIONS="${CCWS_STATIC_DIR_EXCEPTIONS}$(ccws_read_exceptions paths)"
EXCEPTIONS=$(echo "${CCWS_STATIC_DIR_EXCEPTIONS}" | sed "s/:/ --exclude /g")


CCWS_BUILD_WRAPPER="\
scan-build-${CCWS_LLVM_VERSION} \
--use-cc=/usr/bin/clang-${CCWS_LLVM_VERSION} \
--use-c++=/usr/bin/clang++-${CCWS_LLVM_VERSION} \
-o ${CCWS_ARTIFACTS_DIR} \
--status-bugs \
--exclude ${WORKSPACE_DIR}/build \
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

export CCWS_BUILD_WRAPPER

##########################################################################################
