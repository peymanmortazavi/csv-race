const std = @import("std");
const zcsv = @import("zcsv");

const Writer = std.Io.Writer;

const GenerationConfig = struct {
    file_name: []const u8,
    col_count: usize,
    row_count: usize,
    min_col_size: usize,
    max_col_size: usize,
    crlf: bool,
    quote_mode: QuoteMode,
};

const QuoteMode = enum {
    QuotesWithNoEscape,
    QuotesWithEscapes,
    NoQuotes,
    Random,
};

fn generate(ally: std.mem.Allocator, config: GenerationConfig) !void {
    const file = try std.fs.cwd().createFile(config.file_name, .{ .truncate = true });
    defer file.close();

    var buffer: [64 * 1024]u8 = undefined;
    var file_writer = file.writer(&buffer);
    var emitter = zcsv.Emitter.init(&file_writer.interface);
    emitter.use_crlf = config.crlf;
    var randomizer = std.Random.DefaultPrng.init(24);

    const column_buffer = try ally.alloc(u8, config.max_col_size);
    defer ally.free(column_buffer);

    for (0..config.row_count) |_| {
        for (0..config.col_count) |_| {
            const col_size = randomizer.random().intRangeAtMost(usize, config.min_col_size, config.max_col_size);
            const column = random_string(&randomizer, col_size, config.quote_mode, column_buffer);
            try emitter.emit(column);
        }
        emitter.next_row();
    }
    try file_writer.interface.flush();
}

fn random_string(randomizer: *std.Random.Xoshiro256, len: usize, mode: QuoteMode, buffer: []u8) []const u8 {
    var index: usize = 0;
    while (index < len) {
        const char = randomizer.random().intRangeAtMost(u8, 32, 127);
        switch (mode) {
            .NoQuotes => { // should ignore delim chars
                if (char == '\'' or char == ',' or char == '"') continue;
            },
            .QuotesWithNoEscape => { // should ignore double quotes
                if (char == '"') continue;
            },
            else => {},
        }
        buffer[index] = char;
        index += 1;
    }
    return buffer[0..index];
}

pub fn main() !void {
    const configs: []const GenerationConfig = &.{
        .{
            .file_name = "data/gen/xs_no_quotes_52_col_0_256.csv",
            .crlf = false,
            .col_count = 52,
            .row_count = 50,
            .quote_mode = .NoQuotes,
            .min_col_size = 0,
            .max_col_size = 256,
        },
        .{
            .file_name = "data/gen/m_no_quotes_52_col_0_256.csv",
            .crlf = false,
            .col_count = 52,
            .row_count = 5e3,
            .quote_mode = .NoQuotes,
            .min_col_size = 0,
            .max_col_size = 256,
        },
        .{
            .file_name = "data/gen/xl_no_quotes_52_col_0_256.csv",
            .crlf = false,
            .col_count = 52,
            .row_count = 5e5,
            .quote_mode = .NoQuotes,
            .min_col_size = 0,
            .max_col_size = 256,
        },
        .{
            .file_name = "data/gen/xs_mix_quotes_12_col_0_32.csv",
            .crlf = false,
            .col_count = 12,
            .row_count = 5,
            .quote_mode = .Random,
            .min_col_size = 0,
            .max_col_size = 32,
        },
        .{
            .file_name = "data/gen/m_mix_quotes_12_col_0_32.csv",
            .crlf = false,
            .col_count = 12,
            .row_count = 5e5,
            .quote_mode = .Random,
            .min_col_size = 0,
            .max_col_size = 32,
        },
        .{
            .file_name = "data/gen/xl_mix_quotes_12_col_0_32.csv",
            .crlf = false,
            .col_count = 12,
            .row_count = 5e7,
            .quote_mode = .Random,
            .min_col_size = 0,
            .max_col_size = 32,
        },
        .{
            .file_name = "data/gen/xl_mix_quotes_2_col_0_12_many_rows.csv",
            .crlf = false,
            .col_count = 2,
            .row_count = 5e7,
            .quote_mode = .Random,
            .min_col_size = 0,
            .max_col_size = 12,
        },
    };

    const ally = std.heap.smp_allocator;

    for (configs) |config| {
        generate(ally, config) catch |err| {
            std.log.err("failed to generate {s}: {s}", .{ config.file_name, @errorName(err) });
            continue;
        };
        std.log.info("generated file {s}", .{config.file_name});
    }
}
