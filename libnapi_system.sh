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
declare -a g_system=( 'linux' '1' 'NapiProjektPython' )

