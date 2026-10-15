// Everything the Embedded Swift runtime needs from the platform on Linux.
//
// With `-static -nostdlib` there is no libc, so nothing is resolved for us.
// The runtime references six symbols; `_start`, `putchar` and `memmove` are
// real, and the rest are stubs because this program never allocates.
// See ../../swift-baremetal for a real allocator in Swift.

    .section .text.boot
    .global _start
_start:
    bl      app_main              // Linux already set up a valid SP for us
    mov     x8, #94               // exit_group(return value)
    svc     #0

    // putchar(int) -> write(1, &c, 1). This is what `print` drives.
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

    // The embedded runtime emits these in the same .text section as app_main,
    // so --gc-sections cannot drop them. This program does not heap-allocate,
    // so they are never actually executed.

    .global posix_memalign        // int posix_memalign(void **, size_t, size_t)
posix_memalign:
    mov     w0, #12               // ENOMEM
    ret

    .global free
free:
    ret

    .global memset                // void *memset(void *, int, size_t)
memset:
    mov     x3, x0
1:  cbz     x2, 2f
    strb    w1, [x0], #1
    subs    x2, x2, #1
    b.ne    1b
2:  mov     x0, x3
    ret

    // Unlike the three above, this one is reachable: at -Onone the embedded
    // runtime lowers copyMemory to a memmove call instead of inlining it.
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
