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
declare -r ___GIO_WGET=6
declare -r ___GIO_FPS=7

declare -a ___g_io=( 'none' 'none' 'none' \
    'none' 'cp' 'none' 'none' 'none' )


#
# configure the unlink tool
#
io_configure_unlink() {
    # check unlink command
    _debug $LINENO "sprawdzam obecnosc unlink"

    if ! tools_is_detected "unlink"; then
        _info $LINENO 'brak unlink, unlink = rm' &&
        ___g_io[$___GIO_UNLINK]='rm -rf'
    else
        ___g_io[$___GIO_UNLINK]='unlink'
    fi

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# @brief unlink wrapper
#
io_unlink() {
    [ "${___g_io[$___GIO_UNLINK]}" = 'none' ] && io_configure_unlink
    ${___g_io[$___GIO_UNLINK]} "$@"
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


#
# @brief stat wrapper
#
io_stat() {
    [ "${___g_io[$___GIO_STAT]}" = 'none' ] && io_configure_stat
    ${___g_io[$___GIO_STAT]} "$@"
}


#
# configure the base64 tool
#
io_configure_base64() {
    _debug $LINENO "sprawdzam base64"

    g_cmd_base64_decode="base64 -d"
    # verify base64 & md5 tool
    system_is_darwin && ___g_io[$___GIO_BASE64]="base64 -D"

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# @brief base64 wrapper
#
io_base64_decode() {
    [ "${___g_io[$___GIO_BASE64]}" = 'none' ] && io_configure_base64
    ${___g_io[$___GIO_BASE64]} "$@"
}


#
# configure the md5 tool
#
io_configure_md5() {
    _debug $LINENO "konfiguruje md5"

    # verify md5 tool
    ___g_io[$___GIO_MD5]="md5sum"
    system_is_darwin && ___g_io[$___GIO_MD5]="md5"

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# @brief md5 wrapper
#
io_md5() {
    [ "${___g_io[$___GIO_MD5]}" = 'none' ] && io_configure_md5
    ${___g_io[$___GIO_MD5]} "$@"
}


#
# @brief wrapper for copy function
#
io_cp() {
    ${___g_io[$___GIO_CP]} "$@"
}


#
# @brief set copy executable
#
io_cp_set() {
    ___g_io[$___GIO_CP]="${1:-cp}"
    _debug $LINENO "io_cp = ${___g_io[$___GIO_CP]}"
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


io_get_7z() {
    echo "${___g_io[$___GIO_7Z]}"
}


#
# @brief verify presence of any of the 7z tools
#
io_configure_7z() {
    local k=''

    # check 7z command
    _debug $LINENO "sprawdzam narzedzie 7z"

    # use 7z or 7za only, 7zr doesn't support passwords
    declare -a t7zs=( '7za' '7z' )

    for k in "${t7zs[@]}"; do
        tools_is_detected "$k" &&
            _info $LINENO "7z wykryty jako [$k]" &&
            ___g_io[$___GIO_7Z]="$k" &&
            break
    done

    return $RET_OK
}


#
# @brief 7z wrapper
#
io_7z() {
    [ "${___g_io[$___GIO_7Z]}" = 'none' ] && io_configure_7z
    [ "${___g_io[$___GIO_7Z]}" != 'none' ] &&
        "${___g_io[$___GIO_7Z]}" "$@"
}


io_configure_wget() {
    local wget_cmd='wget -q -O'
    local wget_post=0

    _debug $LINENO "sprawdzam czy wget wspiera opcje -S"
    local s_test=$(wget --help 2>&1 | grep "\-S")
    [ -n "$s_test" ] &&
        wget_cmd='wget -q -S -O' &&
        _info $LINENO "wget wspiera opcje -S"

    _debug $LINENO "sprawdzam czy wget wspiera zadania POST"
    local p_test=$(wget --help 2>&1 | grep "\-\-post\-")
    [ -n "$p_test" ] &&
        wget_post=1 &&
        _info $LINENO "wget wspiera zadania POST"

    ___g_io[$___GIO_WGET]="$wget_post|$wget_cmd"

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# @brief execute wget
#
io_wget() {
    [ "${___g_io[$___GIO_WGET]}" = 'none' ] && io_configure_wget
    ${___g_io[$___GIO_WGET]##[0-9]*|} "$@"
}


#
# @brief return true if wget supports POST
#
io_wget_is_post_available() {
    [ "${___g_io[$___GIO_WGET]}" = 'none' ] && io_configure_wget
    [ "${___g_io[$___GIO_WGET]%%|*}" -eq 1 ]
}


#
# @brief set fps tool
#
io_set_fps_tool() {
    ___g_io[$___GIO_FPS]="${1:-none}"
}


io_verify_fps_tool() {
    
}

io_get_fps() {

    _info $LINENO "wykrywam fps uzywajac: ${___g_io[$___GIO_FPS]}"
    io_get_fps_with_tool "${___g_io[$___GIO_FPS]}" "$@"
}


#
# @brief detect fps of the video file
# @param tool
# @param filename
#
io_get_fps_with_tool() {
    local fps=0
    local tbr=0
    local t="${1:-none}"
    local tmp=''
    declare -a atmp=()

    # don't bother if there's no tool available or not specified
    if [ -z "$t" ] || [ "$t" = "none" ]; then
        echo $fps

        # shellcheck disable=SC2086
        return $RET_PARAM
    fi

    if tools_is_detected "$1"; then
        case "$1" in
            'mplayer' | 'mplayer2' )
            fps=$($1 -identify -vo null -ao null -frames 0 "$2" 2> /dev/null | grep ID_VIDEO_FPS | cut -d '=' -f 2)
            ;;

            'mediainfo' )
            fps=$($1 --Output='Video;%FrameRate%' "$2")
            ;;

            'ffmpeg' )
            tmp=$($1 -i "$2" 2>&1 | grep "Video:")
            tbr=$(echo "$tmp" | sed 's/, /\n/g' | tr -d ')(' | grep tbr | cut -d ' ' -f 1)
            fps=$(echo "$tmp" | sed 's/, /\n/g' | grep fps | cut -d ' ' -f 1)

            [ -z "$fps" ] && fps="$tbr"
            ;;

            'ffprobe' )
            tmp=$(ffprobe -v 0 -select_streams v -print_format csv -show_entries stream=avg_frame_rate,r_frame_rate -- "$2" | tr ',' ' ')
            atmp=( $tmp )

            local i=0
            for i in 1 2; do
                local a=$(echo "${atmp[$i]}" | cut -d '/' -f 1)
                local b=$(echo "${atmp[$i]}" | cut -d '/' -f 2)
                [ "${atmp[$i]}" != "0/0" ] && fps=$(float_div "$a" "$b")
            done
            ;;

            *)
            ;;
        esac
    fi

    # just a precaution
    echo "$fps" | cut -d ' ' -f 1

    # shellcheck disable=SC2086
    return $RET_OK

}
