#!/usr/bin/env zsh

eval "$1"

for package in /home/aur-build/.cache/pikaur/pkg/*.xz; do
if [[ ! -f $package.sig ]]; then
    gpg --detach-sign --use-agent -u $GPGKEY --no-armor $package
    chown aur-build $package.sig
fi
done

# TODO: 需要删包的时候怎么办
paccache -rvk2 -c /home/aur-build/.cache/pikaur/pkg

repo-add -s -k $GPGKEY /home/aur-build/.cache/pikaur/pkg/aloxaf.db.tar.gz /home/aur-build/.cache/pikaur/pkg/*.xz

chown aur-build /home/aur-build/.cache/pikaur/pkg/aloxaf.*
