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


# common library shared between napi and subotage
declare -r LIBNAPI_COMMON="libnapi_common.sh"
declare -r LIBNAPI_SYSTEM="libnapi_system.sh"
declare -r LIBNAPI_TOOLS="libnapi_tools.sh"


# verify presence of the napi_common library
declare -r NAPI_COMMON_PATH=
if [ -z "$NAPI_COMMON_PATH" ] || [ ! -e "${NAPI_COMMON_PATH}/${LIBNAPI_COMMON}" ]; then
    echo
	echo "napi.sh i subotage.sh nie zostaly poprawnie zainstalowane"
	echo "uzyj skryptu install.sh (install.sh --help - pomoc)"
	echo "aby zainstalowac napi.sh w wybranym katalogu"
    echo
	exit -1
fi

# Source the common routines.
# Order must be maintained!
. "${NAPI_COMMON_PATH}/${LIBNAPI_COMMON}"
. "${NAPI_COMMON_PATH}/${LIBNAPI_SYSTEM}"
. "${NAPI_COMMON_PATH}/${LIBNAPI_TOOLS}"

################################################################################

#
# @brief abbreviation
# - string added between the filename and the extension
#
# @brief conversion abbreviation
# - string added between the filename and the extension
#   only for the converted subtitles
#
declare -a g_abbrev=( "" "" )

#
# @brief prefix for the original file - before the conversion
#
declare g_orig_prefix='ORIG_'

#
# @brief minimum size of files to be processed
#
declare g_min_size=0

#
# @brief whether to download cover or not
#
declare g_cover=0

#
# @brief whether to download nfo or not
#
declare g_nfo=0

#
# @brief whether to skip downloading if file is already present
#
declare g_skip=0

#
# @brief whether to delete the original file after conversion
#
declare g_delete_orig=0

#
# @brief default subtitles language
#
declare g_lang='PL'

#
# @brief default subtitles extension
#
declare g_default_ext='txt'

#
# @brief subtitles format
#
declare g_sub_format='default'

#
# @brief preferred fps detection tool
#
declare g_fps_tool='default'

#
# @brief napiprojekt.pl user credentials
# 0 - user
# 1 - password
#
declare -a g_cred=( '' '' )

#
# global paths list
#
declare -a g_paths=()

#
# global files list
#
declare -a g_files=()

#
# @brief prepare all the possible filename combinations
#
declare -a g_pf=()

#
# @brief processing stats
# 0 - downloaded
# 1 - unavailable
# 2 - skipped
# 3 - converted
# 4 - covers downloaded
# 5 - covers unavailable
# 6 - covers skipped
# 7 - nfos downloaded
# 8 - nfos unavailable
# 9 - nfos skipped
# 10 - total processed
declare -a g_stats=( 0 0 0 0 0 0 0 0 0 0 0 )

#
# controls whether to print statistics on exit or not
#
g_stats_print=0

#
#
#
#
g_clean_xml=1

################################### TOOLS ######################################

#
# @brief wget details
# 0 - cmd
# 1 - flag defining if wget supports post requests
g_cmd_wget=( 'wget -q -O' '0' )

g_cmd_stat='stat -c%s'
g_cmd_base64_decode="base64 -d"
g_cmd_md5='md5sum'
g_cmd_cp='cp'
g_cmd_unlink='unlink'
g_cmd_7z=''

################################ languages #####################################

# language code arrays
declare -ar g_Language=( 'Albański' 'Angielski' 'Arabski' 'Bułgarski' \
        'Chiński' 'Chorwacki' 'Czeski' 'Duński' \
        'Estoński' 'Fiński' 'Francuski' 'Galicyjski' \
        'Grecki' 'Hebrajski' 'Hiszpanski' 'Holenderski' \
        'Indonezyjski' 'Japoński' 'Koreański' 'Macedoński' \
        'Niemiecki' 'Norweski' 'Oksytański' 'Perski' \
        'Polski' 'Portugalski' 'Portugalski' 'Rosyjski' \
        'Rumuński' 'Serbski' 'Słoweński' 'Szwedzki' \
        'Słowacki' 'Turecki' 'Wietnamski' 'Węgierski' 'Włoski' )

declare -ar g_LanguageCodes2L=( 'SQ' 'EN' 'AR' 'BG' 'ZH' 'HR' 'CS' 'DA' 'ET' 'FI' \
                    'FR' 'GL' 'EL' 'HE' 'ES' 'NL' 'ID' 'JA' 'KO' 'MK' \
                    'DE' 'NO' 'OC' 'FA' 'PL' 'PT' 'PB' 'RU' 'RO' 'SR' \
                    'SL' 'SV' 'SK' 'TR' 'VI' 'HU' 'IT' )

declare -ar g_LanguageCodes3L=( 'ALB' 'ENG' 'ARA' 'BUL' 'CHI' 'HRV' 'CZE' \
                    'DAN' 'EST' 'FIN' 'FRE' 'GLG' 'ELL' 'HEB' \
                    'SPA' 'DUT' 'IND' 'JPN' 'KOR' 'MAC' 'GER' \
                    'NOR' 'OCI' 'PER' 'POL' 'POR' 'POB' 'RUS' \
                    'RUM' 'SCC' 'SLV' 'SWE' 'SLO' 'TUR' 'VIE' 'HUN' 'ITA' )


#
# @brief: list all the supported languages and their respective 2/3 letter codes
#
list_languages() {
    local i=0
    while [ "$i" -lt "${#g_Language[@]}" ]; do
        echo "${g_LanguageCodes2L[$i]}/${g_LanguageCodes3L[$i]} - ${g_Language[$i]}"
        i=$(( i + 1 ))
    done
}


#
# @brief verify that the given language code is supported
#
verify_language() {
    local lang="${1:-}"
    local i=0
    declare -a l_arr=( )

    # shellcheck disable=SC2086
    [ ${#lang} -ne 2 ] && [ ${#lang} -ne 3 ] && return $RET_PARAM

    local l_arr_name="g_LanguageCodes${#lang}L";
    eval l_arr=\( \${${l_arr_name}[@]} \)

    # this function can cope with that kind of input
    # shellcheck disable=SC2068
    i=$(lookup_key "$lang" ${l_arr[@]})
    local found=$?

    echo "$i"

    # shellcheck disable=SC2086
    [ "$found" -eq $RET_OK ] && return $RET_OK

    # shellcheck disable=SC2086
    return $RET_FAIL
}


#
# @brief set the language variable
# @param: language index
#
normalize_language() {
    local i=${1:-0}
    i=$(( i + 0 ))

    local lang=${g_LanguageCodes2L[$1]}

    # don't ask me why
    [ "$lang" = "EN" ] && lang="ENG"
    echo $lang

    # shellcheck disable=SC2086
    return $RET_OK
}

#################################### ENV #######################################

cleanup_tmp_files() {
    _debug $LINENO "usuwam pliki tymczasowe (jesli istnieja)"
    $g_cmd_unlink napisy.7z.*
    $g_cmd_unlink napi.*
    $g_cmd_unlink ipc.*
    $g_cmd_unlink stats.*
}


trap_control_c() {
    _msg $LINENO "przechwycono CTRL+C, koncze wykonywanie...";
    cleanup_tmp_files
    exit $?
}


#
# configure the stat tool
#
configure_stat() {
    _debug $LINENO "konfiguruje stat"

    # verify stat tool
    if system_is_darwin; then

        # stat may be installed through macports, check if
        # there's a need to reconfigure it to BSD flavour
        $g_cmd_stat "$0" > /dev/null 2>&1
        [ $? != 0 ] && g_cmd_stat="stat -f%z"
    else
        g_cmd_stat="stat -c%s"
    fi

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# configure the md5 tool
#
configure_md5() {
    _debug $LINENO "konfiguruje md5"

    # verify md5 tool
    if system_is_darwin; then
        g_cmd_md5="md5"
    else
        g_cmd_md5="md5sum"
    fi

    tools_add_tool "$g_cmd_md5"

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# configure the wget tool
#
configure_wget() {
    _debug $LINENO "sprawdzam czy wget wspiera opcje -S"
    local s_test=$(wget --help 2>&1 | grep "\-S")

    [ -n "$s_test" ] &&
        g_cmd_wget[0]='wget -q -S -O' &&
        _info $LINENO "wget wspiera opcje -S"

    _debug $LINENO "sprawdzam czy wget wspiera zadania POST"
    local p_test=$(wget --help 2>&1 | grep "\-\-post\-")

    g_cmd_wget[1]=0
    [ -n "$p_test" ] &&
        g_cmd_wget[1]=1 &&
        _info $LINENO "wget wspiera zadania POST"

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# configure the base64 tool
#
configure_base64() {
    _debug $LINENO "sprawdzam base64"

    # verify base64 & md5 tool
    if system_is_darwin; then
        g_cmd_base64_decode="base64 -D"
    else
        g_cmd_base64_decode="base64 -d"
    fi

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# configure the unlink tool
#
configure_unlink() {
    # check unlink command
    _debug $LINENO "sprawdzam obecnosc unlink"

    tools_is_detected "unlink" &&
        _info $LINENO 'brak unlink, g_cmd_unlink = rm' &&
        g_cmd_unlink='rm -rf'

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# @brief configure external commands
#
configure_cmds() {
    system_configure
    configure_stat
    configure_md5
    configure_base64
    configure_wget
    configure_unlink

    # shellcheck disable=SC2086
    return $RET_OK
}


verify_tools() {

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


#
# @brief get extension for given subtitle format
#
get_sub_ext() {
    local status=0
    declare -a fmte=( 'subrip=srt' 'subviewer2=sub' )

    # this function can cope with that kind of input
    # shellcheck disable=SC2068
    lookup_value "$1" ${fmte[@]}
    status=$?

    # shellcheck disable=SC2086
    [ "$status" -ne $RET_OK ] && echo $g_default_ext

    # shellcheck disable=SC2086
    return $RET_OK
}

##################################### fps ######################################

#
# @brief detect fps of the video file
# @param tool
# @param filename
#
get_fps() {
    local fps=0
    local tbr=0
    local t="${1:-default}"
    local tmp=''
    declare -a atmp=()

    # don't bother if there's no tool available or not specified
    if [ -z "$t" ] || [ "$t" = "default" ]; then
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


#################################### ARGV ######################################

#
# @brief parse the cli arguments
#
parse_argv() {

    _debug $LINENO "parsowanie argumentow"

    # command line arguments parsing
    while [ $# -gt 0 ]; do
        unset varname
        unset funcname

        # when adding a new option, please remember to maintain the same order as generated by usage()
        case "$1" in
            # abbrev
            "-a" | "--abbrev") varname="g_abbrev[0]"
            msg="nie określono wstawki"
            ;;

            "-b" | "--bigger-than") varname="g_min_size"
            msg="nie okreslono minimalnego rozmiaru"
            ;;

            # cover download
            "-c" | "--cover" ) g_cover=1 ;;
            # nfo download
            "-n" | "--nfo" ) g_nfo=1 ;;
            # orig prefix
            "-d" | "--delete-orig") g_delete_orig=1 ;;
            # skip flag
            "-s" | "--skip") g_skip=1 ;;
            # log overwrite option
            "-lo" | "--log-overwrite") output_raise_log_overwrite ;;
            # don't delete the xml (debugging purposes)
            "-px" | "--preserve-xml") g_clean_xml=0 ;;

            # stats flag
            "--stats") g_stats_print=1 ;;

            # move instead of copy
            "-M" | "--move") g_cmd_cp='mv' ;;

            # charset conversion
            "-C" | "--charset") funcname="system_set_encoding"
            msg="nie podano docelowego kodowania"
            ;;

            # extension
            "-e" | "--ext") varname="g_default_ext"
            msg="nie okreslono domyslnego rozszerzenia dla pobranych plikow"
            ;;

            # identification
            "-I" | "--id") funcname="system_set_napi_id"
            msg="okresl typ narzedzia jako pynapi/other (legacy API) albo NapiProjekt/NapiProjektPython (API-3)"
            ;;

            # logfile
            "-l" | "--log") funcname="output_set_logfile"
            msg="nie podano nazwy pliku loga"
            ;;

            # languages
            "-L" | "--language") varname="g_lang"
            msg="wybierz jeden z dostepnych 2/3 literowych kodow jezykowych (-L list - zeby wyswietlic)"
            ;;

            # password
            "-p" | "--pass") varname="g_cred[1]"
            msg="nie podano hasla"
            ;;

            # external script
            "-S" | "--script") funcname="system_set_hook"
            msg="nie okreslono sciezki do skryptu"
            ;;

            # user login
            "-u" | "--user") varname="g_cred[0]"
            msg="nie podano nazwy uzytkownika"
            ;;

            # verbosity
            "-v" | "--verbosity") funcname="output_set_verbosity"
            msg="okresl poziom gadatliwosci (0 - najcichszy, 3 - najbardziej gadatliwy, 4 - insane)"
            ;;

            # destination format definition
            "-f" | "--format") varname="g_sub_format"
            msg="nie określono formatu docelowego"
            ;;

            "-P" | "--pref-fps") funcname="tools_set_fps_tool"
            msg="nie określono narzedzia do detekcji fps"
            ;;

            # orig prefix
            "-o" | "--orig-prefix") varname="g_orig_prefix"
            msg="nie określono domyslnego prefixu"
            ;;

            # abbrev
            "--conv-abbrev") varname="g_abbrev[1]"
            msg="nie określono wstawki dla konwersji"
            ;;

            "-F" | "--forks") funcname="system_set_forks"
            msg="nie określono ilosci watkow"
            ;;

            # parameter is not a known argument, probably a filename
            *)
            # g_paths+=( "$1" )
            g_paths=( "${g_paths[@]}" "$1" )
            ;;
        esac

        # set the global var for simple switches
        # not requiring any further verification
        if [ -n "$funcname" ] || [ -n "$varname" ]; then
            shift

            # shellcheck disable=SC2086
            [ -z "$1" ] && _error "$msg" && return $RET_FAIL

            if [ -n "$funcname" ] && ! $funcname "$1"; then
                _error "$funcname failure. Setting parameter failed."
                # shellcheck disable=SC2086
                return $RET_FAIL
            fi

            [ -n "$varname" ] && eval "${varname}=\$1"
        fi
        shift
    done

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# @brief validate username and password
#
verify_credentials() {

    local user="${1:-}"
    local passwd="${2:-}"
    local rv=$RET_OK

    if [ -z "$user" ] && [ -n "$passwd" ]; then
        _warning "podano haslo, brak loginu. tryb anonimowy."
        rv=$RET_PARAM
    fi

    if [ -n "$user" ] && [ -z "$passwd" ]; then
        _warning "podano login, brak hasla. tryb anonimowy."
        rv=$RET_PARAM
    fi

    return "$rv"
}


#
# @brief checks id
#
verify_id() {
    local rv=$RET_OK

    # 7z check
    if system_is_7z_needed && [ -z "$g_cmd_7z" ]; then
        _error "7z nie jest dostepny. zmieniam id na 'pynapi'. PRZYWRACAM TRYB LEGACY"
        system_set_napi_id 'pynapi'
        # shellcheck disable=SC2086
        return $RET_UNAV
    fi


    # check for necessary tools for napiprojekt3 API
    if system_is_api_napiprojekt3; then
        declare -a t=( 'base64' 'awk' )
        local k=''

        for k in "${t[@]}"; do
            if ! tools_is_detected "$k"; then
                _error "$k nie jest dostepny. zmieniam id na 'pynapi'. PRZYWRACAM TRYB LEGACY"
                system_set_napi_id 'pynapi'

                # shellcheck disable=SC2086
                return $RET_UNAV
            fi
        done
    fi

    return "$rv"
}


#
# @brief format verification
#
verify_format() {
    # format verification if conversion requested
    if [ "$g_sub_format" != 'default' ]; then

        if ! tools_is_detected "subotage.sh"; then
            _error "subotage.sh nie jest dostepny. konwersja nie jest mozliwa"

            # shellcheck disable=SC2086
            return $RET_PARAM
        fi

        declare -a formats=()
        formats=( $(subotage.sh -gf) )

        # this function can cope with that kind of input
        # shellcheck disable=SC2068
        if ! lookup_key $g_sub_format ${formats[@]} > /dev/null; then
            _error "podany format docelowy jest niepoprawny [$g_sub_format]"

            # shellcheck disable=SC2086
            return $RET_PARAM
        fi
    fi

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# @brief verify presence of any of the 7z tools
#
verify_7z() {
    local rv=$RET_OK
    local lv=''

    # check 7z command
    _debug $LINENO "sprawdzam narzedzie 7z"
    # use 7z or 7za only, 7zr doesn't support passwords
    declare -a t7zs=( '7za' '7z' )
    g_cmd_7z=''

    for k in "${t7zs[@]}"; do
        tools_is_detected "$k" &&
            _info $LINENO "7z wykryty jako [$k]" &&
            g_cmd_7z="$k" &&
            break
    done

    [ -z "$g_cmd_7z" ] &&
        rv=$RET_FAIL &&
        _info $LINENO 'brak 7z/7za albo 7zr'

    return "$rv"
}


#
# @brief verify correctness of the argv settings provided
#
verify_argv() {
    local status=0

    _debug $LINENO "weryfikacja argumentow"

    # verify credentials correctness
    _debug $LINENO 'sprawdzam dane uwierzytelniania'
    if ! verify_credentials "${g_cred[0]}" "${g_cred[1]}"; then
        g_cred[0]='' && g_cred[1]=''
    fi

    # make sure we have a number here
    _debug $LINENO 'normalizacja parametrow numerycznych'
    g_min_size=$(ensure_numeric "$g_min_size")

    # check the 7z tool presence
    verify_7z

    # verify the id setting
    _debug $LINENO 'sprawdzam id'
    verify_id
    status=$?

    case $status in
        $RET_OK )
            _debug $LINENO "id zweryfikowane pomyslnie [$(system_get_napi_id)]"
            ;;

        $RET_UNAV )
            _warning "nie wszystkie narzedzia sa dostepne. Zainstaluj brakujace narzedzia by korzystac z nowego API napiprojekt"
            ;;

        *)
            _error "nieznany blad, podczas weryfikacji id..."

            # shellcheck disable=SC2086
            return $RET_BREAK
            ;;
    esac

    # language verification
    _debug $LINENO 'sprawdzam wybrany jezyk'
    local idx=0
    idx=$(verify_language "$g_lang")
    status=$?

    if [ "$status" -ne $RET_OK ]; then
        if [ "$g_lang" = "list" ]; then
            list_languages

            # shellcheck disable=SC2086
            return $RET_BREAK
        else
            _warning "nieznany jezyk [$g_lang]. przywracam PL"
            g_lang='PL'
        fi
    else
        _debug $LINENO "jezyk znaleziony, index = $idx"
        g_lang=$(normalize_language "$idx")
    fi
    unset idx


    # format verification
    _debug $LINENO 'sprawdzam format'
    ! verify_format && return $RET_PARAM

    ! verify_fps_tool && return $RET_PARAM

    # verify external script
    _debug $LINENO 'sprawdzam zewnetrzny skrypt'

    # shellcheck disable=SC2086
    return $RET_OK
}

################################# napiprojekt ##################################

#
# @brief wrapper for wget
# @param url
# @param output file
# @param POST data - if set the POST request will be done instead of GET (default)
#
# returns the http code(s)
#
download_url() {
    local url="$1"
    local output="$2"
    local post="$3"
    local headers=""
    local rv=$RET_OK
    local code='unknown'

    local status=$RET_FAIL

    # determine whether to perform a GET or a POST
    if [ -z "$post" ]; then
        headers=$(${g_cmd_wget[0]} "$output" "$url" 2>&1)
        status=$?
    elif [ "${g_cmd_wget[1]}" -eq 1 ]; then
        headers=$(${g_cmd_wget[0]} "$output" --post-data="$post" "$url" 2>&1)
        status=$?
    fi

    # check the status of the command
    if [ "$status" -eq $RET_OK ]; then
        # check the headers
        if [ -n "$headers" ]; then
            rv=$RET_FAIL
            code=$(echo "$headers" | \
                get_http_status | \
                cut -d ' ' -f 2)

            # do that to force the shell to get rid of new lines and spaces
            code=$(echo $code)

            # shellcheck disable=SC2143
            # shellcheck disable=SC2086
            [ -n "$(echo $code | grep 200)" ] && rv=$RET_OK
        fi
    else
        rv=$RET_FAIL
    fi

    echo "$code"
    return "$rv"
}


#
# @brief run awk code
# @param awk code
# @param (optional) file - if no file - process the stream
#
run_awk_script() {
    local awk_script="${1:-}"
    local file_path="${2:-}"
    local num_arg=$#

    # 0 - file
    # 1 - stream
    local input_type=0

    # detect number of arguments
    [ "$num_arg" -eq 1 ] && [ ! -e "$file_path" ] && input_type=1

    # bail out if awk is not available
    tools_is_detected "awk" || return $RET_FAIL

    # process a stream or a file
    if [ "$input_type" -eq 0 ]; then
        awk "$awk_script" "$file_path"
    else
        awk "$awk_script"
    fi

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# @brief extracts xml tag contents
# @param tag name
# @param file name (optional)
#
extract_xml_tag() {
    local tag="$1"
    local file_path="${2:-}"
    local awk_script=''
    local num_arg=$#

    # 0 - file
    # 1 - stream
    local input_type=0

# embed small awk program to extract the tag contents
read -d "" awk_script << EOF
BEGIN {
    RS=">"
    ORS=">"
}
/<$tag/,/<\\\/$tag/ { print }
EOF

    # detect number of arguments
    [ "$num_arg" -eq 1 ] && [ ! -e "$file_path" ] && input_type=1

    # process a stream or a file
    if [ "$input_type" -eq 0 ]; then
        run_awk_script "$awk_script" "$file_path"
    else
        run_awk_script "$awk_script"
    fi

    return $?
}


#
# @brief extracts cdata contents
# @param file name or none (if used as a stream filter)
#
extract_cdata_tag() {
    local file_path="${1:-}"
    local awk_script=''
    local num_arg=$#

    # 0 - file
    # 1 - stream
    local input_type=0

# embed small awk program to extract the tag contents
read -d "" awk_script << EOF
BEGIN {
    # this can't be a string - single character delimiter (to be portable)
    # RS="CDATA";
    FS="[\\]\\[]";
}
{
    print \$3;
}
EOF

    # detect number of arguments
    [ "$num_arg" -eq 0 ] && [ ! -e "$file_path" ] && input_type=1

    # process a stream or a file
    if [ "$input_type" -eq 0 ]; then
        awk "$awk_script" "$file_path" | tr -d '\n'
    else
        awk "$awk_script" | tr -d '\n'
    fi

    return $?
}


#
# @brief strip xml tag
# @param tag name (if used with file given)
# @param file name or a tag name (if used as a stream filter)
#
strip_xml_tag() {
    local tag="$1"
    local file_path="${2:-}"
    local awk_script=''
    local num_arg=$#

    # 0 - file
    # 1 - stream
    local input_type=0

# embed small awk program to extract the tag contents
read -d "" awk_script << EOF
BEGIN {
    FS="[><]"
}
/$tag/ { print \$3 }
EOF

    # detect number of arguments
    [ "$num_arg" -eq 1 ] && [ ! -e "$file_path" ] && input_type=1

    # process a stream or a file
    if [ "$input_type" -eq 0 ]; then
        awk "$awk_script" "$file_path"
    else
        awk "$awk_script"
    fi

    return $?
}


#
# @brief download xml data using new napiprojekt API
# @param md5sum of the media file
# @param file name of the media file
# @param size of the media file in bytes
# @param path of the xml file (including filename)
# @param language (PL if not provided)
# @param napi user
# @param napi passwd
#
# If file name is an empty string and file size is zero, a direct query will be
# done in mode 17 (whatever it means)
#
download_data_xml() {
    local url="http://napiprojekt.pl/api/api-napiprojekt3.php"
    local client_version="2.2.0.2399"
    local client_id="$(system_get_napi_id)" # should be something like NapiProjektPython

    # input data
    local md5sum=${1:-0}
    local movie_file="${2:-}"
    local byte_size=${3:-0};
    local of="$4"
    local lang="${5:-PL}"
    local user="${6:-''}"
    local passwd="${7:-''}"

    local http_codes=''
    local status=$RET_OK
    local rv=$RET_OK
    local mode=31

    # mode 17 means we will perform a direct download and ask for subs hash
    # directly, without inspecting the file at all.
    [ -z "$movie_file" ] && [ "$byte_size" = "0" ] && mode=17

    local data="mode=$mode&\
        client=$client_id&\
        client_ver=$client_version&\
        user_nick=$user&\
        user_password=$passwd&\
        downloaded_subtitles_id=$md5sum&\
        downloaded_subtitles_lang=$lang&"

    # in mode 31 we deliver the file details as well
    [ "$mode" = "31" ] &&
        data="$data\
        downloaded_cover_id=$md5sum&\
        advert_type=flashAllowed&\
        video_info_hash=$md5sum&\
        nazwa_pliku=$movie_file&\
        rozmiar_pliku_bajty=$byte_size&"

    # append the end query marker
    data="${data}the=end"

    http_codes=$(download_url "$url" "$of" "$data")
    status=$?
    _info $LINENO "otrzymane odpowiedzi http: [$http_codes]"

    # shellcheck disable=SC2086
    if [ "$status" -ne $RET_OK ]; then
        _error "blad wgeta. nie mozna pobrac pliku [$of], odpowiedzi http: [$http_codes]"
        # ... and exit
        rv=$RET_FAIL
    fi

    return "$rv"
}


#
# @brief get the compound xml file containing all the data
#
# This is a wrapper for download_data_xml
#
# @param md5sum
# @param movie file path
# @param size of the file in bytes
# @param language
#
get_xml() {
    local md5sum=${1:-0}
    local movie_file="${2:-}"
    local byte_size=${3:-0};
    local lang="${4:-PL}"
    local xml_path="${5:-}"

    local size=0
    local min_size=32

    # assume failure
    local rv=$RET_FAIL

    if [ -e "$xml_path" ]; then
        # oh good, we already have it
        rv=$RET_OK
    else
        # snap, it needs to be downloaded

        # g_cred expansion is deliberate
        # shellcheck disable=SC2068
        download_data_xml "$md5sum" "$movie_file" "$byte_size" "$xml_path" "$lang" ${g_cred[@]}
        rv=$?
    fi

    if [ "$rv" -eq $RET_OK ]; then

        # just a precaution
        [ -e "$xml_path" ] && size=$($g_cmd_stat "$xml_path")

        # verify the size
        if [ "$size" -lt "$min_size" ]; then
            _error "downloaded xml file's size is less than $min_size"
            $g_cmd_unlink "$xml_path"
            rv=$RET_FAIL
        fi
    fi

    return "$rv"
}


#
# @brief extract subtitles out of xml
# @param xml file path
# @param subs file path
#
extract_subs_xml() {
    local xml_path="${1:-}"
    local subs_path="${2:-}"
    local xml_status=0
    local rv=$RET_OK
    local status=$RET_FAIL

    local napi_pass="iBlm8NTigvru0Jr0"

    # I've got the xml, extract Interesting parts
    xml_status=$(extract_xml_tag 'status' "$xml_path" | grep 'success' | count_lines)

    _debug $LINENO "subs xml status [$xml_status]"
    if [ "$xml_status" -eq 0 ]; then
        _warning "napiprojekt zglasza niepowodzenie - napisy niedostepne"

        # shellcheck disable=SC2086
        return $RET_UNAV
    fi

    # extract the subs data
    local xml_subs=$(extract_xml_tag 'subtitles' "$xml_path")

	# check if the subtitles tag exist in the output
	# it's possible that the downloaded xml contains only
	# the cover and metadata
	if [ -z "$xml_subs" ]; then
		_debug $LINENO "plik xml nie zawiera taga subtitles"
		_info $LINENO "napisy niedostepne"

        # shellcheck disable=SC2086
		return $RET_UNAV
	fi

    # extract content
    local subs_content=$(echo "$xml_subs" | extract_xml_tag 'content')

    # create archive file
    local tmp_7z_archive=$(mktemp napisy.7z.XXXXXXXX)
    echo "$subs_content" | extract_cdata_tag | $g_cmd_base64_decode > "$tmp_7z_archive" 2> /dev/null

    if [ -s "$tmp_7z_archive" ]; then
        _debug $LINENO "rozpakowuje archiwum ..."
        $g_cmd_7z x -y -so -p"$napi_pass" "$tmp_7z_archive" 2> /dev/null > "$subs_path"
        status=$?
    fi

    # check 7z status
    if [ "$status" -ne $RET_OK ]; then
        _error "7z zwraca blad. nie mozna rozpakowac napisow"
        rv=$RET_FAIL
    fi

    # check for size
    if ! [ -s "$subs_path" ]; then
        _info $LINENO "plik docelowy ma zerowy rozmiar"
        rv=$RET_FAIL
    fi

    # get rid of the subs
    [ "$rv" != $RET_OK ] && [ -e "$subs_path" ] && $g_cmd_unlink "$subs_path"

    # get rid of the archive
    [ -e "$tmp_7z_archive" ] && $g_cmd_unlink "$tmp_7z_archive"

    return "$rv"
}


#
# @brief extract informations out of xml
# @param xml file path
# @param nfo file path
#
extract_nfo_xml() {
    local xml_path="${1:-}"
    local nfo_path="${2:-}"
    local xml_status=0
    local rv=$RET_OK

    local k=''
    local v=''

    declare -a subs_tags=( 'author' 'uploader' 'upload_date' )
    declare -a movie_tags=( 'title' 'other_titles' 'year' \
       'country' 'genre' 'direction' \
       'screenplay' 'music' 'imdb_com' \
       'filmweb_pl' 'fdb_pl' 'stopklatka_pl' )

    # I've got the xml, extract Interesting parts
    xml_status=$(extract_xml_tag 'status' "$xml_path" | grep 'success' | count_lines)

    _debug $LINENO "xml status [$xml_status]"
    if [ "$xml_status" -eq 0 ]; then
        _error "napiprojekt zglasza niepowodzenie - informacje niedostepne"

        # shellcheck disable=SC2086
        return $RET_UNAV
    fi

    # extract the subs data
    local xml_subs=$(extract_xml_tag 'subtitles' "$xml_path")

    # extract the movie data
    local xml_movie=$(extract_xml_tag 'movie' "$xml_path")

    # purge the file initially
    echo "nfo generated by napi $g_revision" > "$nfo_path"

    # extract data from subtitles tag
    for k in "${subs_tags[@]}"; do
        v=$(echo "$xml_subs" | extract_xml_tag "$k" | strip_xml_tag "$k")
        echo "$k: $v" >> "$nfo_path"
    done

    local cdata=0
    local en=''
    local pl=''

    # extract data from movie tag
    for k in "${movie_tags[@]}"; do
        v=$(echo "$xml_movie" | extract_xml_tag "$k")

        cdata=$(echo "$v" | grep 'CDATA' | count_lines)
        en=$(echo "$v" | extract_xml_tag "en" | strip_xml_tag "en")
        pl=$(echo "$v" | extract_xml_tag "pl" | strip_xml_tag "pl")

        if [ "$cdata" != "0" ]; then
            v=$(echo "$v" | extract_cdata_tag | tr -d "\r\n")
        elif [ -n "$en" ] || [ -n "$pl" ]; then
            v="$pl/$en"
        else
            v=$(echo "$v" | strip_xml_tag "$k")
        fi

        echo "$k: $v" >> "$nfo_path"
    done

    return "$rv"
}


#
# @brief extract cover out of xml
# @param xml file path
# @param subs file path
#
extract_cover_xml() {
    local xml_path="${1:-}"
    local cover_path="${2:-}"
    local xml_status=0
    local rv=$RET_OK

    # I've got the xml, extract Interesting parts
    xml_status=$(extract_xml_tag 'status' "$xml_path" | grep 'success' | count_lines)

    _debug $LINENO "cover xml status [$xml_status]"
    if [ "$xml_status" -eq 0 ]; then
        _error "napiprojekt zglasza niepowodzenie - okladka niedostepna"

        # shellcheck disable=SC2086
        return $RET_UNAV
    fi

    # extract the cover data
    local xml_cover=$(extract_xml_tag 'cover' "$xml_path")

    # write archive data
    echo "$xml_cover" | extract_cdata_tag | $g_cmd_base64_decode > "$cover_path" 2> /dev/null

    if ! [ -s "$cover_path" ]; then
        _info $LINENO "okladka ma zerowy rozmiar, usuwam..."
        [ -e "$cover_path" ] && $g_cmd_unlink "$cover_path"
        rv=$RET_FAIL
    fi

    return "$rv"
}


#
# @brief removes the remaining xml file if present
# @param movie filename
#
cleanup_xml() {
    local movie_path="${1:-}"

    if ! system_is_api_napiprojekt3; then
        # don't even bother if id is not configured
        # to any compatible with napiprojekt3 api
        _debug $LINENO "nie ma co sprzatac, plik xml jest tworzony tylko dla napiprojekt3 api"

        # shellcheck disable=SC2086
        return $RET_OK
    fi

    local movie_file=$(basename "$movie_path")
    local base=$(strip_ext "$movie_file")
    local xmlfile="${base}.xml"
    local path=$(dirname "$movie_path")

    # check for file presence
    if [ -e "$path/$xmlfile" ] && [ $g_clean_xml -ge 1 ]; then
        $g_cmd_unlink "$path/$xmlfile"
        _debug $LINENO "usunieto plik xml dla [$movie_file]"
    fi

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# @brief download item (subs or cover) using napiprojekt3 API
# @param md5sum
# @param movie file path
# @param output file path
# @param language
# @param item type subs/cover
#
download_item_xml() {
    local item="${1:-subs}"

    local md5sum=${2:-0}
    local movie_path="${3:-}"
    local item_path="${4:-}"
    local lang="${5:-PL}"

    local path=$(dirname "$movie_path")
    local movie_file=$(basename "$movie_path")
    local noext=$(strip_ext "$movie_file")
    local xml_path="$path/${noext}.xml"
    local byte_size=0

    [ -e "$movie_path" ] && byte_size=$($g_cmd_stat "$movie_path")

    # xml extract function name
    local func_name="extract_${item}_xml"

    # assume failure
    local rv=$RET_FAIL;

    # item verification
    case "$item" in
        'subs' | 'cover' | 'nfo')
            ;;
        *)
            _error "obslugiwane bloki to cover/subs/nfo [$item]"
            rv=$RET_BREAK
            return "$rv"
            ;;
    esac

    _info $LINENO "pobieram $item metoda xml"

    # get the god damn xml
    get_xml "$md5sum" "$movie_file" "$byte_size" "$lang" "$xml_path"
    rv=$?

    # check the status
    # shellcheck disable=SC2086
    [ $rv -ne $RET_OK ] &&
        _error "blad. nie mozna pobrac pliku xml" &&
        return $RET_FAIL

    # verify the contents
    # check if the file was downloaded successfully by checking
    # if it exists at all
    # shellcheck disable=SC2086
    [ ! -e "$xml_path" ] &&
        _error "sciagniety plik nie istnieje, nieznany blad" &&
        return $RET_FAIL

    $func_name "$xml_path" "$item_path"
    rv=$?
    return $rv
}


#
# @brief downloads subtitles
# @param md5 sum of the video file
# @param hash of the video file
# @param output filepath
# @param requested subtitles language
#
download_subs_classic() {
    local md5sum="${1:-0}"
    local h="${2:-0}"
    local of="$3"
    local lang="${4:-PL}"
    local id="${5:-pynapi}"
    local user="${6:-}"
    local passwd="${7:-}"
    local status=$RET_FAIL

    local rv=$RET_OK
    local http_codes=''

    # downloaded filename
    local dof="$of"
    local url="http://napiprojekt.pl/unit_napisy/dl.php?l=${lang}&f=${md5sum}&t=${h}&v=${id}&kolejka=false&nick=${user}&pass=${passwd}&napios=posix"
    local napi_pass="iBlm8NTigvru0Jr0"

    # should be enough to avoid clashing
    [ "$id" = "other" ] && dof="$(mktemp napisy.7z.XXXXXXXX)"

    # log the url with all the variables
    _debug $LINENO "url: [$url]"

    http_codes=$(download_url "$url" "$dof")
    status=$?
    _info $LINENO "otrzymane odpowiedzi http: [$http_codes]"

    if [ "$status" -ne $RET_OK ]; then
        _error "blad wgeta. nie mozna pobrac pliku [$of], odpowiedzi http: [$http_codes]"

        # cleanup
        [ "$id" = "other" ] && [ -e "$dof" ] && $g_cmd_unlink "$dof"

        # ... and exit
        # shellcheck disable=SC2086
        return $RET_FAIL
    fi

    # it seems that we've got the file perform some verifications on it
    case $id in
        "pynapi" )
        # no need to do anything
        ;;

        "other")
        $g_cmd_7z x -y -so -p"$napi_pass" "$dof" 2> /dev/null > "$of"
        status=$?

        [ -e "$dof" ] && $g_cmd_unlink "$dof"

        # check 7z status
        if [ "$status" -ne $RET_OK ]; then
            _error "7z zwraca blad. nie mozna rozpakowac napisow"
            rv=$RET_FAIL
            [ -e "$of" ] && $g_cmd_unlink "$of"
        fi

        # check file existence
        if [ ! -s "$of" ]; then
            _info $LINENO "plik docelowy ma zerowy rozmiar"
            rv=$RET_FAIL
            [ -e "$of" ] && $g_cmd_unlink "$of"
        fi
        ;;

        *)
        _error "not supported"
        ;;
    esac

    # verify the contents
    if [ "$rv" -eq $RET_OK ]; then

        # check if the file was downloaded successfully by checking
        # if it exists at all
        if [ ! -e "$of" ]; then
            _error "sciagniety plik nie istnieje, nieznany blad"

            # shellcheck disable=SC2086
            return $RET_FAIL
        fi

        # count lines in the file
        _debug $LINENO "licze linie w pliku [$of]"
        local lines=$(cat "$of" | count_lines)

        # adjust that if needed
        local min_lines=3

        _debug $LINENO "lines/min_lines: [$lines/$min_lines]"

        if [[ "$lines" -lt "$min_lines" ]]; then
            _info $LINENO "plik zawiera mniej ($lines) niz $min_lines lin(ie). zostanie usuniety"

            local fdata=$(cat "$of")
            _debug $LINENO "$fdata"

            rv=$RET_FAIL
            $g_cmd_unlink "$of"
        fi
    fi

    return "$rv"
}


#
# @brief: retrieve cover (probably deprecated okladka_pobierz doesn't exist - 404)
# @param: md5sum
# @param: outputfile
#
download_cover_classic() {
    local url="http://www.napiprojekt.pl/okladka_pobierz.php?id=$1&oceny=-1"
    local rv=$RET_FAIL
    local http_codes=""

    http_codes=$(download_url "$url" "$2")
    rv=$?
    _info $LINENO "otrzymane odpowiedzi http: [$http_codes]"

    if [ $rv -eq $RET_OK ]; then

        # if file doesn't exist or has zero size
        if ! [ -s "$2" ]; then
            rv=$RET_UNAV
            [ -e "$2" ] && $g_cmd_unlink "$2"
        fi
    fi

    return "$rv"
}


#
# @brief downloads subtitles for a given media file
# @param media file path
# @param subtitles file path
# @param requested subtitles language
#
get_subtitles() {
    local fn="$1"
    local of="$2"
    local lang="$3"

    # md5sum and hash calculation
    local sum=$(dd if="$fn" bs=1024k count=10 2> /dev/null | $g_cmd_md5 | cut -d ' ' -f 1)
    local h=0
    local status=$RET_FAIL

    local media_file=$(basename "$fn")
    _info $LINENO "pobieram napisy dla pliku [$media_file]"

    # pick method depending on id
    if system_is_api_napiprojekt3; then
        download_item_xml "subs" "$sum" "$fn" "$of" "$lang"
        status=$?
    else
        h=$(napiprojekt_f "$sum" | lcase)

        # g_cred expansion is deliberate
        # shellcheck disable=SC2068
        download_subs_classic "$sum" "$h" "$of" "$lang" "$(system_get_napi_id)" ${g_cred[@]}
        status=$?
    fi

    return $status
}


#
# @brief downloads information file for a given media file
# @param media file path
# @param nfo file path
#
get_nfo() {
    local path=$(dirname "$1")
    local media_file=$(basename "$1")
    local nfo_fn=$(strip_ext "$media_file")
    local status=$RET_FAIL

    nfo_fn="${nfo_fn}.nfo"

    # if skipping requested
    if [ "$g_skip" -eq 1 ] && [ -e "$path/$nfo_fn" ]; then
        _info $LINENO "plik nfo juz istnieje. nie bedzie pobrany"

        # shellcheck disable=SC2086
        return $RET_NOACT
    fi

    _info $LINENO "pobieram nfo dla pliku [$media_file]"

    # pick method depending on id
    if ! system_is_api_napiprojekt3; then
        _error "pobieranie informacji o pliku jest mozliwe tylko przy uzyciu napiprojekt API-3 (id: NapiProjekPython/NapiProjekt)"
        return $status
    fi

    download_item_xml "nfo" 0 "$1" "$path/$nfo_fn" 'PL'
}


#
# @param media file path
#
get_cover() {
    local sum=$(dd if="$1" bs=1024k count=10 2> /dev/null | $g_cmd_md5 | cut -d ' ' -f 1)
    local path=$(dirname "$1")
    local media_file=$(basename "$1")
    local cover_fn=$(strip_ext "$media_file")
    local status=$RET_FAIL

    # TODO correct this - extension hardcoded
    cover_fn="${cover_fn}.jpg"

    # if skipping requested
    if [ "$g_skip" -eq 1 ] && [ -e "$path/$cover_fn" ]; then
        _info $LINENO "plik okladki juz istnieje. nie bedzie pobrany"

        # shellcheck disable=SC2086
        return $RET_NOACT
    fi

    # pick method depending on id
    if system_is_api_napiprojekt3; then
        download_item_xml "cover" "$sum" "$1" "$path/$cover_fn"
        status=$?
    else
        download_cover_classic "$sum" "$path/$cover_fn"
        status=$?
    fi

    return $status
}


#
# @brief detects the charset of the subtitles file
# @param full path to the subtitles file
#
get_charset() {
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


################################# file handling ################################

#
# @brief prepare a list of file which require processing
# @param minimum filesize
# @param space delimited file list string
#
prepare_file_list() {
    local file=""
    local min_size=${1:-0}
    local ve=0
    local fs=0

    shift
    for file in "$@"; do

        # check if file exists, if not skip it
        if [ ! -e "$file" ]; then
            continue

        elif [ ! -s "$file" ]; then
            _warning "podany plik jest pusty [$file]"
            continue

        # check if is a directory
        # if so, then recursively search the dir
        elif [ -d "$file" ]; then
            local tmp="$file"
            prepare_file_list "$min_size" "$tmp"/*

        else
            # check if the respective file is a video file (by extention)
            ve=$(verify_extension "$file")
            fs=$($g_cmd_stat "$file")

            if [ "$ve" -eq 1 ] &&
               [ "$fs" -ge $(( min_size*1024*1024 )) ]; then
                # g_files+=( "$file" )
                g_files=( "${g_files[@]}" "$file" )
            fi
        fi
    done

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# @brief prepare all the possible filenames for the output file (in order to check if it already exists)
#
# this function prepares global variables g_pf containing all the possible output filenames
# index description
#
# @param video filename (without path)
#
prepare_filenames() {

    # media filename (with path)
    local fn="${1:-}"

    # media filename without extension
    local noext=$(strip_ext "$fn")

    # converted extension
    local cext=$(get_sub_ext $g_sub_format)

    local ab=${g_abbrev[0]}
    local cab=${g_abbrev[1]}

    # empty the array
    g_pf=()

    # array contents description
    #
    # original_file (o) - as download from napiprojekt.pl (with extension changed only)
    # abbreviation (a)
    # conversion abbreviation (A)
    # prefix (p) - g_orig_prefix for the original file
    # converted_file (c) - filename with converted subtitles format (may have differect extension)
    #
    # 0 - o - filename + g_default_ext
    # 1 - o + a - filename + abbreviation + g_default_ext
    # 2 - p + o - g_orig_prefix + filename + g_default_ext
    # 3 - p + o + a - g_orig_prefix + filename + abbreviation + g_default_ext
    # 4 - c - filename + get_sub_ext
    # 5 - c + a - filename + abbreviation + get_sub_ext
    # 6 - c + A - filename + conversion_abbreviation + get_sub_ext
    # 7 - c + a + A - filename + abbreviation + conversion_abbreviation + get_sub_ext

    # original
    g_pf[0]="${noext}.$g_default_ext"
    g_pf[1]="${noext}.${ab:+$ab.}$g_default_ext"
    g_pf[2]="${g_orig_prefix}${g_pf[0]}"
    g_pf[3]="${g_orig_prefix}${g_pf[1]}"

    # converted
    g_pf[4]="${noext}.$cext"
    g_pf[5]="${noext}.${ab:+$ab.}$cext"
    g_pf[6]="${noext}.${cab:+$cab.}$cext"
    g_pf[7]="${noext}.${ab:+$ab.}${cab:+$cab.}$cext"

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# @brief convert format
# @param full path to the media file
# @param original (as downloaded) subtitles filename
# @param filename to which unconverted subtitles should be renamed
# @param filename for converted subtitles
#
convert_format() {
    local media_path="$1"
    local input="$2"
    local orig="$3"
    local conv="$4"

    local path=$(dirname "$media_path")

    local fps=0
    local fps_opt=''
    local rv=$RET_OK

    # verify original file existence before proceeding further
    # shellcheck disable=SC2086
    ! [ -e "$path/$input" ] &&
        _error "oryginalny plik nie istnieje" &&
        return $RET_FAIL

    # for the backup
    local tmp="$(mktemp napi.XXXXXXXX)"

    # create backup
    _debug $LINENO "backupuje oryginalny plik jako $tmp"
    cp "$path/$input" "$tmp"

    # if delete orig flag has been requested don't rename the original file
    if [ "$g_delete_orig" -eq 0 ]; then
        _info $LINENO "kopiuje oryginalny plik jako [$orig]" &&
        cp "$path/$input" "$path/$orig"
    else
        # get rid of it, if it already exists
        [ -e "$path/$orig" ] && $g_cmd_unlink "$path/$orig"
    fi

    # detect video file framerate
    [ "$g_fps_tool" != 'default' ] &&
        _info $LINENO "wykrywam fps uzywajac: $g_fps_tool"
        fps=$(get_fps "$g_fps_tool" "$media_path")

    if [ -n "$fps" ] && [ "$fps" != "0" ]; then
        _msg "wykryty fps: $fps"
        fps_opt="-fi $fps"
    else
        _msg "fps nieznany, okr. na podstawie napisow albo wart. domyslna"
    fi

    _msg "wolam subotage.sh"

    # create ipc file to update the message counter
    local ipc_file="$(mktemp ipc.XXXXXXXX)"
    local msg_counter=0

    # fps_opt must be expanded for the subotage call
    # shellcheck disable=SC2086
    subotage.sh -v "$(output_get_verbosity)" \
        -i "$path/$input" \
        -of $g_sub_format \
        -t "$(output_get_fork_id)" \
        -m "$(output_get_msg_counter)" \
        --ipc-file "$ipc_file" \
        -o "$path/$conv" $fps_opt
    status=$?

    # update the message counter
    [ -s "$ipc_file" ] && read msg_counter < "$ipc_file"
    output_set_msg_counter "$msg_counter"

    # get rid of the ipc file
    [ -e "$ipc_file" ] && $g_cmd_unlink "$ipc_file"

    # remove the old format if conversion was successful
    if [ $status -eq $RET_OK ]; then
        _msg "pomyslnie przekonwertowano do $g_sub_format"
        [ "$input" != "$conv" ] &&
            _info $LINENO "usuwam oryginalny plik" &&
            $g_cmd_unlink "$path/$input"

    elif [ $status -eq $RET_NOACT ]; then
        _msg "subotage.sh - konwersja nie jest konieczna"

        #copy the backup to converted
        cp "$tmp" "$path/$conv"

        # get rid of the original file
        [ "$input" != "$conv" ] &&
            _msg "usuwam oryginalny plik" &&
            $g_cmd_unlink "$path/$input"

        rv=$RET_OK

    else
        _msg "konwersja do $g_sub_format niepomyslna"
        # restore the backup (the original file may be corrupted due to failed conversion)
        cp "$tmp" "$path/$input"
        rv=$RET_FAIL

    fi

    # delete a backup
    [ -e "$tmp" ] && $g_cmd_unlink "$tmp"
    return "$rv"
}


#
# @brief check file presence
#
check_subs_presence() {
    local media_file="$1"
    local path="$2"

    # bits
    # 1 - unconverted available/unavailable
    # 0 - converted available/unavailable
    #
    # default - converted unavailable, unconverted unavailable
    local rv=0

    _debug $LINENO "g_cmd_cp = $g_cmd_cp"

    if [ "$g_sub_format" != 'default' ]; then

        # unconverted unavailable, converted available
        rv=$(( rv | 1 ))

        if [ -e "$path/${g_pf[7]}" ]; then
            _status "SKIP" "$media_file"

        elif [ -e "$path/${g_pf[6]}" ]; then
            _status "COPY" "${g_pf[6]} -> ${g_pf[7]}"
            $g_cmd_cp "$path/${g_pf[6]}" "$path/${g_pf[7]}"

        elif [ -e "$path/${g_pf[5]}" ]; then
            _status "COPY" "${g_pf[5]} -> ${g_pf[7]}"
            $g_cmd_cp "$path/${g_pf[5]}" "$path/${g_pf[7]}"

        elif [ -e "$path/${g_pf[4]}" ]; then
            _status "COPY" "${g_pf[4]} -> ${g_pf[7]}"
            $g_cmd_cp "$path/${g_pf[4]}" "$path/${g_pf[7]}"

        else
            _info $LINENO "skonwertowany plik niedostepny"
            rv=$(( rv & ~1 ))
        fi

        # we already have what we need - bail out
        [ $(( rv & 1 )) -eq 1 ] && return $rv
    fi

    # assume unconverted available & verify that
    rv=$(( rv | 2 ))

    # when the conversion is not required
    if [ -e "$path/${g_pf[1]}" ]; then
        _status "SKIP" "$media_file"

    elif [ -e "$path/${g_pf[0]}" ]; then
        _status "COPY" "${g_pf[0]} -> ${g_pf[1]}"
        $g_cmd_cp "$path/${g_pf[0]}" "$path/${g_pf[1]}"

    elif [ -e "$path/${g_pf[3]}" ]; then
        _status "COPY" "${g_pf[3]} -> ${g_pf[1]}"
        $g_cmd_cp "$path/${g_pf[3]}" "$path/${g_pf[1]}"

    else
        _info $LINENO "oryginalny plik niedostepny"
        rv=$(( rv & ~2 ))
    fi

    # exceptionally in this function return value caries the
    # information - not the execution status
    return $rv
}


#
# @brief try to obtain media file from napiprojekt or skip
# @param media file full path
#
obtain_file() {
    local media_path="$1"
    local media_file=$(basename "$media_path")
    local path=$(dirname "$media_path")
    local rv=$RET_FAIL

    # file availability
    local av=0
    local should_convert=0

    # prepare all the possible filename combinations
    prepare_filenames "$media_file"
    _debug $LINENO "potencjalne nazwy plikow: ${g_pf[*]}"
    _debug $LINENO "katalog docelowy [$path]"

    if [ "$g_skip" -eq 1 ]; then
        _debug $LINENO "sprawdzam dostepnosc pliku"
        check_subs_presence "$media_file" "$path"
        av=$?
    fi

    _info $LINENO "dostepnosc pliku $av"
    _debug $LINENO "przekonwertowany dostepny = $(( av & 1 ))"
    _debug $LINENO "oryginalny dostepny = $(( (av & 2) >> 1 ))"

    # if conversion is requested
    if [ "$g_sub_format" != 'default' ]; then

        case $av in
            0) # download & convert
                if get_subtitles "$media_path" "$path/${g_pf[1]}" "$g_lang"; then
                    _debug $LINENO "napisy pobrano, nastapi konwersja"
                    should_convert=1
                    g_stats[0]=$(( g_stats[0] + 1 ))
                else
                    # unable to get the file
                    _debug $LINENO "napisy niedostepne"
                    rv=$RET_UNAV
                fi
            ;;

            1) # unconverted unavailable, converted available
                _debug $LINENO "nie pobieram, nie konwertuje - dostepna skonwertowana wersja"

                # increment skipped counter
                g_stats[2]=$(( g_stats[2] + 1 ))
                rv=$RET_NOACT
            ;;

            2|3) # convert
                _debug $LINENO "nie pobieram - dostepna jest nieskonwertowana wersja"

                # increment skipped counter
                g_stats[2]=$(( g_stats[2] + 1 ))
                should_convert=1
            ;;
        esac

        # original file available - convert it
        if [ $should_convert -eq 1 ]; then
            _msg "konwertowanie do formatu $g_sub_format"
            convert_format "$media_path" "${g_pf[1]}" "${g_pf[3]}" "${g_pf[7]}"
            rv=$?

            # increment converted counter
            g_stats[3]=$(( g_stats[3] + 1 ))
        fi

    else
        _info $LINENO "konwersja nie wymagana"

        # file is not available - download
        if [ ${av[0]} -eq 0 ]; then
            get_subtitles "$media_path" "$path/${g_pf[1]}" "$g_lang"
            rv=$?
            [ $rv -eq $RET_OK ] && g_stats[0]=$(( g_stats[0] + 1 ))
        else

            # increment skipped counter
            g_stats[2]=$(( g_stats[2] + 1 ))
            rv=$RET_NOACT
        fi
    fi

    # return the subtitles index
    return "$rv"
}


obtain_others() {
    local what="${1:cover}"
    local media_path="$2"
    local media_file=$(basename "$media_path")

    local status=$RET_NOACT
    local flag_value=0
    local func="get_$what"
    local idx_base=4

    case "$what" in
        "nfo" )
            flag_value="$g_nfo"
            idx_base=7
            ;;

        "cover" )
            flag_value="$g_cover"
            ;;

        *)
            # shellcheck disable=SC2086
            return $RET_FAIL
            ;;
    esac

    # download the data, if requested to do so
    if [ "$flag_value" -eq 1 ]; then
        local offset=0
        local idx=0

        $func "$media_path"
        status=$?

        case $status in
            $RET_NOACT )
                _status "SKIP" "$what for $media_file"
                offset=2
                ;;

            $RET_OK )
                _status "OK" "$what for $media_file"
                offset=0
                ;;

            *)
                _status "UNAV" "$what for $media_file"
                offset=1
                ;;
        esac

        idx=$(( idx_base + offset ))
        g_stats[$idx]=$(( g_stats[$idx] + 1 ))
    fi

    return $status
}


#
# @brief process a single media file
#
process_file() {
    local media_path="$1"
    local media_file=$(basename "$media_path")
    local path=$(dirname "$media_path")

    local rv=$RET_OK
    local status=0
    local si=1

    obtain_file "$media_path"
    status=$?

    if [ $status -eq $RET_OK ] || [ $status -eq $RET_NOACT ]; then
        _status "OK" "$media_file"

        [ "$g_sub_format" != 'default' ] &&
            _debug $LINENO "zadanie konwersji - korekcja nazwy pliku"
            si=7

        # charset conversion (only if freshly downloaded)
        [ $status -eq $RET_OK ] && io_convert_encoding "$path/${g_pf[$si]}"

        # process nfo requests
        obtain_others "nfo" "$media_path"

        # process cover requests
        obtain_others "cover" "$media_path"

        # process hook - only if some processing has been done
        [ $status -eq $RET_OK ] && system_execute_hook "$path/${g_pf[$si]}"
    else
        _status "UNAV" "$media_file"
        g_stats[1]=$(( g_stats[1] + 1 ))
        rv=$RET_UNAV
    fi # if [ $status = $RET_OK ]

    # cleanup the xml remnants
    cleanup_xml "$media_path"

    # increment total processed counter
    g_stats[10]=$(( g_stats[10] + 1 ))

    return "$rv"
}


#
# @brief this is a worker function it will run over the files array with a given step starting from given index
# @param starting index
# @param increment
#
process_files() {

    local s=${1:-0}
    local i=${2:-1}

    # current
    local c=$s

    while [ "$c" -lt ${#g_files[@]} ]; do
        _info $LINENO "#$s - index poczatkowy $c"
        process_file "${g_files[$c]}"
        c=$(( c + i ))
    done

    # dump statistics to fd #8 (if it has been opened before)
    [ -e "/proc/self/fd/8" ] || [ -e "/dev/fd/8" ] &&
        echo "${g_stats[*]}" >&8

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# @brief summarize statistics collected from forks
# @param statistics file
#
sum_stats() {
    local file="$1"
    local awk_script=''
    local fc=${#g_stats[@]}

# embed small awk program to count the columns
read -d "" awk_script << EOF
BEGIN {
    fmax=$fc
    for (x=0; x<fmax; x++) cols[x] = 0
}

{
    max = fmax > NF ? NF : fmax
    for (x=0; x<max; x++) cols[x] += \$(x + 1)
}

END {
    for (x=0; x<fmax; x++)
        printf "%d ", cols[x]
    print ""
}
EOF

    # update the contents
    g_stats=( $(run_awk_script "$awk_script" "$file") )

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# @brief creates the actual worker forks
#
spawn_forks() {
    local c=0
    local stats_file="$(mktemp stats.XXXXXXXX)"
    local old_msg_cnt=0
    local nforks="$(system_get_forks)"

    # open fd #8 for statistics collection
    exec 8<> "$stats_file"

    # spawn parallel processing
    while [ $c -lt "$nforks" ] && [ $c -lt ${#g_files[@]} ]; do

        _debug $LINENO "tworze fork #$(( c + 1 )), przetwarzajacy od $c z incrementem $nforks"

        output_set_fork_id $(( c + 1 ))
        old_msg_cnt=$(output_get_msg_counter)
        output_set_msg_counter 1 # reset message counter
        process_files $c $nforks &

        # restore original values
        output_set_msg_counter "$old_msg_cnt"
        c=$(output_get_fork_id)
        output_set_fork_id 0

    done

    # wait for all forks
    wait

    # sum stats data
    if [ -e "$stats_file" ]; then
        sum_stats "$stats_file"
        # close the fd
        exec 8>&-
        $g_cmd_unlink "$stats_file"
    fi

    # restore main fork id
    output_set_fork_id 0

    # shellcheck disable=SC2086
    return $RET_OK
}


#
# print stats summary
#
print_stats() {
    declare -a labels=( 'OK' 'UNAV' 'SKIP' 'CONV' 'COVER_OK' 'COVER_UNAV' 'COVER_SKIP' 'NFO_OK' 'NFO_UNAV' 'NFO_SKIP' 'TOTAL' )
    local i=0

    _msg "statystyki przetwarzania"

    while [ $i -lt ${#g_stats[@]} ]; do
        _status "${labels[$i]}" "${g_stats[$i]}"
        i=$(( i + 1 ))
    done

    # shellcheck disable=SC2086
    return $RET_OK
}

################################################################################

#
# @brief prints the help & options overview
#
usage() {
    tools_is_detected "subotage.sh"
    local subotage_presence=$?

    tools_is_detected "iconv"
    local iconv_presence=$?

    echo "=============================================================="
    echo "napi.sh version $g_revision (identifies as $(system_get_napi_id))"
    echo "napi.sh [OPCJE] <plik|katalog|*>"
    echo

    echo "   -a  | --abbrev <string> - dodaj dowolny string przed rozszerzeniem (np. nazwa.<string>.txt)"
    echo "   -b  | --bigger-than <size MB> - szukaj napisow tylko dla plikow wiekszych niz <size>"
    echo "   -c  | --cover - pobierz okladke"

    [ "$iconv_presence" -eq $RET_OK ] &&
        echo "   -C  | --charset - konwertuj kodowanie plikow (iconv -l - lista dostepnych kodowan)"

    echo "   -e  | --ext - rozszerzenie dla pobranych napisow (domyslnie *.txt)"
    echo "   -F  | --forks - okresl recznie ile rownoleglych procesow utworzyc (dom. $(system_get_forks))"
    echo "   -I  | --id <pynapi|other|NapiProjektPython|NapiProjekt> - okresla jak napi.sh ma sie przedstawiac serwerom napiprojekt.pl (dom. $(system_get_napi_id))"
    echo "   -l  | --log <logfile> - drukuj output to pliku zamiast na konsole"
    echo "   -lo | --log-overwrite - jezeli plik loga juz istnieje - nadpisz go"
    echo "   -L  | --language <LANGUAGE_CODE> - pobierz napisy w wybranym jezyku"
    echo "   -M  | --move - w przypadku opcji (-s) przenos pliki, nie kopiuj"
    echo "   -n  | --nfo - utworz plik z informacjami o napisach (wspierane tylko z id NapiProjektPython/NapiProjekt)"
    echo "   -p  | --pass <passwd> - haslo dla uzytkownika <login>"
    echo "   -S  | --script <script_path> - wywolaj skrypt po pobraniu napisow (sciezka do pliku z napisami, relatywna do argumentu napi.sh, bedzie przekazana jako argument)"
    echo "   -s  | --skip - nie sciagaj, jezeli napisy juz sciagniete"
    echo "   -u  | --user <login> - uwierzytelnianie jako uzytkownik"
    echo "   -v  | --verbosity <0..3> - zmien poziom gadatliwosci 0 - cichy, 3 - debug"
    echo "       | --stats - wydrukuj statystyki (domyslnie nie beda drukowane)"

    if [ "$subotage_presence" -eq $RET_OK ]; then
        echo "   -d  | --delete-orig - Delete the original file"
        echo "   -f  | --format - konwertuj napisy do formatu (wym. subotage.sh)"
        echo "   -P  | --pref-fps <fps_tool> - preferowany detektor fps (jezeli wykryto jakikolwiek)"
        echo "   -o  | --orig-prefix - prefix dla oryginalnego pliku przed konwersja (domyslnie: $g_orig_prefix)"
        echo "       | --conv-abbrev <string> - dodaj dowolny string przed rozszerzeniem podczas konwersji formatow"
        echo
        echo "Obslugiwane formaty konwersji napisow"
        subotage.sh -gl
    fi

    echo
    echo "Przyklady:"
    echo " napi.sh film.avi          - sciaga napisy dla film.avi."
    echo " napi.sh -c film.avi       - sciaga napisy i okladke dla film.avi."
    echo " napi.sh -u foo -p bar -c film.avi - sciaga napisy i okladke do"
    echo "                             film.avi jako uzytkownik foo"
    echo " napi.sh *                 - szuka plikow wideo w obecnym katalogu"
    echo "                             i podkatalogach, po czym stara sie dla"
    echo "                             nich znalezc i pobrac napisy."
    echo " napi.sh *.avi             - wyszukiwanie tylko plikow avi."
    echo " napi.sh katalog_z_filmami - wyszukiwanie we wskazanym katalogu"
    echo "                             i podkatalogach."

    if [ "$subotage_presence" -ne $RET_OK ]; then
        echo " "
        echo "UWAGA !!!"
        echo "napi.sh moze automatycznie dokonywac konwersji napisow"
        echo "do wybranego przez Ciebie formatu. Zainstaluj uniwersalny"
        echo "konwerter formatow dla basha: subotage.sh"
        echo "http://sourceforge.net/projects/bashnapi/"
        echo
    else
        echo " napi.sh -f subrip *       - sciaga napisy dla kazdego znalezionego pliku"
        echo "                           po czym konwertuje je do formatu subrip"

        local c_fps=$(tools_count_fps_detectors)

        if [ "$c_fps" -gt 0 ]; then
            echo
            echo "Wykryte narzedzia detekcji FPS"
            tools_fpstools_print_with_status
            echo
        else
            echo
            echo "By moc okreslac FPS na podstawie pliku video a nie na"
            echo "podstawie pierwszej linii pliku (w przypadku konwersji z microdvd)"
            echo "zainstaluj dodatkowo jedno z tych narzedzi (dowolne)"
            tools_fpstools_print
            echo
        fi
    fi

    # shellcheck disable=SC2086
    return $RET_OK
}

################################################################################

#
# @brief main function
#
main() {
    # first positional
    local arg1="${1:-}"

    # early debug - requires explicit level modification to appear
    _debug $LINENO "$0: ($g_revision) uruchamianie ..."

    # print bash version
    if [ -z "$BASH_VERSION" ]; then
        _debug $LINENO "interpreter inny niz bash ($SHELL)"
    else
        _debug $LINENO "interpreter to bash $BASH_VERSION"
    fi

    # commands configuration
    configure_cmds

    # verify tools presence
    _debug $LINENO "sprawdzam narzedzia ..."

    tools_verify_global

    if [ $? -ne $RET_OK ]; then
        _error "nie wszystkie wymagane narzedzia sa dostepne"
        _debug $LINENO $(tools_to_string)

        # shellcheck disable=SC2086
        return $RET_FAIL
    fi

    _debug $LINENO $(tools_to_string)

    # if no arguments are given, then print help and exit
    # shellcheck disable=SC2086
    [ $# -lt 1 ] || [ "$arg1" = "--help" ] || [ "$arg1" = "-h" ] &&
        usage &&
        return $RET_OK

    # get argv
    if ! parse_argv "$@"; then
        _error "niepoprawne argumenty..."

        # shellcheck disable=SC2086
        return $RET_FAIL
    fi

    # verify argv
    if ! verify_argv; then
        _error "niepoprawne argumenty..."

        # shellcheck disable=SC2086
        return $RET_FAIL
    fi

    _msg "wywolano o $(date)"
    _msg "system: $(system_get_system), forkow: $(system_get_forks), wersja: $g_revision"

    # inform about new napiprojekt API
    print_new_api_info

    _info $LINENO "przygotowuje liste plikow..."
    prepare_file_list $g_min_size "${g_paths[@]}"
    _msg "znaleziono ${#g_files[@]} plikow..."

    # install traps
    trap trap_control_c SIGINT SIGTERM SIGKILL

    # do the job
    spawn_forks

    [ "$g_stats_print" -eq 1 ] && print_stats

    # cleanup & exit
    _info $LINENO "przywracam STDOUT"
    output_set_logfile "none"

    # shellcheck disable=SC2086
    return $RET_OK
}

# call the main
[ "${SHUNIT_TESTS:-0}" -eq 0 ] && main "$@"

# EOF
