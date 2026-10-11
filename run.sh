#!/bin/bash
set -e

mkdir -p bin

nasm -f bin boot.asm -o bin/boot.bin
nasm -f bin kernel.asm -o bin/kernel.bin

dd if=/dev/zero of=bin/mentha.img bs=512 count=2880 status=none
dd if=bin/boot.bin of=bin/mentha.img conv=notrunc status=none
dd if=bin/kernel.bin of=bin/mentha.img seek=1 conv=notrunc status=none

qemu-system-x86_64 -drive format=raw,file=bin/mentha.img