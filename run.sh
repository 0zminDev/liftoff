make clean # for some reason second .rus.sh give build error without it
make
qemu-system-i386 -fda build/main_floppy.img
