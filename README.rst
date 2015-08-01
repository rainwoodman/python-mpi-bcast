python-mpi-bcast
================

HPC friendly python interpreter.

Why is Python slow on a super computer?
---------------------------------------

One problem with large scale parallel application written in Python is the slow startup time. The Python
Interpreter may spend half an hour before even start processing any useful user logic.

Python does a lot of file operations upon startup.
This is not an issue for small scale applications -- but on
applications at a massive scale (10K+ MPI ranks), these file
operations become a burden to the shared file system, just like the
shared library burden, described in [Hopper-UG]

For example, on a typical python installation with numpy the number of
file operations to 

.. code::

   $ strace -ff -e file python -c '' 2>&1 |wc -l
   917

   $ strace -ff -e file python -c 'import numpy.fft' 2>&1 |wc -l
   4557

   $ strace -ff -e file python -c 'import numpy.fft; import scipy.interpolate' 2>&1|wc -l
   8089

Now multiply this number by the number of ranks, 1024, for example.

Keep in mind that in a massively parallel application, the payload may
in fact only access a few very large files. The overhead here is a
headache.

What do we do about this?
-------------------------

People have thought that python just can never work well on HPC systems.
This is not true. 
We can start 1024 Python ranks on edison.nersc.gov in 40 seconds, consistently, with
the help of this version of :code:`python-mpi-bcast`.

The idea is simple: 

- Avoid meta-data requests from slow filesystems (e.g. home directories);
- Avoid as much as possible meta-data requests on (even fast) shared filesystems;

If these two are done, spinning up thousands of python ranks is no slower than
spinning up the same number of C ranks; and no modifications on the user programs
needs to be done.

The biggest part is from :code:`python-mpi` provided here, which deploy selected packages 
to the computing node, and avoid most of the meta-data requrests.

Here is an example of how to use the broadcast feature of python-mpi

.. code:: bash

    export PYTHON_MPI_CHROOT=/dev/shm
    export PYTHON_MPI_PKGROOT=/project/projectdirs/m779/python-mpi/usg
    export PYTHON_MPI_PACKAGES=matplotlib-1.4.3.tar.gz:mpi4py-1.3.1.tar.gz:numpy-1.9.2.tar.gz:python-2.7.9.tar.gz:scipy-0.15.1.tar.gz

    aprun -n 1024 python-mpi my-jobscript.py
    

Note that python-mpi will reset :code:`PYTHONHOME` and :code:`PYTHONBASE` to subdirectories of :code:`PYTHON_MPI_CHROOT`.

Here is the TODO list that enables the full benefits of the
python-mpi implementation provided here. These steps can be implemented 
either by the computing faciliaties, or by a user.

1. Redirect :code:`PYTHONUSERBASE` to a fast file system; e.g. 
   the scratch or project file systems. This is very important. The default location
   is usually in your home directory. 

   .. notes:: 
   
      For example add this line to the profile script on Edison:

      .. code:: bash

          export PYTHONUSERBASE=$SCRATCH/python-local

   This does mean all packages installed with '--user' need to be reinstalled.
   
   .. attention::
   
      **If PYTHONUSERBASE is not reset to a fast location, the start time will still
      be very slow.**

2. Prepackage the packages to .tar.gz files

   Quite a lot of meta requests are made just for loading
   these system-wide packages, which barely change at all from time to time.
   
   The tar.gz files must be packed at :code:`PYTHON_MPI_PKGROOT`. Here is an example:

   .. code:: bash
        
        cd $PYTHON_MPI_PKGROOT 
        easy_install --prefix=$TMPDIR/mypackage
        tar --exclude=*.png --exclude=*.jpg --exclude=*.html 
            --exclude=*.pyo --exclude=*.pyc  \
            -C $TMPDIR/mypackage
            -czvf mypackage-version.tar.gz

3. Copy the relevant python script to a shared location, and run from there.

   Especially be aware of starting a python script in HOME directory. It can be very
   slow. (recall sometimes ls on home directory takes for ever?)
   
It also helps to check if LD_LIBRARY_PATH and PATH contains references to the slow
HOME filesystem; redirect them as well. This will speed up the start-up of all
dynamic executables.


Here is a full job script example on Edison:

.. code:: bash

    # use the user packages on scratch
    export PYTHONUSERBASE=$SCRATCH/python-local
    export PYTHON_MPI_CHROOT=/dev/shm
    export PYTHON_MPI_PKGROOT=/project/projectdirs/m779/python-mpi/usg
    export PYTHON_MPI_PACKAGES=matplotlib-1.4.3.tar.gz:mpi4py-1.3.1.tar.gz:numpy-1.9.2.tar.gz:pyton-2.7.9.tar.gz:scipy-0.15.1.tar.gz
    # start the scripts from a fast file-system
    cd $SCRATCH/my_codedir

     aprun -n 256 ./python-mpi script.py



