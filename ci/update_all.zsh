#!/usr/bin/env zsh

PROJECT_ROOT=${0:A:h}/..

function init_environment() {
  cat > ~/.makepkg.conf <<'EOF'
CFLAGS="-march=skylake -Os -pipe -fno-plt"
CXXFLAGS="-march=skylake -Os -pipe -fno-plt"
MAKEFLAGS="-j$(nproc)"
PACKAGER="Aloxaf <aloxafx@gmail.com>"
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

init_environment

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

# TODO: 需要删包的时候怎么办
paccache -rvk1 -c ~/.cache/pikaur/pkg

repo-add ~/.cache/pikaur/pkg/aloxaf.db.tar.gz ~/.cache/pikaur/pkg/*.xz
