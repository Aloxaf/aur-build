#!/usr/bin/env zsh

zmodload zsh/datetime

PROJECT_ROOT=${0:A:h}
mkdir -p ~/.cache/aur

function LOG() {
  echo "[LOG] $1"
}

function need_update() {
  setopt local_options extended_glob
  # 如果目录不存在，则需要构建
  if [[ ! -d $aur_dir ]]; then
    return 0
  fi

  pushd $aur_dir
  local ret=0
  if [[ -d .git ]]; then
    # 如果是 AUR 包，则检测上游是否更新
    git remote update
    [[ $(git rev-parse @) != $(git rev-parse @{u}) ]]
    ret=$?
  elif [[ -f PKGBUILD || -f build.zsh ]]; then
    # 如果是本地包，则检测文件是否变化
    local old=$(sha256sum *~last_installed | sed -E 's/ +.*//' | sha256sum)
    local new=$(sha256sum $PROJECT_ROOT/packages/$1/* | sed -E 's/ +.*//' | sha256sum)
    [[ $old != $new ]]
    ret=$?
  fi
  popd
  # 最后对 -git 包以及自定义构建脚本再检测一次
  # 对于它们来说 12 小时之后强制更新一次
  if (( $ret )); then
    if [[ $1 == *-git || -f $aur_dir/build.zsh ]]; then
      if [[ ! -f $aur_dir/last_installed ]] ||
           (( $EPOCHSECONDS - $(<$aur_dir/last_installed) >= 12 * 3600 )); then
        return 0
      else
        return 1
      fi
    fi
  fi
  return $ret
}

function build_packages() {
  setopt local_options null_glob
  for package in $PROJECT_ROOT/packages/*; do
    local aur_dir=~/.cache/aur/${package:t} ret=0
    local -a packages=(~/.cache/pikaur/pkg/*)

    # 先检测是否需要更新，如果需要的话，直接删掉目录重建
    LOG "Checking update for ${package:t}"
    if ! need_update ${package:t}; then
      continue
    fi

    echo "Updating ${package:t}"

    [[ -d $aur_dir ]] && rm -rdf $aur_dir

    if [[ -f $package/build.zsh ]]; then
      cp -r $package $aur_dir
      source $package/build.zsh
      ret=$?
    else
      if [[ ! -f $package/PKGBUILD ]]; then
        git clone https://aur.archlinux.org/${package:t}.git $aur_dir
      else
        cp -r $package $aur_dir
      fi
      echo Y | pikaur -P --mflags=--noprogressbar $aur_dir/PKGBUILD
      ret=$?
    fi
    # 确认成功构建后更新时间戳
    if (( ! $ret )); then
      local -a new_packages=(~/.cache/pikaur/pkg/*)
      if (( $#new_packages > $#packages )) || [[ ! -f $aur_dir/last_installed ]] ; then
        LOG "Updated"
        echo -n $EPOCHSECONDS > $aur_dir/last_installed
      else
        LOG "Nothing to do"
        # 如果本次没有更新的话，则只推后 8 小时
        echo -n $(( $(<$aur_dir/last_installed) + 8 * 3600 )) > $aur_dir/last_installed
      fi
    else
      LOG "Failed to Update"
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
