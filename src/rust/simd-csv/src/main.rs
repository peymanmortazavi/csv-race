use simd_csv::{ReaderBuilder, ByteRecord};
use std::env;
use std::fs::File;
use std::io::BufReader;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let path = env::args()
        .nth(1)
        .expect("usage: count_fields <file.csv>");

    let file = File::open(path)?;
    let reader = BufReader::new(file);

    let mut csv = ReaderBuilder::new()
        .has_headers(false)
        .from_reader(reader);

    let mut record = ByteRecord::new();
    let mut field_count: u64 = 0;

    while csv.read_byte_record(&mut record)? {
        field_count += record.len() as u64;
    }

    println!("fields:  {}", field_count);

    Ok(())
}
