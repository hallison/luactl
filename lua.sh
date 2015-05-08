url="http://www.lua.org/ftp"
desc="Default/official Lua interpreter."

luactl_patch() {
  cp $LUA_SOURCE/src/luaconf.h $LUA_SOURCE/src/luaconf.h.orig
  sed "s|^\(#define LUA_ROOT\)\(.*\)$|\1 \"$LUA_HOME/\"|" $LUA_SOURCE/src/luaconf.h.orig > $LUA_SOURCE/src/luaconf.h

  cp $LUA_SOURCE/Makefile $LUA_SOURCE/Makefile.orig
  sed "s|^\(INSTALL_TOP= \)\(.*\)$|\1$LUA_HOME|" $LUA_SOURCE/Makefile.orig > $LUA_SOURCE/Makefile
}

luactl_install() {
  cd $LUA_SOURCE && {
    make clean linux
    make install
  }
}

luactl_postinstall() {
  return 0
}
