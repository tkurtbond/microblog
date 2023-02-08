SHELL=bash
ifndef CSC
CSC=$(shell type -p csc || type -p chicken-csc || echo 'echo "CSC does not exist; "')
endif

BINDIR=$(HOME)/local/bin

INSTALL_PROGRAMS=gmi-blog-atom tztable2scm
OTHER_PROGRAMS=
PROGRAMS=$(INSTALL_PROGRAMS:%=build/%) $(OTHER_PROGRAMS:%=build/%)

all: build $(PROGRAMS)

build:
	mkdir build

build/gmi-blog-atom: CSCFLAGS+=#-static

build/% : %.scm
	$(TIME) $(CSC) $(CSCFLAGS) -o $@ $^

$(BINDIR)/% : build/%
	[ -d $(BINDIR) ] || (mkdir -p $(BINDIR) && echo built $(BINDIR))
	cp $< $@


install: $(foreach e,$(PROGRAMS:%=%),$(BINDIR)/$(notdir $(e)))

clean: 
	-rm build/*.so build/*.link $(PROGRAMS)

realclean: clean
	-rm .what-sys.dat

.what-sys.dat:
	what-sys
