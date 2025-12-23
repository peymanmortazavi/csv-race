# CSV Race

**CSV Race** is a benchmarking repository for comparing the performance characteristics of CSV parsers across different languages and implementations.

This project was originally created to benchmark and fine-tune my own CSV parser, and to better understand how different parsers behave under a variety of real-world and synthetic workloads. Over time, it evolved into a more general framework for evaluating CSV parsers in a consistent and transparent way.

The goal is twofold:

- **For parser authors**: provide a reproducible environment to evaluate and improve performance.
- **For users**: help identify parsers that best match their performance, memory, and workload requirements.

While this README highlights selected benchmark results, the repository also includes scripts and tooling that allow you to:

- Add your own parsers
- Generate custom datasets
- Run benchmarks on your own machine
- Produce your own charts and raw data

For details on running benchmarks yourself, see [Running the benchmarks](#running-the-benchmarks).

This repository was used extensively during the development of
👉 [csv-zero](https://github.com/peymanmortazavi/csv-zero) and proved invaluable throughout that process.

> **Before diving into the charts**, I strongly recommend reading the
> [Benchmark Methodology](#benchmark-methodology) section to understand what is — and is not — being measured.

---

## Benchmark Methodology

Benchmarks are easy to misinterpret and easy to get wrong. While this repository aims to be careful and transparent, **you should not make decisions solely based on the charts shown here**.

CSV parsers vary widely in:

- Feature sets
- API design
- Error handling
- Memory strategies
- Suitability for specific workloads

Even if raw performance is your primary concern, you should verify that:

- The benchmark matches your usage pattern
- The input data resembles your real data
- The execution environment is comparable to yours

> I have made a best-effort attempt to choose representative test cases and to use each library as intended.
> If you notice an issue, a mistake, or a missing library, contributions and corrections are very welcome.

---

### Task Definition

The benchmark intentionally focuses on **iteration speed**, not downstream data processing.

Each parser is required to:

- Iterate through the entire CSV file
- Count the total number of fields
- Use a **64 KB input buffer** where configurable

Some libraries do not expose buffer size controls; in those cases, the default behavior is used.

This task isolates parsing overhead and minimizes the impact of allocation, data conversion, or user-level processing.

---

### Test Files

#### Real-world datasets

After surveying commonly used CSV benchmark files, the following datasets were selected due to their diversity in size, structure, and quoting behavior:

- `game.csv`
- `gtfs-mbta-stop-times.csv`
- `nfl.csv`
- `worldcitiespop.csv`

These files include a mix of:

- Quoted and unquoted fields
- Escaped characters
- Varying row and column counts

They are reasonably representative of real-world CSV data.

#### Generated datasets

To explore additional edge cases and scalability, synthetic datasets are generated using the following naming scheme:

```
<size>_<mix|no>_quotes_<column-count>_col_<min-field-size>_<max-field-size>.csv
```

Where:

- `size` indicates approximate file size
- `col` indicates column count
- Field contents are random printable ASCII characters (`32–127`)
- Field length is randomly chosen in `[min-field-size, max-field-size]`

If quoting is disabled:

- `"`, `\`, and `,` are excluded

If quoting is enabled:

- These characters may appear, and fields are quoted correctly when required

Examples:

- `xs_mix_quotes_12_col_0_32.csv` — ~1 KB, quoted, 12 columns
- `xs_no_quotes_52_col_0_256.csv` — ~330 KB, unquoted, 52 columns
- `m_mix_quotes_12_col_0_32.csv` — ~102 MB, quoted
- `m_no_quotes_52_col_0_256.csv` — ~32 MB, unquoted
- `xl_mix_quotes_2_col_0_12_many_rows.csv` — ~700 MB
- `xl_no_quotes_52_col_0_256.csv` — ~3.2 GB
- `xl_mix_quotes_12_col_0_32.csv` — ~9.9 GB

---

### Collected Metrics

While wall-clock time is the most visible metric, several additional hardware-level metrics are captured to provide deeper insight:

- **Wall Time**
  Total elapsed time to complete the task.

- **Peak RSS**
  Maximum resident set size (memory usage) during execution.

- **CPU Instructions**
  Number of retired machine instructions, independent of clock speed.

- **CPU Cycles**
  Total cycles elapsed, including stalls and memory waits.

- **Cache References**
  Number of accesses through the CPU cache hierarchy.

- **Cache Misses**
  Cache misses across all cache levels (primarily LLC).

- **Branch Misses**
  Modern CPUs rely heavily on **branch prediction** to keep their pipelines full. Control-flow constructs such as `if`, `switch`, loops, and conditional jumps usually compile down to branch instructions unless the compiler can fully eliminate them.

  When the CPU encounters a branch, it **predicts** which path will be taken and begins executing instructions speculatively. If the prediction is correct, execution continues with little to no cost. If it is wrong, the CPU must **flush part of the pipeline and restart execution**, which incurs a noticeable performance penalty.

  A **branch miss** (or branch misprediction) occurs when the CPU’s prediction does not match the actual control flow.

  This matters for CSV parsing because:

  - Parsers often contain tight loops with many conditionals
  - Decisions depend on input data (e.g. quote handling, escape detection, delimiter checks)
  - Irregular or data-dependent patterns reduce predictability

  CSV files with:

  - Mixed quoted and unquoted fields
  - Escaped characters
  - Varying row and column lengths

  tend to produce less predictable branching behavior than uniform, unquoted data.

---

### Tooling

Benchmarks are primarily executed using:

- **[Poop](https://github.com/andrewrk/poop)**
  A Linux-only benchmarking tool built on top of `perf`.

On macOS or Windows:

- **[Hyperfine](https://github.com/sharkdp/hyperfine)** can be used, but it only provides wall-time metrics.

If you prefer, you may also use `perf` directly or substitute alternative tooling.

---

### Data Visualization

A Python script orchestrates the benchmarks and generates:

- A CSV file with all raw results
- A set of charts for selected metrics

The scripts are easily adaptable if you want to:

- Use different tools
- Add new metrics
- Customize visualizations

---

## Benchmark Results

> Benchmarks were run on:
> **CPU**: AMD Ryzen 5 PRO 5650U
> **Memory**: 30 GB
> **OS**: Linux 6.17.8-arch1-1

Results will vary significantly across machines and architectures.
Contributions with data from other CPUs are very welcome.

To reduce visual noise:

- Charts show only the **top 5 parsers**
- Raw results for all parsers and test cases are available in `result-all.csv`
- Charts focus primarily on the four common real-world datasets

---

### Wall Time

![CSV Parser Wall Time Comparison](images/wall_time.png)

**Observations:**

- SIMD-accelerated parsers (`simd-csv`, `zsv`, `csv-zero`) generally dominate, but show reduced advantage on `game.csv`
- `zsc` performs exceptionally well overall but regresses noticeably on `game.csv`
- `lazycpp` is the most consistent performer across datasets
- Surprisingly, for `worldcitiespop.csv` (no quoted fields), some parsers (`csv (rust)`, `lazycsv (cpp)`) underperform

For large files:

![CSV Parser Wall Time Comparison For Larger Files](images/wall_time_xl.png)

Here, `zsc (c)`, `lazycsv (cpp)`, and `simdcsv-rust` remain consistently strong.
`csv-zero` finishes first across all tested cases.

---

### Peak RSS

![CSV Parser Peak RSS Comparison](images/peak_rss.png)

Most top parsers exhibit stable memory usage regardless of file size.
An exception is `lazycsv (cpp)`, which can consume gigabytes of memory on large inputs.

---

### Branch Misses

![CSV Parser Branch Misses Comparison](images/branch_misses.png)

Branch mispredictions often correlate strongly with wall-time performance.
Parsers with predictable control flow tend to perform better, especially on complex quoting patterns.

Parsers that rely on:

- SIMD classification
- Table-driven state machines
- Branchless or low-branch designs

generally exhibit **fewer branch misses**, which often correlates strongly with lower wall-time.

You can see this correlation by comparing parsers with low branch miss counts against their wall-time results in earlier charts. While branch misses are not the only factor affecting performance, they are frequently one of the dominant contributors in tight parsing loops.

---

### Cache Behavior

![CSV Parser Cache References Comparison](images/cache_references.png)
![CSV Parser Cache Misses Comparison](images/cache_misses.png)

Additional metrics are available in the `images` directory and raw CSV outputs.

---

## Running the Benchmarks

### Requirements

- **Poop** (Linux) or **Hyperfine**
- **Python + matplotlib** (for charts)
- **Zig 0.15.2** (for `csv-zero` and data generation)

---

### Building Parsers

All parsers live under `src/`.

The only exception is:

- `src/zig/src/data_gen.zig` — used for generating test data

To build everything:

```sh
make build_all
```

This requires:

- C
- C++
- Rust
- Go
- Zig

You are free to remove parsers you don’t care about or add your own.
`zsc (c)` requires a manual build but is straightforward if you follow its upstream instructions.

---

### Selecting Parsers and Test Files

You can customize:

- Which parsers participate
- Which test files are used
- Which metrics are collected

---

### Data Visualization

`generate_charts.py`:

- Runs benchmarks using `poop`
- Produces `output.csv`
- Writes figures to `images/`

macOS support is not yet available here.

---

### Hyperfine / Manual Runs

If `poop` is unavailable, you can still run benchmarks manually:

```sh
make hyperfine TEST_FILE=/path/to/your/file.csv
```

Adjust the Makefile targets to control which parsers and tools are used.

---

If you’d like, I can also:

- Tighten this further for GitHub skimmability
- Add a “Supported Parsers” table
- Add contribution guidelines
- Add a “How to add your parser” section
- Rewrite it in a more academic / paper-style tone

Just say the word.
