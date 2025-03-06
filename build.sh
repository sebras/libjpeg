#!/bin/bash
THIS="$(readlink -f "$0")"

# lots of helpers

function fatal()
{
	echo "$1" > /dev/stderr
	exit 1
}

function ren()
{
	if ! mv --interactive "$1" "$2"; then
		fatal "can not rename $1 to $2"
	fi
}

function d2u()
{
	if [ $# -eq 1 ]; then
		if ! dos2unix --quiet "$1"; then
			fatal "can not convert from DOS to Unix line-endings in $1"
		fi
	else
		ren "$1" "$2"
		if ! dos2unix --quiet "$2"; then
			fatal "can not convert from DOS to Unix line-endings in $2"
		fi
	fi
}

function gitadd()
{
	if ! git add "$1"; then fatal "can not add $1 in working directory to git repo."; fi
}

function gitaddall()
{
	if ! git add ./*; then fatal "can not add all files in working directory to git repo."; fi
}

function gitcommitshort()
{
	if ! git commit --message="$1"; then fatal "can not create commit in git repository"; fi
}

function gitcommitfull()
{
	DATE="$1"
	VERSIONSTRING="$2"
	EMAIL="$3"
	URL="$4"
	if ! GIT_COMMITTER_DATE="$DATE 00:00:00 UTC" git commit \
		--author="Indepent JPEG group <${EMAIL}>" \
		--date="$DATE 00:00:00" \
		--message="The Independent JPEG Group's JPEG software version ${VERSIONSTRING}." \
		--message="$URL"; then
		fatal "can not create commit in git repository"
	fi
}

function gittag()
{
	if ! git tag "$1"; then fatal "can not create tag in git repository"; fi
}

function gitrm()
{
	if ! git rm --force ./*; then fatal "can not remove all files from git working directory"; fi
}

function gitrmrecursive()
{
	if ! git rm --force -r .; then fatal "can not remove all recursive files from git working directory"; fi
}

function gitclean()
{
	if ! git clean --force -d; then fatal "can not remove untracked files from working directory"; fi
}

function createbuildscript()
{
	if ! cat "$THIS" > build.sh; then fatal "can not create repo build script"; fi
	if ! chmod 755 build.sh; then fatal "can not set build script permissions"; fi
}

function geturl()
{
	if ! wget "$1"; then fatal "can not download $1"; fi
}

function unpackzip()
{
	if ! unzip "$1"; then fatal "can not unpack zip file $1"; fi
}

function unpacktar()
{
	if ! tar xvf "$1"; then fatal "can not unpack tar file $1"; fi
}

function movefilefromsubdir()
{
	if ! mv ./"$1"/* .; then fatal "can not move files $1/* out of subdirectory into working directory"; fi
	if ! rmdir ./"$1"; then fatal "can not remove subdirectory"; fi
}

function removefile()
{
	if ! rm --force "$1"; then fatal "can not remove file $1"; fi
}

# end of helpers

function v1()
{
	DATE="$1"
	TAG="$2"
	EMAIL="$3"
	VERSIONSTRING="$4"
	URL="$5"
	FILENAME="$(basename "$URL")"

	gitrm
	gitclean
	geturl "$URL"
	unpackzip "$FILENAME"
	removefile "$FILENAME"
	d2u ANSI2KNR.C ansi2knr.c
	d2u ARCHITCT.TXT architecture
	d2u CODING.RLS codingrules
	d2u EGETOPT.C egetopt.c
	d2u JBSMOOTH.C jbsmooth.c
	d2u JCARITH.C jcarith.c
	d2u JCCOLOR.C jccolor.c
	d2u JCDEFLTS.C jcdeflts.c
	d2u JCEXPAND.C jcexpand.c
	d2u JCHUFF.C jchuff.c
	d2u JCMAIN.C jcmain.c
	d2u JCMASTER.C jcmaster.c
	d2u JCMCU.C jcmcu.c
	d2u JCONFIG.H jconfig.h
	d2u JCPIPE.C jcpipe.c
	d2u JCSAMPLE.C jcsample.c
	d2u JDARITH.C jdarith.c
	d2u JDCOLOR.C jdcolor.c
	d2u JDHUFF.C jdhuff.c
	d2u JDMAIN.C jdmain.c
	d2u JDMASTER.C jdmaster.c
	d2u JDMCU.C jdmcu.c
	d2u JDPIPE.C jdpipe.c
	d2u JDSAMPLE.C jdsample.c
	d2u JERROR.C jerror.c
	d2u JFWDDCT.C jfwddct.c
	d2u JINCLUDE.H jinclude.h
	d2u JPEGDATA.H jpegdata.h
	d2u JQUANT1.C jquant1.c
	d2u JQUANT2.C jquant2.c
	d2u JRDGIF.C jrdgif.c
	d2u JRDJFIF.C jrdjfif.c
	d2u JRDPPM.C jrdppm.c
	d2u JREVDCT.C jrevdct.c
	d2u JUTILS.C jutils.c
	d2u JVIRTMEM.C jvirtmem.c
	d2u JWRGIF.C jwrgif.c
	d2u JWRJFIF.C jwrjfif.c
	d2u JWRPPM.C jwrppm.c
	d2u MAKCJPEG.CF makcjpeg.cf
	d2u MAKCJPEG.LNK makcjpeg.lnk
	d2u MAKDJPEG.CF makdjpeg.cf
	d2u MAKDJPEG.LNK makdjpeg.lnk
	d2u MAKEFILE.AMG makefile.manx
	d2u MAKEFILE.MC5 makefile.mc5
	d2u MAKEFILE.MC6 makefile.mc6
	d2u MAKEFILE.PWC makefile.pwc
	d2u MAKEFILE.UNX makefile.unix
	d2u MAKLJPEG.CF makljpeg.cf
	d2u README
	ren TESTIMG.JPG testimg.jpg
	ren TESTIMG.PPM testimg.ppm
	ren TESTORIG.JPG testorig.jpg
	gitaddall
	gitcommitfull "$DATE" "$VERSIONSTRING" "$EMAIL" "$URL"
	gittag "$TAG"
}

function v2()
{
	DATE="$1"
	TAG="$2"
	EMAIL="$3"
	VERSIONSTRING="$4"
	URL="$5"
	FILENAME="$(basename "$URL")"

	gitrm
	gitclean
	geturl "$URL"
	unpackzip "$FILENAME"
	removefile "$FILENAME"
	removefile CATALOG.ASC
	d2u ANSI2KNR.C ansi2knr.c
	d2u ARCHITEC architecture
	d2u CHANGELO CHANGELOG
	d2u CJPEG.1 cjpeg.1
	d2u CODINGRU codingrules
	d2u CONFIG.C config.c
	d2u DJPEG.1 djpeg.1
	d2u EGETOPT.C egetopt.c
	d2u JBSMOOTH.C jbsmooth.c
	d2u JCARITH.C jcarith.c
	d2u JCCOLOR.C jccolor.c
	d2u JCDEFLTS.C jcdeflts.c
	d2u JCEXPAND.C jcexpand.c
	d2u JCHUFF.C jchuff.c
	d2u JCMAIN.C jcmain.c
	d2u JCMASTER.C jcmaster.c
	d2u JCMCU.C jcmcu.c
	d2u JCONFIG.H jconfig.h
	d2u JCPIPE.C jcpipe.c
	d2u JCSAMPLE.C jcsample.c
	d2u JDARITH.C jdarith.c
	d2u JDCOLOR.C jdcolor.c
	d2u JDDEFLTS.C jddeflts.c
	d2u JDHUFF.C jdhuff.c
	d2u JDMAIN.C jdmain.c
	d2u JDMASTER.C jdmaster.c
	d2u JDMCU.C jdmcu.c
	d2u JDPIPE.C jdpipe.c
	d2u JDSAMPLE.C jdsample.c
	d2u JERROR.C jerror.c
	d2u JFWDDCT.C jfwddct.c
	d2u JINCLUDE.H jinclude.h
	d2u JPEGDATA.H jpegdata.h
	d2u JQUANT1.C jquant1.c
	d2u JQUANT2.C jquant2.c
	d2u JRDGIF.C jrdgif.c
	d2u JRDJFIF.C jrdjfif.c
	d2u JRDPPM.C jrdppm.c
	d2u JRDRLE.C jrdrle.c
	d2u JRDTARGA.C jrdtarga.c
	d2u JREVDCT.C jrevdct.c
	d2u JUTILS.C jutils.c
	d2u JVIRTMEM.C jvirtmem.c
	d2u JVERSION.H jversion.h
	d2u JWRGIF.C jwrgif.c
	d2u JWRJFIF.C jwrjfif.c
	d2u JWRPPM.C jwrppm.c
	d2u JWRRLE.C jwrrle.c
	d2u JWRTARGA.C jwrtarga.c
	d2u MAKCJPEG.CF makcjpeg.cf
	d2u MAKCJPEG.LNK makcjpeg.lnk
	d2u MAKCJPEG.LST makcjpeg.lst
	d2u MAKDJPEG.CF makdjpeg.cf
	d2u MAKDJPEG.LNK makdjpeg.lnk
	d2u MAKDJPEG.LST makdjpeg.lst
	d2u MAKEFILE.ANS makefile.ansi
	d2u MAKEFILE.MAN makefile.manx
	d2u MAKEFILE.MC5 makefile.mc5
	d2u MAKEFILE.MC6 makefile.mc6
	d2u MAKEFILE.PWC makefile.pwc
	d2u MAKEFILE.SAS makefile.sas
	d2u MAKEFILE.TC makefile.tc
	d2u MAKEFILE.UNI makefile.unix
	d2u MAKLJPEG.CF makljpeg.cf
	d2u README
	d2u SETUP
	ren TESTIMG.JPG testimg.jpg
	ren TESTIMG.PPM testimg.ppm
	ren TESTORIG.JPG testorig.jpg
	d2u USAGE
	gitaddall
	gitcommitfull "$DATE" "$VERSIONSTRING" "$EMAIL" "$URL"
	gittag "$TAG"
}

function generic1()
{
	DATE="$1"
	TAG="$2"
	EMAIL="$3"
	VERSIONSTRING="$4"
	URL="$5"
	FILENAME="$(basename "$URL")"

	gitrm
	gitclean
	geturl "$URL"
	unpacktar "$FILENAME"
	removefile "$FILENAME"
	gitaddall
	gitcommitfull "$DATE" "$VERSIONSTRING" "$EMAIL" "$URL"
	gittag "$TAG"
}

function generic2()
{
	DATE="$1"
	TAG="$2"
	EMAIL="$3"
	VERSIONSTRING="$4"
	URL="$5"
	FILENAME="$(basename "$URL")"
	SUBDIRPATH="jpeg-$(echo "$TAG" | tr -d v)"

	gitrm
	gitclean
	geturl "$URL"
	unpacktar "$FILENAME"
	removefile "$FILENAME"
	movefilefromsubdir "$SUBDIRPATH"
	gitaddall
	gitcommitfull "$DATE" "$VERSIONSTRING" "$EMAIL" "$URL"
	gittag "$TAG"
}


if ! rm -rf repo; then fatal "can not remove repo directory";  fi
if ! mkdir repo; then fatal "cano not create repo directory"; fi

if ! pushd repo 1> /dev/null 2> /dev/null; then fatal "pushd to new repo directory failed"; fi
if ! git init -b master; then fatal "can not initialize git repository"; fi

if ! git checkout --orphan build; then fatal "can not checkout build branch"; fi
gitclean
createbuildscript
gitadd build.sh
gitcommitshort "Add script to build this git."

if ! git checkout --orphan master; then fatal "can not checkout master branch"; fi

v1 1991-10-07 v1 jpeg-info@uunet.uu.net "1" http://discmaster.textfiles.com/file/12465/floppyshareware.zip/floppyshareware/GLEN/JPEGSRC.ZIP

v2 1991-12-13 v2 jpeg-info@uunet.uu.net "2" "http://discmaster.textfiles.com/file/17025/Suzy%20B%20Software%20CD-ROM%202%20(1994).iso/programm/prog_a2m/jpsrc2/jpsrc2.zip"

generic1 1992-03-17 v3 jpeg-info@uunet.uu.net "3" http://ftp.csc.fi/pub/graphics/formats/jpeg/jpegsrc.v3.tar.Z
generic1 1992-12-10 v4 jpeg-info@uunet.uu.net "4" http://ftp.csc.fi/pub/graphics/formats/jpeg/jpegsrc.v4.tar.Z

generic2 1994-07-28 v5beta1 jpeg-info@uunet.uu.net "5 BETA TEST" http://ftp.csc.fi/pub/graphics/formats/jpeg/jpegsrc.v5beta1.tar.gz
generic2 1994-08-20 v5beta2 jpeg-info@uunet.uu.net "5 BETA TEST" https://cdimage.debian.org/mirror/slackware.com/slackware-2.3/source/ap/jpeg/jpegsrc.v5beta2.tar.gz
generic2 1994-09-24 v5 jpeg-info@uunet.uu.net "5" http://ftp.csc.fi/pub/graphics/formats/jpeg/jpegsrc.v5.tar.gz
generic2 1994-12-07 v5a jpeg-info@uunet.uu.net "5a" https://cdimage.debian.org/mirror/slackware.com/slackware-2.3/source/ap/jpeg/jpegsrc.v5a.tar.gz
generic2 1995-03-15 v5b jpeg-info@uunet.uu.net "5b" https://ftp.ddg.lth.se/pub/graphic/jpegsrc.v5b.tar.gz
generic2 1995-08-02 v6 jpeg-info@uunet.uu.net "6" http://ftp.csc.fi/pub/graphics/formats/jpeg/jpegsrc.v6.tar.gz
generic2 1996-02-07 v6a jpeg-info@uunet.uu.net "6a" https://www.ijg.org/files/jpegsrc.v6a.tar.gz
generic2 1998-02-27 v6b jpeg-info@uunet.uu.net "6b" https://www.ijg.org/files/jpegsrc.v6b.tar.gz
generic2 2009-06-27 v7 jpeg-info@uunet.uu.net "7" https://www.ijg.org/files/jpegsrc.v7.tar.gz
generic2 2010-01-10 v8 jpeg-info@uc.ag "8" https://www.ijg.org/files/jpegsrc.v8.tar.gz
generic2 2010-02-28 v8a jpeg-info@uc.ag "8a" https://www.ijg.org/files/jpegsrc.v8a.tar.gz
generic2 2010-05-16 v8b jpeg-info@uc.ag "8b" https://www.ijg.org/files/jpegsrc.v8b.tar.gz
generic2 2011-01-16 v8c jpeg-info@uc.ag "8c" https://www.ijg.org/files/jpegsrc.v8c.tar.gz
generic2 2014-01-19 v9a jpeg-info@jpegclub.org "9a" https://www.ijg.org/files/jpegsrc.v9a.tar.gz
generic2 2016-01-17 v9b jpeg-info@jpegclub.org "9b" https://www.ijg.org/files/jpegsrc.v9b.tar.gz
generic2 2018-01-14 v9c jpeg-info@jpegclub.org "9c" https://www.ijg.org/files/jpegsrc.v9c.tar.gz
generic2 2020-01-12 v9d jpeg-info@jpegclub.org "9d" https://www.ijg.org/files/jpegsrc.v9d.tar.gz
generic2 2022-01-16 v9e jpeg-info@jpegclub.org "9e" https://www.ijg.org/files/jpegsrc.v9e.tar.gz
generic2 2024-01-14 v9f jpeg-info@jpegclub.org "9f" https://www.ijg.org/files/jpegsrc.v9f.tar.gz

if ! popd 1> /dev/null 2> /dev/null; then fatal "popd from repo directory failed"; fi
echo "Finished successfully."
exit 0
