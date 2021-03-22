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

_xtrace() {
	IFS=":"
	while true; do
		if read -r ASH_SOURCE FUNCNAME SECTION line <&3; then
			printf '+ %s %s:%15s:%12s: %s\n' \
				"$(date +'%F %X')" \
				"${ASH_SOURCE}" \
				"${FUNCNAME}" \
				"${SECTION}" \
				"${line}"
		fi
	done > "${1}"
}

_loopwait() {
	{ if _option_is_set "xtrace"; then
		local FUNCNAME="_loopwait" SECTION=""
	fi
	} 2> /dev/null
	echo hello $i
	sleep 1
	return 0
}

_looping() {
	{ if _option_is_set "xtrace"; then
		local FUNCNAME="_looping" SECTION=""
	fi
	} 2> /dev/null
	local i
	{ if _option_is_set "xtrace"; then
		SECTION="first_loop"
	fi
	} 2> /dev/null
	i=0
	while [ $((i++)) -le 3 ]; do
		echo $i
		_loopwait
	done
	{ if _option_is_set "xtrace"; then
		SECTION="second_loop"
	fi
	} 2> /dev/null
	i=0
	while [ $((i++)) -le 3 ]; do
		echo $i
		_loopwait
	done
}

if [ -n "${DEBUG:-}" ] || \
_option_is_set "xtrace"; then
	set +o xtrace
	pipe="$( { mkfifo "$(mktemp -u | tee /dev/fd/3 )" ; } 3>&1)"

	exec 3<>$pipe
	rm -f $pipe

	{ _xtrace "/tmp/$(basename "${0}")-xtrace.txt" ; } 2> /dev/null &
	pid_xtrace=${!}

	trap 'kill $pid_xtrace; wait' EXIT

	ASH_SOURCE="$(basename "${0}")"
	FUNCNAME=""
	SECTION=""
	exec 2>&3
	export PS4='${ASH_SOURCE}:${FUNCNAME}:${SECTION}: '
	set -o xtrace
fi

set -o errexit -o pipefail

_looping
