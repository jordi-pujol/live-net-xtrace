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
		if read -r SH_SOURCE SH_FUNCNAME SH_SECTION line <&${SH_XTRACEFD}; then
			printf '+ %s %s:%15s:%12s: %s\n' \
				"$(date +'%F %X')" \
				"${SH_SOURCE}" \
				"${SH_FUNCNAME}" \
				"${SH_SECTION}" \
				"${line}"
		fi
	done > "${1}"
}

_loopwait() {
	{ if [ -n "${SH_XTRACEFD}" ]; then
		local SH_FUNCNAME="_loopwait" SH_SECTION=""
	fi
	} 2> /dev/null
	echo hello $i
	sleep 1
	return 0
}

_looping() {
	{ if [ -n "${SH_XTRACEFD}" ]; then
		local SH_FUNCNAME="_looping" SH_SECTION=""
	fi
	} 2> /dev/null
	local i
	{ if [ -n "${SH_XTRACEFD}" ]; then
		SH_SECTION="first_loop"
	fi
	} 2> /dev/null
	i=0
	while [ $((i++)) -le 3 ]; do
		echo $i
		_loopwait
	done
	{ if [ -n "${SH_XTRACEFD}" ]; then
		SH_SECTION="second_loop"
	fi
	} 2> /dev/null
	i=0
	while [ $((i++)) -le 3 ]; do
		echo $i
		_loopwait
	done
}

SH_XTRACEFD=""
if [ -n "${DEBUG:-}" ] || \
_option_is_set "xtrace"; then
	set +o xtrace
	pipe="$( { mkfifo "$(mktemp -u | tee /dev/fd/3 )" ; } 3>&1)"

	SH_XTRACEFD=3
	exec 3<>"${pipe}"
	rm -f "${pipe}"

	{ _xtrace "/tmp/$(basename "${0}")-xtrace.txt" ; } 2> /dev/null &
	pid_xtrace=${!}

	trap 'kill ${pid_xtrace}; wait' EXIT

	SH_SOURCE="$(basename "${0}")"
	SH_FUNCNAME=""
	SH_SECTION=""
	exec 2>&${SH_XTRACEFD}
	export PS4='${SH_SOURCE}:${SH_FUNCNAME}:${SH_SECTION}: '
	set -o xtrace
fi

set -o errexit -o pipefail

_looping
