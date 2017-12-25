include Options.mk

VERSION = 0.1.0
SCRIPTS = activate.sh tar-anaconda.sh tar-dir.sh tar-pip.sh
BCASTSRC = bcast.c bcast-tar.c
DOC = README.rst LICENSE.rst Options.mk.example
.PHONY: build clean sdist install

all: bcast

Options.mk:
	@echo "Need Options.mk; produce the file by copying and modifying Options.mk.example."
	@exit 1

bcast : bcast.c bcast-tar.c depends/lib/libarchive.a
	$(MPICC) -Idepends/include -Ldepends/lib -g -O0 -o bcast \
         bcast.c bcast-tar.c \
         -larchive -lz -lbz2

libarchive-3.1.2.tar.gz:
	curl -o $@ http://www.libarchive.org/downloads/libarchive-3.1.2.tar.gz

libarchive-3.1.2/configure: libarchive-3.1.2.tar.gz
	tar -xzvf libarchive-3.1.2.tar.gz && touch $@

depends/lib/libarchive.a: libarchive-3.1.2/configure
	(cd libarchive-3.1.2; \
        ./configure --prefix=/ "CC=$(CC)" \
        --without-iconv \
        --without-xml2 \
        --without-nettle \
        --without-openssl \
        --without-lzma \
        --without-expat \
        --disable-shared --enable-static \
        --disable-bsdtar --disable-bsdcpio; \
    make install DESTDIR=$(PWD)/depends)


install: bcast
	mkdir -p $(PREFIX)/libexec/python-mpi-bcast
	cp bcast $(SCRIPTS) $(PREFIX)/libexec/python-mpi-bcast/

sdist:
	mkdir -p python-mpi-bcast-$(VERSION)
	cp $(SCRIPTS) $(BCASTSRC) $(DOC) Makefile python-mpi-bcast-$(VERSION)
	tar -czvf python-mpi-bcast-$(VERSION).tar.gz python-mpi-bcast-$(VERSION)
	rm -rf python-mpi-bcast-$(VERSION)

clean:
	rm -f bcast


