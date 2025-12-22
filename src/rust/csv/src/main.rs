use std::env;
use std::fs::File;
use std::io::BufReader;

use csv::{ReaderBuilder, ByteRecord};

const BUF_SIZE: usize = 64 * 1024; // 64 KB

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let path = env::args()
        .nth(1)
        .expect("usage: csv_cell_count <file.csv>");

    let file = File::open(path)?;
    let reader = BufReader::with_capacity(BUF_SIZE, file);

    let mut csv = ReaderBuilder::new().has_headers(false).from_reader(reader);

    let mut record = ByteRecord::new();
    let mut total_cells: u64 = 0;

    while csv.read_byte_record(&mut record)? {
        total_cells += record.len() as u64;
    }

    println!("info: {}", total_cells);

    Ok(())
}
