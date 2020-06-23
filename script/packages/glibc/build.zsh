#!/usr/bin/env zsh

local ret=0
git clone https://git.archlinux.org/svntogit/packages.git/ -b packages/glibc --single-branch /tmp/glibc
sed -i 's#!strip#debug#' /tmp/glibc/repos/core-x86_64/PKGBUILD
echo Y | pikaur -P -k --mflags=--noprogressbar /tmp/glibc/repos/core-x86_64/PKGBUILD
ret=$?
cp ~/.cache/pikaur/build/glibc/*.pkg.tar.* ~/.cache/pikaur/pkg/
return $ret
