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
declare -a ___g_system=( 'linux' '1' 'NapiProjektPython' )


system_is_darwin() {
    [ "${___g_system[$___GSYSTEM_SYSTEM]}" = "darwin" ]
}


system_is_api_napiprojekt3() {
    [ "${___g_system[$___GSYSTEM_NAPIID]}" = "NapiProjekt" ] ||
        [ "${___g_system[$___GSYSTEM_NAPIID]}" = "NapiProjektPython" ]
}


system_is_7z_needed() {
    [ "${___g_system[$___GSYSTEM_NAPIID]}" = 'other' ] ||
        [ "${___g_system[$___GSYSTEM_NAPIID]}" = 'NapiProjektPython' ] ||
        [ "${___g_system[$___GSYSTEM_NAPIID]}" = 'NapiProjekt' ]
}


system_get_forks() {
    echo "${___g_system[$___GSYSTEM_NFORKS]}"
}


system_set_forks() {
    ___g_system[$___GSYSTEM_NFORKS]=$(ensure_numeric "$1")
}


system_get_system() {
    echo "${___g_system[$___GSYSTEM_SYSTEM]}"
}


system_get_napi_id() {
    echo "${___g_system[$___GSYSTEM_NAPIID]}"
}


system_set_napi_id() {
    ___g_system[$___GSYSTEM_NAPIID]="${1:-pynapi}"
    verify_napi_id
}


system_verify_napi_id() {
    case ${___g_system[$___GSYSTEM_NAPIID]} in
        'pynapi' | 'other' | 'NapiProjektPython' | 'NapiProjekt' ) ;;

        *) # any other - revert to napi projekt 'classic'
        ___g_system[$___GSYSTEM_NAPIID]='pynapi'
        return $RET_PARAM
        ;;
    esac

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
    cores=$(get_cores "${g_system[$___GSYSTEM_SYSTEM]}")

    # sanity checks
    [ "${#cores}" -eq 0 ] && cores=1
    [ "$cores" -eq 0 ] && cores=1

    # two threads on one core should be safe enough
    set_forks $(( cores * 2 ))
}
