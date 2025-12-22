#include "rapidcsv.h"
#include <iostream>
#include <string>

int main(int argc, char *argv[]) {
  if (argc != 2) {
    std::cerr << "Usage: " << argv[0] << " <csv_file>" << std::endl;
    return 1;
  }

  std::string filename = argv[1];

  try {
    // Load the CSV file (treat no row/column as labels to include headers)
    rapidcsv::Document doc(filename, rapidcsv::LabelParams(-1, -1));

    // Get the number of rows and columns (now includes header)
    size_t row_count = doc.GetRowCount();
    size_t col_count = doc.GetColumnCount();

    // Count cells by iterating over each field
    size_t total_cells = 0;

    for (size_t row = 0; row < row_count; row++) {
      for (size_t col = 0; col < col_count; col++) {
        // Get each cell (as string)
        std::string cell = doc.GetCell<std::string>(col, row);
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
