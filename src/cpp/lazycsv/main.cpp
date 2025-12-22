#include "lazycsv.h"
#include <iostream>
#include <string>

int main(int argc, char *argv[]) {
  if (argc != 2) {
    std::cerr << "Usage: " << argv[0] << " <csv_file>" << std::endl;
    return 1;
  }

  std::string filename = argv[1];

  try {
    // Create a LazyCSV parser
    lazycsv::parser<lazycsv::mmap_source, lazycsv::has_header<false>> parser(
        filename);

    int record_count = 0;

    // Iterate through each row
    for (const auto &row : parser) {
      for (const auto &col : row) {
        record_count++;
      }
    }

    std::cout << "Total number of records: " << record_count << std::endl;

  } catch (const std::exception &e) {
    std::cerr << "Error: " << e.what() << std::endl;
    return 1;
  }

  return 0;
}
