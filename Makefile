ASM   = nasm
QEMU  = qemu-system-x86_64
BIN   = bin

all: $(BIN)/mentha.img

$(BIN):
	mkdir -p $(BIN)

$(BIN)/boot.bin: boot.asm | $(BIN)
	$(ASM) -f bin boot.asm -o $@

$(BIN)/kernel.bin: kernel.asm | $(BIN)
	$(ASM) -f bin kernel.asm -o $@

$(BIN)/mentha.img: $(BIN)/boot.bin $(BIN)/kernel.bin | $(BIN)
	dd if=/dev/zero of=$@ bs=512 count=2880 status=none
	dd if=$(BIN)/boot.bin of=$@ conv=notrunc status=none
	dd if=$(BIN)/kernel.bin of=$@ seek=1 conv=notrunc status=none

run: $(BIN)/mentha.img
	$(QEMU) -drive format=raw,file=$(BIN)/mentha.img

clean:
	rm -rf $(BIN)

.PHONY: all run clean