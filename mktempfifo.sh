#!/bin/busybox sh

#************************************************************************

PATH=
_mkpipe() {
	mkfifo "$(mktemp -u /tmp/pipe-XXXXXX | tee /dev/stderr )"
}
set +x
pipe="$(_mkpipe 2>&1)"
echo pipe $pipe

pipe="$( { mkfifo "$(mktemp -u /tmp/pipe-XXXXXX | tee /dev/stderr )" ; } 2>&1)"
echo pipe $pipe
