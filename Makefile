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
# remember use python-mpi.py -I openmpi
# to workaround symbol table issues.

.PHONY: build clean

build: 
	$(CCDYNAMIC) -g -O0 -o python-mpi python-mpi.c `$(PYTHONCONFIG) --include --libs`
