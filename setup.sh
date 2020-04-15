apt update
apt-get install -y build-essential liblzma-dev gcc-aarch64-linux-gnu
sudo apt-get install gcc-aarch64-linux-gnu
apt-get install lib32z1-dev
apt-get install libiberty-dev
set -e
mkdir -p build/ipxe
git clone https://github.com/ipxe/ipxe.git ipxe_build
git clone https://github.com/duc5e/iso-ipxe.git ipxe
apt-get -y install nasm
apt-get -y install uuid-dev
cd /usr/local/src/
wget https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/Testing/6.04/syslinux-6.04-pre1.tar.gz
tar zxf syslinux-6.04-pre1.tar.gz
cd syslinux-6.04-pre1
make && make install
cp ipxe/local/* ipxe_build/src/config/local/
cp ipxe/* ipxe_build/src
cd ipxe_build/src
IPXE_HASH=`git log -n 1 --pretty=format:"%H"`
make bin/ipxe.dsk bin/ipxe.iso bin/ipxe.lkrn bin/ipxe.usb bin/ipxe.kpxe bin/undionly.kpxe EMBED=/root/ipxe/disks/duc.pw TRUST=ca.crt,ipxe.crt ISOLINUX_BIN=isolinux.bin LDLINUX_C32=ldlinux.c32
mv bin/ipxe.dsk /root/build/ipxe/duc.pw.dsk
mv bin/ipxe.iso /root/build/ipxe/duc.pw.iso
mv bin/ipxe.lkrn /root/build/ipxe/duc.pw.lkrn
mv bin/ipxe.usb /root/build/ipxe/duc.pw.usb
mv bin/ipxe.kpxe /root/build/ipxe/duc.pw.kpxe
mv bin/undionly.kpxe /root/build/ipxe/duc.pw-undionly.kpxe

make bin/ipxe.usb CONFIG=cloud EMBED=/root/ipxe/disks/duc.pw-gce \
TRUST=ca.crt,ipxe.crt
cp -f bin/ipxe.usb disk.raw
tar Sczvf duc.pw-gce.tar.gz disk.raw
mv duc.pw-gce.tar.gz /root/build/ipxe/duc.pw-gce.tar.gz

make bin/undionly.kpxe \
EMBED=/root/ipxe/disks/duc.pw-packet TRUST=ca.crt,ipxe.crt
mv bin/undionly.kpxe /root/build/ipxe/duc.pw-packet.kpxe

cp config/local/general.h.efi config/local/general.h
make clean
make bin-x86_64-efi/ipxe.efi \
EMBED=/root/ipxe/disks/duc.pw TRUST=ca.crt,ipxe.crt
mkdir -p efi_tmp
dd if=/dev/zero of=efi_tmp/ipxe.img count=2880
mformat -i efi_tmp/ipxe.img -m 0xf8 -f 2880
mmd -i efi_tmp/ipxe.img ::efi ::efi/boot
mcopy -i efi_tmp/ipxe.img bin-x86_64-efi/ipxe.efi ::efi/boot/bootx64.efi
genisoimage -o ipxe.eiso -eltorito-alt-boot -e ipxe.img -no-emul-boot efi_tmp
mv bin-x86_64-efi/ipxe.efi /root/build/ipxe/duc.pw.efi
mv ipxe.eiso /root/build/ipxe/duc.pw-efi.iso

sed -i '/WORKAROUND_CFLAGS/d' arch/arm64/Makefile

make clean
make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 \
EMBED=/root/ipxe/disks/duc.pw TRUST=ca.crt,ipxe.crt \
bin-arm64-efi/snp.efi
mv bin-arm64-efi/snp.efi /root/build/ipxe/duc.pw-arm64.efi

make clean
make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 \
EMBED=/root/ipxe/disks/duc.pw-packet TRUST=ca.crt,ipxe.crt \
bin-arm64-efi/snp.efi
mv bin-arm64-efi/snp.efi /root/build/ipxe/duc.pw-packet-arm64.efi

cp config/local/nap.h.efi config/local/nap.h
cp config/local/usb.h.efi config/local/usb.h
make clean
make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 \
EMBED=/root/ipxe/disks/duc.pw TRUST=ca.crt,ipxe.crt \
bin-arm64-efi/snp.efi
mv bin-arm64-efi/snp.efi /root/build/ipxe/duc.pw-arm64-experimental.efi
