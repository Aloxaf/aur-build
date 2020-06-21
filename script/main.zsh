#!/usr/bin/env zsh

cd ${0:A:h}

source ${0:A:h}/script.conf

function init_system() {
  # -- init pacman --
  cat >> /etc/pacman.conf <<'EOF'
[archlinuxcn]
Server = https://repo.archlinuxcn.org/$arch

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF

  rm -fr /etc/pacman.d/gnupg
  pacman-key --init
  pacman-key --populate archlinux
  pacman -Syu archlinuxcn-keyring --noconfirm --noprogressbar
  pacman -Syu git pacman-contrib openssh rsync pikaur --noconfirm --needed --noprogressbar

  # -- init makepkg --
  print $MAKEPKG_CONF >> /etc/makepkg.conf

  # -- init user --
  useradd --create-home aur-build
  printf "123\n123" | passwd aur-build
  print "aur-build ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

  # -- fix permission --
  mkdir -p ~aur-build/.cache/{pikaur/{build,pkg},aur}
  chown -R aur-build ~aur-build ~aur-build/.cache/{pikaur/{build,pkg},aur}

  # -- import GPG --
  gpg --pinentry-mode loopback --passphrase-file ${0:A:h}/data/private.passphrase \
      --import ${0:A:h}/data/private.key
}

function sign_packages() {
  setopt local_options null_glob extended_glob
  for package in ~aur-build/.cache/pikaur/pkg/*.pkg.tar.*~*.sig; do
    [[ -f $package.sig ]] && rm -f $package.sig
    gpg --passphrase-file ${0:A:h}/data/private.passphrase \
        --pinentry-mode loopback \
        --detach-sign --use-agent -u $GPGKEY --no-armor \
        $package
  done
}

function build_repo() {
  setopt local_options null_glob extended_glob
  paccache -rvk3 -c ~aur-build/.cache/pikaur/pkg
  local -a old_db=(~aur-build/.cache/pikaur/pkg/$REPO_NAME.*) # 辣鸡 Emacs 不认识 (#qN)
  if (( $#old_db )); then
     rm -f $old_db
  fi
  repo-add -s -k $GPGKEY \
           ~aur-build/.cache/pikaur/pkg/$REPO_NAME.db.tar.gz \
           ~aur-build/.cache/pikaur/pkg/*.pkg.tar.*~*.sig
}

function deploy() {
  rsync -avzr --delete -e 'ssh -i ./data/deploy_key -o StrictHostKeyChecking=no' \
        ~aur-build/.cache/pikaur/pkg/ $SERVER
}

# init
init_system

# build packages
sudo -u aur-build zsh update_all.zsh

sign_packages

build_repo

deploy

