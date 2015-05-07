python-mpi-bcast
================

HPC friendly python interpreter.

This version of python-mpi broadcasts the prepackaged python packages to a 
designated local location on computing nodes before starting python.

How to start python Fast on HPC computers
-----------------------------------------

Several things has to be done; using python-mpi is one step them.

The idea is simple: avoid all IO from slow filesystems, and avoid as much as 
possible meta-data requests on shared filesystems.

All of these steps are required to get a consistent, fast python start-up time.


1. Redirect PYTHONUSERBASE to a fast file system; e.g. 
   the scratch or project file systems. 

For example add this line to your profile script on Edison:

.. code:: bash

    export PYTHONUSERBASE=$SCRATCH/python-local

This does mean all packages installed with '--user' need to be reinstalled.
Also scratch is usually purged every now and then. Use a unpurged project directory
if possible.

2. Also check if LD_LIBRARY_PATH and PATH contains references to the slow
   HOME filesystem; redirect them as well. This will speed up the start-up of all
   dynamic executables.

3. Tar the system packages in to a .tar.gz file. 
   Quite a lot of meta requests are made just for loading
   these system-wide packages. We can eliminate these requests with :code:`python-mpi -bcast`

To do so, we pack the packages into a giant tar ball. For example on Edison
(the exclude is to skip obviously useless large files)

.. code:: bash
    
    cd /scratch2/usg-python/

    tar --exclude=*.png --exclude=*.jpg --exclude=*.html 
        --exclude=*.pyo --exclude=*.pyc  \
        -czvf $SCRATCH/usg-python-2.7.9.tar.gz \
        ipython        mysqlpython    \
        numpy          pysqlite       \
        2.7.9          cython         \
        matplotlib     netcdf4-python \
        pil            pytables       \
        scipy h5py                    \
        mpi4py         numexpr    \
        pympi          pyyaml       

4. Speed up in source packages by making sure not running the scripts from HOME.

5. Set up the run. Here is an example on Edison 

.. code:: bash

    # packages will be unzipped to this location by python-mpi
    export PYTHON_MPI_HOME=/dev/shm 

    # python-mpi -bcast will create this directory from the prepackaged file
    export PYTHONHOME=/dev/shm/2.7.9

    # replace /scratch2/use-python/ to the new location.
    export PYTHONPATH=`echo $PYTHONPATH|sed -e 's;/scratch2/usg-python/;/dev/shm/;g'`

    # use the user packages on scratch
    export PYTHONUSERBASE=$SCRATCH/python-local

    # start the scripts from a fast file-system
    cd $SCRATCH/my_codedir

    aprun -n 256 \
        ./python-mpi -bcast $SCRATCH/usg-python-2.7.9.tar.gz \
            your regular script
