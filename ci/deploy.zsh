#!/usr/bin/env zsh

mkdir -p ~/.ssh
touch ~/.ssh/known_hosts

local SSH_KEY=$1

echo -E $SSH_KEY > ~/.ssh/deploy_key

chmod 700 ~/.ssh
chmod 600 ~/.ssh/{deploy_key,known_hosts}

rsync -avzr --delete -e 'ssh -i ~/.ssh/deploy_key -o StrictHostKeyChecking=no' ~/.cache/pikaur/pkg/ aur@107.172.90.125:~/x86_64
