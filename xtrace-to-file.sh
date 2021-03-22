#!/bin/busybox ash

#  lnet-xtrace
#************************************************************************

#PATH=

_option_is_set() {
	set -o | \
	awk -v option="${1}" -v value="${2:-"on"}" \
		'$1 == option {rc=-($2 == value); exit}
		END{exit rc+1}'
}

_datetime() {
	date +"%F %X"
}

_loopwait() {
	{ if _option_is_set "xtrace"; then
		DATETIME="$(_datetime)"
		local FUNCNAME="_loopwait" SECTION=""
	fi
	} 2> /dev/null
	echo hello $i
	sleep 1
	return 0
}

_looping() {
	{ if _option_is_set "xtrace"; then
		DATETIME="$(_datetime)"
		local FUNCNAME="_looping" SECTION=""
	fi
	} 2> /dev/null
	local i
	{ if _option_is_set "xtrace"; then
		SECTION="first_loop"
	fi
	} 2> /dev/null
	i=0
	while [ $((i++)) -le 5 ]; do
		echo $i
		_loopwait
	done
	{ if _option_is_set "xtrace"; then
		SECTION="second_loop"
	fi
	} 2> /dev/null
	i=0
	while [ $((i++)) -le 5 ]; do
		echo $i
		_loopwait
	done
}

if [ -n "${DEBUG:-}" ] || \
_option_is_set "xtrace"; then
	set +o xtrace
	exec 2> "/tmp/$(basename "${0}")-xtrace.txt"
	export PS4='+ ${DATETIME}:${ASH_SOURCE}:${FUNCNAME}:${SECTION}:'
	ASH_SOURCE="$(basename "${0}")"
	FUNCNAME=""
	SECTION=""
	DATETIME="$(_datetime)"
	set -o xtrace
fi

set -o errexit -o pipefail

_looping
