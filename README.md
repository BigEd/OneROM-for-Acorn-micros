# OneROM-for-Acorn-micros

A collection of notes and tools for using OneROM in Acorn microcomputers

see https://onerom.org/ for details on the product

Here's a dump of raw notes from our first session with the devices, which we might tidy up into a script.

observation of a little problem
 - if the device is powered by usb first and then the host, all is well
 - but if usb is disconnected and then reconnected (with power from the host) it isn't. At least on Mac.
symptom: no usb serial device appears
platforms: both linux and mac

slightly bigger problem but not really in practice
 - usb-c hub on the mac does not work at all

$ ./bin/onerom self check
One ROM CLI v0.5.0
A newer release is available: v0.6.0

Download it with:
  onerom self download
or from https://onerom.org/cli

$ ./bin/onerom self download

unzip onerom-cli-mac-0.6.0.zip

We have two flavours of device both for 28 pin DIP sockets
28C with horizontal USB-C socket
suits Beeb better - very limited vertical headroom under keyboard

28D with vertical USB socket
suits Master better - limited space to the right of the socket

For Beeb, we need to emulate the 27128 which is a 16K ROM
But we can load a selection of images into slots (only one active)
- MMFS
- MMFS2
(Ed already has a Boobip which has 4 by 16k active ROMs)

For Master, for the 8 image MegaROM, we need 271024
Again we can have several slots, selected by header jumpers at power up time
Each slot has a MOS and 7 sideways ROMs - at least one of which contains some MOS overflow

Setting up for the Beeb

$ ./bin/onerom scan --slots
Scanning ...
found 1 connected device:
---
One ROM Fire 28 C - Firmware: v0.7.3 State: Running Serial: 11F1[...]
  Plugins:
    One ROM USB
  Configured with 1 slot - Slot 0 is selected (active)
  Slot 0 (selected, active):
    Chip 0: 27512
      Image source: images/test/rand_64KB.rom

downloading MMFS release 1.61:
   wget https://github.com/hoglet67/MMFS/releases/download/mmfs_1_61_0/mmfs_1_61_20261023_1133.zip
   unzip -l mmfs_1_61_20261023_1133.zip
   mkdir -p mmfs/download
   mv mmfs_1_61_20261023_1133.zip mmfs/download/
   cd mmfs/
   mkdir 1.61
   cd 1.61
   unzip ../download/mmfs_1_61_20261023_1133.zip

and programming:
$ ./bin/onerom program --plugin usb --plugin rgb \
   --slot file=mmfs/1.61/MMFS/U/MMFS.rom,type=27128 \
   --slot file=mmfs/1.61/MMFS2/U/MMFS.rom,type=27128
Programming device - DO NOT DISCONNECT
Programming complete

$ ./bin/onerom control rgb on

$ ./bin/onerom scan --slots
Scanning ...
found 1 connected device:
---
One ROM Fire 28 C - Firmware: v0.8.1 State: Running Serial: 11F1[...]
  Plugins:
    One ROM USB
    One ROM RGB
  Configured with 2 slots - Slot 0 is selected (active)
  Slot 0 (selected, active):
    Chip 0: 27128
      Image source: mmfs/1.61/MMFS/U/MMFS.rom
  Slot 1:
    Chip 0: 27128
      Image source: mmfs/1.61/MMFS2/U/MMFS.rom

In fact the RGB plugin isn't helpful to us - it powers up into a colour cycling mode
and we can do without it

$ ./bin/onerom reboot
Rebooting device...
Rebooted device into running mode

Now to program up the Master version

the two vanilla master os megaroms
(with y2k patch)

   cd ../b2-for-os-roms
   mkdir download
   cd download/
   wget https://github.com/stardot/b-em/raw/refs/heads/master/roms/os/mos320p.rom
   wget https://github.com/stardot/b-em/raw/refs/heads/master/roms/os/mos350p.rom

we can program this up as an intermediate test

$ ./bin/onerom program \
   --plugin usb \
   --slot type=231024,cs1=0,file=b2-for-os-roms/download/mos320p.rom \
   --slot type=231024,cs1=0,file=b2-for-os-roms/download/mos350p.rom
Programming device - DO NOT DISCONNECT
Programming complete

$ ./bin/onerom scan --slots
Scanning ...
found 1 connected device:
---
One ROM Fire 28 D - Firmware: v0.8.1 State: Running Serial: 1E30[...]
  Plugins:
    One ROM USB
  Configured with 2 slots - Slot 0 is selected (active)
  Slot 0 (selected, active):
    Chip 0: 231024
      Image source: b2-for-os-roms/download/mos320p.rom
  Slot 1:
    Chip 0: 231024
      Image source: b2-for-os-roms/download/mos350p.rom


let's now patch in an mmfs because we have no floppy system

see
https://mdfs.net/Info/Comp/BBC/SROMs/MegaROM.htm
for replacement limitations

let's replace VIEWSHEET with MMFS in the vanilla 320 (and 350)
that's ROM slot 10
so it goes 8,9,10,...
so that's the third slot, which is slot 2 counting from zero

and we can do that with dd and notrunc onto a clean copy

   cp b2-for-os-roms/download/mos320p.rom patching-in-mmfs/
   dd bs=16k oseek=2 conv=notrunc if=mmfs/1.61/MMFS/U/MAMMFS.rom of=patching-in-mmfs/mos320p.rom
   cp b2-for-os-roms/download/mos350p.rom patching-in-mmfs/
   dd bs=16k oseek=2 conv=notrunc if=mmfs/1.61/MMFS/U/MAMMFS.rom of=patching-in-mmfs/mos350p.rom
   ./bin/onerom program --plugin usb \
     --slot type=231024,cs1=0,file=patching-in-mmfs/mos320p.rom \
     --slot type=231024,cs1=0,file=patching-in-mmfs/mos350p.rom
   ./bin/onerom scan --slots

we will also need tom seddon's improved ROMs which allow more substitutions and have some fixes
he's removed TERMINAL and put all the extra bits in there (ROM F)
he's left E empty, previously VIEW
he's removed VIEWSHEET from A and put in his BASIC EDITOR

Probably we want to move EDITOR to E
and put MMFS in A

let's program up his offering as-is:

   mkdir -p acorn_mos_refreshed/download
   cd acorn_mos_refreshed/download
   wget https://github.com/tom-seddon/acorn_mos_refreshed/releases/download/mos-refreshed-G/mos-refreshed-G.zip
   unzip mos-refreshed-G.zip

./bin/onerom program \
  --plugin usb \
  --slot type=231024,cs1=0,file=patching-in-mmfs/mos320p.rom \
  --slot type=231024,cs1=0,file=patching-in-mmfs/mos350p.rom \
  --slot type=231024,cs1=0,file=acorn_mos_refreshed/320G/320G.bin \
  --slot type=231024,cs1=0,file=acorn_mos_refreshed/350G/350G.bin
Programming device - DO NOT DISCONNECT
Programming complete

$ ./bin/onerom scan --slots
Scanning ...
found 1 connected device:
---
One ROM Fire 28 D - Firmware: v0.8.1 State: Running Serial: 1E30[...]
  Plugins:
    One ROM USB
  Configured with 4 slots - Slot 1 is selected (active)
  Slot 0:
    Chip 0: 231024
      Image source: patching-in-mmfs/mos320p.rom
  Slot 1 (selected, active):
    Chip 0: 231024
      Image source: patching-in-mmfs/mos350p.rom
  Slot 2:
    Chip 0: 231024
      Image source: acorn_mos_refreshed/320G/320G.bin
  Slot 3:
    Chip 0: 231024
      Image source: acorn_mos_refreshed/350G/350G.bin

now we can patch in mmfs, also BE (basic editor) into a different slot
for both 320 and 350

   cp acorn_mos_refreshed/320G/320G.bin patching-in-mmfs/
   dd bs=16k count=1 oseek=6 conv=notrunc if=acorn_mos_refreshed/320G/roms/10.basiced.1.4.rom of=patching-in-mmfs/320G.bin
   dd bs=16k count=1 oseek=2 conv=notrunc if=mmfs/1.61/MMFS/U/MAMMFS.rom  of=patching-in-mmfs/320G.bin

   cp acorn_mos_refreshed/350G/350G.bin patching-in-mmfs/
   dd bs=16k count=1 oseek=6 conv=notrunc if=acorn_mos_refreshed/350G/roms/10.rbasiced.1.46.rom of=patching-in-mmfs/350G.bin
   dd bs=16k count=1 oseek=2 conv=notrunc if=mmfs/1.61/MMFS/U/MAMMFS.rom  of=patching-in-mmfs/350G.bin

   ./bin/onerom program --plugin usb \
     --slot type=231024,cs1=0,file=patching-in-mmfs/mos320p.rom \
     --slot type=231024,cs1=0,file=patching-in-mmfs/mos350p.rom \
     --slot type=231024,cs1=0,file=patching-in-mmfs/320G.bin \
     --slot type=231024,cs1=0,file=patching-in-mmfs/350G.bin

and that seems to have worked well
350 has the advantage of relocating languages to make high versions on the tube side

what have we lost
TERMINAL
VIEW
VIEWSHEET

what have we gained
BASIC EDITOR
MMFS

what have we retained
EDIT because some Acornsoft languages need it

we don't yet have a version with VFS - that's useful because Pi1MHz Domesday needs all SWRAM slots for itself
in that use case MMFS is not needed

so a domesday build would have VFS instead of MMFS

and we put that in slot 4

   mkdir domesday
   cp b2-for-os-roms/download/mos320p.rom domesday/
   mkdir -p Pi1MHz/download
   cd Pi1MHz/download
   wget https://github.com/dp111/Pi1MHz/raw/refs/heads/master/firmware/Pi1MHz/VFS.rom
   cd ../..
   dd bs=16k count=1 oseek=2 conv=notrunc if=mmfs/1.61/MMFS/U/MAMMFS.rom  of=patching-in-mmfs/350G.bin
   dd bs=16k count=1 oseek=2 conv=notrunc if=Pi1MHz/download/VFS.rom  of=domesday/mos320p.rom
   ./bin/onerom program --plugin usb \
     --slot type=231024,cs1=0,file=patching-in-mmfs/mos320p.rom \
     --slot type=231024,cs1=0,file=patching-in-mmfs/mos350p.rom \
     --slot type=231024,cs1=0,file=patching-in-mmfs/320G.bin \
     --slot type=231024,cs1=0,file=patching-in-mmfs/350G.bin \
     --slot type=231024,cs1=0,file=domesday/mos320p.rom

$ ./bin/onerom scan --slots
Scanning ...
found 1 connected device:
---
One ROM Fire 28 D - Firmware: v0.8.1 State: Running Serial: 1E30[...]
  Plugins:
    One ROM USB
  Configured with 5 slots - Slot 3 is selected (active)
  Slot 0:
    Chip 0: 231024
      Image source: patching-in-mmfs/mos320p.rom
  Slot 1:
    Chip 0: 231024
      Image source: patching-in-mmfs/mos350p.rom
  Slot 2:
    Chip 0: 231024
      Image source: patching-in-mmfs/320G.bin
  Slot 3 (selected, active):
    Chip 0: 231024
      Image source: patching-in-mmfs/350G.bin
  Slot 4:
    Chip 0: 231024
      Image source: domesday/mos320p.rom

and this seems to work
