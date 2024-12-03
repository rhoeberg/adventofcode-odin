package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:sort"

read_input :: proc(filename: string) -> string {
	file, err := os.open("input.txt")
	if err != os.ERROR_NONE {
		fmt.println("Could not open file")
		os.exit(1)
	}

	data, ok := os.read_entire_file_from_handle(file)
	if !ok {
		fmt.println("could not read file")
		os.exit(1)
	}

	data_string : string = string(data)
	reports, split_ok := strings.split_lines(data_string)
	if split_ok != .None {
		fmt.println("could not split reports into lines")
		os.exit(1)
	}
	
	return data_string
}

main :: proc() {
	input := read_input("input.txt")
	// fmt.println(input)

	for c in input {
		fmt.println(c)
	}
}

