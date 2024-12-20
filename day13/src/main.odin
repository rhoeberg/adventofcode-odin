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

Vec2 :: [2]int

Claw_Machine :: struct {
	button_a: Vec2,
	button_b: Vec2,
	price: Vec2,
}

main :: proc() {
	input := read_input("input.txt")

	//////////////////
	// PARSING

	claw_machines: [dynamic]Claw_Machine
	for block in strings.split_iterator(&input, "\n\n") {
		if len(block) <= 0 do break


		lines := strings.split_lines(block)

		claw_machine: Claw_Machine

		a_x_index := strings.index(lines[0], "X+") + 2
		a_y_index := strings.index(lines[0], "Y+") + 2
		claw_machine.button_a.x, _ = strconv.parse_int(lines[0][a_x_index:a_x_index+2])
		claw_machine.button_a.y, _ = strconv.parse_int(lines[0][a_y_index:a_y_index+2])

		b_x_index := strings.index(lines[1], "X+") + 2
		b_y_index := strings.index(lines[1], "Y+") + 2
		claw_machine.button_b.x, _ = strconv.parse_int(lines[1][b_x_index:b_x_index+2])
		claw_machine.button_b.y, _ = strconv.parse_int(lines[1][b_y_index:b_y_index+2])

		price_x_index := strings.index(lines[2], "X=") + 2
		price_x_index_end := strings.index(lines[2], ",")
		price_y_index := strings.index(lines[2], "Y=") + 2
		claw_machine.price.x, _ = strconv.parse_int(lines[2][price_x_index:price_x_index_end])
		claw_machine.price.y, _ = strconv.parse_int(lines[2][price_y_index:])

		// fmt.println(claw_machine)
		append(&claw_machines, claw_machine)
	}

	part_1(&claw_machines)
	// part_2(&claw_machines)
}

// find_multiple_or_closest2 :: proc(button, price: Vec2) -> (int, bool) {
// 	for i := 0; ; i += 1{
// 		current := button * i

// 		if current == price {
// 			return i, true
// 		} 
// 		else if current.x > price.x || current.y > price.y {
// 			return i-1, false
// 		}
// 	}
// 	return -1, false
// }

find_multiple_or_closest :: proc(button, price: Vec2) -> (int, bool) {
	if price.x % button.x == 0 {
		// fmt.println("FOUND MULTIPLE OF X")
		// we have a multiple
		multiple := price.x / button.x
		// fmt.println("price x, button x:", price.x, button.x)
		// fmt.println("multiple:", multiple)
		// fmt.println("price y, button y:", price.y, button.y)
		if button.y * multiple == price.y {
			return multiple, true
		}
	}

	x_multiple :=  price.x / button.x
	y_multiple :=  price.y / button.y
	// fmt.println("x and y multiple:", x_multiple, y_multiple)
	return min(x_multiple, y_multiple), false
}

get_machine_tokens :: proc(button_a, button_b, price: Vec2) -> int {
	result := 0


	price_for_a_x := (f32(price.x) / f32(button_a.x)) * 3
	price_for_b_x := (f32(price.x) / f32(button_b.x))

	price_for_a_y := (f32(price.y) / f32(button_a.y)) * 3
	price_for_b_y := (f32(price.y) / f32(button_b.y))

	total_price_a := price_for_a_x + price_for_a_y
	total_price_b := price_for_b_x + price_for_b_y

	if total_price_a < total_price_b {
		// A IS CHEAPER
		closest, is_multiple := find_multiple_or_closest(button_a, price)

		if !is_multiple {
			for i := closest; i >= 0; i -= 1 {
				left := price - (button_a * i)
				closest_b, b_is_multiple := find_multiple_or_closest(button_b, left)
				if b_is_multiple {
					// price of machine is:
					// i a buttons
					// closest_b b buttons
					// i * 3 + closest_b
					price := (i * 3) + closest_b
					result = price

				}
			}
		}
		else {
			result = closest*3
		}
	}
	else {
		// B IS CHEAPER
		closest, is_multiple := find_multiple_or_closest(button_b, price)

		if !is_multiple {
			for i := closest; i >= 0; i -= 1 {
				left := price - (button_b * i)
				closest_a, a_is_multiple := find_multiple_or_closest(button_a, left)


				if a_is_multiple {
					// price of machine is:
					// i a buttons
					// closest_b b buttons
					// i * 3 + closest_b
					price := i + (closest_a * 3)
					result = price

				}
			}
		}
		else {
			result = closest
		}
	}

	return result

}

part_1 :: proc(claw_machines: ^[dynamic]Claw_Machine) {
	// try to get as many of the cheapest button 
	total_tokens := 0
	for machine in claw_machines {
		total_tokens += get_machine_tokens(machine.button_a, machine.button_b, machine.price)
	}

	fmt.println("part 1:", total_tokens)
}

part_2 :: proc(claw_machines: ^[dynamic]Claw_Machine) {
	// try to get as many of the cheapest button 
	total_tokens := 0
	for machine in claw_machines {
		total_tokens += get_machine_tokens(machine.button_a, machine.button_b, machine.price + 10000000000000)
	}

	fmt.println("part 2:", total_tokens)
}

