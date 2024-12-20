package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:sort"
import "core:slice"
import "core:math"
import rl "vendor:raylib"
import "core:container/bit_array"

Operator :: enum {
	Add,
	Mult,
	Concat,
}

Equation :: struct {
	result: int,
	operands: [dynamic]int,
}

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
	equations: [dynamic]Equation

	//////////////////
	// PARSING
	for line in strings.split_lines_iterator(&input) {
		equation: Equation

		parts := strings.split(line, ":")
		result, _ := strconv.parse_int(parts[0])
		equation.result = result

		// fmt.println("RESULT: ", result)
		value_part := strings.trim_space(parts[1])
		for value in strings.split_iterator(&value_part, " ") {
			value_int, _ := strconv.parse_int(value)
			append(&equation.operands, value_int)
		}

		append(&equations, equation)
	}

	/////////////////
	// SOLVING
	result := 0
	for equation in equations {
		if try_all_permutations(equation) {
			result += equation.result
		}
	}
	fmt.println("RESULT: ", result)

	result_part_2 := 0
	for equation, i in equations {
		if try_all_permutations_3(equation) {
			result_part_2 += equation.result
		}
	}
	fmt.println("RESULT PART 2: ", result_part_2)
}

try_all_permutations :: proc(equation: Equation) -> bool {
	amount_of_operators := len(equation.operands)-1
	amount_of_combinations := 1 << u64(amount_of_operators)
	My_Bit_Set :: bit_set[0..<64; u64]
	// fmt.println("amount of combos:", amount_of_combinations)
	for combination := 0; combination < amount_of_combinations; combination += 1 {
		test_operators := make([dynamic]Operator, context.temp_allocator)
		bits := transmute(My_Bit_Set)combination
		for bit_index in 0..<amount_of_operators {
			if bit_index in bits {
				append(&test_operators, Operator.Mult)
			}
			else {
				append(&test_operators, Operator.Add)
			}
		}

		if try_equation(equation.operands[:], test_operators[:]) == equation.result do return true
	}

	return false
}

try_all_permutations_3 :: proc(equation: Equation) -> bool {
	operators: [dynamic]Operator
	for i in 0..<len(equation.operands)-1 {
		append(&operators, Operator.Add)
	}

	all_are_concat :: proc(operators: []Operator) -> bool {
		for operator in operators {
			if operator == .Add do return false
			if operator == .Mult do return false
		}

		return true
	}

	increment_operators :: proc(operators: []Operator) {
		for operator, i in operators {
			if operator == .Add {
				operators[i] = .Mult
				break
			}
			if operator == .Mult {
				operators[i] = .Concat
				break
			}
			if operator == .Concat {
				operators[i] = .Add
			}
		}
	}

	if try_equation(equation.operands[:], operators[:]) == equation.result do return true

	for !all_are_concat(operators[:]) {
		increment_operators(operators[:])
		if try_equation(equation.operands[:], operators[:]) == equation.result do return true
	}

	return false
}

try_equation :: proc(operands: []int, operators: []Operator) -> int {
	assert(len(operators) == len(operands)-1)

	current_result := operands[0]
	for i in 1..<len(operands) {
		switch operators[i-1] {
		case .Add:
			current_result += operands[i]
		case .Mult:
			current_result *= operands[i]
		case .Concat:
			buffer: [128]u8
			fmt.bprintf(buffer[:], "%d%d", current_result, operands[i])
			str_value := string(buffer[:])
			str_value = strings.trim_null(str_value)

			ok: bool
			current_result, ok = strconv.parse_int(str_value)
			if !ok {
				fmt.println("FAILED to convert value to string")
				fmt.println("str_val:", str_value)
				os.exit(1)
			}
		}
	}

	return current_result
}
