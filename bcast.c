/* python-mpi with package broad-casting */
/* Author: Yu Feng */
/* Adapted from the origina python-mpi.c by Lisandro Dalcin   */
/* Contact: rainwoodman@gmail.com */

/* -------------------------------------------------------------------------- */

#define MPICH_IGNORE_CXX_SEEK 1
#define OMPI_IGNORE_CXX_SEEK 1
#include <mpi.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h> /**/
int VERBOSE = 1;
static int getnid() {
    char hostname[1024];
    int i;
    gethostname(hostname, 1024);

    MPI_Barrier(MPI_COMM_WORLD);

    int l = strlen(hostname) + 4;
    int ml = 0;
    int NTask;
    int ThisTask;
    char * buffer;
    int * nid;
    MPI_Comm_size(MPI_COMM_WORLD, &NTask);
    MPI_Comm_rank(MPI_COMM_WORLD, &ThisTask);
    MPI_Allreduce(&l, &ml, 1, MPI_INT, MPI_MAX, MPI_COMM_WORLD);
    
    buffer = malloc(ml * NTask);
    nid = malloc(sizeof(int) * NTask);
    MPI_Allgather(hostname, ml, MPI_BYTE, buffer, ml, MPI_BYTE, MPI_COMM_WORLD);

    qsort(buffer, NTask, ml, strcmp);
    
    nid[0] = 0;
    for(i = 1; i < NTask; i ++) {
        if(strcmp(buffer + i * ml, buffer + (i - 1) *ml)) {
            nid[i] = nid[i - 1] + 1;
        } else {
            nid[i] = nid[i - 1];
        }
    }
    if(ThisTask == 0) {
        for(i = 0; i < NTask; i ++) {
            //printf("%d :%s:%d\n", i, buffer + i * ml, nid[i]);
        }
    }
    for(i = 0; i < NTask; i ++) {
        if(!strcmp(hostname, buffer + i * ml)) {
            break;
        }
    }
    int rt = nid[i];
    free(buffer);
    free(nid);
    MPI_Barrier(MPI_COMM_WORLD);
    return rt;
}
static int bcast_packages(char ** PACKAGES, int NPACKAGES, char * chroot) {
    int i;
    int nid = getnid();

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

    /* now bcast packages to PYTHON_MPI_CHROOT */

    if(NodeRank == 0) {
        if(ThisTask == 0) {
            if(VERBOSE) {
                printf("%d Packages\n", NPACKAGES);
                printf("tmpdir:%s\n", chroot);
            }
        }

        if(VERBOSE)
            printf("node nid:%d\n", nid);

        for(i = 0; PACKAGES[i] != NULL; i ++) {
            long fsize;
            char *fcontent;
            char * dest = alloca(strlen(chroot) + 100);
            char * src = PACKAGES[i];
            mkdir(chroot, 0777);
            sprintf(dest, "%s/_thispackage.tar.gz",  chroot, ThisTask);

            if(ThisTask == 0) {
                FILE * fp = fopen(src, "r");
                if(fp == NULL) {
                    fprintf(stderr, "package file %s not found\n", src);
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
                if(VERBOSE)
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
            
            char * untar = alloca(strlen(dest) + strlen(chroot) + 100);
            sprintf(untar, "tar --overwrite -xzf \"%s\" -C \"%s\"", dest, chroot);
            system(untar);
            unlink(dest);

            MPI_Barrier(NODE_LEADERS);
        }
        char * chmod = alloca(strlen(chroot) + 100);
        sprintf(chmod, "chmod -fR 777 \"%s\"", chroot);
        system(chmod);
    }
    MPI_Barrier(MPI_COMM_WORLD);
    if(ThisTask == 0) {
        if(VERBOSE)
            printf("Packages delivered. \n");
    }
}
int
main(int argc, char **argv)
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

  bcast_packages(argv + 2, argc - 2, argv[1]);

  /* completely ignore PYTHONPATH for now */

  MPI_Barrier(MPI_COMM_WORLD);

    MPI_Finalize();
  return 0;
}

