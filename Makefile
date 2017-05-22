AS        = arm-none-eabi-as
ASFLAGS   =
CC        = arm-none-eabi-gcc
CFLAGS    = -fno-stack-protector -fPIC -nostdlib
CPPFLAGS  =
AR        = arm-none-eabi-ar
ARFLAGS   =
LD        = arm-none-eabi-ld
LDFLAGS   =
OBJCOPY   = arm-none-eabi-objcopy

DESTDIR   =
PREFIX    = /usr/local
MANPREFIX = $(if $(subst /,,$(PREFIX)),$(PREFIX),/usr)
MAN5DIR   = $(MANPREFIX)/share/man/man5
MAN8DIR   = $(MANPREFIX)/share/man/man8
BUILDDIR  = build

SRCS      = $(wildcard src/*.c)
DEPS      = $(patsubst src/%,$(BUILDDIR)/%,$(addsuffix .d,$(SRCS)))

-include $(BUILDDIR)/Makefile.dep

# Dependencies

$(BUILDDIR)/Makefile.dep: $(DEPS)
	@mkdir -p $(dir $(@))
	@cat $^ > $@

$(BUILDDIR)/%.c.d: src/%.c
	@mkdir -p $(dir $(@))
	@$(CC) $(CPPFLAGS) -MG -MM $^ -MF $@ -MQ $(subst .c.d,.o,$@)

$(BUILDDIR)/%.o: src/%.c
	@mkdir -p $(dir $(@))
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

$(BUILDDIR)/%.o: src/%.s
	@mkdir -p $(dir $(@))
	$(AS) $< -o $@

$(BUILDDIR)/%.bin: $(BUILDDIR)/%.elf
	$(OBJCOPY) -O binary $< $@

# Targets

$(BUILDDIR)/kernel.elf: $(BUILDDIR)/init.o $(BUILDDIR)/test.o
	@mkdir -p $(dir $(@))
	$(LD) -T src/link.ld $^ -o $@

.PHONY: all
all: $(BUILDDIR)/kernel.bin

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)

.PHONY: run
run: all
	@echo "C-a x to exit."
	qemu-system-arm -M versatilepb -m 64M -nographic -kernel $(BUILDDIR)/kernel.bin

.PHONY: debug
debug: all
	@echo "Open another terminal and run:"
	@echo "$$ arm-none-eabi-gdb"
	@echo "> target remote localhost:1234"
	@echo "> file $(BUILDDIR)/kernel.elf"
	qemu-system-arm -M versatilepb -m 64M -nographic -s -S -kernel $(BUILDDIR)/kernel.bin

