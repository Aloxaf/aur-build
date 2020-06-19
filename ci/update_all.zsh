#!/usr/bin/env zsh

PROJECT_ROOT=${0:A:h}/..

eval "$1"

function init_environment() {
  cat > ~/.makepkg.conf <<EOF
CFLAGS="-march=skylake -Os -pipe -fno-plt"
CXXFLAGS="-march=skylake -Os -pipe -fno-plt"
MAKEFLAGS="-j\$(nproc)"
PACKAGER="$PACKAGER"
EOF

  cat > /tmp/sudo <<'EOF'
#!/usr/bin/env zsh
if [[ $1 == pacman ]]; then
    echo "123" | /usr/bin/sudo -S $* --noconfirm
else
    echo "123" | /usr/bin/sudo -S $*
fi
EOF

  chmod +x /tmp/sudo
  export PATH=/tmp:$PATH
}

function build_packages() {
  sudo echo "Test sudo"

  for package in $PROJECT_ROOT/packages/*; do
    echo "Building ${package:t}"
    if [[ -f $package/build.zsh ]]; then
      source $package/build.zsh
    else
      if [[ ! -f $package/PKGBUILD ]]; then
        git clone https://aur.archlinux.org/${package:t}.git /tmp/${package:t}
      else
        cp -r $package /tmp/
      fi
      echo Y | pikaur -P --noedit /tmp/${package:t}/PKGBUILD
    fi
  done
}

init_environment

build_packages

