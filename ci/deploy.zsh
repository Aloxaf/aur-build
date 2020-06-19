#!/usr/bin/env zsh

eval "$1"

mkdir -p ~/.ssh
touch ~/.ssh/known_hosts

local SSH_KEY=$2
echo -E $SSH_KEY > ~/.ssh/deploy_key

chmod 700 ~/.ssh
chmod 600 ~/.ssh/{deploy_key,known_hosts}

rsync -avzr --delete -e 'ssh -i ~/.ssh/deploy_key -o StrictHostKeyChecking=no' ~/.cache/pikaur/pkg/ $DEPLOY_DST
