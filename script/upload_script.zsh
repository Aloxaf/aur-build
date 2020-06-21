#!/usr/bin/env zsh

source ${0:A:h}/script.conf

[[ -f /tmp/script.7z ]] && rm -f /tmp/script.7z
7z a /tmp/script.7z -mhe=on -p$PASSWORD ${0:A:h}
scp /tmp/script.7z $SCRIPT

