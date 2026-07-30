use std::env;
use std::fs::File;

use csv::{ReaderBuilder, ByteRecord};

const BUF_SIZE: usize = 64 * 1024; // 64 KB

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let path = env::args()
        .nth(1)
        .expect("usage: csv_cell_count <file.csv>");

    let file = File::open(path)?;

    let mut csv = ReaderBuilder::new().buffer_capacity(BUF_SIZE).has_headers(false).from_reader(file);

    let mut record = ByteRecord::new();
    let mut total_cells: u64 = 0;

    while csv.read_byte_record(&mut record)? {
        total_cells += record.len() as u64;
    }

    println!("info: {}", total_cells);

    Ok(())
}
