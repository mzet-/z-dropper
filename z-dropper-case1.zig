const std = @import("std");
const linux = std.os.linux;
const net = std.net;

fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var buf: [1024]u8 = undefined;
    const args = [2]?[*:0]const u8{ "random_name", null };

    const localhost = try net.Address.parseIp("127.0.0.1", 4443);
    const socket = try net.tcpConnectToAddress(localhost);
    defer socket.close();

    const fd = linux.memfd_create("a", linux.MFD.CLOEXEC);
    if (fd == -1) {
        try stdout.print("memfd_create: {d}!\n", .{linux.getErrno(fd)});
        return error.MemFdCreateFailed;
    }

    while (true) {
        const count = try socket.reader().read(&buf);
        //_ = linux.syscall3(.write, fd, @ptrToInt(&buf[0]), count);
        _ = linux.write(@intCast(i32, fd), &buf, count);
        if (count <= 0 or count < buf.len)
            break;
    }

    const res = linux.syscall5(.execveat, fd, @ptrToInt(""), @ptrToInt(&args[0]), 0, linux.AT.EMPTY_PATH);
    if (res == -1) {
        try stdout.print("execveat: {d}!\n", .{linux.getErrno(fd)});
        return error.ExecveatFailed;
    }

    std.process.exit(0);
}

pub export fn _start() void {
    main() catch unreachable;
}
