const std = @import("std");
const Packet = @import("dns/packet.zig").Packet;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const allocator = init.gpa;

    var tanuk = try Packet.create(allocator, io, "tanuko");
    defer tanuk.destroy();

    _ = try tanuk.writeNameService();
}
