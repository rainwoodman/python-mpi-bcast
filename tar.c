/*
 *  * This file is in the public domain.
 *   * Use it as you wish.
 *    */

#include <sys/types.h>

#include <sys/stat.h>

#include <archive.h>
#include <archive_entry.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static void errmsg(const char *);
void extract(const char *filename, int do_extract, int flags);
static void fail(const char *, const char *, int);
static int  copy_data(struct archive *, struct archive *);
static void msg(const char *);
static void warn(const char *, const char *);


void
extract(const char *filename, int do_extract, int flags)
{
    struct archive *a;
    struct archive *ext;
    struct archive_entry *entry;
    int r;

    a = archive_read_new();
    ext = archive_write_disk_new();
    archive_write_disk_set_options(ext, flags);
    /*
 *   * Note: archive_write_disk_set_standard_lookup() is useful
 *       * here, but it requires library routines that can add 500k or
 *           * more to a static executable.
 *               */
    archive_read_support_format_tar(a);
    archive_read_support_filter_gzip(a);
    archive_read_support_filter_bzip2(a);
    /*
 *   * On my system, enabling other archive formats adds 20k-30k
 *       * each.  Enabling gzip decompression adds about 20k.
 *           * Enabling bzip2 is more expensive because the libbz2 library
 *               * isn't very well factored.
 *                   */
    if (filename != NULL && strcmp(filename, "-") == 0)
        filename = NULL;
    if ((r = archive_read_open_filename(a, filename, 10240)))
        fail("archive_read_open_filename()",
            archive_error_string(a), r);
    for (;;) {
        r = archive_read_next_header(a, &entry);
        if (r == ARCHIVE_EOF)
            break;
        if (r != ARCHIVE_OK)
            fail("archive_read_next_header()",
                archive_error_string(a), 1);
        if (do_extract) {
            r = archive_write_header(ext, entry);
            if (r != ARCHIVE_OK)
                warn("archive_write_header()",
                    archive_error_string(ext));
            else {
                copy_data(a, ext);
                r = archive_write_finish_entry(ext);
                if (r != ARCHIVE_OK)
                    fail("archive_write_finish_entry()",
                        archive_error_string(ext), 1);
            }

        }
    }
    archive_read_close(a);
    archive_read_free(a);
    archive_write_close(ext);
    archive_write_free(ext);
}

static int
copy_data(struct archive *ar, struct archive *aw)
{
    int r;
    const void *buff;
    size_t size;
#if ARCHIVE_VERSION >= 3000000
    int64_t offset;
#else
    off_t offset;
#endif

    for (;;) {
        r = archive_read_data_block(ar, &buff, &size, &offset);
        if (r == ARCHIVE_EOF)
            return (ARCHIVE_OK);
        if (r != ARCHIVE_OK)
            return (r);
        r = archive_write_data_block(aw, buff, size, offset);
        if (r != ARCHIVE_OK) {
            warn("archive_write_data_block()",
                archive_error_string(aw));
            return (r);
        }
    }
}

/*
 *  * These reporting functions use low-level I/O; on some systems, this
 *   * is a significant code reduction.  Of course, on many server and
 *    * desktop operating systems, malloc() and even crt rely on printf(),
 *     * which in turn pulls in most of the rest of stdio, so this is not an
 *      * optimization at all there.  (If you're going to pay 100k or more
 *       * for printf() anyway, you may as well use it!)
 *        */
static void
msg(const char *m)
{
    write(1, m, strlen(m));
}

static void
errmsg(const char *m)
{
    write(2, m, strlen(m));
}

static void
warn(const char *f, const char *m)
{
    errmsg(f);
    errmsg(" failed: ");
    errmsg(m);
    errmsg("\n");
}

static void
fail(const char *f, const char *m, int r)
{
    warn(f, m);
    exit(r);
}

static void
usage(void)
{
    const char *m = "Usage: untar [-tvx] [-f file] [file]\n";
    errmsg(m);
    exit(1);
}
