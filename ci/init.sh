#!/usr/bin/env sh

pacman -Syu base-devel git zsh pacman-contrib openssh rsync --noconfirm

cat >> /etc/pacman.conf <<'EOF'
[archlinuxcn]
Server = https://repo.archlinuxcn.org/$arch

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
rm -fr /etc/pacman.d/gnupg
pacman-key --init
pacman-key --populate archlinux
pacman -Syu archlinuxcn-keyring --noconfirm
pacman -Syu pikaur --noconfirm

useradd --create-home aur-build
printf "123\n123" | passwd aur-build
echo "aur-build ALL=(ALL) ALL" >> /etc/sudoers

