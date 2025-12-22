use std::env;
use std::fs::File;
use std::io::{Read, BufReader};

use csv_core::{Reader, ReadFieldResult};

const BUF_SIZE: usize = 64 * 1024; // 64 KB

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let path = env::args()
        .nth(1)
        .expect("usage: csv_core_cell_count <file.csv>");

    let file = File::open(path)?;
    let mut reader = BufReader::with_capacity(BUF_SIZE, file);

    let mut csv = Reader::new();
    let mut input_buf = [0u8; BUF_SIZE];
    let mut output_buf = [0u8; BUF_SIZE];
    
    let mut total_cells: u64 = 0;
    let mut input_start = 0;
    let mut input_end = 0;

    loop {
        // Shift unconsumed data to the beginning
        if input_start > 0 {
            input_buf.copy_within(input_start..input_end, 0);
            input_end -= input_start;
            input_start = 0;
        }

        // Read more data
        let n = reader.read(&mut input_buf[input_end..])?;
        if n == 0 && input_end == 0 {
            break;
        }
        input_end += n;

        // Process all available data
        while input_start < input_end {
            let (result, in_used, _out_used) =
                csv.read_field(&input_buf[input_start..input_end], &mut output_buf);

            input_start += in_used;

            match result {
                ReadFieldResult::Field { .. } => {
                    total_cells += 1;
                }
                ReadFieldResult::InputEmpty => {
                    break;
                }
                ReadFieldResult::End => {
                    if n == 0 {
                        break;
                    }
                }
                ReadFieldResult::OutputFull => {
                    // Field too large; continue streaming
                }
            }
        }

        // Break if EOF and all data consumed
        if n == 0 && input_start >= input_end {
            break;
        }
    }

    // Finalize
    if let (ReadFieldResult::Field { .. }, ..) = csv.read_field(&[], &mut output_buf) {
        total_cells += 1;
    }

    println!("info: {}", total_cells);

    Ok(())
}
