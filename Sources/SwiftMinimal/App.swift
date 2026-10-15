// The entire program.
//
// Compiled for aarch64-unknown-linux-gnu in Embedded Swift mode and linked
// with `-static -nostdlib`, so this is the whole thing: no Foundation, no
// libswiftCore, no libc. Everything it needs beyond this file is a `_start`,
// a `putchar`, a `memmove`, and three symbols the runtime references but this
// program never calls (see the `Bootstrap` target).

@c(app_main)
public func appMain() -> Int32 {
    print("hello from Swift", terminator: "\n")

    var total: Int32 = 0
    var value: Int32 = 1
    while value <= 10 {
        total += value
        value += 1
    }
    print(value)
    return 0
}
