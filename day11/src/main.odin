//  86384 too low
// 177012 too low

package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:sort"
import "core:slice"
import "core:math"
import "core:time"
import rl "vendor:raylib"
import "core:container/bit_array"

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
	// input := "125 17"

	stones := make([dynamic]u64, 0, 512000)

	//////////////////
	// PARSING
	for stone_str in strings.split_iterator(&input, " ") {
		stone_value, value_ok := strconv.parse_u64(strings.trim_space(stone_str))
		if value_ok {
			append(&stones, stone_value)
		}
		else {
			fmt.println("COULD NOT PARSE VALUE:", stone_str)
		}
	}
	fmt.println("LEN OF STARTING STONES:", len(stones))

	// rule2 :: proc(

	time_in_rule1: u64 = 0
	time_in_rule2: u64 = 0
	time_in_rule3: u64 = 0

	for blink in 0..<25 {
		i := 0
		size_before_splitting := len(stones)
		for i < size_before_splitting {
		// for i < len(stones) {

			{
				// rule 1:
				// If the stone is engraved with the number 0, it is replaced by a stone engraved with the number 1.
				cycles_start := time.read_cycle_counter()
				if stones[i] == 0 {
					stones[i] = 1
					i += 1
					continue
				}
				cycles_stop := time.read_cycle_counter()
				time_in_rule1 += cycles_stop - cycles_start
			}


			{
				// rule 2:
				// If the stone is engraved with a number that has an even number of digits, it is replaced by two stones. The left half of the digits are engraved on the new left stone, and the right half of the digits are engraved on the new right stone. (The new numbers don't keep extra leading zeroes: 1000 would become stones 10 and 0.)
				cycles_start := time.read_cycle_counter()

				digits := math.count_digits_of_base(stones[i], 10)
				if digits % 2 == 0 {
				// 10 / 2 = 1
				// 1000 / 2 = 2
				// 100000 / 2 = 3
					split_decimal := f64(stones[i]) / math.pow_f64(10, f64(digits)/2)
					first_value, second_value := math.modf_f64(split_decimal)
					stones[i] = u64(first_value)
					append(&stones, u64(second_value))
					i += 1
					cycles_stop := time.read_cycle_counter()
					time_in_rule2 += cycles_stop - cycles_start
					continue
				}


				// buffer: [128]u8
				// stone_str := strings.trim_null(fmt.bprintf(buffer[:], "%d", stones[i]))
				// if len(stone_str) % 2 == 0 {
				// 	half := len(stone_str) / 2
				// 	first_value, _ := strconv.parse_u64(stone_str[:half])

				// 	second_value, _ := strconv.parse_u64(stone_str[half:])
				// 	stones[i] = first_value

				// 	// inject_at(&stones, i+1, second_value)
				// 	// i += 2
				// 	append(&stones, second_value)
				// 	i += 1
				// 	cycles_stop := time.read_cycle_counter()
				// 	time_in_rule2 += cycles_stop - cycles_start

				// 	continue
				// }

			}

			// rule 3:
			// If none of the other rules apply, the stone is replaced by a new stone; the old stone's number multiplied by 2024 is engraved on the new stone.
			cycles_start := time.read_cycle_counter()
			stones[i] = stones[i] * 2024
			cycles_stop := time.read_cycle_counter()
			time_in_rule3 += cycles_stop - cycles_start
			i += 1
		}
		fmt.println("------ BLINK ------:", blink)
		fmt.println("time in rule1:", time_in_rule1)
		fmt.println("time in rule2:", time_in_rule2)
		fmt.println("time in rule3:", time_in_rule3)
	}

	// fmt.println("STONE:", stones)
	fmt.println("AMOUNT OF STONES:", len(stones))
}
