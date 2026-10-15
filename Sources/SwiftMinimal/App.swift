// The entire program.
//
// Compiled for aarch64-unknown-linux-gnu in Embedded Swift mode and linked
// with `-static -nostdlib`, so this is almost the whole thing: no Foundation,
// no libswiftCore, no libc. Beyond this file that is a `_start`, a `putchar`,
// a `sys_brk`, `memset`, `memmove`, and the `posix_memalign`/`free` pair the
// heap needs (see the `Bootstrap` target and Heap.swift).
//
// `print` is ours (see Console.swift), so literals interpolate.

@c(app_main)
public func appMain() -> Int32 {
    print("hello from Swift")

    var total: Int32 = 0
    var value: Int32 = 1
    while value <= 10 {
        total += value
        value += 1
    }
    print("1 + 2 + ... + 10 = \(total)")

    // Too long for `String` to keep inline, so this one lives on the heap:
    // posix_memalign for the storage, free when it goes out of scope.
    let long = String(repeating: "swift ", count: 8)
    print(long)
    print("heap bytes used: \(heapBytesUsed())")
    return 0
}
