/*
 * jcmain.c
 *
 * Copyright (C) 1991, Thomas G. Lane.
 * This file is part of the Independent JPEG Group's software.
 * For conditions of distribution and use, see the accompanying README file.
 *
 * This file contains a trivial test user interface for the JPEG compressor.
 * It should work on any system with Unix- or MS-DOS-style command lines.
 *
 * Two different command line styles are permitted, depending on the
 * compile-time switch TWO_FILE_COMMANDLINE:
 *	cjpeg [options]  inputfile outputfile
 *	cjpeg [options]  [inputfile]
 * In the second style, output is always to standard output, which you'd
 * normally redirect to a file or pipe to some other program.  Input is
 * either from a named file or from standard input (typically redirected).
 * The second style is convenient on Unix but is unhelpful on systems that
 * don't support pipes.  Also, you MUST use the first style if your system
 * doesn't do binary I/O to stdin/stdout.
 */

#include "jinclude.h"
#ifdef INCLUDES_ARE_ANSI
#include <stdlib.h>		/* to declare exit() */
#endif

#ifdef THINK_C
#include <console.h>		/* command-line reader for Macintosh */
#endif

#ifdef DONT_USE_B_MODE		/* define mode parameters for fopen() */
#define READ_BINARY	"r"
#define WRITE_BINARY	"w"
#else
#define READ_BINARY	"rb"
#define WRITE_BINARY	"wb"
#endif

#include "jversion.h"		/* for version message */


/*
 * PD version of getopt(3).
 */

#include "egetopt.c"


/*
 * This routine determines what format the input file is,
 * and selects the appropriate input-reading module.
 *
 * To determine which family of input formats the file belongs to,
 * we may look only at the first byte of the file, since C does not
 * guarantee that more than one character can be pushed back with ungetc.
 * Looking at additional bytes would require one of these approaches:
 *     1) assume we can fseek() the input file (fails for piped input);
 *     2) assume we can push back more than one character (works in
 *        some C implementations, but unportable);
 *     3) provide our own buffering as is done in djpeg (breaks input readers
 *        that want to use stdio directly, such as the RLE library);
 * or  4) don't put back the data, and modify the input_init methods to assume
 *        they start reading after the start of file (also breaks RLE library).
 * #1 is attractive for MS-DOS but is untenable on Unix.
 *
 * The most portable solution for file types that can't be identified by their
 * first byte is to make the user tell us what they are.  This is also the
 * only approach for "raw" file types that contain only arbitrary values.
 * We presently apply this method for Targa files.  Most of the time Targa
 * files start with 0x00, so we recognize that case.  Potentially, however,
 * a Targa file could start with any byte value (byte 0 is the length of the
 * seldom-used ID field), so we accept a -T switch to force Targa input mode.
 */

static boolean is_targa;	/* records user -T switch */

#ifdef MSDOS
#define JPEG_EXT        "jpg"
static char *input_ext = "tga";
#endif



LOCAL void
select_file_type (compress_info_ptr cinfo)
{
  int c;

  if (is_targa) {
#ifdef TARGA_SUPPORTED
    jselrtarga(cinfo);
#else
    ERREXIT(cinfo->emethods, "Targa support was not compiled");
#endif
    return;
  }

  if ((c = getc(cinfo->input_file)) == EOF)
    ERREXIT(cinfo->emethods, "Empty input file");

  switch (c) {
#ifdef GIF_SUPPORTED
  case 'G':
    jselrgif(cinfo);
#ifdef MSDOS
    input_ext = "gif";
#endif
    break;
#endif
#ifdef PPM_SUPPORTED
  case 'P':
    jselrppm(cinfo);
#ifdef MSDOS
    input_ext = "ppm";
#endif
    break;
#endif
#ifdef RLE_SUPPORTED
  case 'R':
    jselrrle(cinfo);
#ifdef MSDOS
    input_ext = "rle";
#endif
    break;
#endif
#ifdef TARGA_SUPPORTED
  case 0x00:
    jselrtarga(cinfo);
    break;
#endif
  default:
#ifdef TARGA_SUPPORTED
    ERREXIT(cinfo->emethods, "Unrecognized input file format--did you forget -T ?");
#else
    ERREXIT(cinfo->emethods, "Unrecognized input file format");
#endif
    break;
  }

  if (ungetc(c, cinfo->input_file) == EOF)
    ERREXIT(cinfo->emethods, "ungetc failed");
}


/*
 * This routine gets control after the input file header has been read.
 * It must determine what output JPEG file format is to be written,
 * and make any other compression parameter changes that are desirable.
 */

METHODDEF void
c_ui_method_selection (compress_info_ptr cinfo)
{
  /* If the input is gray scale, generate a monochrome JPEG file. */
  if (cinfo->in_color_space == CS_GRAYSCALE)
    j_monochrome_default(cinfo);
  /* For now, always select JFIF output format. */
#ifdef JFIF_SUPPORTED
  jselwjfif(cinfo);
#else
  You shoulda defined JFIF_SUPPORTED.   /* deliberate syntax error */
#endif
}


LOCAL void
usage (char * progname)
/* complain about bad command line */
{
  fprintf(stderr, "usage: %s ", progname);
  fprintf(stderr, "[-Q quality 0..100] [-o] [-T] [-I] [-a] [-d]");
#ifdef TWO_FILE_COMMANDLINE
  fprintf(stderr, " inputfile outputfile\n");
#else
  fprintf(stderr, " [inputfile]\n");
#endif
  exit(2);
}

#ifdef MSDOS

/*
 * Compose a filename given a base name and extension.  If file had
 * and extension, throw it away.  We must scan the filename from the
 * right looking for a '.', but stopping if we encounter a path
 * separator character (just in case we are handled a long pathname
 * in which one of the directories has a '.', but the file doesn't).
 */

LOCAL void
fix_msdos_filename (char *dest, char *src, char *ext)
{
  int i, l;
  char *dotp;

  strcpy(dest, src);
  l = strlen(dest);
  dotp = dest + l; /* Assume there is no extension */

  for (i = --l; i >= 0; --i) {
    if (dest[i] == '.') {
      dotp = dest + i;
      break;
    } else if ( dest[i] == '/' || dest[i] == '\\' ||
                dest[i] == ':') {
      break;
    }
  }
  *dotp++ = '.';
  strcpy(dotp, ext);
}

#endif /* MSDOS */

/*
 * The main program.
 */

GLOBAL void
main (int argc, char **argv)
{
#ifdef MSDOS
  char infname[FILENAME_MAX], outfname[FILENAME_MAX];
#endif
  struct compress_info_struct cinfo;
  struct compress_methods_struct c_methods;
  struct external_methods_struct e_methods;
  int c;

  /* On Mac, fetch a command line. */
#ifdef THINK_C
  argc = ccommand(&argv);
#endif

  /* Initialize the system-dependent method pointers. */
  cinfo.methods = &c_methods;
  cinfo.emethods = &e_methods;
  jselerror(&e_methods);	/* error/trace message routines */
  jselvirtmem(&e_methods);	/* memory allocation routines */
  c_methods.c_ui_method_selection = c_ui_method_selection;

  /* Set up default JPEG parameters. */
  j_c_defaults(&cinfo, 75, FALSE); /* default quality level = 75 */
  is_targa = FALSE;

  /* Scan command line options, adjust parameters */
  
  while ((c = egetopt(argc, argv, "IQ:Taod")) != EOF)
    switch (c) {
    case 'I':			/* Create noninterleaved file. */
#ifdef MULTISCAN_FILES_SUPPORTED
      cinfo.interleave = FALSE;
#else
      fprintf(stderr, "%s: sorry, multiple-scan support was not compiled\n",
	      argv[0]);
      exit(2);
#endif
      break;
    case 'Q':			/* Quality factor. */
      { int val;
	if (optarg == NULL)
	  usage(argv[0]);
	if (sscanf(optarg, "%d", &val) != 1)
	  usage(argv[0]);
	/* Note: for now, we make force_baseline FALSE.
	 * This means non-baseline JPEG files can be created with low Q values.
	 * To ensure only baseline files are generated, pass TRUE instead.
	 */
	j_set_quality(&cinfo, val, FALSE);
      }
      break;
    case 'T':			/* Input file is Targa format. */
      is_targa = TRUE;
      break;
    case 'a':			/* Use arithmetic coding. */
#ifdef ARITH_CODING_SUPPORTED
      cinfo.arith_code = TRUE;
#else
      fprintf(stderr, "%s: sorry, arithmetic coding not supported\n",
	      argv[0]);
      exit(2);
#endif
      break;
    case 'o':			/* Enable entropy parm optimization. */
#ifdef ENTROPY_OPT_SUPPORTED
      cinfo.optimize_coding = TRUE;
#else
      fprintf(stderr, "%s: sorry, entropy optimization was not compiled\n",
	      argv[0]);
      exit(2);
#endif
      break;
    case 'd':			/* Debugging. */
      e_methods.trace_level++;
      break;
    case '?':
    default:
      usage(argv[0]);
      break;
    }

  /* If -d appeared, print version identification */
  if (e_methods.trace_level > 0)
    fprintf(stderr, "Independent JPEG Group's CJPEG, version %s\n%s\n",
	    JVERSION, JCOPYRIGHT);

  /* Select the input and output files */

#ifdef TWO_FILE_COMMANDLINE

#  ifdef MSDOS

  if (optind < argc-2 || optind > argc-1) {
    usage(argv[0]);
  }
  fix_msdos_filename(infname, argv[optind], input_ext);
  if (optind == argc-2) {
    fix_msdos_filename(outfname, argv[optind+1], JPEG_EXT);
  } else {
    fix_msdos_filename(outfname, argv[optind], JPEG_EXT);
  }
  if ((cinfo.input_file = fopen(infname, READ_BINARY)) == NULL) {
    fprintf(stderr, "%s: can't open %s\n", argv[0], infname);
    exit(2);
  }
  if ((cinfo.output_file = fopen(outfname, WRITE_BINARY)) == NULL) {
    fprintf(stderr, "%s: can't open %s\n", argv[0], outfname);
    exit(2);
  }

#  else

  if (optind != argc-2) {
    fprintf(stderr, "%s: must name one input and one output file\n", argv[0]);
    usage(argv[0]);
  }
  if ((cinfo.input_file = fopen(argv[optind], READ_BINARY)) == NULL) {
    fprintf(stderr, "%s: can't open %s\n", argv[0], argv[optind]);
    exit(2);
  }
  if ((cinfo.output_file = fopen(argv[optind+1], WRITE_BINARY)) == NULL) {
    fprintf(stderr, "%s: can't open %s\n", argv[0], argv[optind+1]);
    exit(2);
  }

#  endif

#else /* not TWO_FILE_COMMANDLINE -- use Unix style */

  cinfo.input_file = stdin;	/* default input file */
  cinfo.output_file = stdout;	/* always the output file */

  if (optind < argc-1) {
    fprintf(stderr, "%s: only one input file\n", argv[0]);
    usage(argv[0]);
  }
  if (optind < argc) {
    if ((cinfo.input_file = fopen(argv[optind], READ_BINARY)) == NULL) {
      fprintf(stderr, "%s: can't open %s\n", argv[0], argv[optind]);
      exit(2);
    }
  }

#endif /* TWO_FILE_COMMANDLINE */

  /* Figure out the input file format, and set up to read it. */
  select_file_type(&cinfo);

  /* Do it to it! */
  jpeg_compress(&cinfo);

  /* Release memory. */
  j_c_free_defaults(&cinfo);
#ifdef MEM_STATS
  if (e_methods.trace_level > 0) /* Optional memory-usage statistics */
    j_mem_stats();
#endif

  /* All done. */
  exit(0);
}
