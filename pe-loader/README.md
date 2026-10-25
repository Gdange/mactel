# pe-loader (experimental, no code yet)

Goal: map a Windows x64 PE (`*.dll`) into the current macOS process and call one exported
function, with no Wine and no emulation.

## Scope

- PE parsing: headers, sections, `.reloc`, import table.
- Map sections at the image's preferred base (or relocate if the base is taken).
- Resolve imports against a small stub table (`KERNEL32` -> return 0).
- One call: `ms_abi` C function pointer, integer/pointer arguments and a return value.

## Out of scope

- TLS callbacks, `DllMain`, SEH/unwind tables, C++ exceptions.
- Calling back from the DLL into macOS code.
- Threads created inside the DLL.
- 32-bit PEs.

## Verification plan

A DLL is accepted only when a test calls an exported pure function and the result matches a
known-good value produced on Windows. Anything that cannot be tested this way is documented as
unsupported rather than assumed to work.
