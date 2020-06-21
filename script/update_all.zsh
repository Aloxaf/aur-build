#!/usr/bin/env zsh

PROJECT_ROOT=${0:A:h}
mkdir -p ~/.cache/aur

function need_update() {
  # 不存在则需要升级
  if [[ ! -d ~/.cache/aur/$1 ]]; then
    return 0
  fi

  if [[ $1 == *-git ]]; then
    # -git 包总是需要更新
    return 0
  else
    pushd ~/.cache/aur/$1
    local ret=0
    if [[ -d .git ]]; then
      # 对于 AUR 包，检测上游是否更新
      git remote update
      [[ $(git rev-parse @) != $(git rev-parse @{u}) ]]
      ret=$?
    elif [[ -f PKGBUILD ]]; then
      # 对于本地包，检测文件是否变化
      local old=$(sha256sum *(.) | sed -E 's/ +.*//' | sha256sum)
      local new=$(sha256sum $PROJECT_ROOT/packages/$1/*(.) | sed -E 's/ +.*//' | sha256sum)
      [[ $old != $new ]]
      ret=$?
    fi
    popd
    return $ret
  fi

  return 0
}

function build_packages() {
  for package in $PROJECT_ROOT/packages/*; do

    # 先检测是否需要更新，如果需要的话，直接删掉目录重建
    if ! need_update ${package:t}; then
      continue
    fi

    [[ -d ~/.cache/aur/${package:t} ]] && rm -rdf ~/.cache/aur/${package:t}

    if [[ -f $package/build.zsh ]]; then
      cp -r $package ~/.cache/aur/${package:t}
      echo "Building ${package:t}"
      source $package/build.zsh
    else
      if [[ ! -f $package/PKGBUILD ]]; then
        git clone https://aur.archlinux.org/${package:t}.git ~/.cache/aur/${package:t}
      else
        cp -r $package ~/.cache/aur/${package:t}
      fi
      echo "Building ${package:t}"
      echo Y | pikaur -P --mflags=--noprogressbar \
                      ~/.cache/aur/${package:t}/PKGBUILD
    fi
  done
}

function init() {
  mkdir -p ~/.config
  cat >> ~/.config/pikaur.conf <<EOF
[sync]
[build]
SkipFailedBuild = yes
[colors]
[ui]
RequireEnterConfirm = no
PrintCommands = yes
[misc]
PacmanPath = /tmp/pacman
[network]
[review]
DontEditByDefault = yes
NoEdit = yes
NoDiff = yes
EOF
  cat > /tmp/pacman <<'EOF'
#!/usr/bin/env zsh
if (( ${*[(I)--sync]} || ${*[(I)--upgrade]} || ${*[(I)--remove]} )); then
  /usr/bin/pacman $* --noconfirm --noprogressbar
else
  /usr/bin/pacman $*
fi
EOF
  chmod +x /tmp/pacman

  export PATH=/tmp:$PATH
}

init

build_packages
