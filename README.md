# 0DOS

**A tiny x86 bootloader + kernel, built from scratch in assembly (and eventually C), for the joy of understanding how a computer actually wakes up.**

[![CI/CD](https://github.com/0zminDev/liftoff/actions/workflows/ci.yml/badge.svg)](https://github.com/0zminDev/liftoff/actions/workflows/ci.yml)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Made with NASM](https://img.shields.io/badge/asm-NASM-orange.svg)](https://www.nasm.us/)
[![Status: learning project](https://img.shields.io/badge/status-learning%20project-yellow.svg)](#-disclaimer)

---

## ⚠️ Disclaimer

**0DOS is a learning project, not a production operating system.**

It exists so I can understand real mode, protected mode, FAT12, and the boot
process from the ground up — not to compete with Linux, Windows, or anything
else that runs on real hardware people depend on. Expect bugs, dead ends,
half-finished features, and code that gets rewritten as I learn more.

That said, it's built and maintained the way a "real" open source project
would be: a real license, a real contribution process, and a real code of
conduct. If you're learning OS development too, dig in, fork it, break it,
and open a PR.

This project follows the structure and ideas taught in
[**nanobyte_os**](https://github.com/nanobyte-dev/nanobyte_os), the excellent
"Building an OS" tutorial series from the
[Nanobyte YouTube channel](https://www.youtube.com/@nanobyte_dev). 0DOS is
**not affiliated with or endorsed by Nanobyte** — it's an independent,
from-scratch implementation written while following along with (and
diverging from) that series. Huge thanks to Nanobyte for teaching this stuff
so well. See [Acknowledgments](#-acknowledgments) below.

---

## ✨ What is 0DOS?

0DOS is a two-stage x86 bootloader with its own minimal kernel, currently
targeting **BIOS/legacy boot on a FAT12 floppy image**, run under QEMU
(`qemu-system-i386`).

The long-term goal is for 0DOS's bootloader to grow into a small, general
purpose **boot manager**: something that can chainload other operating
systems' loaders (Windows' `BOOTMGR`, a Linux distro's GRUB/kernel image,
and — where technically and legally possible — a macOS EFI loader) in
addition to booting 0DOS's own kernel. This is aspirational and a big part
of *why* the project exists: it forces you to actually understand the boot
protocols other systems use instead of only your own.

### Current state

- [x] Stage 1 bootloader (fits in the boot sector, FAT12-aware)
- [x] Reads Stage 2 off a FAT12 floppy image via BIOS INT 13h
- [x] Stage 2 loads and jumps into a kernel binary
- [x] Minimal kernel stub (prints to screen via BIOS video interrupts)
- [x] Build pipeline producing a bootable `main_floppy.img` for QEMU

### Roadmap

- [ ] Protected mode (GDT setup, A20 line, 32-bit jump)
- [ ] [Multiboot Specification](https://www.gnu.org/software/grub/manual/multiboot/multiboot.html)
      compliance, so 0DOS can be loaded by GRUB and other Multiboot-compliant
      bootloaders (and so its own bootloader can load Multiboot kernels)
- [ ] Port stage2 boot logic from asm to C (16-bit, via OpenWatcom)
- [ ] Basic memory management / paging
- [ ] Chainloading support:
  - [ ] Linux (handing off to an existing GRUB/vmlinuz chain)
  - [ ] Windows (chainloading `BOOTMGR`)
  - [ ] macOS (best-effort — EFI-only on modern hardware, may not be feasible on real BIOS boot)
- [ ] UEFI boot path (separate from the legacy BIOS path above)
- [ ] A genuinely useful 0DOS kernel (shell, drivers, the works — someday)

None of this is promised on a timeline. This is a nights-and-weekends
learning project.

---

## 🧱 Project structure

```
liftoff/
├── Makefile                     # top-level build orchestration
├── run.sh                       # build + boot in QEMU
├── build/                       # build artifacts (gitignored, except .gitkeep)
└── src/
    ├── bootloader/
    │   ├── stage1/               # boot sector: fits in 512 bytes, FAT12-aware
    │   │   ├── stage1.asm
    │   │   ├── main.asm
    │   │   ├── load_stage_2.asm
    │   │   ├── data/              # FAT12 BPB header, static data
    │   │   └── utils/              # disk I/O, stdio, error handling helpers
    │   └── stage2/               # loaded by stage1, sets up + jumps to kernel
    │       └── stage2.asm
    └── kernel/                    # the "OS" itself (currently a stub)
        └── main.asm
```

The repo is called `liftoff` on GitHub; the operating system it builds is
**0DOS** (the floppy image volume label is `ODOS`).

---

## 🛠️ Building & running

### Prerequisites

You'll need a Linux (or WSL) environment with:

| Tool | Purpose |
|---|---|
| [`nasm`](https://www.nasm.us/) | Assembling the bootloader and kernel |
| `gcc` | Host tooling |
| [OpenWatcom `wcc`/`wlink`](https://github.com/open-watcom/open-watcom-v2) | 16-bit C compilation (future stage2/kernel-in-C work) |
| `dd` | Writing the boot sector onto the floppy image |
| `mkfs.fat` (dosfstools) | Formatting the floppy image as FAT12 |
| `mtools` (`mcopy`) | Copying files into the FAT12 image without mounting it |
| [`qemu-system-i386`](https://www.qemu.org/) | Running the resulting image |

### Build

```sh
make clean
make
```

This produces `build/main_floppy.img` — a 1.44MB floppy image containing:

- the stage 1 bootloader written directly to the boot sector
- `stage2.bin` and `kernel.bin` copied into the FAT12 filesystem

### Run

```sh
./run.sh
```

which is equivalent to:

```sh
make clean && make
qemu-system-i386 -fda build/main_floppy.img
```

You should see stage2 and the kernel each print their own hello-world banner
to the emulated screen.

---

## 🚦 CI/CD

Every push is built automatically via [GitHub Actions](.github/workflows/ci.yml):

- **Any branch** — the bootloader, kernel, and floppy image are built with
  `make` to catch compile errors early. Build artifacts (`main_floppy.img`,
  `stage1.bin`, `stage2.bin`, `kernel.bin`) are uploaded for every run.
- **`master` only** — after a successful build, the pipeline computes the
  next [semantic version](https://semver.org/) (`vMAJOR.MINOR.PATCH`, based
  on the latest existing git tag), tags the commit, and publishes a
  [GitHub Release](https://github.com/0zminDev/liftoff/releases) with the
  built image and binaries attached.

Versioning is automatic and patch-only for now (no automated major/minor
bumps) — bump those manually by pushing a tag like `v1.0.0` ahead of a
`master` push if a bigger version jump is warranted.

---

## 🤝 Contributing

Contributions, questions, and "why did you do it this way" issues are all
welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow, coding
style, and commit conventions used in this repo.

Please also read the [Code of Conduct](CODE_OF_CONDUCT.md) before
participating.

---

## 📜 License

0DOS is licensed under the **GNU General Public License v3.0 (GPL-3.0)**.
See [LICENSE](LICENSE) for the full text.

In short: you're free to use, study, modify, and redistribute this code,
including commercially, as long as any distributed derivative work is also
licensed under GPL-3.0 (or a compatible license) with source made available.
There is no warranty of any kind.

### Why GPLv3, and how it differs from GPLv2

GPL comes in a few flavors that get compared a lot, so here's the short
version of why v3 was chosen for this project:

| | GPLv2 (1991) | GPLv3 (2007) |
|---|---|---|
| **Patent grants** | No explicit patent language | Explicit patent license + patent-retaliation clause: contributors can't sue users for patent infringement on their own contributions |
| **Tivoization** | Not addressed | Requires that if GPLv3 code ships on consumer hardware, the hardware must let you install *modified* versions of that code ("anti-tivoization") |
| **DRM / anti-circumvention** | Not addressed | Explicitly states GPLv3 code isn't a "technological protection measure" under laws like the DMCA |
| **License compatibility** | Notably incompatible with some other free licenses (e.g. Apache 2.0) | Designed to be compatible with more licenses, including Apache 2.0 |
| **Internationalization** | US-centric legal language | Rewritten with more internationally portable legal terms |
| **"or later version"** | Code marked "v2 or later" can be upgraded to v3 by downstream users | N/A |

0DOS is licensed strictly as **GPL-3.0** (not "v3 or later") — see
[LICENSE](LICENSE). GPLv3 was chosen mainly for the anti-tivoization and
explicit patent-retaliation clauses, which feel appropriate for
boot-level/firmware-adjacent code that could otherwise end up locked onto
hardware in ways the original GPL didn't anticipate.

---

## 🙏 Acknowledgments

- [**nanobyte_os**](https://github.com/nanobyte-dev/nanobyte_os) and the
  [Nanobyte YouTube channel](https://www.youtube.com/@nanobyte_dev) — the
  "Building an OS" series this project is based on and learned from. If
  you're starting out in OS development, go watch it.
- The [OSDev Wiki](https://wiki.osdev.org/) — the de facto encyclopedia for
  anyone doing this kind of work.
- Everyone who's ever written a "hello world from the bootloader" — you know
  who you are.

---

## 📬 Contact

Questions, bug reports, and ideas: please open a
[GitHub Issue](https://github.com/0zminDev/liftoff/issues) on this repo.
