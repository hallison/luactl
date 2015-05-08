#!/bin/sh -e
changecom()dnl
#? Lua environment control
#? _NAME _VERSION (_RELEASE)
#?
#? Usage:
#?   _PROGRAM <COMMAND> <VM-VERSION>
#?   _PROGRAM <COMMAND> [OPTION]
#?
#? Commands:
#?   help                   Show this message.
#?   versions               List supported Lua versions.
#?   download <VM-VERSION>  Download the Lua source code.
#?   install  <VM-VERSION>  Install Lua version.
#?   use      <VM-VERSION>  Set the interpreter and version.
#?   list,ls                List all interpreters installed.
#?
#? Options:
#?   -h,--help   Show this message.
#?. 

set -a

# luactl directories
export LUACTL_ROOTDIR=_PREFIX
export LUACTL_LIBDIR=_LIBDIR
export LUACTL_SYSCONFDIR=_SYSCONFDIR
export LUACTL_VMDIR=_VMDIR
export LUACTL_SOURCEDIR=_SOURCEDIR

# luactl files
export LUACTL_ENVRC=$HOME/.luavcrc
export LUACTL_LUAENVRC=$LUACTL_SYSCONFDIR/luaenvrc

test -r $LUACTL_ENVRC && . $LUACTL_ENVRC

#@ Do not duplicate directory.
luactl_munge_path() {
  : ${1:?path}
  echo "$1:$PATH" | awk -v RS=':' -v ORS=':' '!path[$1]++'
}

#@ Split attributes returning interpreter and version.
luactl_split_attributes() {
  : ${1:?interpreter/compiler-version}
  local interpreter=${1%%-*}
  local version=${1##${interpreter}-}
  echo $interpreter $version
}

#@ Simple check configuration.
luactl_check() {
  test -f "$LUACTL_ENVRC"
}

#@ Configure LuaVC.
luactl_config() {
  test -d $LUACTL_ROOTDIR || {
    echo "Creating $LUACTL_ROOTDIR ..."
    mkdir -p $LUACTL_ROOTDIR
  }
  test -d $LUACTL_VMDIR || {
    echo "Creating $LUACTL_VMDIR ..."
    mkdir -p $LUACTL_VMDIR
  }
  test -d $LUACTL_SOURCEDIR || {
    echo "Creating $LUACTL_SOURCEDIR ..."
    mkdir -p $LUACTL_SOURCEDIR
  }
  test -f $LUACTL_ENVRC || {
    echo "Creating configurarion file $LUACTL_ENVRC ..."
    echo "export LUACTL_ROOTDIR=\"$LUACTL_ROOTDIR\""     >  $LUACTL_ENVRC
    echo "export LUACTL_ENVRC=\"$LUACTL_ENVRC\""         >> $LUACTL_ENVRC
    echo "export LUACTL_LUAENVRC=\"$LUACTL_LUAENVRC\""   >> $LUACTL_ENVRC
    echo "export LUACTL_VMDIR=\"$LUACTL_VMDIR\""       >> $LUACTL_ENVRC
    echo "export LUACTL_SOURCEDIR=\"$LUACTL_SOURCEDIR\"" >> $LUACTL_ENVRC
    echo "test -r \$LUACTL_LUAENVRC && . \$LUACTL_LUAENVRC" >> $LUACTL_ENVRC
  }
}

#@ Initialize luactl
luactl_init() {
  : ${1:?interpreter/compiler-version}
  local atr=$(luactl_split_attributes $1)
  local pkg=$(luactl_archive $atr)
  local lua=$(${atr%% })
  local env=$LUACTL_SYSCONFDIR/$1-$2.rc
  test $pkg && {
    export LUA_VERSION=$2
    export LUA_HOME=$LUACTL_VMDIR/$lua
    export LUA_SOURCE=$LUACTL_SOURCEDIR/$lua
    export LUA_PATH=";;$LUA_HOME/share/lua/${LUA_VERSION%.*}/?.lua;$LUA_HOME/share/lua/${LUA_VERSION%.*}/?/init.lua"
    export LUA_CPATH=";;$LUA_HOME/lib/lua/${LUA_VERSION%.*}/?.so"
    export LUA_INIT="require 'luarocks.loader'"
    export _PATH="$(luactl_munge_path $LUA_HOME/bin):\$PATH"
    echo "Creating configurarion for $lua ..."
      echo "export LUA_VERSION=\"$LUA_VERSION\"" >  $env
      echo "export LUA_HOME=\"$LUA_HOME\""       >> $env
      echo "export LUA_SOURCE=\"$LUA_SOURCE\""   >> $env
      echo "export LUA_PATH=\"$LUA_PATH\""       >> $env
      echo "export LUA_CPATH=\"$LUA_CPATH\""     >> $env
      echo "export LUA_INIT=\"$LUA_INIT\""       >> $env
      echo "export PATH=\"$_PATH\""               >> $env
  }
}

#@ Get archive package name.
luactl_archive() {
  : ${1:?interpreter/compiler}
  : ${2:?version}
  local md5=$LUACTL_SYSCONFDIR/$1.md5
  local pkg=
  test -r $md5 && {
    pkg=$(grep $2.tar.gz $md5 | cut -c35-)
    test $pkg && {
      echo $pkg
    } || {
      echo "Version $2 not suported"
      exit 1
    }
  } || {
    echo "Interpreter $1 not suported"
    return 1
  }
}

#@ Load library which contains functions to handle interpreter.
luactl_library() {
  : ${1:?interpreter/compiler}
  local lib=$LUACTL_LIBDIR/$1.sh
  test -r $lib && . $lib
}

luactl_error_handler() {
  echo "ERROR: $1"
}

#@ Comand to show usage message.
luactl_command_help() {
  grep '^#[?]' "${0}" | cut -c4-
}

#@ Command to show supported versions.
luactl_command_versions() {
  local lua=
  local pkg=
  local md5=
  luactl_command_help | head -3
  echo "Lua Interpreters"
  echo
  for lua in $LUACTL_LIBDIR/*.sh; do
    . $lua
    lua=${lua##*/}
    lua=${lua%%.*}
    md5=$LUACTL_SYSCONFDIR/$lua.md5
    printf "** %s\n\n" "$desc"
    cat $md5 | cut -c35- | sed 's/.tar.gz//' | sort | column
    echo
  done
}

#@ Command to download interpreter package.
luactl_command_download() {
  : ${1:?interpreter/compiler}
  : ${2:?version}
  luactl_library $1
  local wget=$(command -v wget)
  local url=$url/$(luactl_archive $1 $2)

  test $? -eq 0 && test -x $wget && {
    cd $LUACTL_SOURCEDIR
    $wget --continue --progress=dot --tries 3 "$url"
    cd - > /dev/null
  }
}

#@ Command to install interpreter.
luactl_command_install() {
  : ${1:?interpreter/compiler-version}
  luactl_library $1
  local pkg=$LUACTL_SOURCEDIR/$(luactl_archive $1 $2)
  local tar=$(command -v tar)

  test -f $pkg || luactl_command_download $1 $2

  luactl_init $1 $2

  $tar -xf $pkg --overwrite --directory=$LUACTL_SOURCEDIR

  test -d $LUA_SOURCE && cd $LUA_SOURCE && {
    luactl_patch $LUA_SOURCE $LUA_HOME
    luactl_install
    luactl_postinstall
  }
}

#@ Command to set version.
luactl_command_use() {
  : ${1:?interpreter}
  : ${2:?version}
  local cfg=$LUACTL_SYSCONFDIR/$1-$2.rc
  rm -f $LUACTL_LUAENVRC
  test -r $cfg && ln -s $cfg $LUACTL_LUAENVRC
}

#@ Command to list installed interpreters and respective versions.
luactl_command_list() {
  local name=
  luactl_command_help | head -3
  echo "Interpreters installed"
  echo
  for lua in $LUACTL_SYSCONFDIR/*.rc; do
    name=${lua##*/}
    echo "* ${name%.*}"
  done
}
luactl_command_ls() {
  luactl_command_list $@
}

#@ Main function.
luactl() {
  trap '{ luactl_command_help; exit $?; }' HUP INT
  command=$(command -v luactl_command_$1 || echo luactl_command_help)
  test $# -gt 0 && shift 1
  $command "${@}" || {
    exit $?
  }
}

luactl_check && {
  . "$LUACTL_ENVRC"
} || {
  luactl_config
}

luactl $@
