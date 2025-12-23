const std = @import("std");
const csvz = @import("csvzero");

pub fn main() !void {
    var it = std.process.args();
    _ = it.skip();

    const file_path = it.next() orelse {
        std.debug.print("no file specified\n", .{});
        std.process.exit(1);
    };

    var file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
    var buffer: [64 * 1024]u8 = undefined;
    var reader = file.reader(&buffer);
    const file_reader = &reader.interface;
    var csvit = csvz.Iterator.init(file_reader);
    var sum: usize = 0;
    while (true) {
        const col = csvit.next() catch |err| switch (err) {
            csvz.Iterator.Error.EOF => break,
            else => |e| return e,
        };
        _ = col;
        // std.debug.print("col: {s}, last? {}\n", .{ col.data, col.last_column });
        sum += 1;
    }
    std.log.info("{d}", .{sum});
}
