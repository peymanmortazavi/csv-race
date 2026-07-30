use simd_csv::{ReaderBuilder, ZeroCopyReaderBuilder, SplitterBuilder, ByteRecord};
use std::env;
use std::fs::File;

const BUF_SIZE: usize = 64 * 1024; // 64 KB

static USAGE: &str = "usage: count_fields <file.csv> [--zero-copy|--splitter]";

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = env::args().skip(1).collect::<Vec<_>>();

    let path = args.first()
        .expect(USAGE);

    let file = File::open(path)?;

    let field_count = match args.get(1).map(|a| a.as_str()) {
        // Copy reader
        None => {
            let mut csv = ReaderBuilder::with_capacity(BUF_SIZE)
                .has_headers(false)
                .from_reader(file);

            let mut record = ByteRecord::new();
            let mut field_count: u64 = 0;

            while csv.read_byte_record(&mut record)? {
                field_count += record.len() as u64;
            }

            field_count
        },

        // Zero-copy reader
        Some("--zero-copy") => {
            let mut csv = ZeroCopyReaderBuilder::with_capacity(BUF_SIZE)
                .has_headers(false)
                .from_reader(file);

            let mut field_count: u64 = 0;

            while let Some(record) = csv.read_byte_record()? {
                field_count += record.len() as u64;
            }

            field_count
        },

        // Splitter
        Some("--splitter") => {
            let mut csv = SplitterBuilder::with_capacity(BUF_SIZE)
                .has_headers(false)
                .from_reader(file);

            let cols = csv.byte_headers()?.iter().filter(|c| **c == b',').count() as u64 + 1;

            let mut field_count: u64 = 0;

            while csv.split_record()?.is_some() {
                field_count += cols;
            }

            field_count
        }

        _ => panic!("{}", USAGE)
    };

    println!("fields:  {}", field_count);

    Ok(())
}
