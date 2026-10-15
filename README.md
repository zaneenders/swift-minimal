# swift-minimal

The smallest Swift binary for linux aarch64

```sh
swift build -c release
```

## Gotchas worth knowing

- Embedded Swift's `print` takes a `StaticString`, which cannot see an
  interpolated literal (it is not `ExpressibleByStringInterpolation`). A
  same-signature `print` in this module shadows the stdlib one, and
  `@_disfavoredOverload` steers plain literals to `String`, so everything
  prints through it and `"1 + ... + 10 = \(total)"` works. See
  `Sources/SwiftMinimal/Console.swift`.
- Real `String` works, but only if you hand it a heap. Embedded Swift lowers
  every allocation to `posix_memalign`/`free`, which glibc normally answers;
  under `-static -nostdlib` nobody does, so `Sources/SwiftMinimal/Heap.swift`
  does. It is a bump allocator over `brk(2)` and `free` is a no-op — fine for a
  short-lived program, not for one that churns strings.
- Strings of 15 UTF-8 bytes or fewer are stored inline and never reach the
  allocator, which is why the literal-only path still costs nothing.
- Embedded Swift's stdlib subset has no `Synchronization`/`Mutex`, so the
  allocator's globals are `nonisolated(unsafe)`. That is honest here: the
  program is single-threaded and never yields.

## Size

Linking the real `String` machinery — Unicode tables included — costs ~24 KB
over the hand-rolled interpolation this used to carry: 5.6 KB → ~30 KB, still
statically linked and stripped.

`-Onone` additionally wants `memcpy` (the integer-to-ASCII helper calls it),
which is why the boot stub carries `memset`, `memcpy` and `memmove`.
