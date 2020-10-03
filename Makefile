.PHONY: all
all: pget test-samples

.PHONY: pget
pget:
	@$(MAKE) -s ./bin/pget.com

.PHONY: test-samples
test-samples:
	@cp test.txt ./bin
	@cp short.txt ./bin

RELOCASSEMBLER=node ./apploader.js --page-align
ASSEMBLER=z80asm

ASS_FLAGS=-mz80 \
	-D__SDCC -D__SDCC_IY ${MEASURE} \
	-I"${ZCCCFG}/../../libsrc/_DEVELOPMENT/target/cpm" \
	-I"${ZCCCFG}/../../libsrc/_DEVELOPMENT/target/z80" \
	-I"${ZCCCFG}/../../libsrc/_DEVELOPMENT/target/hbios" \
	-I"${ZCCCFG}/../../lib" \
	-L. \
	-L"${ZCCCFG}/../../libsrc/_DEVELOPMENT/lib/sdcc_iy" \
	-lmath32 \
	-lcpm \
	-mz80 \
	-opt-speed

ZSDCPP_FLAGS=-iquote"." \
	-D__Z88DK -D__EMBEDDED -DEMBEDDED -D__EMBEDDED_Z80 -D__Z80 -DZ80 \
	${MEASURE} \
	-D__SDCC -D__SDCC_IY \
	-D__SDCC 						\
	-isystem"${ZCCCFG}/../../include/_DEVELOPMENT/sdcc"

ZCCRELFLAGS=

ifdef RELEASE
ZCCRELFLAGS=" -SO3 --max-allocs-per-node200000 -Cs\"--opt-code-speed\" --allow-unsafe-read"
endif

ZCCFLAGS="${ZCCRELFLAGS}"

include ./depends.d

get_sources = $(wildcard ./src/*.c) $(wildcard ./src/*.asm)
get_objects = ./src/memap.o ./relocmem.asm ./src/crt.o ./src/reloccrt.o ./src/cpm.o ./src/cpmasm.o ./src/hbios_cio.o ./src/hbios.o ./src/xstdio.o ./src/chartesters.o $(patsubst %.asm,%.o,$(patsubst %.c,%.o,$(get_sources)))

./bin/pget.com: $(get_objects)
	@mkdir -p ./bin
	@$(RELOCASSEMBLER) -o./bin/pget.com -b $(ASS_FLAGS) ./src/memap.o $(filter-out ./src/memap.o,$^)
	@echo "\nBuilt ./bin/pget.com"

#-DDIAGNOSTICS_ON
%.asm: %.c
	@zcc +embedded -subtype=none -lm -clib=sdcc_iy -vn -cleanup -m -S --list $< -o $@  -create-app  -Cs --Werror --c-code-in-asm $(ZCCFLAGS)
	@echo "compiled $< to $@"

%.o: %.asm
	@$(ASSEMBLER) -o$(basename $<).bin $(ASS_FLAGS) $(basename $<).asm
	@echo "Assembled $< to $@"

deps: SHELL := bash
deps:
	@echo "" > ./depends.d && \
	find -name "*.c" | while read -r file; do \
		file_no_ext="$${file%.*}" 							; \
		filename=$$(basename $$file_no_ext)			; \
		from="$$filename.rel"										; \
		to="$$file_no_ext.asm"									; \
		zsdcpp ${ZSDCPP_FLAGS} -MM -MF /tmp/deps.deps $$file; \
		sed "s+$$from+$$to+g" /tmp/deps.deps >> ./depends.d; \
	done && \
	echo "./depends.d created"


clean:
	@git clean -xf

.PHONY: format
format: SHELL:=/bin/bash
format:
	@cd src && find \( -name "*.c" -o -name "*.h" \) -exec echo "formating {}" \; -exec clang-format -i {} \;
