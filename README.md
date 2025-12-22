# CSV Race

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive benchmarking suite for CSV parsers across multiple programming languages. CSV Race helps parser authors optimize their implementations and helps developers choose the right CSV parser for their specific use case.

## Overview

CSV Race benchmarks CSV parsers from C, C++, Rust, Go, and Zig, measuring not just wall time but also CPU instructions, cache performance, branch predictions, and memory usage. The project provides test files of varying sizes and characteristics, tooling for running benchmarks, and automated visualization of results.

## Features

- **Multi-Language Support**: Benchmarks parsers written in C, C++, Rust, Go, and Zig
- **Comprehensive Metrics**: Measures wall time, peak RSS, CPU instructions, CPU cycles, cache behavior, and branch misses
- **Diverse Test Cases**: Includes both real-world CSV files and generated files with controlled characteristics
- **Automated Visualization**: Python scripts generate charts comparing parser performance
- **Hardware Performance Counters**: Uses `perf` via [poop](https://github.com/andrewrk/poop) for accurate CPU-level metrics
- **Extensible**: Easy to add your own parsers and test files

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Quick Start](#quick-start)
- [Benchmark Methodology](#benchmark-methodology)
  - [Task](#task)
  - [Test Files](#test-files)
  - [Metrics Collected](#metrics-collected)
  - [Tooling](#tooling)
  - [Data Visualization](#data-visualization)
- [Benchmark Results](#benchmark-results)
  - [Wall Time](#wall-time)
  - [Peak RSS](#peak-rss)
  - [Branch Misses](#branch-misses)
  - [Cache Misses & References](#cache-misses--references)
- [Running the Benchmarks](#running-the-benchmarks)
  - [Prerequisites](#prerequisites)
  - [Building Parsers](#building-parsers)
  - [Running Tests](#running-tests)
- [Contributing](#contributing)
- [Related Projects](#related-projects)
- [License](#license)

## Quick Start

```bash
# Build all parsers
make build_all

# Run benchmarks with poop (Linux only)
make poop TEST_FILE=data/game.csv

# Generate visualizations
python generate_charts.py
```

> **Note**: Before diving into the results, please read the [Benchmark Methodology](#benchmark-methodology) section to understand how tests are conducted and what the metrics represent.

## Benchmark Methodology

**Important Disclaimer**: While these benchmarks test libraries across various file sizes and characteristics, they should not be your sole decision-making criterion. Different parsers may:
- Handle your specific use cases better
- Offer unique features or utilities not available elsewhere
- Perform differently in your execution environment
- Provide better APIs or ergonomics for your needs

Even if performance is your primary concern, validate that these benchmarks reflect your specific requirements and environment.

> **Feedback Welcome**: If you spot mistakes or want to suggest additional libraries, please open an issue or pull request.

### Task

This benchmark wants to focus on speed of iteration and not what consumers might want to do with that data. For this
reason, each parser must iterate and count the number of fields in a CSV file as fast as it can using only `64 KB`
buffer size. Some libraries might not provide a way to specify this, for those, we have not enforced a buffer size.

### Test Files

The benchmark suite includes two categories of test files:

#### Real-World Files

Four commonly-used CSV files that represent realistic data patterns:
- `game.csv`
- `gtfs-mbta-stop-times.csv`
- `nfl.csv`
- `worldcitiespop.csv`

These files contain a mixture of quoted and non-quoted regions, escape characters, and varying sizes typical of production CSV data.

#### Generated Files

Synthetic files designed to test specific characteristics. File naming follows this format:

```
<size>_<mix|no>_quotes_<column-count>_col_<min-field-size>_<max-field-size>.csv
```

**Generation Method**: Each field is populated with randomly chosen printable ASCII characters (range 32-127). Field length is randomly selected between `min-field-size` and `max-field-size`. For `mix_quotes` files, special characters (`"`, `\`, `,`) may be included, causing the field to be properly quoted. For `no_quotes` files, these characters are excluded entirely.

**Available Generated Files**:

| File | Size | Quotes | Columns | Field Size |
|------|------|--------|---------|------------|
| `xs_mix_quotes_12_col_0_32.csv` | ~1 KB | Mixed | 12 | 0-32 chars |
| `xs_no_quotes_52_col_0_256.csv` | ~330 KB | None | 52 | 0-256 chars |
| `m_mix_quotes_12_col_0_32.csv` | ~102 MB | Mixed | 12 | 0-32 chars |
| `m_no_quotes_52_col_0_256.csv` | ~32 MB | None | 52 | 0-256 chars |
| `xl_mix_quotes_2_col_0_12_many_rows.csv` | ~700 MB | Mixed | 2 | 0-12 chars |
| `xl_no_quotes_52_col_0_256.csv` | ~3.2 GB | None | 52 | 0-256 chars |
| `xl_mix_quotes_12_col_0_32.csv` | ~9.9 GB | Mixed | 12 | 0-32 chars |

### Metrics Collected

Beyond simple execution time, we capture detailed performance metrics:

| Metric | Description |
|--------|-------------|
| **Wall Time** | Total elapsed time to complete the task |
| **Peak RSS** | Maximum resident set size (memory) occupied by the parser process |
| **CPU Instructions** | Total machine-level instructions executed (independent of clock speed) |
| **CPU Cycles** | Total CPU clock cycles, including execution and stalls (memory, branch resolution, etc.) |
| **Cache References** | Number of memory accesses through the cache hierarchy |
| **Cache Misses** | Failed cache lookups across all levels (primarily LLC misses) |
| **Branch Misses** | Branch mispredictions by the CPU. See [Branch predictor](https://en.wikipedia.org/wiki/Branch_predictor) for details |

### Tooling

**Primary Tool**: [Poop](https://github.com/andrewrk/poop) (Linux only) - Uses `perf` to collect CPU and hardware performance counters.

**Alternative**: [Hyperfine](https://github.com/sharkdp/hyperfine) (macOS/Windows) - Provides wall time measurements only. You can also use `perf` directly or platform-specific alternatives.

### Data Visualization

The included Python script (`generate_charts.py`) automates benchmark execution with `poop` and generates:
- A CSV file containing all raw metrics
- PNG charts for each metric in the `images/` directory

You can customize the script to use different tooling or adjust chart parameters.

## Benchmark Results

**Test Environment**:
- CPU: AMD Ryzen 5 PRO 5650U with Radeon Graphics
- Memory: 30 GB
- OS: Linux 6.17.8-arch1-1

> **Note**: Results vary significantly across different CPUs and architectures. Contributions of benchmark data from other platforms are welcome!

**About the Charts**:
- Charts display the **top 5 parsers** to reduce visual noise
- Focus primarily on the 4 real-world CSV files
- Full raw data for all parsers and test cases is available in `result-all.csv`

**Parsers Benchmarked**:
- **csv-zero** (Zig) - [Repository](https://github.com/peymanmortazavi/csv-zero)
- **simdcsv** (Rust)
- **csv** (Rust)
- **csv-core** (Rust)
- **zsv** (C)
- **lazycsv** (C++)
- And more (see `src/` directories)

### Wall Time

Wall time represents the actual elapsed time to complete parsing each CSV file.

![CSV Parser Wall Time Comparison](images/wall_time.png "CSV Parser Wall Time Comparison")

**Key Observations**:

- **SIMD Performance Characteristics**: SIMD-accelerated parsers (`simdcsv`, `zsv`, `csv-zero`) show reduced advantage on `game.csv` compared to other test files, though they still outperform non-SIMD parsers. The gap narrows significantly for this particular file.

- **Consistency Winner**: `lazycsv` (C++) demonstrates the most stable performance across all test cases. While not always the fastest, it maintains consistently good times without dramatic variations.

- **Unexpected Patterns**: On `worldcitiespop.csv` (which contains no quoted regions), some parsers like `csv` (Rust) and `lazycsv` (C++) perform worse than expected, suggesting quoted field handling optimizations may affect unquoted parsing.

#### Large File Performance

![CSV Parser Wall Time Comparison For Larger Files](images/wall_time_xl.png "CSV Parser Wall Time Comparison For Larger Files")

For larger files (XL test cases), performance rankings remain consistent:
- **csv-zero** achieves first place across all large file tests
- `zsv` (C), `lazycsv` (C++), and `simdcsv` (Rust) also deliver strong, consistent performance

### Peak RSS

Peak Resident Set Size (RSS) measures the maximum memory occupied by a process during execution.

![CSV Parser Peak RSS Comparison](images/peak_rss.png "CSV Parser Peak RSS Comparison")

**Key Observations**:

- **Consistent Memory Usage**: Most top-5 parsers maintain similar memory footprints regardless of file size, indicating efficient streaming implementations.

- **Exception**: `lazycsv` (C++) shows significantly higher memory usage that scales with file size. For XL test cases, it consumes gigabytes of memory, which may be problematic in memory-constrained environments.

- **Production Suitability**: All other top parsers handle multi-gigabyte files with minimal memory overhead, making them suitable for resource-constrained scenarios.

### Branch Misses

Branch mispredictions occur when the CPU incorrectly predicts the outcome of conditional statements (`if`, `switch`, etc.). When a prediction fails, the CPU must discard speculative work and restart, causing performance penalties.

Modern CPUs excel at predicting patterns, but unpredictable branches (like those in CSV parsing with varying quoted/unquoted fields) can cause significant slowdowns. Lower branch miss counts typically correlate with better wall-time performance.

![CSV Parser Branch Misses Comparison](images/branch_misses.png "CSV Parser Branch Misses Comparison")

**Analysis**: Parsers with fewer branch misses generally achieve better wall-time performance. SIMD-based approaches often reduce branching by processing data in parallel.

### Cache Misses & References

Cache performance significantly impacts parser speed. Cache references indicate memory accesses through the cache hierarchy, while cache misses represent failed lookups requiring slower main memory access.

![CSV Parser Cache References Comparison](images/cache_references.png "CSV Parser Cache References Comparison")
![CSV Parser Cache Misses Comparison](images/cache_misses.png "CSV Parser Cache Misses Comparison")

> Additional metrics (CPU cycles, instructions, etc.) are available in the `images/` directory and `result-all.csv`.

## Running the Benchmarks

### Prerequisites

**Required**:
- C, C++, Rust, Go, and Zig compilers (or subset for specific parsers you want to test)
- `make`

**Benchmarking Tools** (choose one):
- [Poop](https://github.com/andrewrk/poop) - Linux only, provides full metrics
- [Hyperfine](https://github.com/sharkdp/hyperfine) - Cross-platform, wall-time only

**Optional**:
- Python 3 + matplotlib - For generating visualizations
- Zig 0.15.2 - Required for building `csv-zero` and generating test data

### Building Parsers

All parser implementations are in the `src/` directory, organized by language:
```
src/
├── c/        # C implementations
├── cpp/      # C++ implementations
├── go/       # Go implementations
├── rust/     # Rust implementations
└── zig/      # Zig implementations (includes data_gen.zig for test data)
```

**Build all parsers**:
```bash
make build_all
```

**Notes**:
- You can selectively build/test parsers by modifying Makefile targets
- Most C++ parsers are header-only libraries
- Rust parsers use Cargo for dependency management
- `zsv` (C) requires building from source (follow their repository instructions)

### Running Tests

#### Quick Test (Single File)

Using Poop (Linux):
```bash
make poop TEST_FILE=data/game.csv
```

Using Hyperfine (Cross-platform):
```bash
make hyperfine TEST_FILE=data/game.csv
```

#### Generate Full Benchmark Report

Run all tests and generate visualizations:
```bash
python generate_charts.py
```

This creates:
- `output.csv` - Raw benchmark data
- `images/*.png` - Performance comparison charts

#### Custom Test Files

You can benchmark with your own CSV files:
```bash
# Using poop
make poop TEST_FILE=/path/to/your/file.csv

# Using hyperfine
make hyperfine TEST_FILE=/path/to/your/file.csv
```

#### Customizing Parsers and Test Cases

Edit `generate_charts.py` to:
- Select which parsers to benchmark
- Choose specific test files
- Adjust chart parameters
- Use different benchmarking tools

## Contributing

Contributions are welcome! You can help by:

- Adding parsers from other languages or alternative implementations
- Providing benchmark results from different CPU architectures
- Improving test coverage with new CSV file types
- Enhancing visualization scripts
- Fixing bugs or improving documentation

Please open an issue or pull request on the repository.

## Related Projects

- [csv-zero](https://github.com/peymanmortazavi/csv-zero) - High-performance CSV parser for Zig

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
