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
declare -a ___g_tools=( 'tr=1' 'printf=1' 'mktemp=1' 'wget=1' \
    'wc=1' 'dd=1' 'grep=1' 'seq=1' 'sed=1' \
    'cut=1' 'base64=0' 'unlink=0' 'stat=1' \
    'basename=1' 'dirname=1' 'cat=1' 'cp=1' \
    'mv=1' 'awk=0' 'file=0' 'subotage.sh=0' \
    '7z=0' '7za=0' '7zr=0' 'iconv=0' 'mediainfo=0' \
    'mplayer=0' 'mplayer2=0' 'ffmpeg=0' 'ffprobe=0' )


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

    local tool=''
    local p=0
    local m=0
    local t=''

    for t in "$@"; do
        p=1
        tool=$(get_key "$t")
        m=$(get_value "$t")

        ! verify_tool_presence "$tool" && p=0
        # ret+=( "$tool=$p" )
        ret=( "${ret[@]}" "$tool=$p" )

        # break if mandatory tool is missing
        [ "$m" -eq 1 ] && [ "$p" -eq 0 ] && rv=$RET_FAIL && break
    done

    echo ${ret[*]}

    # shellcheck disable=SC2086
    return $rv
}


tools_verify_global() {
    # this function can cope with that kind of input
    # shellcheck disable=SC2068
    ___g_tools=( $(tools_verify ${___g_tools[@]}) )
}


tools_is_detected() {
    # this function can cope with that kind of input
    # shellcheck disable=SC2068
    local t="$(lookup_value $1 ${___g_tools[@]} )"
    local rv=$RET_UNAV
    t=$(ensure_numeric "$t")
    [ "$t" -eq 1 ] && rv=$RET_OK

    return $rv
}

