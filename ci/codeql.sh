#!/bin/sh

. "$OWROOT/cmnvars.sh"

sh build.sh boot
RC=$?
if [ $RC -ne 0 ]; then
    BOOTX_LOG="$OWROOT/build/$OWOBJDIR/bootx.log"
    if [ -f "$BOOTX_LOG" ]; then
        echo "===== wmake bootstrap log ($BOOTX_LOG) ====="
        cat "$BOOTX_LOG"
        echo "===== end of wmake bootstrap log ====="
    fi
fi
exit $RC
