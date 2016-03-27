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


declare -r ___GIO_UNLINK=0
declare -r ___GIO_STAT=1
declare -r ___GIO_BASE64=2
declare -r ___GIO_MD5=3
declare -r ___GIO_CP=4
declare -r ___GIO_7Z=5

declare -a ___g_io=( 'unlink' 'stat -c%s' 'base64 -d' \
    'md5sum' 'cp' 'none' )


io_unlink() {
    ${___g_io[$___GIO_UNLINK]} "$@"
}


io_stat() {
    ${___g_io[$___GIO_STAT]} "$@"
}


#
# @brief detects the charset of the subtitles file
# @param full path to the subtitles file
#
io_get_encoding() {
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
io_convert_encoding_generic() {
    local file="$1"
    local d="${2:-utf8}"
    local s="${3}"
    local rv=$RET_FAIL

    # detect charset
    [ -z "$s" ] && s=$(io_get_encoding "$file")

    local tmp=$(mktemp napi.XXXXXXXX)
    iconv -f "$s" -t "$d" "$file" > "$tmp"

    if [ $? -eq $RET_OK ]; then
        _debug $LINENO "moving after charset conv. $tmp -> $file"
        mv "$tmp" "$file"
        rv=$RET_OK
    fi

    [ -e "$tmp" ] && io_unlink "$tmp"

    return "$rv"
}


#
# @brief convert charset of the file
# @param input file path
#
io_convert_encoding() {
    local filepath="$1"

    local encoding=$(system_get_encoding)
    local filename=$(basename "$filepath")

    [ "$encoding" = "default" ] && return $RET_OK

    _msg "[$filename]: konwertowanie kodowania do $encoding"
    io_convert_encoding_generic \
        "$filepath" "$encoding"
}


#
# configure the md5 tool
#
io_configure_md5() {
    _debug $LINENO "konfiguruje md5"

    # verify md5 tool
    ___g_io[$___GIO_MD5]="md5sum"
    system_is_darwin && ___g_io[$___GIO_MD5]="md5"
    tools_add_tool "${___g_io[$___GIO_MD5]}"

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# configure the stat tool
#
io_configure_stat() {
    _debug $LINENO "konfiguruje stat"

    # verify stat tool
    ___g_io[$___GIO_STAT]="stat -c%s"

    if system_is_darwin; then
        # stat may be installed through macports, check if
        # there's a need to reconfigure it to BSD flavour
        "${___g_io[$___GIO_STAT]}" "$0" > /dev/null 2>&1 &&
            ___g_io[$___GIO_STAT]="stat -f%z"
    fi

    # shellcheck disable=SC2086
    return $RET_OK
}


io_configure() {
    io_configure_md5
    io_configure_stat
}
