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

Node :: struct {
	type: rune,
	pos: [2]int
}

main :: proc() {
	input := read_input("input.txt")
	equations: [dynamic]Equation

	//////////////////
	// PARSING
	nodes: [dynamic]Node
	anti_nodes := make(map[[2]int]bool)

	// we subtrack 1 from amount of lines to account for empty last line
	lines: [dynamic]string
	for line in strings.split_lines_iterator(&input) {
		if len(line) <= 0 do break

		append(&lines, line)
	}

	amount_of_rows := len(lines)
	amount_of_columns := len(lines[0])

	for line, y in lines {
		for r, x in line {
			if r == '.' do continue

			node: Node
			node.type = r
			node.pos = {x, y}
			append(&nodes, node)
		}
	}

	for node, i in nodes {
		for other_node, j in nodes {
			if i == j do continue

			if node.type == other_node.type {
				anti_nodes[node.pos] = true
				anti_nodes[other_node.pos] = true
				dir := other_node.pos - node.pos
				anti_node_pos := other_node.pos
				for {
					anti_node_pos += dir
					if anti_node_pos.x >= 0 && anti_node_pos.x < amount_of_columns && anti_node_pos.y >= 0 && anti_node_pos.y < amount_of_rows {
						// anti node IN  bounds
						anti_nodes[anti_node_pos] = true
						continue
					}
					break
				}
			}
		}
	}

	fmt.println("antinode count: ", len(anti_nodes))
}
