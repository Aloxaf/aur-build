#!/usr/bin/env zsh

function TRAPZERR() {
  local ret=$?
  LOG "Non zero exit code($ret) detected. Exiting..."
  exit $ret
}

cd ${0:A:h}

source ${0:A:h}/script.conf

function LOG() {
  echo "[LOG] $1"
}

function init_system() {
  LOG 'Initing pacman'
  cat >> /etc/pacman.conf <<EOF
[$REPO_NAME]
Server = file:///home/aur-build/.cache/pikaur/pkg
SigLevel = Optional TrustAll

[archlinuxcn]
Server = https://repo.archlinuxcn.org/\$arch

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
  print $MAKEPKG_CONF >> /etc/makepkg.conf

  LOG "Initing user"
  useradd --create-home aur-build
  printf "123\n123" | passwd aur-build
  print "aur-build ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
  chown -R aur-build:aur-build ~aur-build

  LOG "Initing GPG"
  rm -fr /etc/pacman.d/gnupg
  pacman-key --init
  pacman-key --populate archlinux
  pacman-key --add ${0:A:h}/data/private.key
  pacman-key --lsign-key $GPGKEY

  LOG "Importing GPG"
  sudo -u aur-build gpg --import --batch --yes ${0:A:h}/data/private.key
  shred --remove ${0:A:h}/data/private.key
  cat > ~aur-build/.gnupg/gpg-agent.conf <<EOF
default-cache-ttl 7200
max-cache-ttl 31536000
allow-preset-passphrase
EOF
  chown aur-build ~aur-build/.gnupg/gpg-agent.conf
  sudo -u aur-build gpg-connect-agent "RELOADAGENT" /bye

  local keygrip=$(grep grp --max-count 1 <(
     grep $GPGKEY -A 3 <(
       sudo -u aur-build gpg --batch --with-colons --with-keygrip --list-secret-keys $GPGKEY
  )))
  keygrip=$keygrip[(s|:|w)2]
  sudo -u aur-build /usr/lib/gnupg/gpg-preset-passphrase -c $keygrip < ${0:A:h}/data/private.passphrase

  LOG "Initing repo"
  mkdir -p ~aur-build/.cache/{pikaur/{build,pkg},aur}
  chown -R aur-build:aur-build ~aur-build/.cache/{pikaur/{build,pkg},aur}
  if [[ ! -f ~aur-build/.cache/pikaur/pkg/$REPO_NAME.db.tar.gz ]]; then
    sudo -u aur-build repo-add -n -p -s -k $GPGKEY \
         ~aur-build/.cache/pikaur/pkg/$REPO_NAME.db.tar.gz
  fi

  LOG 'Installing packages'
  pacman -Syu archlinuxcn-keyring --noconfirm --noprogressbar
  pacman -Syu git pacman-contrib openssh rsync pikaur --noconfirm --needed --noprogressbar
}

function current_package_list() {
  LOG "Current package list"
  for i in ~aur-build/.cache/pikaur/pkg/*.pkg.tar.*~*.sig; do
    LOG "=> $i"
  done
}

function build_repo() {
  setopt local_options null_glob extended_glob
  current_package_list
  paccache -rvk1 -c ~aur-build/.cache/pikaur/pkg
  local -a new_packages=(~aur-build/.cache/pikaur/pkg/*.pkg.tar.*~*.sig)
  local -a new_packages=(${new_packages:|packages})
  if (( $#new_packages )); then
    LOG "There are $#new_packages new packages"
    sudo -u aur-build repo-add -n -p -s -k $GPGKEY \
         ~aur-build/.cache/pikaur/pkg/$REPO_NAME.db.tar.gz \
         $new_packages
  else
    LOG "No new package"
  fi
}

function deploy() {
  LOG "Uploading to server"
  rsync -avzr --delete -e 'ssh -i ./data/deploy_key -o StrictHostKeyChecking=no' \
        ~aur-build/.cache/pikaur/pkg/ $SERVER
}

function remove_package() {
  LOG "Revoming package $1"
  setopt local_options null_glob
  [[ -d ~aur-build/.cache/aur/$1 ]] && rm -rdf ~aur-build/.cache/aur/$1
  sudo -u aur-build repo-remove -s -k $GPGKEY ~aur-build/.cache/pikaur/pkg/$REPO_NAME.db.tar.gz $1 \
    || LOG "Cannot found $1 in database"
  for file in ~aur-build/.cache/pikaur/pkg/$1-*.pkg.tar.*; do
    rm -f $file
  done
}

function prebuild_hook() {
  setopt local_options null_glob extended_glob
  typeset -g -a packages=(~aur-build/.cache/pikaur/pkg/*.pkg.tar.*~*.sig)
  # remove_package libgccjit
  # remove_package emacs-native-comp-git
}

typeset -g -a packages=()

# init
init_system

prebuild_hook

# build packages
sudo -u aur-build zsh update_all.zsh

build_repo

deploy
