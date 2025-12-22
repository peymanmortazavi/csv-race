#include "csv.hpp"
#include <iostream>
#include <string>

int main(int argc, char *argv[]) {
  if (argc != 2) {
    std::cerr << "Usage: " << argv[0] << " <csv_file>" << std::endl;
    return 1;
  }

  std::string filename = argv[1];

  try {
    // Create CSV reader
    csv::CSVReader reader(filename);

    size_t total_cells = 0;

    // Iterate through each row
    for (csv::CSVRow &row : reader) {
      for (csv::CSVField &field : row) {
        total_cells++;
      }
    }

    std::cout << "Total number of cells (by iteration): " << total_cells
              << std::endl;

  } catch (const std::exception &e) {
    std::cerr << "Error: " << e.what() << std::endl;
    return 1;
  }

  return 0;
}
