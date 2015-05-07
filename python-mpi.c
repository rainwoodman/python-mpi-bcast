
/* python-mpi with package broad-casting */
/* Author: Yu Feng */
/* Adapted from the origina python-mpi.c by Lisandro Dalcin   */
/* Contact: rainwoodman@gmail.com */

/* -------------------------------------------------------------------------- */

#include <Python.h>

#define MPICH_IGNORE_CXX_SEEK 1
#define OMPI_IGNORE_CXX_SEEK 1
#include <mpi.h>

#include <unistd.h> /**/

#ifdef __FreeBSD__
#include <floatingpoint.h>
#endif

static int PyMPI_Main(int, char **);

#if PY_MAJOR_VERSION >= 3
static int Py3_Main(int, char **);
#endif

/* -------------------------------------------------------------------------- */

int
main(int argc, char **argv)
{
#ifdef __FreeBSD__
  fp_except_t m;
  m = fpgetmask();
  fpsetmask(m & ~FP_X_OFL);
#endif
  return PyMPI_Main(argc, argv);
}
static int bcast_packages(int * argc, char ***argv) {
    char ** PACKAGES = NULL;
    int NPACKAGES = 0;
    int i;

    PACKAGES = (char**) malloc(sizeof(char*) * *argc);
    NPACKAGES = 0;

    char ** newargv = (char**) malloc(sizeof(char*) * *argc);

    char ** oldargv = *argv;
    int oldargc = *argc; 
    int newargc = 0;

    /* parse argv to find all packages that shall be bcasted */
    for(i = 0; i < oldargc; i ++) {
        if (!strncmp(oldargv[i], "-bcast", 6)) {
            PACKAGES[NPACKAGES] = strdup(oldargv[i + 1]);
            NPACKAGES ++;
            i ++;
        } else {
            newargv[newargc] = oldargv[i];
            newargc ++;
        }
    }

    char hostname[1024];
    gethostname(hostname, 1024);

    /* hack on Crays; this would translate the host name to
     * a pure number format. 
     * we really should find a different way to find all ranks
     * on the same node.
     */
    for(i = 0; i < strlen(hostname); i ++) {
        if(hostname[i] < '0' || hostname[i] > '9') {
            hostname[i] = '0';
        }
    }
    int nid = atoi(hostname);

    int ThisTask = 0;
    int NodeRank = -1;

    MPI_Comm_rank(MPI_COMM_WORLD, &ThisTask);

    MPI_Comm NODE_GROUPS;
    MPI_Comm NODE_LEADERS;

    /* First split into ranks on the same node */
    MPI_Comm_split(MPI_COMM_WORLD, nid, ThisTask, &NODE_GROUPS);

    MPI_Comm_rank(NODE_GROUPS, &NodeRank);

    /* Next split by Node Rank */
    MPI_Comm_split(MPI_COMM_WORLD, NodeRank, ThisTask, &NODE_LEADERS);

    /* now bcast packages to PYTHON_MPI_HOME */

    if(NodeRank == 0) {
        char * PYTHON_MPI_HOME = getenv("PYTHON_MPI_HOME");

        if(ThisTask == 0) {
            if (PYTHON_MPI_HOME == NULL) {
                fprintf(stderr, "PYTHON_MPI_HOME must be set to a writable location, for example /dev/shm/\n");
                MPI_Abort(MPI_COMM_WORLD, 1);
            }
            printf("%d Packages\n", NPACKAGES);
        }

        printf("node nid:%d\n", nid);

        for(i = 0; i < NPACKAGES; i ++) {
            long fsize;
            char *fcontent;
            char * dest = alloca(strlen(PYTHON_MPI_HOME) + 100);
            sprintf(dest, "%s/_thispackage.tar.gz",  PYTHON_MPI_HOME, ThisTask);

            if(ThisTask == 0) {
                FILE * fp = fopen(PACKAGES[i], "r");
                if(fp == NULL) {
                    fprintf(stderr, "package file %s not found\n", PACKAGES[i]);
                    MPI_Abort(MPI_COMM_WORLD, 1);
                }
                fseek(fp, 0, SEEK_END);
                fsize = ftell(fp);
                fseek(fp, 0, SEEK_SET);

                fcontent = malloc(fsize + 1);
                fread(fcontent, 1, fsize, fp);
                fclose(fp);
                MPI_Bcast(&fsize, 1, MPI_LONG, 0, NODE_LEADERS);
                MPI_Bcast(fcontent, fsize, MPI_BYTE, 0, NODE_LEADERS);
                printf("operating %s: %ld bytes\n", PACKAGES[i], fsize);
            } else {
                MPI_Bcast(&fsize, 1, MPI_LONG, 0, NODE_LEADERS);
                fcontent = malloc(fsize + 1);
                MPI_Bcast(fcontent, fsize, MPI_BYTE, 0, NODE_LEADERS);
            }
            
            MPI_Barrier(NODE_LEADERS);
            FILE * fp = fopen(dest, "w");
            fwrite(fcontent, 1, fsize, fp);
            fclose(fp);
            free(fcontent);
            
            char * untar = alloca(strlen(dest) + strlen(PYTHON_MPI_HOME) + 100);
            sprintf(untar, "tar --overwrite -xzf \"%s\" -C \"%s\"", dest, PYTHON_MPI_HOME);
            system(untar);
            unlink(dest);

            MPI_Barrier(NODE_LEADERS);
        }
    }
    MPI_Barrier(MPI_COMM_WORLD);
    if(ThisTask == 0) {
        printf("Python packages delivered\n");
    }
    *argc = newargc;
    *argv = newargv;
}
static int
PyMPI_Main(int argc, char **argv)
{
  int sts=0, flag=1, finalize=0;

  /* MPI initalization */
  (void)MPI_Initialized(&flag);
  if (!flag) {
#if defined(MPI_VERSION) && (MPI_VERSION > 1)
    int required = MPI_THREAD_MULTIPLE;
    int provided = MPI_THREAD_SINGLE;
    (void)MPI_Init_thread(&argc, &argv, required, &provided);
#else
    (void)MPI_Init(&argc, &argv);
#endif
    finalize = 1;
  }

  bcast_packages(&argc, &argv);


  /* Python main */
#if PY_MAJOR_VERSION >= 3
  sts = Py3_Main(argc, argv);
#else
  sts = Py_Main(argc, argv);
#endif
  if (sts != 0) (void)MPI_Abort(MPI_COMM_WORLD, sts);

  /* MPI finalization */
  (void)MPI_Finalized(&flag);

  if (!flag) {
    if (sts != 0) (void)MPI_Abort(MPI_COMM_WORLD, sts);
    if (finalize) (void)MPI_Finalize();
  }

  return sts;
}

/* -------------------------------------------------------------------------- */

#if PY_MAJOR_VERSION >= 3

#include <locale.h>

static wchar_t **mk_wargs(int, char **);
static wchar_t **cp_wargs(int, wchar_t **);
static void rm_wargs(wchar_t **, int);

static int
Py3_Main(int argc, char **argv)
{
  int sts = 0;
  wchar_t **wargv  = mk_wargs(argc, argv);
  wchar_t **wargv2 = cp_wargs(argc, wargv);
  if (wargv && wargv2)
    sts = Py_Main(argc, wargv);
  else
    sts = 1;
  rm_wargs(wargv2, 1);
  rm_wargs(wargv,  0);
  return sts;
}

#if PY_VERSION_HEX < 0x03050000
#define Py_DecodeLocale _Py_char2wchar
#endif

#if PY_VERSION_HEX < 0x03040000
#define PyMem_RawMalloc PyMem_Malloc
#define PyMem_RawFree   PyMem_Free
#endif

static wchar_t **
mk_wargs(int argc, char **argv)
{
  int i; char *saved_locale = NULL;
  wchar_t **args = NULL;

  args = (wchar_t **)PyMem_RawMalloc((size_t)(argc+1)*sizeof(wchar_t *));
  if (!args) goto oom;

  saved_locale = strdup(setlocale(LC_ALL, NULL));
  if (!saved_locale) goto oom;
  setlocale(LC_ALL, "");

  for (i=0; i<argc; i++) {
    args[i] = Py_DecodeLocale(argv[i], NULL);
    if (!args[i]) goto oom;
  }
  args[argc] = NULL;

  setlocale(LC_ALL, saved_locale);
  free(saved_locale);

  return args;

 oom:
  fprintf(stderr, "out of memory\n");
  if (saved_locale) {
    setlocale(LC_ALL, saved_locale);
    free(saved_locale);
  }
  if (args)
    rm_wargs(args, 1);
  return NULL;
}

static wchar_t **
cp_wargs(int argc, wchar_t **args)
{
  int i; wchar_t **args_copy = NULL;
  if (!args) return NULL;
  args_copy = (wchar_t **)PyMem_RawMalloc((size_t)(argc+1)*sizeof(wchar_t *));
  if (!args_copy) goto oom;
  for (i=0; i<(argc+1); i++) { args_copy[i] = args[i]; }
  return args_copy;
 oom:
  fprintf(stderr, "out of memory\n");
  return NULL;
}

static void
rm_wargs(wchar_t **args, int deep)
{
  int i = 0;
  if (args && deep)
    while (args[i])
      PyMem_RawFree(args[i++]);
  if (args)
    PyMem_RawFree(args);
}

#endif /* !(PY_MAJOR_VERSION >= 3) */

/* -------------------------------------------------------------------------- */

/*
   Local variables:
   c-basic-offset: 2
   indent-tabs-mode: nil
   End:
*/
