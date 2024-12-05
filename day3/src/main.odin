/*

too low: 176087131

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

check_do_operation :: proc(input: string, current_token: int) -> bool {

	new_current := current_token + 1
	if rune(input[new_current])  != 'o' {
		return false
	}
	new_current += 1

	if rune(input[new_current])  != '(' {
		return false
	}
	new_current += 1

	if rune(input[new_current])  != ')' {
		return false
	}

	fmt.println("FOUND DO")

	// new_current += 1
	return true
}

check_dont_operation :: proc(input: string, current_token: int) -> bool {
	new_current := current_token + 1

	if rune(input[new_current])  != 'o' {
		return false
	}
	new_current += 1
	if rune(input[new_current])  != 'n' {
		return false
	}
	new_current += 1
	if rune(input[new_current])  != '\'' {
		return false
	}
	new_current += 1
	if rune(input[new_current])  != 't' {
		return false
	}
	new_current += 1
	if rune(input[new_current])  != '(' {
		return false
	}
	new_current += 1
	if rune(input[new_current])  != ')' {
		return false
	}

	fmt.println("FOUND DONT")

	// new_current += 1
	return true
}

check_mul_start :: proc(input: string, current_token: int) -> (int, bool) {
	// check if we have a mul operation
	if rune(input[current_token + 1])  != 'u' {
		return current_token+1, false
	}
	if rune(input[current_token + 2])  != 'l' {
		return current_token+1, false
	}
	if rune(input[current_token + 3])  != '(' {
		return current_token+1, false
	}

	return current_token+4, true
}

is_digit :: proc(r: rune) -> bool {
	switch r {
	case '0': return true
	case '1': return true
	case '2': return true
	case '3': return true
	case '4': return true
	case '5': return true
	case '6': return true
	case '7': return true
	case '8': return true
	case '9': return true
	}

	return false
}

try_get_number :: proc(input: string, current_token: int) -> (int, int, bool) {

	last_digit := current_token
	for {
		// fmt.println("LAST DIGIT: ", input[last_digit])
		// fmt.println("LAST DIGIT RUNE: ", rune(input[last_digit]))
		if is_digit(rune(input[last_digit])) {
			// fmt.println("IS DIGIT")
			last_digit += 1
		}
		else {
			break
		}
	}

	if last_digit > current_token {
		digit_substring := input[current_token:last_digit]
		// fmt.println("DIGIT: ", digit_substring)
		// if true do os.exit(0)
		return last_digit, strconv.parse_int(digit_substring) 
	}

	return last_digit, 0, false
}

main :: proc() {
	input := read_input("input.txt")

	DO_ACTIVE: bool = true

	result := 0
	for current_token := 0; current_token < len(input); {
		current_rune := rune(input[current_token])
		if current_rune == 'm' {
			mul_found: bool
			current_token, mul_found = check_mul_start(input, current_token)
			if mul_found {
				first_operand: int
				first_operand_valid: bool

				current_token, first_operand, first_operand_valid = try_get_number(input, current_token)
				if !first_operand_valid do continue

				if rune(input[current_token]) != ',' do continue
				current_token += 1

				second_operand: int
				second_operand_valid: bool
				current_token, second_operand, second_operand_valid = try_get_number(input, current_token)
				if !second_operand_valid do continue


				// we now have both first and second operand
				if rune(input[current_token]) != ')' do continue
				current_token += 1

				
				fmt.println("FOUND MUL")
				fmt.println(first_operand, " * ", second_operand)

				if DO_ACTIVE {
					fmt.println("DO ACTIVE")
					result += first_operand * second_operand
				}
			}
		}
		else if current_rune == 'd' {
			is_do: bool
			is_do = check_do_operation(input, current_token)
			if is_do {
				DO_ACTIVE = true
				current_token += 4
				continue
			}

			is_dont: bool
			is_dont = check_dont_operation(input, current_token)
			if is_dont {
				DO_ACTIVE = false
				current_token += 7
				continue
			}

			current_token += 1
		}
		else {
			current_token += 1
		}

	}
	fmt.println("RESULT = ", result)
}
