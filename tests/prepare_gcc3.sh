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

declare -r GCC_PATCH="0001-collect-open-issue.patch"
declare -r GCC_ARCHIVE="gcc-3.0.tar.gz"
declare -r GCC_URL="https://ftp.gnu.org/gnu/gcc/gcc-3.0/gcc-3.0.tar.gz"

declare -r WORKDIR="/tmp"

declare -r GCC_PREFIX="/opt/gcc-3.0"
declare -r GCC_SRC="$WORKDIR/gcc-3.0"
declare -r GCC_BLD="$WORKDIR/gcc-build"


[ -e "$GCC_PREFIX" ] &&
	echo "GCC3 already installed. Nothing to do. Skipping" &&
	exit

if ! [[ -e "$WORKDIR/$GCC_PATCH" ]]; then
	echo "Won't be able to prepare gcc3, required patch is missing."
	exit
fi


export LIBRARY_PATH=/usr/lib/$(gcc -print-multiarch)
export C_INCLUDE_PATH=/usr/include/$(gcc -print-multiarch)
export CPLUS_INCLUDE_PATH=/usr/include/$(gcc -print-multiarch)


[ -e "$WORKDIR/$GCC_ARCHIVE"  ] || wget -O "$WORKDIR/$GCC_ARCHIVE" "$GCC_URL"
[ -e "$GCC_SRC" ] || {
	tar zvxf "$WORKDIR/$GCC_ARCHIVE" -C "$WORKDIR" &&
        patch -d "$GCC_SRC" -p1 -i "$WORKDIR/$GCC_PATCH"
}


mkdir -p "$GCC_BLD"


cd "$GCC_BLD" && "$GCC_SRC/configure" \
    --prefix=/opt/gcc-3.0 \
    --host=i686-linux-gnu \
    --build=i686-linux-gnu \
    --enable-shared \
    --enable-languages=c \
    --disable-libgcj \
    --disable-java-net \
    --disable-static-libjava


make && make install && rm -rf "$GCC_BLD"
