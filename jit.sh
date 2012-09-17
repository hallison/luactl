url="http://luajit.org/download"
desc="LuaJIT interpreter/environment."

luavm_patch() {
  cp $LUA_SOURCE/src/luaconf.h $LUA_SOURCE/src/luaconf.h.orig
  sed "s|^\(#define LUA_ROOT\)\(.*\)$|\1 \"$LUA_HOME\"|" $LUA_SOURCE/src/luaconf.h.orig > $LUA_SOURCE/src/luaconf.h

  cp $LUA_SOURCE/Makefile $LUA_SOURCE/Makefile.orig
  sed "s|^\(INSTALL_TOP= \)\(.*\)$|\1$LUA_HOME|" $LUA_SOURCE/Makefile.orig > $LUA_SOURCE/Makefile
}

luavm_install() {
  cd $LUA_SOURCE && {
    make clean linux
    make install
  }
}

luavm_postinstall() {
  ex -c "4s/\/${LUA_VERSION%.*}\//\/5.1\/jit\//g" -cx $LUAVM_LUAENVRC
  ex -c "5s/\/${LUA_VERSION%.*}\//\/5.1\//g"      -cx $LUAVM_LUAENVRC
}
