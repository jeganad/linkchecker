# This Makefile is only used by developers.
# You will need a Debian Linux system to use this Makefile because
# some targets produce Debian .deb packages
VERSION=$(shell ./setup.py --version)
PACKAGE=linkchecker
NAME=$(shell ./setup.py --name)
HOST=treasure.calvinsplayground.de
#LCOPTS=-ocolored -Ftext -Fhtml -Fgml -Fsql -Fcsv -Fxml -R -t0 -v -s
LCOPTS=-ocolored -Ftext -Fhtml -Fgml -Fsql -Fcsv -Fxml -R -t0 -v -s
OFFLINETESTS = test_base test_misc test_file test_frames
ONLINETESTS = test_mail test_http test_https test_news test_ftp

DESTDIR=/.
.PHONY: test clean distclean package files upload dist locale all

all:
	@echo "Read the file INSTALL to see how to build and install"

clean:
	-./setup.py clean --all # ignore errors of this command
	$(MAKE) -C po clean
	find . -name '*.py[co]' | xargs rm -f

distclean: clean cleandeb
	rm -rf dist build # just to be sure clean also the build dir
	rm -f $(PACKAGE)-out.* VERSION _$(PACKAGE)_configdata.py MANIFEST Packages.gz

cleandeb:
	rm -rf debian/$(PACKAGE) debian/$(PACKAGE)-ssl debian/tmp
	rm -f debian/*.debhelper debian/{files,substvars}
	rm -f configure-stamp build-stamp

dist:	locale
	./setup.py sdist --formats=gztar,zip bdist_rpm
	# extra run without SSL compilation
	python setup.py bdist_wininst

deb:
	# cleandeb because distutils choke on dangling symlinks
	# (linkchecker.1 -> undocumented.1)
	$(MAKE) cleandeb
	fakeroot debian/rules binary
	fakeroot dpkg-buildpackage -sgpg -pgpg -k959C340F

packages:
	-cd .. && dpkg-scanpackages . | gzip --best > Packages.gz

sources:
	-cd .. && dpkg-scansources  . | gzip --best > Sources.gz

files:	locale
	env http_proxy="" ./$(PACKAGE) $(LCOPTS) -i$(HOST) http://$(HOST)/~calvin/

VERSION:
	echo $(VERSION) > VERSION

upload: distclean dist files VERSION
	scp debian/changelog shell1.sourceforge.net:/home/groups/$(PACKAGE)/htdocs/changes.txt
	scp README shell1.sourceforge.net:/home/groups/$(PACKAGE)/htdocs/readme.txt
	scp linkchecker-out.* shell1.sourceforge.net:/home/groups/$(PACKAGE)/htdocs
	scp VERSION shell1.sourceforge.net:/home/groups/$(PACKAGE)/htdocs/raw/
	scp dist/* shell1.sourceforge.net:/home/groups/ftp/pub/$(PACKAGE)/
	ssh -C -t shell1.sourceforge.net "cd /home/groups/$(PACKAGE) && make"

test:
	python2 test/regrtest.py $(OFFLINETESTS)

onlinetest:
	python2 test/regrtest.py $(ONLINETESTS)

locale:
	$(MAKE) -C po
