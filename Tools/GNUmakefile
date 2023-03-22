SHELL=bash
ifndef CSC
CSC=$(shell type -p csc || type -p chicken-csc || echo 'echo "CSC does not exist; "')
endif

# Stop using static because the executable is 13MiB!
# ifndef NOSTATIC
# STATIC=-static
# endif

BINDIR=$(HOME)/local/bin

INSTALL_PROGRAMS=gmi-html-atom
OTHER_PROGRAMS=
PROGRAMS=$(INSTALL_PROGRAMS) $(OTHER_PROGRAMS)

all: $(PROGRAMS)

% : %.scm
	$(TIME) $(CSC) $(STATIC) $<
%.o : %.scm
	$(TIME) $(CSC) -c -J $^ -unit $(^:.scm=)
$(BINDIR)/% : %
	[ -d $(BINDIR) ] || (mkdir -p $(BINDIR) && echo built $(BINDIR))
	cp $< $@


install: $(foreach e,$(PROGRAMS:%=%),$(BINDIR)/$(notdir $(e)))

clean: 
	-rm *.o *.so *.import.scm *.link $(PROGRAMS) 

realclean: clean
	-rm .what-sys.dat

.what-sys.dat:
	what-sys
