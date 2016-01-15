CC=mpicc
CCDYNAMIC=$(CC) -dynamic
LDSHARED=$(CC) -shared
PYTHONCONFIG=python-config

# on BlueWaters
# make CC=cc LDSHARED="cc -shared"

# on COMA (CMU)
# make CC=mpiicc LDSHARED="mpiicc -shared"

# on Fedora 19 with openmpi
# make CC=mpicc LDSHARED="mpicc -shared"

# on Edison
# LIBRARY_PATH=$LD_LIBRARY_PATH make CC=cc 

.PHONY: build clean

all: bcast

python-mpi: python-mpi.c 
	$(CCDYNAMIC) -g -O0 -o python-mpi python-mpi.c `$(PYTHONCONFIG) --include --libs`

bcast : bcast.c tar.c
	$(CC) -g -O0 -o bcast bcast.c tar.c -larchive

clean:
	rm python-mpi bcast tar
