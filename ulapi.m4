dnl @synopsis ACX_PTHREAD([ACTION-IF-FOUND[, ACTION-IF-NOT-FOUND]])
dnl
dnl This macro figures out how to build C programs using POSIX
dnl threads.  It sets the PTHREAD_LIBS output variable to the threads
dnl library and linker flags, and the PTHREAD_CFLAGS output variable
dnl to any special C compiler flags that are needed.  (The user can also
dnl force certain compiler flags/libs to be tested by setting these
dnl environment variables.)
dnl
dnl Also sets PTHREAD_CC to any special C compiler that is needed for
dnl multi-threaded programs (defaults to the value of CC otherwise).
dnl (This is necessary on AIX to use the special cc_r compiler alias.)
dnl
dnl NOTE: You are assumed to not only compile your program with these
dnl flags, but also link it with them as well.  e.g. you should link
dnl with $PTHREAD_CC $CFLAGS $PTHREAD_CFLAGS $LDFLAGS ... $PTHREAD_LIBS $LIBS
dnl
dnl If you are only building threads programs, you may wish to
dnl use these variables in your default LIBS, CFLAGS, and CC:
dnl
dnl        LIBS="$PTHREAD_LIBS $LIBS"
dnl        CFLAGS="$CFLAGS $PTHREAD_CFLAGS"
dnl        CC="$PTHREAD_CC"
dnl
dnl In addition, if the PTHREAD_CREATE_JOINABLE thread-attribute
dnl constant has a nonstandard name, defines PTHREAD_CREATE_JOINABLE
dnl to that name (e.g. PTHREAD_CREATE_UNDETACHED on AIX).
dnl
dnl ACTION-IF-FOUND is a list of shell commands to run if a threads
dnl library is found, and ACTION-IF-NOT-FOUND is a list of commands
dnl to run it if it is not found.  If ACTION-IF-FOUND is not specified,
dnl the default action will define HAVE_PTHREAD.
dnl
dnl Please let the authors know if this macro fails on any platform,
dnl or if you have any other suggestions or comments.  This macro was
dnl based on work by SGJ on autoconf scripts for FFTW (www.fftw.org)
dnl (with help from M. Frigo), as well as ac_pthread and hb_pthread
dnl macros posted by Alejandro Forero Cuervo to the autoconf macro
dnl repository.  We are also grateful for the helpful feedback of
dnl numerous users.
dnl
dnl author Steven G. Johnson

AC_DEFUN([ACX_PTHREAD], [
AC_REQUIRE([AC_CANONICAL_HOST])
AC_LANG_SAVE
AC_LANG_C
acx_pthread_ok=no

# We used to check for pthread.h first, but this fails if pthread.h
# requires special compiler flags (e.g. on True64 or Sequent).
# It gets checked for in the link test anyway.

# First of all, check if the user has set any of the PTHREAD_LIBS,
# etcetera environment variables, and if threads linking works using
# them:
if test x"$PTHREAD_LIBS$PTHREAD_CFLAGS" != x; then
        save_CFLAGS="$CFLAGS"
        CFLAGS="$CFLAGS $PTHREAD_CFLAGS"
        save_LIBS="$LIBS"
        LIBS="$PTHREAD_LIBS $LIBS"
        AC_MSG_CHECKING([for pthread_join in LIBS=$PTHREAD_LIBS with CFLAGS=$PTHREAD_CFLAGS])
        AC_TRY_LINK_FUNC(pthread_join, acx_pthread_ok=yes)
        AC_MSG_RESULT($acx_pthread_ok)
        if test x"$acx_pthread_ok" = xno; then
                PTHREAD_LIBS=""
                PTHREAD_CFLAGS=""
        fi
        LIBS="$save_LIBS"
        CFLAGS="$save_CFLAGS"
fi

# We must check for the threads library under a number of different
# names; the ordering is very important because some systems
# (e.g. DEC) have both -lpthread and -lpthreads, where one of the
# libraries is broken (non-POSIX).

# Create a list of thread flags to try.  Items starting with a "-" are
# C compiler flags, and other items are library names, except for "none"
# which indicates that we try without any flags at all, and "pthread-config"
# which is a program returning the flags for the Pth emulation library.

acx_pthread_flags="pthreads pthread none -Kthread -kthread lthread -pthread -pthreads -mthreads --thread-safe -mt pthread-config"

# The ordering *is* (sometimes) important.  Some notes on the
# individual items follow:

# pthreads: AIX (must check this before -lpthread)
# none: in case threads are in libc; should be tried before -Kthread and
#       other compiler flags to prevent continual compiler warnings
# -Kthread: Sequent (threads in libc, but -Kthread needed for pthread.h)
# -kthread: FreeBSD kernel threads (preferred to -pthread since SMP-able)
# lthread: LinuxThreads port on FreeBSD (also preferred to -pthread)
# -pthread: Linux/gcc (kernel threads), BSD/gcc (userland threads)
# -pthreads: Solaris/gcc
# -mthreads: Mingw32/gcc, Lynx/gcc
# -mt: Sun Workshop C (may only link SunOS threads [-lthread], but it
#      doesn't hurt to check since this sometimes defines pthreads too;
#      also defines -D_REENTRANT)
# pthread: Linux, etcetera
# --thread-safe: KAI C++
# pthread-config: use pthread-config program (for GNU Pth library)

case "${host_cpu}-${host_os}" in
        *solaris*)

        # On Solaris (at least, for some versions), libc contains stubbed
        # (non-functional) versions of the pthreads routines, so link-based
        # tests will erroneously succeed.  (We need to link with -pthread or
        # -lpthread.)  (The stubs are missing pthread_cleanup_push, or rather
        # a function called by this macro, so we could check for that, but
        # who knows whether they'll stub that too in a future libc.)  So,
        # we'll just look for -pthreads and -lpthread first:

        acx_pthread_flags="-pthread -pthreads pthread -mt $acx_pthread_flags"
        ;;
esac

if test x"$acx_pthread_ok" = xno; then
for flag in $acx_pthread_flags; do

        case $flag in
                none)
                AC_MSG_CHECKING([whether pthreads work without any flags])
                ;;

                -*)
                AC_MSG_CHECKING([whether pthreads work with $flag])
                PTHREAD_CFLAGS="$flag"
                ;;

		pthread-config)
		AC_CHECK_PROG(acx_pthread_config, pthread-config, yes, no)
		if test x"$acx_pthread_config" = xno; then continue; fi
		PTHREAD_CFLAGS="`pthread-config --cflags`"
		PTHREAD_LIBS="`pthread-config --ldflags` `pthread-config --libs`"
		;;

                *)
                AC_MSG_CHECKING([for the pthreads library -l$flag])
                PTHREAD_LIBS="-l$flag"
                ;;
        esac

        save_LIBS="$LIBS"
        save_CFLAGS="$CFLAGS"
        LIBS="$PTHREAD_LIBS $LIBS"
        CFLAGS="$CFLAGS $PTHREAD_CFLAGS"

        # Check for various functions.  We must include pthread.h,
        # since some functions may be macros.  (On the Sequent, we
        # need a special flag -Kthread to make this header compile.)
        # We check for pthread_join because it is in -lpthread on IRIX
        # while pthread_create is in libc.  We check for pthread_attr_init
        # due to DEC craziness with -lpthreads.  We check for
        # pthread_cleanup_push because it is one of the few pthread
        # functions on Solaris that doesn't have a non-functional libc stub.
        # We try pthread_create on general principles.
        AC_TRY_LINK([#include <pthread.h>],
                    [pthread_t th; pthread_join(th, 0);
                     pthread_attr_init(0); pthread_cleanup_push(0, 0);
                     pthread_create(0,0,0,0); pthread_cleanup_pop(0); ],
                    [acx_pthread_ok=yes])

        LIBS="$save_LIBS"
        CFLAGS="$save_CFLAGS"

        AC_MSG_RESULT($acx_pthread_ok)
        if test "x$acx_pthread_ok" = xyes; then
                break;
        fi

        PTHREAD_LIBS=""
        PTHREAD_CFLAGS=""
done
fi

# Various other checks:
if test "x$acx_pthread_ok" = xyes; then
        save_LIBS="$LIBS"
        LIBS="$PTHREAD_LIBS $LIBS"
        save_CFLAGS="$CFLAGS"
        CFLAGS="$CFLAGS $PTHREAD_CFLAGS"

        # Detect AIX lossage: threads are created detached by default
        # and the JOINABLE attribute has a nonstandard name (UNDETACHED).
        AC_MSG_CHECKING([for joinable pthread attribute])
        AC_TRY_LINK([#include <pthread.h>],
                    [int attr=PTHREAD_CREATE_JOINABLE;],
                    ok=PTHREAD_CREATE_JOINABLE, ok=unknown)
        if test x"$ok" = xunknown; then
                AC_TRY_LINK([#include <pthread.h>],
                            [int attr=PTHREAD_CREATE_UNDETACHED;],
                            ok=PTHREAD_CREATE_UNDETACHED, ok=unknown)
        fi
        if test x"$ok" != xPTHREAD_CREATE_JOINABLE; then
                AC_DEFINE(PTHREAD_CREATE_JOINABLE, $ok,
                          [Define to the necessary symbol if this constant
                           uses a non-standard name on your system.])
        fi
        AC_MSG_RESULT(${ok})
        if test x"$ok" = xunknown; then
                AC_MSG_WARN([we do not know how to create joinable pthreads])
        fi

        AC_MSG_CHECKING([if more special flags are required for pthreads])
        flag=no
        case "${host_cpu}-${host_os}" in
                *-aix* | *-freebsd* | *-darwin*) flag="-D_THREAD_SAFE";;
                *solaris* | *-osf* | *-hpux*) flag="-D_REENTRANT";;
        esac
        AC_MSG_RESULT(${flag})
        if test "x$flag" != xno; then
                PTHREAD_CFLAGS="$flag $PTHREAD_CFLAGS"
        fi

        LIBS="$save_LIBS"
        CFLAGS="$save_CFLAGS"

        # More AIX lossage: must compile with cc_r
        AC_CHECK_PROG(PTHREAD_CC, cc_r, cc_r, ${CC})
else
        PTHREAD_CC="$CC"
fi

AC_SUBST(PTHREAD_LIBS)
AC_SUBST(PTHREAD_CFLAGS)
AC_SUBST(PTHREAD_CC)

# Finally, execute ACTION-IF-FOUND/ACTION-IF-NOT-FOUND:
if test x"$acx_pthread_ok" = xyes; then
        ifelse([$1],,AC_DEFINE(HAVE_PTHREAD,1,[Define if you have POSIX threads libraries and header files.]),[$1])
        :
else
        acx_pthread_ok=no
        $2
fi
AC_LANG_RESTORE
])dnl ACX_PTHREAD

AC_DEFUN([ACX_RTAI],
    [AC_MSG_CHECKING([for RTAI])]
    [AC_ARG_WITH(rtai,
	    [  --with-rtai=<path to rtai>  Specify path to RTAI],
	    dirs=$withval,dirs="/usr/realtime /usr/src/rtai")]
    for dir in $dirs ; do
	if test -f $dir/include/rtai.h ; then rtai_dir=$dir ; break; fi
    done
    if test x$rtai_dir = x ; then
	[AC_MSG_RESULT([no])]
	[AC_MSG_WARN([not found in $dirs, try --with-rtai=<path to rtai>])]
	\rm -f rtaidir
	RTAI_LIBS=""
    else
	RTAI_DIR=$rtai_dir
	RTAI_INCLUDE="-I$RTAI_DIR/include"
	RTAI_LIBS="-L$RTAI_DIR/lib -llxrt"
dnl put HAVE_RTAI in config.h
	[AC_DEFINE(HAVE_RTAI,
		1, [Define non-zero if you have RTAI.])]
dnl put RTAI_DIR and linking flags in Makefile
	[AC_SUBST(RTAI_DIR)]
	[AC_SUBST(RTAI_INCLUDE)]
	[AC_SUBST(RTAI_LIBS)]
	[AC_MSG_RESULT([$RTAI_DIR])]
dnl put RTAI_DIR into variable file for use by shell scripts
	echo RTAI_DIR=$rtai_dir > rtaidir
    fi
    [AM_CONDITIONAL(HAVE_RTAI, test x$rtai_dir != x)]
)

AC_DEFUN([ACX_XENOMAI],
    [AC_MSG_CHECKING([for Xenomai])]
    [AC_ARG_WITH(xenomai,
	    [  --with-xenomaii=<path to Xenomai>  Specify path to Xenomai],
	    dirs=$withval,dirs="/usr/xenomai")]
    for dir in $dirs ; do
	if test -f $dir/include/xenomai/init.h ; then xenomai_dir=$dir ; break; fi
    done
    if test x$xenomai_dir = x ; then
	[AC_MSG_RESULT([no])]
	[AC_MSG_WARN([not found in $dirs, try --with-xenomai=<path to Xenomai>])]
	\rm -f xenomaidir
	XENOMAI_CFLAGS=""
	XENOMAI_LDFLAGS=""
    else
	XENOMAI_DIR=$xenomai_dir
	XENOMAI_CFLAGS="`xeno-config --skin=alchemy --cflags`"
	XENOMAI_LDFLAGS="`xeno-config --skin=alchemy --ldflags`"
dnl put HAVE_XENOMAI in config.h
	[AC_DEFINE(HAVE_XENOMAI,
		1, [Define non-zero if you have XENOMAI.])]
dnl put XENOMAI_DIR and linking flags in Makefile
	[AC_SUBST(XENOMAI_DIR)]
	[AC_SUBST(XENOMAI_CFLAGS)]
	[AC_SUBST(XENOMAI_LDFLAGS)]
	[AC_MSG_RESULT([$XENOMAI_DIR])]
dnl put XENOMAI_DIR into variable file for use by shell scripts
	echo XENOMAI_DIR=$xenomai_dir > xenomaidir
    fi
    [AM_CONDITIONAL(HAVE_XENOMAI, test x$xenomai_dir != x)]
)

AC_DEFUN([ACX_DL],
dnl put HAVE_DLFCN_H in config/config.h
	[AC_CHECK_HEADERS([dlfcn.h])]
dnl put -ldl in default link line, and then set a custom variable
	[AC_SEARCH_LIBS([dlopen], [dl], , no_dl=yes)]
dnl check the custom variable, and add some CFLAGS for compiling shared objs
	if test x$no_dl = xyes ; then
	[AC_DEFINE(NO_DL,
		1, [Define non-zero if you are missing dl libraries.])]
	DL_CFLAGS=""
	else
	DL_CFLAGS="-shared -fPIC"
	fi
	[AC_SUBST(DL_CFLAGS)]
	[AM_CONDITIONAL(NO_DL, test x$no_dl = xyes)]
)

AC_DEFUN([ACX_TIME],
dnl put -lrt,,, in default link line, and then set a custom variable
	[AC_SEARCH_LIBS([clock_gettime], [rt], have_clockgettime=yes)]
	if test x$have_clockgettime = xyes ; then
dnl put HAVE_CLOCK_GETTIME in config.h
	[AC_DEFINE(HAVE_CLOCK_GETTIME,
		1, [Define non-zero if you have clock_gettime.])]
	fi
)

AC_DEFUN([ACX_GETOPT],
	[AC_CHECK_HEADERS([getopt.h],,need_getopt=yes)]
	if test x$need_getopt = xyes ; then
dnl put NEED_GETOPT in config.h
	[AC_DEFINE(NEED_GETOPT,
		1, [Define non-zero if you need ulapi to provide getopt.])]
	fi
)

AC_DEFUN([ACX_HAVE_IOPL],
	[AC_MSG_CHECKING([for iopl])]
	[AC_TRY_LINK([#include <sys/io.h>],
		[int val=iopl(0);],
		have_iopl=yes)]
	if test x$have_iopl = xyes ; then
	[AC_MSG_RESULT([yes])]
dnl put HAVE_IOPL in config.h
	[AC_DEFINE(HAVE_IOPL,
		1, [Define non-zero if you have iopl.])]
	else
	[AC_MSG_RESULT([no])]
	fi
	[AM_CONDITIONAL(HAVE_IOPL, test xhave_iopl = xyes	)]
)

AC_DEFUN([ACX_PIC],
	PIC_CFLAGS="-fPIC"
	[AC_SUBST(PIC_CFLAGS)]
)	

AC_DEFUN([ACX_PRE_ULAPI],
	[ACX_PTHREAD]
	[ACX_RTAI]
	[ACX_XENOMAI]
	[ACX_DL]
	[ACX_TIME]
	[ACX_GETOPT]
	[ACX_HAVE_IOPORTS]
	[ACX_HAVE_IOPL]
	[ACX_PIC]
)

AC_DEFUN([ACX_ULAPI],
	[ACX_PRE_ULAPI]
	[AC_MSG_CHECKING([for ULAPI interface to common functions])]
	[AC_ARG_WITH(ulapi,
		[ --with-ulapi=<path to ulapi>  Specify path to ulapi directory],
		dirs=$withval,dirs="/usr/local /usr/local/ulapi /usr/local/src/ulapi $HOME/ulapi")]
	for dir in $dirs ; do
		if test -f $dir/include/ulapi.h ; then ULAPI_DIR=$dir ; break ; fi
	done
	if test x$ULAPI_DIR = x ; then
	[AC_MSG_ERROR([not found, specify using --with-ulapi=<path to ulapi>])]
	else
	[AC_MSG_RESULT([$ULAPI_DIR])]
	ULAPI_CFLAGS="-I$ULAPI_DIR/include"
	ULAPI_LIBS="-L$ULAPI_DIR/lib -lulapi $PTHREAD_LIBS"
dnl put HAVE_ULAPI in config.h
	[AC_DEFINE(HAVE_ULAPI,
		1, [Define non-zero if you have ulapi.])]
dnl put ULAPI_DIR in Makefile
	[AC_SUBST(ULAPI_DIR)]
	[AC_SUBST(ULAPI_CFLAGS)]
	[AC_SUBST(ULAPI_LIBS)]
	fi
dnl put ULAPI_DIR into variable file for use by shell scripts
	echo ULAPI_DIR=$ULAPI_DIR > ulapi_dir
dnl enable HAVE_ULAPI test in Makefile
	[AM_CONDITIONAL(HAVE_ULAPI, test x$ULAPI_DIR != x)]
)

AC_DEFUN([ACX_HAVE_IOPORTS],
	[AC_MSG_CHECKING([for inb/outb])]
	[AC_TRY_LINK([#include <sys/io.h>],
		[int in=inb(0x80);],
		have_ioports=yes)]
	if test x$have_ioports = xyes ; then
	[AC_MSG_RESULT([yes])]
dnl put HAVE_IOPORTS in config.h
	[AC_DEFINE(HAVE_IOPORTS,
		1, [Define non-zero if you have inb/outb.])]
	else
	[AC_MSG_RESULT([no])]
	fi
dnl enable check for HAVE_IOPORTS in Makefile.am
	[AM_CONDITIONAL(HAVE_IOPORTS, test x$have_ioports = xyes)]
)
