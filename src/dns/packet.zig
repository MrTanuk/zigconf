const std = @import("std");

pub const Name = []const []const u8; // type alias, for Question y RR

pub const Packet = struct {
    const SERVICE = "_chat";
    const PROTOCOL = "_tcp";
    const DOMAIN = "local";

    Name: Name,
    Allocator: std.mem.Allocator,
    Io: std.Io,

    // 12 bytes
    pub const Header = struct {
        id: u16,
        qr: bool,
        opcode: u4,
        aa: bool,
        tc: bool,
        rd: bool,
        ra: bool,
        z: bool,
        ad: bool,
        cd: bool,
        rcode: u4,
        qdcount: u16,
        ancount: u16,
        nscount: u16,
        arcount: u16,
    };

    pub const Question = struct {
        qname: Name, //
        qtype: u16, // 1 for A, 12 for ptr, etc etc
        qclass: u16, // In
    };

    // For
    // Answer
    // Authority
    // Additional
    pub const ResourceRecord = struct {
        name: Name,
        rtype: u16,
        rclass: u16,
        ttl: u32,
        rdata: []const u8,
    };

    pub const Message = struct {
        header: Header,
        questions: []Question,
        answers: []ResourceRecord,
        authorities: []ResourceRecord,
        additionals: []ResourceRecord,
    };

    pub fn create(allocator: std.mem.Allocator, io: std.Io, instance: []const u8) !*Packet {
        var packet = try allocator.create(Packet);
        errdefer allocator.destroy(packet);

        const name = try allocator.alloc([]const u8, 4);
        errdefer allocator.free(name);

        name[0] = instance;
        name[1] = SERVICE;
        name[2] = PROTOCOL;
        name[3] = DOMAIN;

        packet.Name = name;
        packet.Allocator = allocator;
        packet.Io = io;

        return packet;
    }

    pub fn destroy(self: *Packet) void {
        self.Allocator.free(self.Name);
        self.Allocator.destroy(self);
    }

    pub fn writeNameService(self: *Packet) !void {
        var buffer: [512]u8 = undefined;
        var w = std.Io.File.Writer.init(.stdout(), self.Io, &buffer);

        const writer = &w.interface;

        for (self.Name) |string| {
            _ = try writer.print("{s}.", .{string});
        }

        _ = try writer.print("\n", .{});
        _ = try writer.flush();
    }
};
