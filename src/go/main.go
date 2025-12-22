package main

import (
	"encoding/csv"
	"io"
	"log"
	"os"
)

func main() {
	if len(os.Args) < 2 {
		log.Fatalf("missing filename")
	}
	filename := os.Args[1]
	file, err := os.Open(filename)
	if err != nil {
		log.Fatalf("failed to open %q: %v", filename, err)
	}
	defer file.Close()

	reader := csv.NewReader(file)
	reader.ReuseRecord = true
	field_count := 0
	for {
		record, err := reader.Read()
		if err != nil {
			if err == io.EOF {
				break
			}

			log.Fatalf("err: %v", err)
		}
		field_count += len(record)
	}

	log.Printf("count: %d", field_count)
}
