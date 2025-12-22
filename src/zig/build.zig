const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zcsv_mod = b.dependency("zcsv", .{ .target = target, .optimize = optimize });
    const zcsv_exe = b.addExecutable(.{
        .name = "zcsv",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/zcsv.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zcsv", .module = zcsv_mod.module("zcsv") },
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
                .{ .name = "zcsv", .module = zcsv_mod.module("zcsv") },
            },
        }),
    });

    b.installArtifact(zcsv_exe);
    b.installArtifact(data_gen_exe);
}
