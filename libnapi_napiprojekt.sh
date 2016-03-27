#!/bin/bash

# force indendation settings
# vim: ts=4 shiftwidth=4 expandtab

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

#
# @brief: mysterious f() function
# @param: md5sum
#
napiprojekt_f() {
    declare -a t_idx=( 0xe 0x3 0x6 0x8 0x2 )
    declare -a t_mul=( 2 2 5 4 3 )
    declare -a t_add=( 0 0xd 0x10 0xb 0x5 )
    local sum="$1"
    local b=""
    local i=0

    # for i in {0..4}; do
    # again in order to be compliant with bash < 3.0
    for i in $(seq 0 4); do
        local a=${t_add[$i]}
        local m=${t_mul[$i]}
        local g=${t_idx[$i]}

        local t=$(( a + 16#${sum:$g:1} ))
        local v=$(( 16#${sum:$t:2} ))

        local x=$(( (v*m) % 0x10 ))
        local z=$(printf "%x" $x)
        b="$b$z"
    done

    echo "$b"

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# @brief detects the charset of the subtitles file
# @param full path to the subtitles file
#
napiprojekt_get_encoding() {
    local file="$1"
    local charset='WINDOWS-1250'
    local et=''

    if tools_is_detected "file"; then

        et=$(file \
            --brief \
            --mime-encoding \
            --exclude apptype \
            --exclude tokens \
            --exclude cdf \
            --exclude compress \
            --exclude elf \
            --exclude soft \
            --exclude tar \
            "$file" | lcase)

        if [ "$?" = "0" ] && [ -n "$et" ]; then
            case "$et" in
                *utf*) charset="UTF8";;
                *iso*) charset="ISO-8859-2";;
                us-ascii) charset="US-ASCII";;
                csascii) charset="CSASCII";;
                *ascii*) charset="ASCII";;
                *) charset="WINDOWS-1250";;
            esac
        fi
    fi

    echo "$charset"

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# @brief convert charset of the file
# @param input file path
# @param output charset
# @param input charset or null
#
napiprojekt_convert_encoding_generic() {
    local file="$1"
    local d="${2:-utf8}"
    local s="${3}"
    local rv=$RET_FAIL

    # detect charset
    [ -z "$s" ] && s=$(napiprojekt_get_encoding "$file")

    local tmp=$(mktemp napi.XXXXXXXX)
    iconv -f "$s" -t "$d" "$file" > "$tmp"

    if [ $? -eq $RET_OK ]; then
        _debug $LINENO "moving after charset conv. $tmp -> $file"
        mv "$tmp" "$file"
        rv=$RET_OK
    fi

    # TODO fix g_cmd_unlink handling
    [ -e "$tmp" ] && $g_cmd_unlink "$tmp"

    return "$rv"
}


#
# @brief convert charset of the file
# @param input file path
#
napiprojekt_convert_encoding() {
    local filepath="$1"

    local encoding=$(system_get_encoding)
    local filename=$(basename "$filepath")

    [ "$encoding" = "default" ] && return $RET_OK

    _msg "[$filename]: konwertowanie kodowania do $encoding"
    napiprojekt_convert_encoding_generic \
        "$filepath" "$encoding"
}
