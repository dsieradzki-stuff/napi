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


# language code arrays
declare -ar ___g_language=( 'Albański' 'Angielski' 'Arabski' 'Bułgarski' \
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
# @brief default subtitles language
#
declare ___g_lang='PL'


#
# @brief: list all the supported languages and their respective 2/3 letter codes
#
language_list() {
    local i=0
    while [ "$i" -lt "${#g_Language[@]}" ]; do
        echo "${g_LanguageCodes2L[$i]}/${g_LanguageCodes3L[$i]} - ${g_Language[$i]}"
        i=$(( i + 1 ))
    done
}


language_set() {
    local idx=0
    ___g_lang="${1}"
    idx=$(language_verify) || ___g_lang="PL"

    _debug $LINENO 'sprawdzam wybrany jezyk'
    if [ $? -ne $RET_OK ]; then
        if [ "$___g_lang" = "list" ]; then
            list_languages

            # shellcheck disable=SC2086
            return $RET_BREAK
        else
            _warning "nieznany jezyk [$___g_lang]. przywracam PL"
            ___g_lang='PL'
        fi
    fi

    language_normalize "$idx"
    return $RET_OK
}


language_get() {
    echo "$___g_lang"
}


#
# @brief verify that the given language code is supported
#
language_verify() {
    local i=0
    declare -a l_arr=( )

    # shellcheck disable=SC2086
    [ ${#___g_lang} -ne 2 ] && [ ${#___g_lang} -ne 3 ] && return $RET_PARAM

    local l_arr_name="g_LanguageCodes${#___g_lang}L";
    eval l_arr=\( \${${l_arr_name}[@]} \)

    # this function can cope with that kind of input
    # shellcheck disable=SC2068
    i=$(lookup_key "$___g_lang" ${l_arr[@]})
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
language_normalize() {
    local i=${1:-0}
    i=$(( i + 0 ))

    local lang=${g_LanguageCodes2L[$1]}

    # don't ask me why
    [ "$lang" = "EN" ] && lang="ENG"
    ___g_lang="$lang"

    # shellcheck disable=SC2086
    return $RET_OK
}

# EOF
