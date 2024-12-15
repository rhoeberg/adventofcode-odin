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

Fence_Direction :: enum {
	Up,
	Left,
	Down,
	Right,
}

Plot_Fences :: bit_set[Fence_Direction]

Vec2 :: [2]int

main :: proc() {
	input := read_input("input.txt")

	garden_plots: [dynamic][dynamic]rune

	//////////////////
	// PARSING
	for line in strings.split_lines_iterator(&input) {
		if len(line) <= 0 do break

		row: [dynamic]rune
		for char in line {
			append(&row, char)
		}
		append(&garden_plots, row)
	}

	// PRINT PLOTS
	fmt.println("-------------")
	for y in 0..<len(garden_plots) {
		for x in 0..<len(garden_plots[y]) {
			fmt.print(garden_plots[y][x])
		}
		fmt.println()
	}

	calculate_part1(&garden_plots)
	calculate_part2(&garden_plots)
}

Stack_Entry :: struct {
	pos: Vec2,
	type: rune,
	last_pos: Vec2,
	last_fence: Plot_Fences,
}

check_plot :: proc(garden_plots: ^[dynamic][dynamic]rune, pos: Vec2, type: rune) -> bool {
	// check bounds
	if pos.x < 0 || pos.x >= len(garden_plots[0]) || pos.y < 0 || pos.y >= len(garden_plots) {
		return false
	}

	// check type
	return garden_plots[pos.y][pos.x] == type
}

calculate_part1 :: proc(garden_plots: ^[dynamic][dynamic]rune) {
	Region :: struct {
		fences: [dynamic]Plot_Fences
	}
	
	used_plots := make(map[Vec2]struct{})
	stack: [dynamic]Stack_Entry
	regions: [dynamic]Region
	for y in 0..<len(garden_plots) {
		for x in 0..<len(garden_plots[y]) {
			next_pos := Vec2{x, y}

			// skip position
			if next_pos in used_plots do continue

			clear(&stack)
			append(&stack, Stack_Entry{pos=next_pos, type=garden_plots[next_pos.y][next_pos.x]})
			region: Region

			for len(stack) > 0 {
				entry := pop(&stack)

				if entry.pos in used_plots do continue

				used_plots[entry.pos]={}

				fences: Plot_Fences
				up := Vec2{entry.pos.x, entry.pos.y - 1}
				left := Vec2{entry.pos.x - 1, entry.pos.y}
				down := Vec2{entry.pos.x, entry.pos.y + 1}
				right := Vec2{entry.pos.x + 1, entry.pos.y}

				// check above
				if !check_plot(garden_plots, up, entry.type) {
					fences += {.Up}
				}
				else {
					append(&stack, Stack_Entry{pos=up, type=entry.type})
				}
				// check left
				if !check_plot(garden_plots, left, entry.type) {
					fences += {.Left}
				}
				else {
					append(&stack, Stack_Entry{pos=left, type=entry.type})
				}
				// check down
				if !check_plot(garden_plots, down, entry.type) {
					fences += {.Down}
				}
				else {
					append(&stack, Stack_Entry{pos=down, type=entry.type})
				}
				// check right
				if !check_plot(garden_plots, right, entry.type) {
					fences += {.Right}
				}
				else {
					append(&stack, Stack_Entry{pos=right, type=entry.type})
				}

				append(&region.fences, fences)
			}

			append(&regions, region)
		}
	}

	
	result := 0
	for region in regions {
		area := 0
		fence_perimeter := 0

		for fence in region.fences {
			area += 1
			fence_perimeter += card(fence)
		}

		result += area * fence_perimeter
	}

	fmt.println("part 1 = ", result)
}

Side :: struct {
	direction: Fence_Direction,
	start: Vec2,
	end: Vec2,
}

Region :: struct {
	fences: map[Vec2]Plot_Fences,
	sides: [dynamic]Side,
}
calculate_part2 :: proc(garden_plots: ^[dynamic][dynamic]rune) {
	used_plots := make(map[Vec2]struct{})
	stack: [dynamic]Stack_Entry
	regions: [dynamic]Region
	for y in 0..<len(garden_plots) {
		for x in 0..<len(garden_plots[y]) {
			next_pos := Vec2{x, y}

			// skip position
			if next_pos in used_plots do continue

			clear(&stack)
			append(&stack, Stack_Entry{pos=next_pos, type=garden_plots[next_pos.y][next_pos.x]})
			region: Region

			for len(stack) > 0 {
				entry := pop(&stack)

				// check entry
				// if garden_plots[entry.pos.y][entry.pos.x] == entry.type {
				// found another plot for the region
				if entry.pos in used_plots do continue

				used_plots[entry.pos]={}

				fences: Plot_Fences
				up := Vec2{entry.pos.x, entry.pos.y - 1}
				down := Vec2{entry.pos.x, entry.pos.y + 1}
				left := Vec2{entry.pos.x - 1, entry.pos.y}
				right := Vec2{entry.pos.x + 1, entry.pos.y}

				// check above
				if !check_plot(garden_plots, up, entry.type) {
					fences += {.Up}
				}
				else {
					append(&stack, Stack_Entry{pos=up, type=entry.type})
				}
				// check down
				if !check_plot(garden_plots, down, entry.type) {
					fences += {.Down}
				}
				else {
					append(&stack, Stack_Entry{pos=down, type=entry.type})
				}
				// check left
				if !check_plot(garden_plots, left, entry.type) {
					fences += {.Left}
				}
				else {
					append(&stack, Stack_Entry{pos=left, type=entry.type})
				}
				// check right
				if !check_plot(garden_plots, right, entry.type) {
					fences += {.Right}
				}
				else {
					append(&stack, Stack_Entry{pos=right, type=entry.type})
				}
				region.fences[entry.pos] = fences
			}

			append(&regions, region)
		}
	}

	result := 0
	for region, i in regions {
		area := 0

		for pos, fences in region.fences {
			area += 1
			
			if .Up in fences && !side_exists(&regions[i].sides, pos, .Up){
				side: Side
				side.start, side.end = find_side_start_and_end(&regions[i].fences, pos, .Up)
				side.direction = .Up
				append(&regions[i].sides, side)
			}
			if .Down in fences && !side_exists(&regions[i].sides, pos, .Down) {
				side: Side
				side.start, side.end = find_side_start_and_end(&regions[i].fences, pos, .Down)
				side.direction = .Down
				append(&regions[i].sides, side)
			}
			if .Left in fences && !side_exists(&regions[i].sides, pos, .Left) {
				side: Side
				side.start, side.end = find_side_start_and_end(&regions[i].fences, pos, .Left)
				side.direction = .Left
				append(&regions[i].sides, side)
			}
			if .Right in fences && !side_exists(&regions[i].sides, pos, .Right) {
				side: Side
				side.start, side.end = find_side_start_and_end(&regions[i].fences, pos, .Right)
				side.direction = .Right
				append(&regions[i].sides, side)
			}
		}
		
		result += area * len(regions[i].sides)
	}

	fmt.println("part 2 = ", result)
}

side_exists :: proc(sides: ^[dynamic]Side, pos: Vec2, direction: Fence_Direction) -> bool {
	for side in sides {
		if side.direction == direction {
			switch direction {
			case .Up, .Down:
				if pos.y == side.start.y && pos.x >= side.start.x && pos.x <= side.end.x {
					return true
				}
			case .Left, .Right:
				if pos.x == side.start.x && pos.y >= side.start.y  && pos.y <= side.end.y {
					return true
				}
			}
		}
	}
	return false
}

find_side_start_and_end :: proc(fences: ^map[Vec2]Plot_Fences, pos: Vec2, direction: Fence_Direction) -> (Vec2, Vec2) {
	x_offset := 0

	dir: Vec2
	switch direction {
	case .Up, .Down:
		dir = {1, 0}
	case .Left, .Right:
		dir = {0, 1}
	}

	start_pos := pos
	end_pos := pos
	for {
		next_fences, ok := fences[pos - (dir * x_offset)]
		if ok && direction in next_fences {
			start_pos = pos - (dir * x_offset)
			x_offset += 1
		}
		else do break
	}

	// check right
	x_offset = 0
	for {
		next_fences, ok := fences[pos + (dir * x_offset)]
		if ok && direction in next_fences {
			end_pos = pos + (dir * x_offset)
			x_offset += 1
		}
		else do break
	}

	return start_pos, end_pos
}
