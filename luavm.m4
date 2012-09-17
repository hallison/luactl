#!/bin/sh
changecom()dnl
#? Lua Environment Manager
#? _NAME _VERSION (_RELEASE)
#?
#? Usage:
#?   _PROGRAM <COMMAND> <VM> <VERSION>
#?   _PROGRAM <COMMAND> [OPTION]
#?
#? Commands:
#?   help                     Show this message.
#?   versions                 List supported Lua versions.
#?   download <VM> <VERSION>  Download the Lua source code.
#?   install  <VM> <VERSION>  Install Lua version.
#?   use      <VM> <VERSION>  Set the interpreter and version.
#?   list                     List all interpreters installed.
#?
#? Options:
#?   -h,--help   Show this message.
#?. 

# LuaVM directories
export LUAVM_ROOTDIR=_PREFIX
export LUAVM_LIBDIR=_LIBDIR
export LUAVM_SYSCONFDIR=_SYSCONFDIR
export LUAVM_LUADIR=_LUADIR
export LUAVM_SOURCEDIR=_SOURCEDIR

# LuaVM files
export LUAVM_ENVRC=$HOME/.luavmrc
export LUAVM_LUAENVRC=$LUAVM_SYSCONFDIR/luaenvrc

test -r $LUAVM_ENVRC && . $LUAVM_ENVRC

luavm_pushpath() {
  : ${1:?path}
  echo "$1:$PATH" | awk -v RS=':' -v ORS=':' '!path[$1]++'
}

luavm_check() {
  test -f "$LUAVM_ENVRC"
}

luavm_config() {
  test -d $LUAVM_ROOTDIR || {
    echo "Creating $LUAVM_ROOTDIR ..."
    mkdir -p $LUAVM_ROOTDIR
  }
  test -d $LUAVM_LUADIR || {
    echo "Creating $LUAVM_LUADIR ..."
    mkdir -p $LUAVM_LUADIR
  }
  test -d $LUAVM_SOURCEDIR || {
    echo "Creating $LUAVM_SOURCEDIR ..."
    mkdir -p $LUAVM_SOURCEDIR
  }
  test -f $LUAVM_ENVRC || {
    echo "Creating configurarion file $LUAVM_ENVRC ..."
    echo "LUAVM_ROOTDIR=\"$LUAVM_ROOTDIR\""     >  $LUAVM_ENVRC
    echo "LUAVM_ENVRC=\"$LUAVM_ENVRC\""         >> $LUAVM_ENVRC
    echo "LUAVM_LUAENVRC=\"$LUAVM_LUAENVRC\""   >> $LUAVM_ENVRC
    echo "LUAVM_LUADIR=\"$LUAVM_LUADIR\""       >> $LUAVM_ENVRC
    echo "LUAVM_SOURCEDIR=\"$LUAVM_SOURCEDIR\"" >> $LUAVM_ENVRC
    echo "test -r \$LUAVM_LUAENVRC && . \$LUAVM_LUAENVRC" >> $LUAVM_ENVRC
  }
}

luavm_init() {
  : ${1:?interpreter/compiler}
  : ${2:?version}
  local pkg=$(luavm_archive $1 $2)
  local lua=${pkg%%.tar.gz}
  local env=$LUAVM_SYSCONFDIR/$1-$2.rc
  test $pkg && {
    export LUA_VERSION=$2
    export LUA_HOME=$LUAVM_LUADIR/$lua
    export LUA_SOURCE=$LUAVM_SOURCEDIR/$lua
    export LUA_PATH=";;$LUA_HOME/share/lua/${LUA_VERSION%.*}/?.lua;$LUA_HOME/share/lua/${LUA_VERSION%.*}/?/init.lua"
    export LUA_CPATH=";;$LUA_HOME/lib/lua/${LUA_VERSION%.*}/?.so"
    export LUA_INIT="require \\\"luarocks.loader\\\""
    export PATH="$(luavm_pushpath $LUA_HOME/bin)"
    echo "Creating configurarion for $lua ..."
      echo "LUA_VERSION=\"$LUA_VERSION\"" >  $env
      echo "LUA_HOME=\"$LUA_HOME\""       >> $env
      echo "LUA_SOURCE=\"$LUA_SOURCE\""   >> $env
      echo "LUA_PATH=\"$LUA_PATH\""       >> $env
      echo "LUA_CPATH=\"$LUA_CPATH\""     >> $env
      echo "LUA_INIT=\"$LUA_INIT\""       >> $env
      echo "PATH=\"$PATH\""               >> $env
  }
}

luavm_archive() {
  : ${1:?interpreter/compiler}
  : ${2:?version}
  local md5=$LUAVM_SYSCONFDIR/$1.md5
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

luavm_library() {
  : ${1:?interpreter/compiler}
  local lib=$LUAVM_LIBDIR/$1.sh
  test -r $lib && . $lib
}

luavm_command_help() {
  grep '^#[?]' "${0}" | cut -c4-
}

luavm_command_versions() {
  local lua=
  local pkg=
  local md5=
  echo "Lua Environment Manager"
  echo "_NAME _VERSION (_RELEASE)"
  echo
  echo "Interpreters"
  echo
  for lua in $LUAVM_LIBDIR/*.sh; do
    . $lua
    lua=${lua##*/}
    lua=${lua%%.*}
    md5=$LUAVM_SYSCONFDIR/$lua.md5
    printf "* %-8s %s\n" "$lua" "$desc"
    cut -c35- $md5 | while read pkg; do
      pkg=${pkg#*-}
      echo "  - ${pkg%.tar.gz}"
    done
  done
}

luavm_command_download() {
  : ${1:?interpreter/compiler}
  : ${2:?version}
  luavm_library $1
  local wget=$(command -v wget)
  local url=$url/$(luavm_archive $1 $2)

  test $? -eq 0 && test -x $wget && {
    cd $LUAVM_SOURCEDIR
    $wget --continue --progress=dot --tries 3 "$url"
    cd - > /dev/null
  }
}

luavm_command_install() {
  : ${1:?interpreter/compiler}
  : ${2:?version}
  luavm_library $1
  local pkg=$LUAVM_SOURCEDIR/$(luavm_archive $1 $2)
  local tar=$(command -v tar)

  test -f $pkg || luavm_command_download $1 $2

  luavm_init $1 $2

  $tar -xf $pkg --overwrite --directory=$LUAVM_SOURCEDIR

  test -d $LUA_SOURCE && cd $LUA_SOURCE && {
    luavm_patch $LUA_SOURCE $LUA_HOME
    luavm_install
    luavm_postinstall
  }
}

luavm_command_use() {
  : ${1:?interpreter}
  : ${2:?version}
  local cfg=$LUAVM_SYSCONFDIR/$1-$2.rc
  rm -f $LUAVM_LUAENVRC
  test -r $cfg && ln -s $cfg $LUAVM_LUAENVRC
}

luavm_command_list() {
  local name=
  echo "Lua Environment Manager"
  echo "_NAME _VERSION (_RELEASE)"
  echo
  echo "Interpreters installed"
  echo
  for lua in $LUAVM_SYSCONFDIR/*.rc; do
    name=${lua##*/}
    echo "* ${name%.*}"
  done
}

luavm() {
  trap '{ luavm_command_help; exit $?; }' 1 2
  command=$(command -v luavm_command_$1 || echo luavm_command_help)
  test $# -gt 0 && shift 1
  $command "${@}"
  exit $?
}

set -o allexport
set -o errexit
# set -o xtrace

luavm_check && {
  . "$LUAVM_ENVRC"
} || {
  luavm_config
}

eval "luavm $@"
set -o interactive
exec . $LUAVM_LUAENVRC
