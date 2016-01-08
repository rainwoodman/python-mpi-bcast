python-mpi-bcast
================

An HPC friendly python environment that deploys packages to computing nodes via MPI.

.. image:: https://api.travis-ci.org/rainwoodman/python-mpi-bcast.svg
    :alt: Build Status
    :target: https://travis-ci.org/rainwoodman/python-mpi-bcast/

Benchmark on Edison
-------------------

We can start 12,288 ranks, each import scipy, anding doing all of these in 50 seconds.
See the following figure. 

.. image:: https://raw.githubusercontent.com/rainwoodman/python-mpi-bcast/master/cray-xc30/startup-time.png

Why is Python slow on a supercomputer?
---------------------------------------

One problem with large scale parallel application written in Python is the slow startup time. 
The Python interpreter may spend half an hour before even start processing any useful user logic.

Python does a lot of file operations upon startup.
This is not an issue for small scale applications -- but on
applications at a massive scale (10K+ MPI ranks), these file
operations become a burden to the shared file system, just like the
shared library burden, described in [Hopper-UG]

For example, on a typical python installation with numpy the number of
file operations to  ::

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
We can start 1024 Python ranks on edison.nersc.gov in 40 seconds, consistently as long as we
follow the principles in this page. We will need the help of a tool 'bcast' that is provided here.

The idea is simple: 

- Avoid meta-data requests from slow filesystems (e.g. home directories);
- Avoid as much as possible meta-data requests on (even fast) shared filesystems;

If these two are done, spinning up thousands of python ranks is no slower than
spinning up the same number of C ranks; and no modifications on the user programs
needs to be done.

The biggest part is from :code:`bcast` provided here, which deploys selected packages 
to the computing node, and properly set up the python environment to avoid
most of the meta-data requests on the shared filesystem.


Here is the TODO list that enables the full benefits of the
python-mpi implementation provided here. These steps can be implemented 
either by the computing faciliaties, or by a user.

1. Install Conda/Anaconda, and create a tar ball of the entire installation with
   the supplied 'tar-anaconda.sh'

.. code:: bash

    wget http://repo.continuum.io/miniconda/Miniconda-latest-Linux-x86_64.sh -O miniconda.sh
    chmod +x miniconda.sh
    ./miniconda.sh -b -p $HOME/miniconda
    export PATH=$HOME/miniconda/bin:$PATH
    conda update --yes conda
    conda create --yes -n test python=2.7
    source activate test
    conda install --yes numpy=1.9 nose mpi4py # install other packages as well
    bash tar-anaconda.sh anaconda.tar.gz $HOME/miniconda/envs/test

.. note::
    
    On some systems, an anaconda based installation is already supplied by the vendor.
    (e.g. Edison and Cori). In that case, find the location of that installation
    via the module file, and directly use tar-anaconda.sh to generate a tar ball.

.. attention::

    copy the tar ball file to a fast file system, e.g. scratch or project directory.

    We will assume the location is $SCRATCH/2.7-anaconda.tar.gz

2. Alternatively, prepackage individual python packages to .tar.gz files. On some systems
   where the conda prebuilt packages are not an option, this will be the only feasible way. 
   We provide a script tar-pip.sh for this:

.. code:: bash
    
    # build a fitsio bundle

    bash tar-pip.sh fitsio-0.9.8rc2.tar.gz https://github.com/esheldon/fitsio/archive/v0.9.8rc2.zip

    # build a bundle for locally checked out code with a setup.py

    bash tar-pip.sh my-package.tar.gz .

    # you get the idea

.. note::

    Still, the installation of some packages may not be this trivial.
    Luckily, usually the vendor must have compiled most python packages, and it is worthwhile
    to inspect the module files and directly run the tar command there, skipping the installation
    part.

3. Reset :code:`PYTHONHOME` :code:`PYTHONBASE`, :code:`PYTHONUSERBASE`, and :code:`PATH`, 
:code:`LD_LIBRARY_PATH` to /dev/shm/local.

This can be done by sourcing 'activate.sh'. activate.sh takes 2 arguments, the prefix of the new python
environment, and the command prefix to launch 'bcast'. activate.sh also provide a 'bcast' function
to the shell script, which will simply run bcast with the provided prefix. A good choice of the prefix
is /dev/shm/local. If the computing nodes contain private scratch hardrives, that would be a good location as well.

.. warning::

    All packages install in :code:`~/.local` is unavailable during the session.

4. Copy the relevant python scripts to a fast filesystem.

Especially be aware of starting a python script in HOME directory. It can be very
slow. (recall sometimes ls on home directory takes for ever?)
   

Here is a full job script example on Edison following all of the guidelines.
Notice that on Edison, I have already created the tar ball of the
2.7 and 3.4 version of anaconda installation at /project/projectdirs/m779/python-mpi

.. code:: bash

    #PBS -j eo
    #PBS -l mppwidth=1024
    #PBS -q debug

    set -x
    export OMP_NUM_THREADS=1

    source /project/projectdirs/m779/python-mpi/activate.sh /dev/shm/local "aprun -n 1024 -d 1"

    cd $PBS_O_WORKDIR

    # send the anaconda packages
    bcast -v /project/projectdirs/m779/python-mpi/2.7-anaconda.tar.gz 

    # testpkg contains the tar-ed version of the script;
    # if the script is sufficiently complicated, it helps to treat it like 
    # another package.

    bcast -v testpkg.tar.gz

    time aprun -n 1024 -d 1 python-mpi /dev/shm/local/testpkg/main.py

Yu Feng - BCCP / BIDS.

