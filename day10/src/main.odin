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

map_pos_valid :: proc(height_map: ^[dynamic][dynamic]int, pos: [2]int, height_to_check: int) -> bool {

	// check bounds
	if pos[0] >= len(height_map) do return false
	if pos[0] < 0 do return false
	if pos[1] >= len(height_map[0]) do return false
	if pos[1] < 0 do return false

	// check pos
	return height_map[pos[0]][pos[1]] == height_to_check
}

get_trailhead_score :: proc(height_map: ^[dynamic][dynamic]int, peaks: ^map[[2]int]bool, pos: [2]int, height_to_check: int) {
	if !map_pos_valid(height_map, pos, height_to_check) {
		return
	}
	else if height_to_check == 9 {
		peaks[pos] = true
		return
	}

	under := [2]int{pos[0] + 1, pos[1]}
	over := [2]int{pos[0] - 1, pos[1]}
	left := [2]int{pos[0], pos[1] - 1}
	right := [2]int{pos[0], pos[1] + 1}

	get_trailhead_score(height_map, peaks, under, height_to_check + 1)

	// check over
	get_trailhead_score(height_map, peaks, over, height_to_check + 1)

	// check left
	get_trailhead_score(height_map, peaks, left, height_to_check + 1)

	// check right
	get_trailhead_score(height_map, peaks, right, height_to_check + 1)

	return
}

get_trailhead_score_distinct :: proc(height_map: ^[dynamic][dynamic]int, pos: [2]int, height_to_check: int) -> int {
	if !map_pos_valid(height_map, pos, height_to_check) {
		return 0
	}
	else if height_to_check == 9 {
		return 1
	}

	under := [2]int{pos[0] + 1, pos[1]}
	over := [2]int{pos[0] - 1, pos[1]}
	left := [2]int{pos[0], pos[1] - 1}
	right := [2]int{pos[0], pos[1] + 1}

	result := 0
	result += get_trailhead_score_distinct(height_map, under, height_to_check + 1)

	// check over
	result += get_trailhead_score_distinct(height_map, over, height_to_check + 1)

	// check left
	result += get_trailhead_score_distinct(height_map, left, height_to_check + 1)

	// check right
	result += get_trailhead_score_distinct(height_map, right, height_to_check + 1)

	return result
}

main :: proc() {
	input := read_input("input.txt")

	height_map: [dynamic][dynamic]int

	// ROW FIRST
	trailheads: [dynamic][2]int

	//////////////////
	// PARSING
	lines: [dynamic]string
	for line in strings.split_lines_iterator(&input) {
		if len(line) > 0 do append(&lines, line)
	}

	for line, y in lines {
		row: [dynamic]int
		for column, x in line {
			height, ok := strconv.parse_int(line[x:x+1])
			if ok {
				append(&row, height)
				if height == 0 {
					trailhead_pos := [2]int{y, x}
					append(&trailheads, trailhead_pos)
				}
			}
			
		}
		append(&height_map, row)
	}


	{
		total_score := 0
		current_peaks := make(map[[2]int]bool)
		for trailhead in trailheads {
			clear(&current_peaks)
			get_trailhead_score(&height_map, &current_peaks, trailhead, 0)
			total_score += len(current_peaks)
		}

		fmt.println("TOTAL SCORE PART 1: ", total_score)
	}

	{
		total_score := 0
		for trailhead in trailheads {
			total_score += get_trailhead_score_distinct(&height_map, trailhead, 0)
		}

		fmt.println("TOTAL SCORE PART 2: ", total_score)
	}
}
