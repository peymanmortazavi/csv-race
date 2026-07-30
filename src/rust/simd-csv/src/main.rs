use simd_csv::{ReaderBuilder, ByteRecord};
use std::env;
use std::fs::File;

const BUF_SIZE: usize = 64 * 1024; // 64 KB

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let path = env::args()
        .nth(1)
        .expect("usage: count_fields <file.csv>");

    let file = File::open(path)?;

    let mut csv = ReaderBuilder::with_capacity(BUF_SIZE)
        .has_headers(false)
        .from_reader(file);

    let mut record = ByteRecord::new();
    let mut field_count: u64 = 0;

    while csv.read_byte_record(&mut record)? {
        field_count += record.len() as u64;
    }

    println!("fields:  {}", field_count);

    Ok(())
}
