const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const csvzero_mod = b.dependency("csvzero", .{ .target = target, .optimize = optimize });
    const csvzero_exe = b.addExecutable(.{
        .name = "csvzero",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/csv_zero.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "csvzero", .module = csvzero_mod.module("csvzero") },
            },
        }),
    });

    const data_gen_exe = b.addExecutable(.{
        .name = "datagen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/data_gen.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "csvzero", .module = csvzero_mod.module("csvzero") },
            },
        }),
    });

    b.installArtifact(csvzero_exe);
    b.installArtifact(data_gen_exe);
}
