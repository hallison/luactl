.POSIX:
SHELL = /bin/sh

name          = luavm
version      ?= $(shell git tag | sort | tail -1 | tr -d [v\n])
release      ?= $(shell git log v$(version) --format='%ad' --date=short | head -1 | tr -d [\n])

prefix       ?= ${HOME}/.luavm
bindir       ?= $(prefix)/bin
sysconfdir   ?= $(prefix)/etc
libdir       ?= $(prefix)/lib
datarootdir  ?= $(prefix)/share
sharerootdir ?= $(datarootdir)
docdir       ?= $(sharerootdir)/doc
luadir       ?= $(prefix)/luas
sourcedir    ?= $(prefix)/src

testdir       = test
directories   =  \
	$(prefix)      \
	$(bindir)      \
	$(libdir)      \
	$(sysconfdir)  \
	$(datarootdir) \
	$(docdir)      \
	$(luadir)      \
	$(sourcedir)   \

program       = luavm
sources       = lua.sh luajit.sh
resources     = lua.md5 luajit.md5
texts         = README.mkd README.pt-BR.mkd

executables   = $(addprefix $(bindir)/,$(program))
libraries     = $(addprefix $(libdir)/,$(sources))
documents     = $(addprefix $(docdir)/,$(texts))
configs       = $(addprefix $(sysconfdir)/,$(resources))

test         ?= all
errors        = test.err

munge         = \
	m4 -D_NAME="$(name)"               \
     -D_VERSION="$(version)"         \
     -D_RELEASE="$(release)"         \
     -D_PROGRAM="$(program)"         \
     -D_PREFIX="$(prefix)"           \
     -D_BINDIR="$(bindir)"           \
     -D_LIBDIR="$(libdir)"           \
     -D_SYSCONFDIR="$(sysconfdir)"   \
     -D_DATAROOTDIR="$(datarootdir)" \
     -D_DOCDIR="$(docdir)"           \
     -D_LUADIR="$(luadir)"           \
     -D_SOURCEDIR="$(sourcedir)"     \

all::build

.SUFFIXES: .m4 .sh .err .mkd .html

.m4:
	$(munge) $(<) > $(@)
	chmod a+x $(@)

.sh.err: 
	time -p sh -x $(<) $(test) 2> $(@)

.mkd.html:
	markdown $(<) > $(@)

clean:
	rm -rf *.err
	rm -rf *.html
	rm -rf $(testdir)
	rm -rf $(program)

check: $(errors)

doc: README.html README.pt-BR.html

build: $(program)

install: build install-dirs install-bins install-libs install-configs install-docs

uninstall: uninstall-bins uninstall-configs uninstall-libs uninstall-docs

install-dirs: $(directories)

install-bins: $(executables)

uninstall-bins:
	rm -f $(executables)

install-libs: $(libraries)

uninstall-libs:
	rm -f $(libraries)

install-configs: $(configs)

uninstall-configs:
	rm -f $(configs)

install-docs: doc $(documents)

uninstall-docs:
	rm -f $(documents)

$(executables) $(libraries) $(configs) $(documents):
	cp $(@F) $(@)

$(directories):
	mkdir -p $(@)

