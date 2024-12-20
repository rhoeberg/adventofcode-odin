package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:sort"

main :: proc() {
	fmt.println("hello wurld")

	file, err := os.open("input.txt")
	// if err == os.General_Error.None {
	if err != os.ERROR_NONE {
		fmt.println("Could not open file")
		os.exit(1)
	}

	data, ok := os.read_entire_file_from_handle(file)
	if !ok {
		fmt.println("could not read file")
		os.exit(1)
	}

	first_column : [dynamic]int
	second_column : [dynamic]int

	// fmt.printf("%s\n", data)
	data_string : string = string(data)
	parts, split_ok := strings.split_multi(data_string, {" ", "\n"})
	it := &data_string

	index := 0
	for part in strings.split_multi_iterate(it, {" ", "\n"})  {
		if len(part) > 0 {
			index += 1

			// parse int
			part_int, int_ok := strconv.parse_int(part)
			if !int_ok {
				fmt.println("could not parse int from string: ", part)
				os.exit(1)
				
			}
			
			// add to columns
			if index % 2 == 1 {
				append(&first_column, part_int)
			}
			else {
				append(&second_column, part_int)
			}
		}
	}

	sort.quick_sort(first_column[:])
	sort.quick_sort(second_column[:])
	// fmt.println(first_column)
	// fmt.println(second_column)

	assert(len(first_column) == len(second_column), "columns are not same length!")
	fmt.println("length of columns: ", len(first_column))



	current_length := 0
	for i in 0..<len(first_column) {
		// fmt.print(i, " ")
		current_length += abs(first_column[i] - second_column[i])
	}

	fmt.println("distance size: ", current_length)


	// second part
	similarity_score := 0
	for i in 0..<len(first_column) {
		similarity_score += (first_column[i] * occurences_in_second(first_column[i], second_column[:]))
	}


	fmt.println("similarity: ", similarity_score)

}

occurences_in_second :: proc(value: int, second: []int) -> int {
	count := 0
	for second_value in second {
		if value == second_value {
			count += 1
		}
	}

	return count
}
