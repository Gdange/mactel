# mactel

Small, focused tools for building on **Intel Macs** — the cases where the ecosystem assumes
arm64 and a plain `make` leaves you with "Bad CPU type in executable".

Not a compatibility layer, not an emulator, and not a framework: each tool does one narrow job
and documents where it stops.

| Tool | State | What it does |
|---|---|---|
| [`dotnet-universal-launcher`](dotnet-universal-launcher/) | works, verified | Build a universal (x86_64 + arm64) launcher for a .NET app |
| [`pe-loader`](pe-loader/) | experiment, no code yet | Call one exported function of a Windows x64 DLL from a macOS process |

## dotnet-universal-launcher

A .NET console app is `app.dll` plus a native *apphost* launcher. The apphost is architecture
specific, so a tool published for arm64 dies on an Intel Mac (and the reverse). Apple's `lipo`
can join the two, and `dotnet build -r` produces both without a Mac of each kind:

```bash
dotnet-universal-launcher/build.sh <project dir or .csproj> [output path]
```

Verified on an Intel Mac with a .NET 8 tool: both RIDs build, `lipo` reports `x86_64 arm64`, and
the universal launcher runs and prints the same output as the x86_64-only one.

Caveat: the apphost looks for `<name>.dll` beside itself. Replace the launcher in the published
output; do not move it away from its dll unless you publish self-contained.

## pe-loader

Windows-only binaries are a recurring blocker on macOS: a vendor SDK ships `something.dll` and
the tool you need is one pure function inside it. Wine solves this generally but weighs a few
hundred MB and drags a whole prefix along; a small PE loader that maps the DLL into the current
process and calls one export solves the narrow case.

The loader that motivated this repository maps Windows' `oo2core_win64.dll` (Oodle) on an Intel
Mac and calls `OodleLZ_Decompress` with `__attribute__((ms_abi))` for the Windows x64 calling
convention. Four things cost the most time:

1. read `.reloc` entries **from the file**, not from the mapped image — the loader skips the
   section's bytes, so relocations read after mapping are garbage;
2. fill the IAT; point every `KERNEL32` import at a stub returning 0 if the target does not touch
   the CRT — an unfilled IAT jumps to the hint/name RVA and crashes;
3. `mprotect` per segment (`.text` RX, data RW). Mapping the whole image RX makes BSS unwritable
   and the process dies with SIGBUS;
4. `read()` on a pipe returns short — loop until the request is complete.

**Scope, honestly:** mapping, base relocations, import resolution, one exported function with a
simple ABI. No TLS callbacks, no SEH/unwind, no C++ exceptions, no `DllMain`. A DLL that needs
any of those is out of scope until the code and tests say otherwise. There is no code in this
directory yet; the notes above are the design brief, not a claim.

## Non-goals

- Running Windows programs (that is Wine's job).
- Emulating another architecture (that is Rosetta's / QEMU's job).
- Packaging games, iOS apps, or anything project-specific.

## Disclaimer

No warranty, no liability, and no third-party binaries in this repository. Read
[DISCLAIMER.md](DISCLAIMER.md) before use — it covers data loss, device damage, vendor licenses
and platform terms. In short: test on hardware you can afford to lose.

## License

No license file yet; treat the code as all rights reserved until one is added.
