# Image BBS 3.0 build
#
#   make asm      assemble source/*.s with KickAssembler    -> build/asm/
#   make basic    build core/*.lbl with C64List             -> build/basic/
#   make tests    build core/tests/*.lbl with C64List       -> build/tests/
#   make disk     copy the release boot disk (Disk 1) and replace the
#                 files listed in disk.manifest              -> build/image30.d81
#   make clean    remove build/
#
# Override any of these on the command line, e.g. make KICKASS=/path/KickAss.jar

KICKASS     ?= $(HOME)/bin/KickAssembler/KickAss.jar
JAVA        ?= java
# C64List 4.04: 4.06 rejects the numeric {assign:} labels in 3_0-preface.lbl
C64LIST     ?= $(HOME)/bin/c64list4_04.exe
WINE        ?= wine
C1541       ?= c1541
# 8-Bit Boyz release 231231: its Disk 1 is the starting point for the boot disk
RELEASE_ZIP ?= $(HOME)/Documents/c64/image30-231231.zip
RELEASE_D81 ?= MASTER D1 231231.d81
# chr/scn/col.imagelogo for image.prg ("image 3.0"); copied from Image 2.0's contrib/
LOGO_DIR    ?= source

BUILD := build
DISK  := $(BUILD)/image30.d81

# wine prints a lot of debug noise; C64List needs Windows-style paths for output
RUN_C64LIST = WINEDEBUG=-all $(WINE) $(C64LIST)
winpath = Z:$(abspath $(1))

.PHONY: all asm basic tests disk clean

all: asm basic tests

# ---------------------------------------------------------------------------
# Assembly (KickAssembler)

ASM_TARGETS := ml boot image rs232 post path tagscan net punter xmodem \
               copier clock menu2 sort
ASM_PRGS    := $(ASM_TARGETS:%=$(BUILD)/asm/%.prg)

ML_PARTS := wedge editor gc ecs struct swap1 swap2 swap3 jmptb strio mcicm \
            chrio dskio irqhn setup varbl miscl shdlr modem calls intro

asm: $(ASM_PRGS)

$(BUILD)/asm:
	mkdir -p $@

# -o: output file (KickAssembler 5.25 takes it relative to the current
# directory, not -odir); -odir: where the .sym file goes; -libdir: where
# .import finds files, so rs232.s can find rs232_user.prg and rs232_swift.prg
$(BUILD)/asm/%.prg: source/%.s source/equat.s | $(BUILD)/asm
	$(JAVA) -jar $(KICKASS) $< -odir $(abspath $(BUILD)/asm) -o $(abspath $@) \
		-libdir $(abspath $(BUILD)/asm) -libdir $(abspath $(LOGO_DIR))

$(BUILD)/asm/ml.prg: $(ML_PARTS:%=source/%.s) source/stamp.s
$(BUILD)/asm/rs232.prg: $(BUILD)/asm/rs232_user.prg $(BUILD)/asm/rs232_swift.prg

# the current git commit, shown as the ML version string
source/stamp.s: FORCE
	echo '.var version_string ="'`git log -1 --format='%H' | cut -c 1-16`'"' > $@

$(BUILD)/asm/image.prg: $(addprefix $(LOGO_DIR)/,chr.imagelogo scn.imagelogo col.imagelogo)

.PHONY: FORCE
FORCE:

# ---------------------------------------------------------------------------
# BASIC (C64List)
#
# Several .lbl names contain spaces, which make can't use as targets, so
# these are shell loops: each file is rebuilt only if its .lbl is newer.
# Modules that fail to build are reported, and the loop carries on.
# C64List 4.04 ignores {crunch:on}, so -crunch is passed for files that use it.

define build_lbl_dir
	@mkdir -p $(2); fail=0; \
	for f in $(1)/*.lbl; do \
		b=$$(basename "$$f" .lbl); \
		case "$$b" in 3_0-preface|quoters) continue;; esac; \
		out="$(2)/$$b.prg"; \
		[ "$$out" -nt "$$f" ] && [ "$$out" -nt core/3_0-preface.lbl ] && continue; \
		echo "C64List: $$f"; \
		crunch=; grep -q -i '{crunch:on}' "$$f" && crunch=-crunch; \
		( cd "$$(dirname "$$f")" && $(RUN_C64LIST) "$$b.lbl" -prg:"$(call winpath,$(2))/$$b.prg" $$crunch -ovr ) \
			> "$(2)/$$b.log" 2>&1 \
			|| { echo "  FAILED: see $(2)/$$b.log"; rm -f "$$out"; fail=1; }; \
	done; \
	[ $$fail = 0 ] || echo "Some files failed to build (listed above)."
endef

basic:
	$(call build_lbl_dir,core,$(BUILD)/basic)

tests:
	$(call build_lbl_dir,core/tests,$(BUILD)/tests)

# ---------------------------------------------------------------------------
# Boot disk (VICE c1541)
#
# disk.manifest lists, one per line, separated by tabs:
#   <file under build/>   <C64 filename on the disk>
# Each file replaces the release disk's file of that name (or is added).

disk:
	@test -f "$(RELEASE_ZIP)" || { echo "Release zip not found: $(RELEASE_ZIP)"; exit 1; }
	@mkdir -p $(BUILD)
	unzip -p "$(RELEASE_ZIP)" "$(RELEASE_D81)" > $(DISK)
	@grep -v -e '^#' -e '^[[:space:]]*$$' disk.manifest | \
	while IFS='	' read -r file name; do \
		if [ ! -f "$(BUILD)/$$file" ]; then echo "  skipped (not built): $$file"; continue; fi; \
		echo "  $$file -> \"$$name\""; \
		$(C1541) -attach $(DISK) -delete "$$name" -write "$(BUILD)/$$file" "$$name" > /dev/null 2>&1 \
			|| { echo "  c1541 failed for $$file"; exit 1; }; \
	done
	@$(C1541) -attach $(DISK) -list 2>/dev/null | tail -1

clean:
	rm -rf $(BUILD)
