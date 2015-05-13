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

3. Prepackage the packages to .tar.gz files
   Quite a lot of meta requests are made just for loading
   these system-wide packages. We can eliminate these requests with :code:`python-mpi`

   Here is an example of how to use the broadcast feature of python-mpi

   .. code:: bash

       export PYTHON_MPI_CHROOT=/dev/shm
       export PYTHON_MPI_PKGROOT=/project/projectdirs/m779/python-mpi/usg
       export PYTHON_MPI_PACKAGES=matplotlib-1.4.3.tar.gz:mpi4py-1.3.1.tar.gz:numpy-1.9.2.tar.gz:python-2.7.9.tar.gz:scipy-0.15.1.tar.gz

   python-mpi will reset :code:`PYTHONHOME` and :code:`PYTHONBASE` to subdirectories of :code:`PYTHON_MPI_CHROOT`.

   The tar.gz files must be packed at :code:`PYTHON_MPI_PKGROOT`. Here is an example:

   .. code:: bash
        
        cd $PYTHON_MPI_PKGROOT 
        easy_install --prefix=$TMPDIR/mypackage
        tar --exclude=*.png --exclude=*.jpg --exclude=*.html 
            --exclude=*.pyo --exclude=*.pyc  \
            -C $TMPDIR/mypackage
            -czvf mypackage-version.tar.gz

    
4. Speed up in source packages by making sure not running the scripts from HOME.

5. Set up the run. Here is an example on Edison 

   .. code:: bash

        # python-mpi -bcast will create this directory from the prepackaged file
        export PYTHONHOME=/dev/shm/2.7.9

        # use the user packages on scratch
        export PYTHONUSERBASE=$SCRATCH/python-local

        export PYTHON_MPI_CHROOT=/dev/shm
        export PYTHON_MPI_PKGROOT=/project/projectdirs/m779/python-mpi/usg
        export PYTHON_MPI_PACKAGES=matplotlib-1.4.3.tar.gz:mpi4py-1.3.1.tar.gz:numpy-1.9.2.tar.gz:python-2.7.9.tar.gz:scipy-0.15.1.tar.gz

        # start the scripts from a fast file-system
        cd $SCRATCH/my_codedir

        aprun -n 256 \
            ./python-mpi
                your regular script
