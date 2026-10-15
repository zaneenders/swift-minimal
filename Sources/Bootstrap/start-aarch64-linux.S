// Everything the Embedded Swift runtime needs from the platform on Linux.
//
// With `-static -nostdlib` there is no libc, so nothing is resolved for us.
// The runtime references these symbols; `_start`, `putchar` and `sys_brk` are
// real, `memset`/`memcpy`/`memmove` are the real thing too, and
// `posix_memalign`/`free` now live in Swift (see Sources/SwiftMinimal/Heap.swift).
// See ../../swift-baremetal for the same story on a bare-metal target.

    .section .text.boot
    .global _start
_start:
    bl      app_main              // Linux already set up a valid SP for us
    mov     x8, #94               // exit_group(return value)
    svc     #0

    // putchar(int) -> write(1, &c, 1).
    .global putchar
putchar:
    sub     sp, sp, #16
    str     w0, [sp, #12]
    mov     x0, #1
    add     x1, sp, #12
    mov     x2, #1
    mov     x8, #64               // write
    svc     #0
    add     sp, sp, #16
    ret

    // brk(2) for the Swift allocator: x0 is the requested break, and the
    // resulting break is returned (unchanged if the kernel refused to grow).
    .global sys_brk
sys_brk:
    mov     x8, #214              // brk
    svc     #0
    ret

    // The embedded runtime emits these in the same .text section as app_main,
    // so --gc-sections cannot drop them.

    .global memset                // void *memset(void *, int, size_t)
memset:
    mov     x3, x0
1:  cbz     x2, 2f
    strb    w1, [x0], #1
    subs    x2, x2, #1
    b.ne    1b
2:  mov     x0, x3
    ret

    // Unlike memset, these two are reachable at -Onone: there the embedded
    // runtime and the String machinery lower copyMemory and integer-to-ASCII
    // to real calls instead of inlining them.
    .global memcpy                // void *memcpy(void *, const void *, size_t)
memcpy:
    mov     x3, x0
    cbz     x2, 2f
1:  ldrb    w4, [x1], #1
    strb    w4, [x0], #1
    subs    x2, x2, #1
    b.ne    1b
2:  mov     x0, x3
    ret

    .global memmove               // void *memmove(void *, const void *, size_t)
memmove:
    mov     x3, x0
    cbz     x2, 2f
1:  ldrb    w4, [x1], #1
    strb    w4, [x0], #1
    subs    x2, x2, #1
    b.ne    1b
2:  mov     x0, x3
    ret
