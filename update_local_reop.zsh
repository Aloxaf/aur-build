#!/usr/bin/env zsh

REPO_PATH=~/.cache/aur_repo
REPO_NAME=custom
[[ -d $REPO_PATH ]] || mkdir -p ~/.cache/aur_repo
PROJECT_ROOT=${0:A:h}

if [[ -f $PROJECT_ROOT/custom.zsh ]]; then
  source $PROJECT_ROOT/custom.zsh
fi

function check_pacman() {
  if grep "file://${~REPO_PATH}" /etc/pacman.conf > /dev/null; then
    return
  fi
  echo "Please add these lines to your /etc/pacman.conf"
  echo '```'
  echo "[$REPO_NAME]"
  echo "SigLevel = Optional TrustAll"
  echo "Server = file://${~REPO_PATH}"
  echo '```'
}

function update_repo() {
  local remote=$(git -C $PROJECT_ROOT config --get remote.origin.url)
  remote=${${remote#*:}%.*}
  echo "Remote is $remote"

  local -a urls=(${(f)"$(curl --silent "https://api.github.com/repos/$remote/releases/latest" | \
               jq --raw-output '.assets | .[] | .browser_download_url')"})

  for url in $urls; do
    if [[ -n $CF_PROXY ]]; then
      url=https://$CF_PROXY/${url#https://}
    fi
    echo Downloading ${url:t}
    if [[ ! -f $REPO_PATH/${url:t} ]]; then
      aria2c -c $url -d $REPO_PATH &&
        repo-add $REPO_PATH/$REPO_NAME.db.tar.gz $REPO_PATH/${url:t}
    fi
  done

  paccache -rvk2 -c $REPO_PATH
}

check_pacman
update_repo
