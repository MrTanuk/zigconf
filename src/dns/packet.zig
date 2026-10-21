const std = @import("std");
const testing = std.testing;

const Name = []const []const u8;

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
    qname: Name,
    qtype: u16, // 1 for A, 12 for ptr, etc etc
    qclass: u16, // In
};

// For Answer, Authority, Additional
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

pub fn encodeServiceInstanceName(labels: []const []const u8, out: []u8) !usize {
    var seek: usize = 0;

    for (labels) |s| {
        if (s.len > 63) return error.LabelTooLong;
        if (seek + 1 + s.len > out.len) return error.NoSpace;

        out[seek] = @intCast(s.len);
        seek += 1;

        @memcpy(out[seek .. seek + s.len], s);
        seek += s.len;
    }

    if (seek + 1 > out.len) return error.NoSpace;
    out[seek] = 0x00;
    seek += 1;

    return seek;
}

pub fn decodeServiceInstanceName(in: []const u8, out: []u8) !usize {
    var s_pos: usize = 0;
    var d_pos: usize = 0;

    while (true) {
        if (s_pos >= in.len) return error.Truncated;
        const label_len: usize = in[s_pos];

        if (label_len == 0) return s_pos + 1;

        if (s_pos + 1 + label_len > in.len) return error.Truncated;
        if (d_pos + label_len > out.len) return error.NoSpace;

        @memcpy(out[d_pos .. d_pos + label_len], in[s_pos + 1 .. s_pos + 1 + label_len]);

        d_pos += label_len;
        s_pos += 1 + label_len;
    }
}


// Tests

const sample_labels = [_][]const u8{ "tanuko", "_chat", "_tcp", "local" };

const sample_wire = [_]u8{
    6,   't', 'a', 'n', 'u', 'k', 'o',
    5,   '_', 'c', 'h', 'a', 't', 4,
    '_', 't', 'c', 'p', 5,   'l', 'o',
    'c', 'a', 'l', 0,
};

const sample_flat = "tanuko_chat_tcplocal";

test "encodeServiceInstanceName: 25 bytes of wire" {
    var out: [64]u8 = undefined;

    const len = try encodeServiceInstanceName(&sample_labels, &out);

    try testing.expectEqual(@as(usize, sample_wire.len), len);
    try testing.expectEqualSlices(u8, &sample_wire, out[0..len]);
}

test "encodeServiceInstanceName: NoSpace" {
    var out: [3]u8 = undefined;
    try testing.expectError(error.NoSpace, encodeServiceInstanceName(&sample_labels, &out));
}

test "decodeServiceInstanceName: Empty input" {
    var out: [64]u8 = undefined;
    try testing.expectError(error.Truncated, decodeServiceInstanceName(&[_]u8{}, &out));
}

test "decodeServiceInstanceName: Truncated label" {
    const wire = [_]u8{ 3, 'a', 'b' };
    var out: [64]u8 = undefined;
    try testing.expectError(error.Truncated, decodeServiceInstanceName(&wire, &out));
}

test "decodeServiceInstanceName: No terminator" {
    const wire = [_]u8{ 3, 'a', 'b', 'c' };
    var out: [64]u8 = undefined;
    try testing.expectError(error.Truncated, decodeServiceInstanceName(&wire, &out));
}

test "decodeServiceInstanceName: NoSpace" {
    const wire = [_]u8{ 3, 'a', 'b', 'c', 0 };
    var out: [2]u8 = undefined;
    try testing.expectError(error.NoSpace, decodeServiceInstanceName(&wire, &out));
}
