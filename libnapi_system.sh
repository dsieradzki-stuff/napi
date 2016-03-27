#!/bin/bash

# force indendation settings
# vim: ts=4 shiftwidth=4 expandtab

########################################################################
########################################################################
########################################################################

#  Copyright (C) 2015 Tomasz Wisniewski aka
#       DAGON <tomasz.wisni3wski@gmail.com>
#
#  http://github.com/dagon666
#  http://pcarduino.blogspot.co.uk
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


declare -r ___GSYSTEM_SYSTEM=0
declare -r ___GSYSTEM_NFORKS=1
declare -r ___GSYSTEM_NAPIID=2
declare -r ___GSYSTEM_ENCODING=3
declare -r ___GSYSTEM_HOOK=4


#
# 0 - system - detected system type
# - linux
# - darwin - mac osx
#
# 1 - numer of forks
#
# 2 - id
# - pynapi - identifies itself as pynapi
# - other - identifies itself as other
# - NapiProjektPython - uses new napiprojekt3 API - NapiProjektPython
# - NapiProjekt - uses new napiprojekt3 API - NapiProjekt
#
# 3 - text encoding
# defines the charset of the resulting file
#
# 4 - external script
#
declare -a ___g_system=( 'linux' '1' 'NapiProjektPython' \
    'default' 'none' )

#
# @brief check if system is darwin
#
system_is_darwin() {
    [ "${___g_system[$___GSYSTEM_SYSTEM]}" = "darwin" ]
}


#
# @brief check if API is XML (napiprojekt3) or not
#
system_is_api_napiprojekt3() {
    [ "${___g_system[$___GSYSTEM_NAPIID]}" = "NapiProjekt" ] ||
        [ "${___g_system[$___GSYSTEM_NAPIID]}" = "NapiProjektPython" ]
}


#
# @brief check if 7z is needed
#
# 7z is required when using specific API type.
#
system_is_7z_needed() {
    [ "${___g_system[$___GSYSTEM_NAPIID]}" = 'other' ] ||
        [ "${___g_system[$___GSYSTEM_NAPIID]}" = 'NapiProjektPython' ] ||
        [ "${___g_system[$___GSYSTEM_NAPIID]}" = 'NapiProjekt' ]
}


#
# @brief get the number of configured forks
#
system_get_forks() {
    echo "${___g_system[$___GSYSTEM_NFORKS]}"
}


#
# @brief set the number of forks
#
system_set_forks() {
    ___g_system[$___GSYSTEM_NFORKS]=$(ensure_numeric "$1")
}


#
# @brief get system type
#
system_get_system() {
    echo "${___g_system[$___GSYSTEM_SYSTEM]}"
}


#
# @brief get the id used to identify with napiprojekt servers
#
system_get_napi_id() {
    echo "${___g_system[$___GSYSTEM_NAPIID]}"
}


#
# @brief set the id used to identify with napiprojekt servers
#
system_set_napi_id() {
    ___g_system[$___GSYSTEM_NAPIID]="${1:-pynapi}"
    verify_napi_id || ___g_system[$___GSYSTEM_NAPIID]='pynapi'
}


#
# @brief verify if the configured napi id is correct and auto-correct it if
# it's not.
#
system_verify_napi_id() {
    case ${___g_system[$___GSYSTEM_NAPIID]} in
        'pynapi' | 'other' | 'NapiProjektPython' | 'NapiProjekt' )
            ;;

        *) # any other - revert to napi projekt 'classic'
            _warning "Nieznany napiprojekt API id"
            # shellcheck disable=SC2086
            return $RET_PARAM
            ;;
    esac

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# @brief verify system settings and gather info about commands
#
system_configure() {
    local cores=1
    _debug $LINENO "weryfikuje system"

    # detect the system first
    ___g_system[$___GSYSTEM_SYSTEM]="$(get_system)"

    # establish the number of cores
    cores=$(get_cores "${___g_system[$___GSYSTEM_SYSTEM]}")

    # sanity checks
    [ "${#cores}" -eq 0 ] && cores=1
    [ "$cores" -eq 0 ] && cores=1

    # two threads on one core should be safe enough
    set_forks $(( cores * 2 ))
}


#
# @brief set the desired output file encoding
#
system_set_encoding() {
    ___g_system[$___GSYSTEM_ENCODING]="${1:-default}"
    if ! system_verify_encoding; then
        _warning "charset [$g_charset] niewspierany, ignoruje zadanie"
        ___g_system[$___GSYSTEM_ENCODING]="default"
    fi
    return $RET_OK
}


#
# @brief get the output file encoding
#
system_get_encoding() {
    echo "${___g_system[$___GSYSTEM_ENCODING]}"
}


#
# @brief checks if the given encoding is supported
#
system_verify_encoding() {
    [ "${___g_system[$___GSYSTEM_ENCODING]}" = 'default' ] &&
        return $RET_OK

    ! tools_is_detected "iconv" &&
        _warning "iconv jest niedostepny. Konwersja kodowania niewsperana" &&
        return $RET_UNAV

    echo test | iconv \
        -t "${___g_system[$___GSYSTEM_ENCODING]}" > /dev/null 2>&1
    return $?
}


system_set_hook() {
    ___g_system[$___GSYSTEM_HOOK]="$1"
    system_verify_hook

}


system_verify_hook() {
    ___g_system[$___GSYSTEM_HOOK]="$1"

    if [ "${___g_system[$___GSYSTEM_HOOK]}" != 'none' ] &&
        [ ! -x "${___g_system[$___GSYSTEM_HOOK]}" ]; then
           _error "podany skrypt jest niedostepny (lub nie ma uprawnien do wykonywania)" &&
           return $RET_PARAM
    fi
    return $RET_OK
}


system_execute_hook() {
    local filepath="$1"
    local filename=$(basename "$filepath")

    [ "${___g_system[$___GSYSTEM_HOOK]}" = 'none' ] && return $RET_OK
    _msg "wywoluje zewnetrzny skrypt: $filename"
    "${___g_system[$___GSYSTEM_HOOK]}" "$filepath"
}

# EOF
