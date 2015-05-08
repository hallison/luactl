.POSIX:
SHELL = /bin/sh

name          = luactl
version      ?= $(shell git tag | sort | tail -1 | tr -d [v\n])
release      ?= $(shell git log v$(version) --format='%ad' --date=short | head -1 | tr -d [\n])

prefix       ?= /usr/local
bindir       ?= $(prefix)/bin
sysconfdir   ?= $(prefix)/etc/$(name)
libdir       ?= $(prefix)/lib/$(name)
libexecdir   ?= $(prefix)/libexec/$(name)
datarootdir  ?= $(prefix)/share/$(name)
sharerootdir ?= $(datarootdir)
docdir       ?= $(sharerootdir)/doc/$(name)
vmdir        ?= $(libexecdir)/luavm
sourcedir    ?= $(prefix)/src

testdir       = test
directories   = $(prefix) $(bindir) $(libdir) $(libexecdir)
directories  += $(sysconfdir) $(datarootdir) $(docdir) $(vmdir) $(sourcedir)

program       = $(name)
sources       = lua.sh LuaJIT.sh
resources     = lua.md5 LuaJIT.md5
texts         = README.md README.pt-BR.md

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
     -D_VMDIR="$(vmdir)"           \
     -D_SOURCEDIR="$(sourcedir)"     \

all::build

.SUFFIXES: .m4 .sh .err .md .html

.m4:
	$(munge) $(<) > $(@)
	chmod a+x $(@)

.sh.err: 
	time -p sh -x $(<) $(test) 2> $(@)

.md.html:
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

reinstall: uninstall install

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
	install -d $(@)

