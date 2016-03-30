# SPDX-License-Identifier: BSD-2-Clause
# 
# Copyright (c) 2015-2018 Colin Rothwell
# Copyright (c) 2015-2018 A. Theodore Markettos
# 
# This software was developed by SRI International and the University of
# Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-10-C-0237
# ("CTSRD"), as part of the DARPA CRASH research programme.
# 
# We acknowledge the support of EPSRC.
# 
# We acknowledge the support of Arm Ltd.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

POSTGRES ?= 0
TARGET ?= BERI
#POSTGRES ?= 1
#TARGET ?= NATIVE
SEP :=, 
TARGETS = BERI$(SEP)NATIVE

# Remove instances of SEP from the TARGET, then search for TARGET follwed by
# SEP in the list of TARGETS followed by SEP to guarentee that an exact match
# for TARGET is in the TARGET list.
ifeq (,$(findstring $(filter-out $(SEP), $(TARGET))$(SEP), $(TARGETS)$(SEP)))
$(error $(TARGET) is not a valid target: choices are $(TARGETS))
endif

LDFLAGS := -static #-target mips64-unknown-freebsd #-G0
LDFLAGS := $(LDFLAGS) --sysroot=/home/cr437/cheri-sdk/my-freebsd-root
LIBS := glib-2.0 pixman-1
LDLIBS := -lthr -lm -lz

ifeq ($(TARGET),BERI)
$(info Building for BERI)
SDK = /home/cr437/cheri-sdk/sdk
CC = $(SDK)/bin/clang
OBJDUMP = $(SDK)/bin/objdump
#CC=/home/cr437/cheri-sdk/sdk/bin/gcc
EXTRA_USR=/home/cr437/iommu/iommu/beri-fake-peripherals/usr
CFLAGS := $(addprefix "-I$(EXTRA_USR)/local/include/",$(LIBS))
#CFLAGS := $(CFLAGS) --target=mips64-unknown-freebsd
CFLAGS := $(CFLAGS) --sysroot=/home/cr437/cheri-sdk/my-freebsd-root
CFLAGS := $(CFLAGS) -I$(EXTRA_USR)/local/lib/glib-2.0/include
CFLAGS := $(CFLAGS) -DTARGET=TARGET_BERI -femulated-tls # -G0 -mxgot
LDFLAGS := $(LDFLAGS) -L$(EXTRA_USR)/local/lib
LDLIBS := -lpixman-1 -lpcre -lglib-2.0 -lutil -liconv -lintl $(LDLIBS)
else ifeq ($(TARGET),NATIVE)
$(info Building native)
CC = clang
CFLAGS := $(shell pkg-config --cflags $(LIBS))
CFLAGS := $(CFLAGS) -DTARGET=TARGET_NATIVE
LDLIBS := $(LDLIBS) $(shell pkg-config --libs $(LIBS)) -lutil 
ifeq ($(POSTGRES), 1)
CFLAGS := $(CFLAGS) -I$(shell pg_config --includedir)
LDFLAGS := $(LDFLAGS) -L$(shell pg_config --libdir)
LDLIBS := $(LBLIBS) -lintl -lssl -lcrypto -lpq
endif #POSTGRES
endif

CFLAGS := $(CFLAGS) -g -O2
CFLAGS := $(CFLAGS) -Itcg/tci -Islirp
#CFLAGS := $(CFLAGS) -ferror-limit=1
CFLAGS := $(CFLAGS) -I. -Ihw/net -Ilinux-headers -Itarget-i386 -Itcg
CFLAGS := $(CFLAGS) -Ix86_64-softmmu -Ihw/core -Ii386-softmmu
CFLAGS := $(CFLAGS) -D NEED_CPU_H -D TARGET_X86_64 -D CONFIG_BSD
# NEED_CPU_H to stop poison...
#CFLAGS := $(CFLAGS) -Wno-error=initializer-overrides
CFLAGS := $(CFLAGS) -D_GNU_SOURCE # To pull in pipe2 -- seems dodgy

DONT_FIND_TEMPLATES := $(shell grep "include \".*\.c\"" -Roh . | sort | uniq | sed 's/include /! -name /g')
SOURCES := $(shell find . -name "*.c" $(DONT_FIND_TEMPLATES))
O_FILES := $(SOURCES:.c=.o)
HEADERS := $(shell find . -name "*.h")

test: test.o $(O_FILES)

test.dump: test
	$(OBJDUMP) -ChdS $< > $@

.PHONY: clean
clean:
	rm -f $(shell find . -name "*.o")
