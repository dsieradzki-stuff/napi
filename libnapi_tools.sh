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


#
# @brief global tools array
# =1 - mandatory tool
# =0 - optional tool
#
# Syntax: [group:]<key1|key2|...>=<value>
#
declare -a ___g_tools=( 'tr=1' 'printf=1' 'mktemp=1' 'wget=1' \
    'wc=1' 'dd=1' 'grep=1' 'seq=1' 'sed=1' \
    'cut=1' 'base64=0' 'unlink=0' 'stat=1' \
    'basename=1' 'dirname=1' 'cat=1' 'cp=1' \
    'mv=1' 'awk=0' 'file=0' 'subotage.sh=0' \
    '7z=0|7za=0' 'iconv=0' 'fps:mediainfo=0' \
    'fps:mplayer|mplayer2=0' 'fps:ffmpeg|ffprobe=0' \
    'md5|md5sum=1' )


#
# @brief append given tool to tools array
#
tools_add_tool() {
    _debug $LINENO "Dodaje narzedzie: [$1]"

    # g_tools+=( "$1=${2:-1}" )
    ___g_tools=( "${___g_tools[@]}" "$1=${2:-1}" )
    return $RET_OK
}


#
# @brief perform tools presence verification
#
tools_verify() {
    declare -a ret=()
    local rv=$RET_OK
    local t=''

    for t in "$@"; do
        local key=$(get_key "$t")
        local mandatory=$(get_value "$t")
        local tool=''
        local counter=0

        for tool in ${key//|/ }; do
            local p=1
            ! verify_tool_presence "$tool" && p=0
            ret=( "${ret[@]}" "$tool=$p" )
            counter=$(( counter + 1 ))
        done

        # break if mandatory tool is missing
        [ "$mandatory" -eq 1 ] &&
            [ "$counter" -eq 0 ] &&
            rv=$RET_FAIL &&
            break
    done

    # shellcheck disable=SC2086
    echo ${ret[*]}

    # shellcheck disable=SC2086
    return $rv
}


#
# @brief verify all the registered tools from the tools array
#
tools_configure() {
    # this function can cope with that kind of input
    # shellcheck disable=SC2068
    ___g_tools=( $(tools_verify ${___g_tools[@]}) )
}


#
# @brief check if given tool has been detected
#
tools_is_detected() {
    # this function can cope with that kind of input
    # shellcheck disable=SC2068
    local t="$(lookup_value $1 ${___g_tools[@]} )"
    local rv=$RET_UNAV
    t=$(ensure_numeric "$t")
    [ "$t" -eq 1 ] && rv=$RET_OK

    return $rv
}


tools_first_available_from_group() {
    local t=''
    for t in $(lookup_group_keys "${1:-none}" "${___g_tools[@]}"); do
        tools_is_detected "$t" && echo "$t" && break
    done

    # shellcheck disable=SC2086
    return $RET_OK
}


tools_is_in_group() {
    local t=''
    for t in $(lookup_group_keys "${1:-none}" "${___g_tools[@]}"); do
        # shellcheck disable=SC2086
        [ "$t" = "${2:-none}" ] && return $RET_OK
    done
    _info $LINENO "$2 nie znajduje sie w grupie $1"
    # shellcheck disable=SC2086
    return $RET_UNAV
}


tools_is_in_group_and_detected() {
    local t=''
    for t in $(lookup_group_keys "${1:-none}" "${___g_tools[@]}"); do
        # shellcheck disable=SC2086
        [ "$t" = "${2:-none}" ] && tools_is_detected "$t" && return $RET_OK
    done

    _info $LINENO "$2 nie znajduje sie w grupie $1, badz nie zostal wykryty"

    # shellcheck disable=SC2086
    return $RET_UNAV
}


#
# @brief returns the number of tools in the group
#
tools_count_group_members() {
    local a=( $(lookup_group_keys "${1:-none}" "${___g_tools[@]}") )
    echo "${#a{*}}"
}


#
# @brief returns the number of detected tools in the group
#
tools_count_detected_group_members() {
    local t=''
    local count=0
    for t in $(lookup_group_keys "${1:-none}" "${___g_tools[@]}"); do
        # shellcheck disable=SC2086
        tools_is_detected "$t" && count=$(( count + 1 ))
    done

    echo "$count"

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# @brief concat the tools array to single line
#
tools_to_string() {
    echo "${___g_tools[*]}"
}


#
# @brief concat the tools array to list
#
tools_to_list() {
    ( IFS=$'\n'; echo "${___g_tools[*]}" )
}


#
# @brief concat the group members to single line
#
tools_group_to_string() {
    lookup_group_kv "$1"
}


#
# @brief concat the group members to list
#
tools_group_to_list() {
    local a=( $(lookup_group_kv "$1") )
    ( IFS=$'\n'; echo "${a[*]}" )
}

# EOF
