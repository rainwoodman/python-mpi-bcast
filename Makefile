CC=mpicc
CCDYNAMIC=$(CC) -dynamic
LDSHARED=$(CC) -shared
PYTHONCONFIG=python-config

# on BlueWaters (cray)
# make CC='cc -static'

# on COMA (CMU)
# make CC=mpiicc LDSHARED="mpiicc -shared"

# on Fedora 19 with openmpi
# make CC=mpicc LDSHARED="mpicc -shared"

# on Edison (gcc)
# make CC='cc -static'

.PHONY: build clean

all: bcast

python-mpi: python-mpi.c 
	$(CCDYNAMIC) -g -O0 -o python-mpi python-mpi.c `$(PYTHONCONFIG) --include --libs`

bcast : bcast.c tar.c _inst/lib/libarchive.a
	$(CC) -I_inst/include -L_inst/lib -g -O0 -o bcast bcast.c tar.c -larchive -lz -lbz2

libarchive-3.1.2.tar.gz:
	wget http://www.libarchive.org/downloads/libarchive-3.1.2.tar.gz

libarchive-3.1.2/configure: libarchive-3.1.2.tar.gz
	tar -xzvf libarchive-3.1.2.tar.gz && touch $@

_inst/lib/libarchive.a: libarchive-3.1.2/configure
	(cd libarchive-3.1.2; ./configure --prefix=/ --disable-shared --enable-static; make install DESTDIR=$(PWD)/_inst)

clean:
	rm python-mpi bcast tar
