#!/bin/bash

# force indendation settings
# vim: ts=4 shiftwidth=4 expandtab

#
# version for the whole bundle (napi.sh & subotage.sh)
#
declare -r g_revision="v1.3.6"

########################################################################
########################################################################
########################################################################

#  Copyright (C) 2014 Tomasz Wisniewski aka
#       DAGON <tomasz.wisni3wski@gmail.com>
#
#  http://github.com/dagon666
#  http://pcarduino.blogspot.co.ul
#
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

########################################################################
########################################################################
########################################################################


################################## GLOBALS #####################################

declare -r ___GOUTPUT_VERBOSITY=0
declare -r ___GOUTPUT_LOGFILE=1
declare -r ___GOUTPUT_FORKID=2
declare -r ___GOUTPUT_MSGCNT=3
declare -r ___GOUTPUT_OWRT=4

#
# 0 - verbosity
# - 0 - be quiet (prints only errors)
# - 1 - standard level (prints errors, warnings, statuses & msg)
# - 2 - info level (prints errors, warnings, statuses, msg & info's)
# - 3 - debug level (prints errors, warnings, statuses, msg, info's and debugs)
#
# 1 - the name of the file containing the output
#
# 2 - fork id
# 3 - msg counter
# 4 - flag defining whether to overwrite the log or not
#
declare -a ___g_output=( 1 'none' 0 1 0 )

################################## RETVAL ######################################

# success
declare -r RET_OK=0

# function failed
declare -r RET_FAIL=255

# parameter error
declare -r RET_PARAM=254

# parameter/result will cause the script to break
declare -r RET_BREAK=253

# resource unavailable
declare -r RET_UNAV=252

# no action taken
declare -r RET_NOACT=251

################################################################################

#
# @brief count the number of lines in a file
#
count_lines() {

    # it is being executed in a subshell to strip any leading white spaces
    # which some of the wc versions produce

    # shellcheck disable=SC2046
    # shellcheck disable=SC2005
    echo $(wc -l)
}


#
# @brief lowercase the input
#
lcase() {
    # some old busybox implementations have problems with locales
    # which renders that syntax unusable
    # tr '[:upper:]' '[:lower:]'

    # deliberately reverted to old syntax
    # shellcheck disable=SC2021
    tr '[A-Z]' '[a-z]'
}


#
# @brief get rid of the newline/carriage return
#
strip_newline() {
    tr -d '\r\n'
}


#
# @brief get the extension of the input
#
get_ext() {
    echo "${1##*.}"
}


#
# @brief strip the extension of the input
#
strip_ext() {
    echo "${1%.*}"
}


#
# @brief get the value from strings like key=value
#
get_value() {
    echo "${1##*=}"
}


#
# @brief get the key from strings like key=value
#
get_key() {
    echo "${1%=*}"
}


#
# @brief returns numeric value even for non-numeric input
#
ensure_numeric() {
    echo $(( $1 + 0 ))
}


#
# @brief search for specified key and return it's value
# @param key
# @param array
#
lookup_value() {
    local i=''
    local rv=$RET_FAIL
    local key="$1" && shift
    local tk=''

    # using $* is deliberate to allow parsing either array or space delimited strings

    # shellcheck disable=SC2048
    for i in $*; do
        tk=$(get_key "$i")
        if [ "$tk"  = "$key" ]; then
            get_value "$i"
            rv=$RET_OK
            break
        fi
    done
    return $rv
}


#
# @brief lookup index in the array for given value
# returns the index of the value and 0 on success
#
lookup_key() {
    local i=''
    local idx=0
    local rv=$RET_FAIL
    local key="$1"

    shift

    for i in "$@"; do
        [ "$i" = "$key" ] && rv=$RET_OK && break
        idx=$(( idx + 1 ))
    done

    echo $idx
    return $rv
}


#
# @brief modify value in the array (it will be added if the key doesn't exist)
# @param key
# @param value
# @param array
#
modify_value() {
    local key=$1 && shift
    local value=$1 && shift

    local i=0
    local k=''
    declare -a rv=()

    # shellcheck disable=SC2048
    for i in $*; do
        k=$(get_key "$i")
        # unfortunately old shells don't support rv+=( "$i" )
        [ "$k" != "$key" ] && rv=( "${rv[@]}" "$i" )
    done

    rv=( "${rv[@]}" "$key=$value" )
    echo ${rv[*]}

    return $RET_OK
}


#
# determines number of available cpu's in the system
#
get_cores() {
    local os="${1:-linux}"

    if [ "$os" = "darwin" ]; then
        sysctl hw.ncpu | cut -d ' ' -f 2
	else
        grep -i processor /proc/cpuinfo | wc -l
    fi
}



#
# @brief detects running system type
#
get_system() {
    uname | lcase
}


#
# @brief extracts http status from the http headers
#
get_http_status() {
    # grep -o "HTTP/[\.0-9]* [0-9]*"
    awk '{ m = match($0, /HTTP\/[\.0-9]* [0-9]*/); if (m) print substr($0, m, RLENGTH) }'
}

################################## STDOUT ######################################

#
# @brief produce output
#
_blit() {
    printf "#%02d:%04d %s\n" ${___g_output[$___GOUTPUT_FORKID]} ${___g_output[$___GOUTPUT_MSGCNT]} "$*"
    ___g_output[$___GOUTPUT_MSGCNT]=$(( ___g_output[___GOUTPUT_MSGCNT] + 1 ))
}


#
# @brief set insane verbosity
#
_debug_insane() {
    PS4='+ [${LINENO}] ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    set -x
}


#
# @brief print a debug verbose information
#
_debug() {
    local line="${1:-0}" && shift
    [ "${___g_output[$___GOUTPUT_VERBOSITY]}" -ge 3 ] && _blit "--- $line: $*"
    return $RET_OK
}


#
# @brief print information
#
_info() {
    local line=${1:-0} && shift
    [ "${___g_output[$___GOUTPUT_VERBOSITY]}" -ge 2 ] && _blit "-- $line: $*"
    return $RET_OK
}


#
# @brief print warning
#
_warning() {
    _status "WARNING" "$*"
    return $RET_OK
}


#
# @brief print error message
#
_error() {
    local tmp="${___g_output[$___GOUTPUT_VERBOSITY]}"
    ___g_output[$___GOUTPUT_VERBOSITY]=1
    _status "ERROR" "$*" | to_stderr
    ___g_output[$___GOUTPUT_VERBOSITY]="$tmp"
    return $RET_OK
}


#
# @brief print standard message
#
_msg() {
    [ "${___g_output[$___GOUTPUT_VERBOSITY]}" -ge 1 ] && _blit "- $*"
    return $RET_OK
}


#
# @brief print status type message
#
_status() {
    [ "${___g_output[$___GOUTPUT_VERBOSITY]}" -ge 1 ] && _blit "$1 -> $2"
    return $RET_OK
}


#
# @brief redirect errors to standard error output
#
to_stderr() {
    if [ -n "${___g_output[$___GOUTPUT_LOGFILE]}" ] && [ "${___g_output[$___GOUTPUT_LOGFILE]}" != "none" ]; then
        cat
    else
        cat > /dev/stderr
    fi
}


#
# @brief redirect stdout to logfile
#
redirect_to_logfile() {
    if [ -n "${___g_output[$___GOUTPUT_LOGFILE]}" ] && [ "${___g_output[$___GOUTPUT_LOGFILE]}" != "none" ]; then
        # truncate
        cat /dev/null > "${___g_output[$___GOUTPUT_LOGFILE]}"

        # append instead of ">" to assure that children won't mangle the output
        exec 3>&1 4>&2 1>> "${___g_output[$___GOUTPUT_LOGFILE]}" 2>&1
    fi
}


#
# @brief redirect output to stdout
#
redirect_to_stdout() {
    # restore everything
    [ -n "${___g_output[$___GOUTPUT_LOGFILE]}" ] &&
    [ "${___g_output[$___GOUTPUT_LOGFILE]}" != "none" ] &&
        exec 1>&3 2>&4 4>&- 3>&-
}

# EOF

################################## FLOAT CMP ###################################

float_lt() {
    awk -v n1="$1" -v n2="$2" 'BEGIN{ if (n1<n2) exit 0; exit 1}'
}


float_gt() {
    awk -v n1="$1" -v n2="$2" 'BEGIN{ if (n1>n2) exit 0; exit 1}'
}


float_le() {
    awk -v n1="$1" -v n2="$2" 'BEGIN{ if (n1<=n2) exit 0; exit 1}'
}


float_ge() {
    awk -v n1="$1" -v n2="$2" 'BEGIN{ if (n1>=n2) exit 0; exit 1}'
}


float_eq() {
    awk -v n1="$1" -v n2="$2" 'BEGIN{ if (n1==n2) exit 0; exit 1}'
}

float_div() {
    awk -v n1="$1" -v n2="$2" 'BEGIN { print n1/n2 }'
}

float_mul() {
    awk -v n1="$1" -v n2="$2" 'BEGIN { print n1*n2 }'
}

#################################### ENV #######################################

#
# @brief checks if the tool is available in the PATH
#
verify_tool_presence() {
    local tool=$(builtin type -p "$1")
    local rv=$RET_UNAV

    # make sure it's really there
    if [ -z "$tool" ]; then
        type "$1" > /dev/null 2>&1
        rv=$?
    else
        rv=$RET_OK
    fi

    return $rv
}

#
# @brief check function presence
#
verify_function_presence() {
    local tool=$(builtin type -t "$1")
    local rv=$RET_UNAV
    local status=0

    # make sure it's really there
    if [ -z "$tool" ]; then
        type "$1" > /dev/null 2>&1;
        status=$?
        [ "$status" -ne $RET_OK ] && tool='empty'
    fi

    # check the output
    [ "$tool" = "function" ] && rv=$RET_OK
    return $rv
}

############################# OUTPUT ###########################################

#
# @brief set the output verbosity level
#
# Automatically fall back to standard level if given level is out of range.
#
output_set_verbosity() {
    ___g_output[$___GOUTPUT_VERBOSITY]=$(ensure_numeric "$1")
    output_verify_verbosity || ___g_output[$___GOUTPUT_VERBOSITY]=1
    [ ${___g_output[$___GOUTPUT_VERBOSITY]} -eq 4 ] && _debug_insane
    return $RET_OK
}


#
# @brief get the output verbosity level
#
output_get_verbosity() {
    echo "${___g_output[$___GOUTPUT_VERBOSITY]}"
    return $RET_OK
}

#
# @brief verify if given verbosity level is in supported range
#
output_verify_verbosity() {
    # make sure first that the printing functions will work
    _debug $LINENO 'sprawdzam poziom gadatliwosci'
    case "${___g_output[$___GOUTPUT_VERBOSITY]}" in
        0 | 1 | 2 | 3 | 4)
            ;;

        *)
            _error "poziom gadatliwosci moze miec jedynie wartosci z zakresu (0-4)"
            # shellcheck disable=SC2086
            return $RET_PARAM
            ;;
    esac
    return $RET_OK
}

#
# @brief set logging to a file or stdout
#
output_set_logfile() {
    if [ "${___g_output[$___GOUTPUT_LOGFILE]}" != "$1" ]; then
        _info $LINENO "ustawiam STDOUT"
        redirect_to_stdout

        ___g_output[$___GOUTPUT_LOGFILE]="$1"
        output_verify_logfile || ___g_output[$___GOUTPUT_LOGFILE]="none"

        redirect_to_logfile
    fi
    return $RET_OK
}

#
# @brief verify if given logging file can be used
#
output_verify_logfile() {
    _debug $LINENO 'sprawdzam logfile'
    if [ -e "${___g_output[$___GOUTPUT_LOGFILE]}" ] &&
       [ "${___g_output[$___GOUTPUT_LOGFILE]}" != "none" ]; then

        # whether to fail or not ?
        if [ "${___g_output[$___GOUTPUT_OWRT]}" -eq 0 ]; then
            _error "plik loga istnieje, podaj inna nazwe pliku aby nie stracic danych"
            # shellcheck disable=SC2086
            return $RET_PARAM
        else
            _warning "plik loga istnieje, zostanie nadpisany"
        fi
    fi

    return $RET_OK
}

#
# @brief set fork id
#
output_set_fork_id() {
    ___g_output[$___GOUTPUT_FORKID]=$(ensure_numeric "$1")
    return $RET_OK
}


#
# @brief get fork id of the current process
#
output_get_fork_id() {
    echo "${___g_output[$___GOUTPUT_FORKID]}"
    return $RET_OK
}


#
# @brief set message counter
#
output_set_msg_counter() {
    ___g_output[$___GOUTPUT_MSGCNT]=$(ensure_numeric "$1")
    return $RET_OK
}


#
# @brief get message counter
#
output_get_msg_counter() {
    echo "${___g_output[$___GOUTPUT_MSGCNT]}"
    return $RET_OK
}


#
# @brief set log overwrite to given value
#
output_set_log_overwrite() {
    ___g_output[$___GOUTPUT_OWRT]=$(ensure_numeric "$1")
    return $RET_OK
}


#
# @brief set log overwrite to true
#
output_raise_log_overwrite() {
    output_set_log_overwrite 1
    return $RET_OK
}


#
# @brief set log overwrite to false
#
output_clear_log_overwrite() {
    output_set_log_overwrite 0
    return $RET_OK
}

################################ COMMON ########################################

#
# @brief inform that we're using new API now
#
print_new_api_info() {
    _msg "================================================="
    _msg "$0 od wersji 1.3.1 domyslnie uzywa nowego"
    _msg "API (napiprojekt-3)"
    _msg "Jezeli zauwazysz jakies problemy z nowym API"
    _msg "albo skrypt dziala zbyt wolno, mozesz wrocic do"
    _msg "starego API korzystajac z opcji --id pynapi"
    _msg "================================================="

    # shellcheck disable=SC2086
    return $RET_OK
}

#
# @brief: check if the given file is a video file
# @param: video filename
# @return: bool 1 - is video file, 0 - is not a video file
#
verify_extension() {
    local filename=$(basename "$1")
    local extension=$(get_ext "$filename" | lcase)
    local is_video=0

    declare -a formats=( 'avi' 'rmvb' 'mov' 'mp4' 'mpg' 'mkv' \
        'mpeg' 'wmv' '3gp' 'asf' 'divx' \
        'm4v' 'mpe' 'ogg' 'ogv' 'qt' )

    # this function can cope with that kind of input
    # shellcheck disable=SC2068
    lookup_key "$extension" ${formats[@]} > /dev/null && is_video=1

    echo $is_video

    # shellcheck disable=SC2086
    return $RET_OK
}

################################## DB ##########################################

# that was an experiment which I decided to drop after all.
# those functions provide a mechanism to generate consistently named global vars
# i.e. _db_set "abc" 1 will create glob. var ___g_db___abc=1
# left as a reference - do not use it

## #
## # @global prefix for the global variables generation
## #
## g_GlobalPrefix="___g_db___"
##
##
## #
## # @brief get variable from the db
## #
## _db_get() {
##  eval "echo \$${g_GlobalPrefix}_$1"
## }
##
##
## #
## # @brief set variable in the db
## #
## _db_set() {
##  eval "${g_GlobalPrefix}_${1/./_}=\$2"
## }

################################################################################
