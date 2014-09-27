#!/bin/bash
set -e

test -n "$srcdir" || srcdir=`dirname "$0"`
test -n "$srcdir" || srcdir=.

f="${srcdir}/patches.list"

function die
{
    echo "Malformed ${f} file"
    exit 1
}

while read -r patch
do
    read -r desc || die
    echo "Processing ${patch}"
    git apply --whitespace=nowarn "${srcdir}/${patch}"
    read -r chmod_num || die
    for i in `seq 1 "${chmod_num}"`
    do
        read -r chmod_mode || die
        read -r file || die
        chmod "${chmod_mode}" "${file}"
    done
    git add --all .
    git commit --quiet --message="${desc}"
done < "${f}"
