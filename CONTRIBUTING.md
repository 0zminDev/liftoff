# Contributing to 0DOS

First off — thanks for even considering it. This is a small, learning-driven
OS/bootloader project, so contributions of *any* size are genuinely useful:
fixing a typo in a comment, correcting a wrong assumption about FAT12,
proposing a cleaner way to set up the GDT, or implementing a whole new stage
of the boot process are all welcome.

This document exists so that contributing feels predictable rather than
mysterious. If something here is unclear or wrong, that's itself worth an
issue or PR.

## Before you start

By contributing, you agree that your contributions will be licensed under
the project's [GNU GPL v3.0 license](LICENSE) — the same license as the rest
of the codebase ("inbound = outbound"). There's no CLA to sign; opening a PR
is enough.

Please also read the [Code of Conduct](CODE_OF_CONDUCT.md). It's short.

## Ways to contribute

- **Bug reports** — something doesn't boot, crashes QEMU, or behaves
  differently than the code implies it should.
- **Documentation** — clarifying how a boot stage works, fixing outdated
  build instructions, improving comments on tricky assembly.
- **Code** — bug fixes, new bootloader/kernel features, refactors, build
  system improvements.
- **Discussion** — opening an issue to propose a direction (e.g. "should
  stage2 move to C before or after protected mode?") is genuinely welcome
  before you write any code, especially for larger changes.

## Development setup

See the [README's build & run section](README.md#-building--running) for
required tools (`nasm`, `mtools`, `qemu-system-i386`, etc.).

Quick loop while developing:

```sh
make clean && make
qemu-system-i386 -fda build/main_floppy.img
```

or just:

```sh
./run.sh
```

`make clean` before `make` is currently required — a fresh build after a
prior one can otherwise produce a stale/incorrect image.

## Branching & commits

- Branch off `master` using a `feature/<short-description>` name, e.g.
  `feature/protected_mode`, `feature/fat12_write_support`. This matches the
  convention already used in this repo's history.
- Keep commits focused — one logical change per commit is easier to review
  and easier to `git blame` later, especially in assembly where a "small"
  change can have large behavioral effects.
- Write commit messages that explain **why**, not just what changed. The
  diff already shows what changed.
- Open a PR against `master` when ready. Small, incremental PRs are strongly
  preferred over large ones — bootloader code is easiest to review in small
  slices, since a single wrong byte offset can be very hard to spot in a big
  diff.

## Code style

### Assembly (NASM)

- Formatting follows [`.clang-format`](.clang-format) where applicable
  (tabs for indentation, tab width 4) — apply the same conventions by hand
  in `.asm` files, since clang-format itself doesn't format NASM.
- Use `.label` (dot-prefixed local labels) for labels scoped to a single
  routine, matching the existing style (e.g. `.loop`, `.done`, `.halt`).
- Comment **why**, not what — `mov ax, 0x0` doesn't need a comment; a magic
  segment offset or an undocumented BIOS interrupt quirk does.
- Keep stage 1 mindful of the 512-byte boot sector limit at all times.

### C (future stage2/kernel work)

- This project targets 16-bit real-mode C via OpenWatcom (`wcc`/`wlink`)
  for anything that runs before protected mode. Don't assume a hosted/libc
  environment is available.
- See [`compile_flags.txt`](compile_flags.txt) and
  [`.clang-format`](.clang-format) for editor/tooling configuration.

### Editor tooling

- [`asm-lsp.toml`](asm-lsp.toml) configures `asm-lsp` for NASM/x86 — if your
  editor supports it, use it for accurate autocomplete on instructions and
  registers.

## Testing your change

There's no automated test suite (yet — this is bootloader/kernel code
running outside any OS, so "testing" mostly means "boots correctly in
QEMU"). Before opening a PR:

1. `make clean && make` completes without errors.
2. `qemu-system-i386 -fda build/main_floppy.img` boots and behaves as
   expected (or as described in your PR) — describe what you saw in the PR
   description, ideally with a screenshot or terminal output.
3. If you touched stage 1, double-check the resulting `stage1.bin` still
   fits within the 512-byte boot sector — the build will still "succeed"
   with an oversized stage1 in some configurations, but it won't boot.

## Pull request checklist

- [ ] Branch named `feature/<description>` (or `fix/<description>` for bug fixes)
- [ ] Builds cleanly with `make clean && make`
- [ ] Boots and behaves as described, tested in QEMU
- [ ] Commit messages explain *why*
- [ ] PR description explains what changed and, for anything non-obvious,
      why this approach was chosen
- [ ] No unrelated changes bundled in (formatting-only churn, unrelated
      refactors) — open a separate PR for those

## Questions?

Open a [GitHub Issue](https://github.com/0zminDev/liftoff/issues) — for a
project this size, "unsure where to start" is a perfectly good reason to
open one.
