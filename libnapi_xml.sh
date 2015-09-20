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
# @brief parses the XML file and sets the XMLTAG_TAG global variable to the
# currently parsed tag and XMLTAG_CONTENT global variable to it's contents.
#
# Restrictions:
# 1. First call returns an empty string.
# 2. Support for simple tags only (doesn't extract tag's children if any)
# 3. Does not support XML attributes parsing.
#
# @param input_stream
#
xml_parse_dom() {
    local IFS=\>
    # shellcheck disable=SC2034
    read -d \< XMLTAG_TAG XMLTAG_CONTENT
}
