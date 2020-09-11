#!/usr/bin/env zsh

local ret=0

git clone https://git.archlinux.org/svntogit/packages.git/ -b packages/glibc --single-branch /tmp/glibc
sed -i 's#!strip#debug#' /tmp/glibc/repos/core-x86_64/PKGBUILD

cat /etc/makepkg.conf > /tmp/glibc.makepkg.conf
print ${MAKEPKG_CONF//-march=skylake /} >> /tmp/glibc.makepkg.conf

echo Y | MAKEPKG_CONF=/tmp/glibc.makepkg.conf pikaur -P -k --mflags=--noprogressbar,--skippgpcheck /tmp/glibc/repos/core-x86_64/PKGBUILD
ret=$?

cp ~/.cache/pikaur/build/glibc/*.pkg.tar.* ~/.cache/pikaur/pkg/

return $ret
