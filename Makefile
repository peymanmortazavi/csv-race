TEST_FILE=./data/worldcitiespop.csv
# TEST_FILE=./data/nfl.csv
# TEST_FILE=./data/game.csv
# TEST_FILE=./data/gtfs-mbta-stop-times.csv

# TEST_FILE=./data/gen/m_mix_quotes_12_col_0_32.csv
# TEST_FILE=./data/gen/m_no_quotes_52_col_0_256.csv
# TEST_FILE=./data/gen/xl_mix_quotes_12_col_0_32.csv
# TEST_FILE=./data/gen/xl_mix_quotes_2_col_0_12_many_rows.csv
# TEST_FILE=./data/gen/xl_no_quotes_52_col_0_256.csv
# TEST_FILE=./data/gen/xs_mix_quotes_12_col_0_32.csv
# TEST_FILE=./data/gen/xs_no_quotes_52_col_0_256.csv

POOP=~/Downloads/x86_64-linux-poop

hyperfine:
	hyperfine -N --warmup 20 \
		"./src/rust/csv/target/release/count_fields ${TEST_FILE}" \
		"./src/rust/csv_core/target/release/count_fields ${TEST_FILE}" \
		"./src/rust/simd-csv/target/release/count_fields ${TEST_FILE}" \
		"./src/zig/zig-out/bin/csvzero ${TEST_FILE}" \
		"./src/c/zsv/count_fields ${TEST_FILE}" \
		"./src/cpp/csv-parser/count_fields ${TEST_FILE}" \
		"./src/cpp/lazycsv/count_fields ${TEST_FILE}" \
		"./src/cpp/rapidcsv/count_fields ${TEST_FILE}" \
		"./src/go/count_fields ${TEST_FILE}"

poop:
	${POOP} -d 10000 \
		"./src/rust/csv/target/release/csv-race ${TEST_FILE}" \
		"./src/rust/csv_core/target/release/csv_race ${TEST_FILE}" \
		"./src/rust/simd-csv/target/release/csv-race ${TEST_FILE}" \
		"./src/zig/zig-out/bin/csvzero ${TEST_FILE}" \
		"./src/c/zsv/count_fields ${TEST_FILE}" \
		"./src/cpp/csv-parser/count_fields ${TEST_FILE}" \
		"./src/cpp/lazycsv/count_fields ${TEST_FILE}" \
		"./src/cpp/rapidcsv/count_fields ${TEST_FILE}" \
		"./src/go/count_fields ${TEST_FILE}"

.PHONY:test
test:
		./src/rust/csv/target/release/csv-race ${TEST_FILE}
		./src/rust/csv_core/target/release/csv_race ${TEST_FILE}
		./src/rust/simd-csv/target/release/csv-race ${TEST_FILE}
		./src/zig/zig-out/bin/csvzero ${TEST_FILE}
		./src/c/zsv/count_fields ${TEST_FILE}
		./src/cpp/csv-parser/count_fields ${TEST_FILE}
		./src/cpp/lazycsv/count_fields ${TEST_FILE}
		./src/cpp/rapidcsv/count_fields ${TEST_FILE}
		./src/go/count_fields ${TEST_FILE}

generate_data:
	@mkdir -p data/gen
	@cd ./src/zig/ && zig build --release=fast
	@./src/zig/zig-out/bin/datagen

build_all:
	@cd src/c/zsv && ./build.sh
	@cd src/cpp/csv-parser && ./build.sh
	@cd src/cpp/lazycsv && ./build.sh
	@cd src/cpp/rapidcsv && ./build.sh
	@cd src/go && go build .
	@cd src/rust/csv && cargo build --release
	@cd src/rust/csv_core && cargo build --release
	@cd src/rust/simd-csv && cargo build --release
	@cd src/zig && zig build --release=fast
