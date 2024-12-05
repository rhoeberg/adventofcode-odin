/*
2127 too low
*/
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
	count_xmas(input)
	count_x_mas(input)
}

count_x_mas :: proc(input: string) {
	// 1848 too low
	input := input
	input_it := &input
	lines: [dynamic]string
	for line in strings.split_iterator(input_it, "\n") {
		if len(line) > 0 {
			append(&lines, line)
		}
	}

	fmt.println("LINES HORIZONTAL: ", len(lines))
	fmt.println("LINES VERTICAL: ", len(lines[0]))
	
	count := 0

	forward_SE :: proc(lines: ^[dynamic]string, line_index: int, char_index: int) -> bool {
		if lines[line_index][char_index] != 'M' do return false
		if lines[line_index+1][char_index+1] != 'A' do return false
		if lines[line_index+2][char_index+2] != 'S' do return false
		// fmt.println("FOUND FORWARD SE")
		return true
	}

	backward_SE :: proc(lines: ^[dynamic]string, line_index: int, char_index: int) -> bool {
		if lines[line_index][char_index] != 'S' do return false
		if lines[line_index+1][char_index+1] != 'A' do return false
		if lines[line_index+2][char_index+2] != 'M' do return false
		// fmt.println("FOUND BACKWARD SE")
		return true
	}

	forward_SW :: proc(lines: ^[dynamic]string, line_index: int, char_index: int) -> bool {
		if lines[line_index][char_index] != 'M' do return false
		if lines[line_index+1][char_index-1] != 'A' do return false
		if lines[line_index+2][char_index-2] != 'S' do return false
		// fmt.println("FOUND FORWARD SW")
		return true
	}

	backward_SW :: proc(lines: ^[dynamic]string, line_index: int, char_index: int) -> bool {
		if lines[line_index][char_index] != 'S' do return false
		if lines[line_index+1][char_index-1] != 'A' do return false
		if lines[line_index+2][char_index-2] != 'M' do return false
		// fmt.println("FOUND BACKWARD SW")
		return true
	}

	for line_index in 0..<len(lines)-2 {
		for char_index  in 0..<len(lines[line_index])-2 {
			if !forward_SE(&lines, line_index, char_index) && !backward_SE(&lines, line_index, char_index) do continue
			if !forward_SW(&lines, line_index, char_index+2) && !backward_SW(&lines, line_index, char_index+2) do continue

			// fmt.println("FOUND X MAS")
			l11 := lines[line_index][char_index]
			l13 := lines[line_index][char_index+2]
			l21 := lines[line_index+1][char_index+1]
			l31 := lines[line_index+2][char_index]
			l33 := lines[line_index+2][char_index+2]
			// fmt.printf("%c.%c\n.%c.\n%c.%c\n", l11, l13, l21, l31, l33)
			count += 1
		}
	}

	fmt.println("amount of x MAS: ", count)
}

count_xmas :: proc(input: string) {
	input := input
	input_it := &input
	lines: [dynamic]string
	for line in strings.split_iterator(input_it, "\n") {
		if len(line) > 0 {
			append(&lines, line)
		}
	}

	count := 0

	// FORWARD XMAS
	for line_index in 0..<len(lines) {
		for char_index in 0..<len(lines[line_index])-3 {
			// if i+3 > len(line)-1 {
				// no more room for xmas on line
				// continue to next line
				// break
			// }

			if lines[line_index][char_index] != 'X' do continue
			if lines[line_index][char_index+1] != 'M' do continue
			if lines[line_index][char_index+2] != 'A' do continue
			if lines[line_index][char_index+3] != 'S' do continue

			// we have found XMAS
			// fmt.printf("xmas on line:%d, %s\n", line_index, lines[line_index][char_index:char_index+4])
			count += 1
		}

	}

	// BACKWARD XMAS
	for line_index in 0..<len(lines) {
		for char_index in 0..<len(lines[line_index])-3 {
			// if i+3 > len(line)-1 {
				// no more room for xmas on line
				// continue to next line
				// break
			// }

			if lines[line_index][char_index] != 'S' do continue
			if lines[line_index][char_index+1] != 'A' do continue
			if lines[line_index][char_index+2] != 'M' do continue
			if lines[line_index][char_index+3] != 'X' do continue

			// we have found XMAS
			// fmt.printf("samx on line:%d, %s\n", line_index, lines[line_index][char_index:char_index+4])
			count += 1
		}
	}

	// VERTICAL FORWARD
	for line_index in 0..<len(lines)-3 {
		for char_index in 0..<len(lines[line_index]) {
			if lines[line_index][char_index] != 'X' do continue
			if lines[line_index+1][char_index] != 'M' do continue
			if lines[line_index+2][char_index] != 'A' do continue
			if lines[line_index+3][char_index] != 'S' do continue

			// we have found XMAS
			char_x := lines[line_index][char_index]
			char_m := lines[line_index+1][char_index]
			char_a := lines[line_index+2][char_index]
			char_s := lines[line_index+3][char_index]

			// fmt.printf("FOUND VERTICAL FORWARD: %d %d %c%c%c%c\n", line_index, char_index, char_x, char_m, char_a, char_s)

			count += 1
		}
	}

	// VERTICAL BACKWARDS
	for line_index in 0..<len(lines)-3 {
		for char_index in 0..<len(lines[line_index]) {
			if lines[line_index][char_index] != 'S' do continue
			if lines[line_index+1][char_index] != 'A' do continue
			if lines[line_index+2][char_index] != 'M' do continue
			if lines[line_index+3][char_index] != 'X' do continue

			// we have found XMAS
			char_x := lines[line_index][char_index]
			char_m := lines[line_index+1][char_index]
			char_a := lines[line_index+2][char_index]
			char_s := lines[line_index+3][char_index]

			// fmt.printf("FOUND VERTICAL BACKWARD: %d %d %c%c%c%c\n", line_index, char_index, char_x, char_m, char_a, char_s)

			count += 1
		}
	}

	// SOUTH_EAST FORWARD
	for line_index in 0..<len(lines)-3 {
		for char_index in 0..<len(lines[line_index])-3 {
			if lines[line_index][char_index] != 'X' do continue
			if lines[line_index+1][char_index+1] != 'M' do continue
			if lines[line_index+2][char_index+2] != 'A' do continue
			if lines[line_index+3][char_index+3] != 'S' do continue

			// found XMAS
			char_x := lines[line_index][char_index]
			char_m := lines[line_index+1][char_index+1]
			char_a := lines[line_index+2][char_index+2]
			char_s := lines[line_index+3][char_index+3]
			// fmt.printf("FOUND DIAGONAL XMAS: %d %d %c%c%c%c\n", line_index, char_index, char_x, char_m, char_a, char_s)
			count += 1
		}
	}

	// SOUTH_EAST BACKWARD
	for line_index in 0..<len(lines)-3 {
		for char_index in 0..<len(lines)-3 {
			if lines[line_index][char_index] != 'S' do continue
			if lines[line_index+1][char_index+1] != 'A' do continue
			if lines[line_index+2][char_index+2] != 'M' do continue
			if lines[line_index+3][char_index+3] != 'X' do continue

			// found XMAS
			char_x := lines[line_index][char_index]
			char_m := lines[line_index+1][char_index+1]
			char_a := lines[line_index+2][char_index+2]
			char_s := lines[line_index+3][char_index+3]
			// fmt.printf("FOUND DIAGONAL SAMX: %d %d %c%c%c%c\n", line_index, char_index, char_x, char_m, char_a, char_s)
			count += 1
		}
	}

	// SOUTH_WEST FORWARD
	for line_index in 0..<len(lines)-3 {
		for char_index in 3..<len(lines) {
			if lines[line_index][char_index] != 'X' do continue
			if lines[line_index+1][char_index-1] != 'M' do continue
			if lines[line_index+2][char_index-2] != 'A' do continue
			if lines[line_index+3][char_index-3] != 'S' do continue

			// found XMAS
			char_x := lines[line_index][char_index]
			char_m := lines[line_index+1][char_index-1]
			char_a := lines[line_index+2][char_index-2]
			char_s := lines[line_index+3][char_index-3]
			// fmt.printf("FOUND SW XMAS: %d %d %c%c%c%c\n", line_index, char_index, char_x, char_m, char_a, char_s)
			count += 1
		}
	}

	// SOUTH_WEST BACKWARD
	for line_index in 0..<len(lines)-3 {
		for char_index in 3..<len(lines) {
			if lines[line_index][char_index] != 'S' do continue
			if lines[line_index+1][char_index-1] != 'A' do continue
			if lines[line_index+2][char_index-2] != 'M' do continue
			if lines[line_index+3][char_index-3] != 'X' do continue

			// found XMAS
			char_x := lines[line_index][char_index]
			char_m := lines[line_index+1][char_index-1]
			char_a := lines[line_index+2][char_index-2]
			char_s := lines[line_index+3][char_index-3]
			// fmt.printf("FOUND SW SAMX: %d %d %c%c%c%c\n", line_index, char_index, char_x, char_m, char_a, char_s)
			count += 1
		}
	}

	fmt.println("RESULT: ", count)

	/*
	        0000000000000
	        0000000000000
	        0000000000000
	        0000000000000
	        0000000000000

	        len = 5
            0 < 5-3 = run
            1 < 5-3 = run
            2 < 5-3 = dont run



            0000
            len = 4
            0 < 4-3 = run
            1 < 4-3 = dont run
    */
}
