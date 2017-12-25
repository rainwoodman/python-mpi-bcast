include Options.mk

VERSION = 0.1.0
SCRIPTS = activate.sh tar-anaconda.sh tar-dir.sh tar-pip.sh
BCASTSRC = bcast.c bcast-tar.c

.PHONY: build clean sdist install

all: bcast

bcast : bcast.c bcast-tar.c _inst/lib/libarchive.a
	$(MPICC) -I_inst/include -L_inst/lib -g -O0 -o bcast bcast.c bcast-tar.c -larchive -lz

libarchive-3.1.2.tar.gz:
	curl -o $@ http://www.libarchive.org/downloads/libarchive-3.1.2.tar.gz

libarchive-3.1.2/configure: libarchive-3.1.2.tar.gz
	tar -xzvf libarchive-3.1.2.tar.gz && touch $@

_inst/lib/libarchive.a: libarchive-3.1.2/configure
	(cd libarchive-3.1.2; \
        ./configure --prefix=/ --without-xml2 --without-nettle --without-openssl --without-lzma --without-expat --without-bz2lib \
        --disable-shared --enable-static; \
    make install DESTDIR=$(PWD)/_inst)

install: bcast
	mkdir -p $(PREFIX)/libexec/python-mpi-bcast
	cp bcast $(SCRIPTS) $(PREFIX)/libexec/python-mpi-bcast/

sdist:
	mkdir -p python-mpi-bcast-$(VERSION)
	cp $(SCRIPTS) $(BCASTSRC) Makefile Options.mk.example python-mpi-bcast-$(VERSION)
	tar -czvf python-mpi-bcast-$(VERSION).tar.gz python-mpi-bcast-$(VERSION)
	rm -rf python-mpi-bcast-$(VERSION)

clean:
	rm -f bcast


