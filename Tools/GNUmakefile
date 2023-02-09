SHELL=bash
ifndef CSC
CSC=$(shell type -p csc || type -p chicken-csc || echo 'echo "CSC does not exist; "')
endif

BINDIR=$(HOME)/local/bin

INSTALL_PROGRAMS=gmi-blog-atom tztable2scm
OTHER_PROGRAMS=
PROGRAMS=$(INSTALL_PROGRAMS) $(OTHER_PROGRAMS)

all: $(PROGRAMS)

% : %.scm
	$(TIME) $(CSC) -static $<
%.o : %.scm
	$(TIME) $(CSC) -c -J $^ -unit $(^:.scm=)
$(BINDIR)/% : %
	[ -d $(BINDIR) ] || (mkdir -p $(BINDIR) && echo built $(BINDIR))
	cp $< $@


install: $(foreach e,$(PROGRAMS:%=%),$(BINDIR)/$(notdir $(e)))

clean: 
	-rm *.o *.so *.import.scm $(PROGRAMS) 

realclean: clean
	-rm .what-sys.dat

.what-sys.dat:
	what-sys
