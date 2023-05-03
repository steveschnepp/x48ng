# Makefile to build x48ng without autotools

CC = gcc

CFLAGS = -g -O2
LIBS = -lm -lhistory -lreadline

#possible values: x11, sdl1
GUI = x11

ifeq ($(GUI), x11)
	CFLAGS += -D 'GUI_IS_X11 = 1'
	LIBS += -lX11 -lXext
endif
ifeq ($(GUI), sdl1)
	CFLAGS += $(shell pkg-config --cflags SDL_gfx readline sdl12_compat) -D 'GUI_IS_SDL1 = 1'
	LIBS += $(shell pkg-config --libs SDL_gfx readline sdl12_compat)
endif

FULL_WARNINGS = no
ifeq ($(FULL_WARNINGS), yes)
	CFLAGS += -Wall -Wextra -Wno-unused-parameter -Wno-unused-function -Wconversion -Wdouble-promotion -Wno-sign-conversion -fsanitize=undefined -fsanitize-trap
endif

.PHONY: all clean clean-all pretty-code install

all: mkcard checkrom dump2rom x48ng

# Binaries
mkcard: src/mkcard.o
	$(CC) $(CFLAGS) $(LIBS) $^ -o $@

dump2rom: src/dump2rom.o
	$(CC) $(CFLAGS) $(LIBS) $^ -o $@

checkrom: src/checkrom.o src/romio.o
	$(CC) $(CFLAGS) $(LIBS) $^ -o $@

x48ng: src/main.o src/actions.o src/debugger.o src/device.o src/disasm.o src/emulate.o src/errors.o src/init.o src/lcd.o src/memory.o src/register.o src/resources.o src/romio.o src/rpl.o src/serial.o src/timer.o src/x48.o src/options.o src/resources.o
	$(CC) $(CFLAGS) $(LIBS) $^ -o $@

# Cleaning
clean:
	rm -f src/*.o

clean-all: clean
	rm -f x48ng mkcard checkrom dump2rom

# Formatting
pretty-code:
	clang-format -i src/*.c src/*.h

# Installing
PREFIX = /usr
DOCDIR = $(PREFIX)/doc/x48ng
MANDIR = $(PREFIX)/man
install: all
	install -m 755 -d -- $(DESTDIR)$(PREFIX)/bin
	install -c -m 755 x48ng $(DESTDIR)$(PREFIX)/bin/x48ng

	install -m 755 -d -- $(DESTDIR)$(PREFIX)/share/x48ng
	install -c -m 755 mkcard $(DESTDIR)$(PREFIX)/share/x48ng/mkcard
	install -c -m 755 dump2rom $(DESTDIR)$(PREFIX)/share/x48ng/dump2rom
	install -c -m 755 checkrom $(DESTDIR)$(PREFIX)/share/x48ng/checkrom
	install -c -m 644 hplogo.png $(DESTDIR)$(PREFIX)/share/x48ng/hplogo.png
	cp -R ROMs/ $(DESTDIR)$(PREFIX)/share/x48ng/
	find $(DESTDIR)$(PREFIX)/share/x48ng/ROMs/ -name "*.bz2" -exec bunzip2 {} \;
	sed "s|@PREFIX@|$(PREFIX)|g" setup-x48ng-home.sh > $(DESTDIR)$(PREFIX)/share/x48ng/setup-x48ng-home.sh
	chmod 755 $(DESTDIR)$(PREFIX)/share/x48ng/setup-x48ng-home.sh

	install -m 755 -d -- $(DESTDIR)$(MANDIR)/man1
	install -c -m 644 x48ng.man.1 $(DESTDIR)$(MANDIR)/man1/x48ng.1
	gzip -9  $(DESTDIR)$(MANDIR)/man1/x48ng.1

	install -m 755 -d -- $(DESTDIR)$(DOCDIR)
	cp -R AUTHORS COPYING ChangeLog* LICENSE README* doc/ romdump/ $(DESTDIR)$(DOCDIR)

	install -m 755 -d -- $(DESTDIR)$(PREFIX)/share/applications
	sed "s|@PREFIX@|$(PREFIX)|g" x48ng.desktop > $(DESTDIR)$(PREFIX)/share/applications/x48ng.desktop

	install -m 755 -d -- $(DESTDIR)/etc/X11/app-defaults
	install -c -m 644 X48NG.ad $(DESTDIR)/etc/X11/app-defaults/X48NG
