import re
import csv
from collections import defaultdict
import subprocess
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter


TEST_FILES = [
    # {
    #     'path': './data/gen/xs_mix_quotes_12_col_0_32.csv',
    #     'name': 'XS Mix Quotes, 12 col, 0-32 chars',
    # },
    # {
    #     'path': './data/gen/xs_no_quotes_52_col_0_256.csv',
    #     'name': 'XS No Quotes, 52 col, 0-256 chars',
    # },
    # {
    #     'path': './data/gen/m_mix_quotes_12_col_0_32.csv',
    #     'name': 'M Mix Quotes, 12 col, 0-32 chars',
    # },
    # {
    #     'path': './data/gen/m_no_quotes_52_col_0_256.csv',
    #     'name': 'M No Quotes, 52 col, 0-256 chars',
    # },
    {
        'path': './data/gen/xl_mix_quotes_12_col_0_32.csv',
        'name': 'XL Mix Quotes, 12 col, 0-32 chars',
    },
    {
        'path': './data/gen/xl_mix_quotes_2_col_0_12_many_rows.csv',
        'name': 'XL Mix Quotes, 2 col, 0-12 chars, many rows',
    },
    {
        'path': './data/gen/xl_no_quotes_52_col_0_256.csv',
        'name': 'XL No Quotes, 52 col, 0-256 chars',
    },
    # {
    #     'path': './data/nfl.csv',
    #     'name': 'nfl.csv',
    # },
    # {
    #     'path': './data/worldcitiespop.csv',
    #     'name': 'worldcitiespop.csv',
    # },
    # {
    #     'path': './data/gtfs-mbta-stop-times.csv',
    #     'name': 'mbta-stop-times.csv',
    # },
    # {
    #     'path': './data/game.csv',
    #     'name': 'game.csv',
    # },
]
PARSERS = [
    {'name': 'zcsv (zig)', 'path':  './src/zig/zig-out/bin/zcsv', 'bar_color': '#EBB101'},
    {'name': 'zsc (c)', 'path': './src/c/zsv/count_fields', 'bar_color': '#9AC3B4'},
    {'name': 'lazycsv (cpp)', 'path':  './src/cpp/lazycsv/count_fields', 'bar_color': '#9A89B3'},
    {'name': 'simd-csv (rust)', 'path':  './src/rust/simd-csv/target/release/count_fields', 'bar_color': '#90ACC2'},
    {'name': 'csv (rust)', 'path':  './src/rust/csv/target/release/count_fields', 'bar_color': '#C69B9C'},
]
POOP_PATH = '/home/peyman/Downloads/x86_64-linux-poop'


def parse_scalar(value: str) -> int:
    [value, unit] = re.findall(r'(\d+[.]?\d*)(.*)', value)[0]
    units = {
        '': 1,
        'K': 1e3,
        'M': 1e6,
        'G': 1e9,
    }
    return float(value) * units[unit]


def scalar_formatter(x, *args):
    if x < 1e3:
        return f"{x:.0f}"
    elif x < 1e6:
        return f"{x/1e3:.1f} K"
    elif x < 1e9:
        return f"{x/1e6:.1f} M"
    else:
        return f"{x/1e9:.1f} G"


def parse_memory_size(value: str) -> int:
    [value, unit] = re.findall(r'(\d+[.]?\d*)(.*)', value)[0]
    units = {
        'KB': 1,
        'MB': 1e3,
        'GB': 1e6,
    }
    return float(value) * units[unit]


def memory_formatter(x, *args):
    if x < 1:
        return f"{x*1000:.0f} bytes"
    elif x < 1e3:
        return f"{x:.0f} KB"
    elif x < 1e6:
        return f"{x/1e3:.3f} MB"
    else:
        return f"{x/1e6:.3f} GB"


def parse_wall_time(value: str) -> int:
    [value, unit] = re.findall(r'(\d+[.]?\d*)(.*)', value)[0]
    units = {
        'ms': 1,
        'us': 1/1e3,
        's': 1e3,
    }
    return float(value) * units[unit]


def time_formatter(x, *args):
    if x < 1:
        return f"{x*1000:.0f} µs"
    elif x < 1000:
        return f"{x:.2f} ms"
    else:
        return f"{x/1000:.3f} s"


METRICS = {
    'wall_time': {
        'parse_func': parse_wall_time, 'display_func': time_formatter,
        'x': 'Wall Time - Less is better', 'title': 'CSV Parser Wall Time Performance Comparison' },
    'peak_rss': {
        'parse_func': parse_memory_size, 'display_func': memory_formatter,
        'x': 'Peak RSS - Less is better', 'title': 'CSV Parser Peak RSS Comparison' },
    'branch_misses': {
        'parse_func': parse_scalar, 'display_func': scalar_formatter,
        'x': 'Branch Misses - Less is better', 'title': 'CSV Parser Branch Misses Comparison' },
    'cache_misses': {
        'parse_func': parse_scalar, 'display_func': scalar_formatter,
        'x': 'Cache Misses', 'title': 'CSV Parser Cache Misses Comparison' },
    'cache_references': { 
        'parse_func': parse_scalar, 'display_func': scalar_formatter,
        'x': 'Cache References', 'title': 'CSV Parser Cache References Comparison' },
    'instructions': { 
        'parse_func': parse_scalar, 'display_func': scalar_formatter,
        'x': 'Instructions', 'title': 'CSV Parser CPU Instructions Comparison' },
    'cpu_cycles': {
        'parse_func': parse_scalar, 'display_func': scalar_formatter,
        'x': 'CPU Cycles', 'title': 'CSV Parser CPU Cycles Comparison' },
}


def capture_output(test_file: str) -> dict:
    args = [POOP_PATH, '--color', 'never', '-d', '10000']
    for parser in PARSERS:
        path = parser['path']
        args.append(f'{path} {test_file}')
    result = subprocess.run(args, check=True, capture_output=True).stdout

    lines = result.decode('utf-8').splitlines()
    benchmark_lines = []
    data = {}
    index = 0
    for line in lines:
        if line.startswith('Benchmark'):
            if benchmark_lines:
                info = capture_benchmark_info(benchmark_lines)
                parser_name = PARSERS[index]['name']
                data[parser_name] = info
                index += 1
                benchmark_lines = []
            continue
        benchmark_lines.append(line)
    if benchmark_lines:
        info = capture_benchmark_info(benchmark_lines)
        parser_name = PARSERS[index]['name']
        data[parser_name] = info
    return data


def capture_benchmark_info(lines: [str]) -> dict:
    lines.pop(0)
    data = {}
    for line in lines:
        parts = line.split()
        if len(parts) >= 2:
            data[parts[0]] = parts[1]
    return data


def create_charts(tests: dict):
    for metric in METRICS:
        metric_details = METRICS[metric]
        test_names = []
        test_data = defaultdict(lambda: [])
        for test_name in tests:
            test_names.append(test_name)
            test_result = tests[test_name]
            for parser in test_result:
                info = test_result[parser]
                val = metric_details['parse_func'](info[metric])
                test_data[parser].append(val)

        fig, ax = plt.subplots(layout='constrained', figsize=(20, 12))
        height = 0.14
        num_parsers = len(test_data)
        y_positions = range(len(test_names))

        index = 0
        for parser in PARSERS:
            name = parser['name']
            values = test_data[name]
            # Offset each parser's bars so they stack next to each other
            offset = (index - num_parsers/2 + 0.5) * height
            y_pos = [y + offset for y in y_positions]
            rects = ax.barh(y_pos, values,
                            height=height,
                            label=name,
                            color=parser['bar_color'],
                            edgecolor='#333',
                            linewidth=0.5)
            ax.bar_label(rects, padding=3, fmt=metric_details['display_func'])
            index += 1

        ax.set_yticks(y_positions)
        ax.set_yticklabels(test_names)
        ax.set_xlabel(metric_details['x'])
        ax.set_ylabel("Test Files")
        ax.set_title(metric_details['title'])
        ax.xaxis.set_major_formatter(FuncFormatter(metric_details['display_func']))
        plt.gcf().set_dpi(200)
        plt.legend(test_data.keys())
        plt.savefig(f'images/{metric}.png')
        plt.close()


data = {}
for test in TEST_FILES:
    data[test['name']] = capture_output(test['path'])


with open('output.csv', 'w', newline='') as file:
    writer = csv.writer(file)
    writer.writerow([
        'test',
        'parser',
        'wall_time',
        'peak_rss',
        'branch_misses',
        'cache_misses',
        'cache_references',
        'instructions',
        'cpu_cycles',
    ])
    for test_name in data:
        test_details = data[test_name]
        for parser in test_details:
            info = test_details[parser]
            writer.writerow([
                test_name,
                parser,
                info['wall_time'],
                info['peak_rss'],
                info['branch_misses'],
                info['cache_misses'],
                info['cache_references'],
                info['instructions'],
                info['cpu_cycles'],
            ])

create_charts(data)
