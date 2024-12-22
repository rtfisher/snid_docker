#
# Makefile for SNID v5.0
#

# Shell
SHELL= /bin/sh

# Select the appropriate OS (Linux, Solaris, Mac PowerPC, Mac Intel)
# and uncomment the FC, FFLAGS, XLIBS, and PGLIBS settings. XLIBS and
# PGLIBS are particularly system-dependent. If they are not located at
# /usr/X11R6/lib/ and /usr/local/pgplot/, respectively, edit the XLIBS
# and PGLIBS settings accordingly.


#                            COMPILER FLAGS
#
# If you use a compiler different than the one specified for your OS
# (g77 for Linux; f77/f90 for Solaris; g77 for Mac PPC; g77 for Mac
# Intel), consult the table below to set the appropriate FFLAGS 
# compiler flags:
#
# Compiler	OS			FFLAGS
#--------------------------------------------------------
# g77		Linux			-O -fno-automatic
# gfortran	Linux			-O -fno-automatic
# Intel 	Linux			-O -save
# Sun 		Solaris			-O
# IBM 		IBM AIX, Linux, etc.	-O -qsave
# SGI 		SGI IRIX		-O -static
# Compaq 	Tru64 Unix		-O -static


#                       NOTE ON PGPLOT LIBRARIES
# 
# You must set the LD_LIBRARY_PATH and PGPLOT_DIR environment
# variables to point to the directory containing the libpgplot.*
# library. Do this in the .*rc file corresponding to your shell
# (~/.cshrc, ~/.bashrc, etc.):
#
# [in (t)csh]
#       setenv LD_LIBRARY_PATH /usr/local/pgplot
#	setenv PGPLOT_DIR /usr/local/pgplot
#
# [in bash]
#       export LD_LIBRARY_PATH="/usr/local/pgplot"
#       export PGPLOT_DIR="/usr/local/pgplot"


#                           FOR MAC USERS 
#
# The assumption is that you have the fink distribution of pgplot
# (i.e. the pgplot libraries are located in /sw/lib/pgplot). If this
# is not the case then edit the "-L/sw/lib/pgplot" portion of the
# PGLIBS variable.
# 
# On Mac Intel, you can download the Scisoft distribution of pgplot at
# http://web.mac.com/npirzkal/Scisoft/Scisoft.html . The pgplot
# libraries will then be located in /scisoft/lib .
#
# Linking the pgplot libraries on a Mac requires to also link
# the png, z, and aquaterm libraries: 
#
# PGLIBS= (...) -L/sw/lib -lpng -lz -laquaterm (...)
#
# If the libpng.*, libz.* and libaquaterm.* are not in /sw/lib, you
# will need to edit the PGLIBS setting accordingly.


##-----------------------  Edit as appropriate  -----------------------##

# ------
# Linux
# ------
# NOTE: for 64-bit CPUs, the X11 libraries are located in the lib64/
# directory:
#
#    XLIBS= -L/usr/X11R6/lib64 -lX11
# OR XLIBS= -L/usr/lib64 -lX11
# ------
FC= g77
FFLAGS= -O -fno-automatic
XLIBS= -L/usr/X11R6/lib -lX11 
PGLIBS= -L/usr/local/pgplot -lpgplot

# --------
# Solaris
# --------
# NOTES: 
# (1) using /opt/SUNWspro/bin/f77 will usually invoke
# /opt/SUNWspro/bin/f90 -f77 -ftrap=%none. This is fine.
# (2) If you see a "Note: IEEE floating-point exception flags raised:"
# at runtime then simply uncomment the call to ieee_flags() towards
# the end of snid.f, then recompile.
# ------------
#FC= /opt/SUNWspro/bin/f77
#FFLAGS= -O
#XLIBS= -L/usr/X11R6/lib -lX11 
#PGLIBS= -L/usr/local/pgplot -lpgplot

# ------------
# Mac PowerPC
# ------------
# NOTE: if you get an error message that complains about libgcc then
# try using gfortran instead of g77.
# ------------
# NOTE: Linking the pgplot libraries on a Mac requires to also link
# the png, z, and aquaterm libraries: 
#
# PGLIBS= (...) -L/sw/lib -lpng -lz -laquaterm (...)
#
# If the libpng.*, libz.* and libaquaterm.* are not in /sw/lib, you
# will need to edit the PGLIBS setting accordingly. E.g. the libpng.*
# and libz.* libraries could be in /usr/lib, while the libaquaterm.*
# library could be in /usr/local/lib. In this case you should set
# (assuming the libpgplot.* library is in /sw/lib):
#
# PGLIBS= -Wl,-framework -Wl,Foundation -L/usr/lib -lpng -lz -L/usr/local/lib -laquaterm -L/sw/lib/pgplot -lpgplot
# ------------
#FC= g77
#FFLAGS= -O -fno-automatic
#XLIBS= -L/usr/X11R6/lib -lX11 
#PGLIBS= -Wl,-framework -Wl,Foundation -L/sw/lib -lpng -lz -laquaterm -L/sw/lib/pgplot -lpgplot

# ----------
# Mac Intel
# ----------
# NOTE: Linking the pgplot libraries on a Mac requires to also link
# the png, z, and aquaterm libraries: 
#
# PGLIBS= (...) -L/sw/lib -lpng -lz -laquaterm (...)
#
# If the libpng.*, libz.* and libaquaterm.* are not in /sw/lib, you
# will need to edit the PGLIBS setting accordingly. E.g. the libpng.*
# and libz.* libraries could be in /usr/lib, while the libaquaterm.*
# library could be in /usr/local/lib. In this case you should set
# (assuming the libpgplot.* library is in /sw/lib):
#
# PGLIBS= -Wl,-framework -Wl,Foundation -L/usr/lib -lpng -lz -L/usr/local/lib -laquaterm -L/sw/lib/pgplot -lpgplot
# ------------
#FC= g77
#FFLAGS= -O -fno-automatic
#XLIBS= -L/usr/X11R6/lib -lX11
#PGLIBS= -Wl,-framework -Wl,Foundation -L/sw/lib -lpng -lz -laquaterm -L/sw/lib/pgplot -lpgplot



##-------------------  DO NOT EDIT BELOW THIS LINE! -------------------##

# Implicit rules
%.o : %.f
	$(FC) $(FFLAGS) -c $< -o $@

# For distribution
DISTDIR= snid-5.0

# Object files
OBJ1= source/snid.o source/snidmore.o source/typeinfo.o source/snidtype.o \
	source/snidplot.o source/spliner.o source/apodize.o source/rmsetc.o \
	source/peakfit.o
OBJ2= source/logwave.o source/typeinfo.o source/spliner.o source/apodize.o
OBJ3= source/plotlnw.o source/rmsetc.o

# location of various utilities
OUTILS1= utils/lnb.o utils/median.o utils/legendre.o utils/invert.o \
	utils/four2.o utils/stddev.o utils/linearfit.o
OUTILS2= utils/lnb.o utils/median.o
OUTILS3= utils/four2.o utils/lnb.o

# Button library
BUTTLIB= button/libbutton.a

all : snid logwave plotlnw

snid :  $(OBJ1) $(OUTILS1)
	cd button && $(MAKE) FC=$(FC)
	$(FC) $(FFLAGS) $(OBJ1) $(OUTILS1) $(BUTTLIB) $(PGLIBS) $(XLIBS) -o $@

logwave : $(OBJ2) $(OUTILS2)
	$(FC) $(FFLAGS) $(OBJ2) $(OUTILS2) -o $@

plotlnw : $(OBJ3) $(OUTILS3)
	$(FC) $(FFLAGS) $(OBJ3) $(OUTILS3) $(PGLIBS) $(XLIBS) -o $@

snid.o : source/snid.inc 
snidmore.o : source/snid.inc 
typeinfo.o : source/snid.inc 
snidtype.o : source/snid.inc 
snidplot.o : source/snid.inc 
logwave.o  : source/snid.inc
plotlnw.o : source/snid.inc
legendre.o : utils/lengendre.inc

install :
	cp snid logwave plotlnw bin/

clean :
	-rm source/*.o
	-rm utils/*.o
	-rm button/*.o

realclean :
	-rm snid logwave plotlnw 
	-rm source/*.o
	-rm utils/*.o
	-rm button/*.o $(BUTTLIB)

dist:
	mkdir $(DISTDIR)
	cp -r AAREADME Makefile bin button doc examples gpl-3.0.txt source \
	templates test utils $(DISTDIR)
	-rm $(DISTDIR)/button/*.o $(DISTDIR)/source/*.o $(DISTDIR)/utils/*.o
	tar cvf $(DISTDIR).tar $(DISTDIR)
	gzip $(DISTDIR).tar
	rm -rf $(DISTDIR)
