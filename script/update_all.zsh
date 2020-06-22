#!/usr/bin/env zsh

zmodload zsh/datetime

PROJECT_ROOT=${0:A:h}
mkdir -p ~/.cache/aur

function need_update() {
  # 不存在则需要升级
  if [[ ! -d $aur_dir ]]; then
    return 0
  fi

  if [[ $1 == *-git || -f $aur_dir/build.zsh ]]; then
    # -git 包或者自定义包 12 小时之后需要更新
    if [[ ! -f $aur_dir/last_installed ]] ||
         (( $EPOCHSECONDS - $(<$aur_dir/last_installed) >= 12 * 3600 )); then
      return $?
    else
      return 1
    fi
  else
    pushd $aur_dir
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
}

function build_packages() {
  for package in $PROJECT_ROOT/packages/*; do
    local aur_dir=~/.cache/aur/${package:t}

    # 先检测是否需要更新，如果需要的话，直接删掉目录重建
    if ! need_update ${package:t}; then
      continue
    fi

    [[ -d $aur_dir ]] && rm -rdf $aur_dir

    if [[ -f $package/build.zsh ]]; then
      cp -r $package $aur_dir
      echo -n $EPOCHSECONDS > $aur_dir/last_installed
      echo "Building ${package:t}"
      source $package/build.zsh
    else
      if [[ ! -f $package/PKGBUILD ]]; then
        git clone https://aur.archlinux.org/${package:t}.git $aur_dir
      else
        cp -r $package $aur_dir
      fi
      echo -n $EPOCHSECONDS > $aur_dir/last_installed
      echo "Building ${package:t}"
      echo Y | pikaur -P --mflags=--noprogressbar $aur_dir/PKGBUILD
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
