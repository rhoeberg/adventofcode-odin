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

Space_Block :: struct {
}

File_Block :: struct {
	id: int,
	size: int,
}

Block :: union {
	Space_Block,
	File_Block,
}

Space_Block_Position :: struct {
	is_valid: bool,
	index: int,
	size: int,
}

memory_is_sorted :: proc(memory: ^[dynamic]Block) -> bool {
	found_space_block := false
	for block in memory {
		switch type in block {
			case Space_Block:
			found_space_block = true
			case File_Block:
			if found_space_block {
				return false
			}
		}
	}

	return true
}

get_last_file_block :: proc(memory: ^[dynamic]Block) -> int {
	last_file_block := 0
	for block, i in memory {
		switch type in block {
			case Space_Block:
			case File_Block:
			last_file_block = i
		}
	}

	return last_file_block
}


/*
NEXT:
the current method doesnt skip n to next file id but instead just pushes it 
*/
// get_last_file_start_and_size :: proc(memory: ^[dynamic]Block, n_from_last: int) -> (int, int) {
// 	start_index := 0
// 	end_index := 0
// 	current_file_id := 0
// 	n := -1
// 	#reverse loop: for block, i in memory {
// 		switch type in block {
// 		case Space_Block:
// 		case File_Block:
// 			file_block := block.(File_Block)
// 			if file_block.id != current_file_id {
// 				// found new file
// 				n += 1 // first file found will be n==0
// 				current_file_id = file_block.id
// 				if n == n_from_last {
// 					end_index = i
// 					start_index = i
// 				}
// 			}
// 			else {
// 				if n == n_from_last {
// 					start_index = i
// 				}
// 				else if n > n_from_last {
// 					// fmt.println("FOUND FILE:", current_file_id)
// 					size := end_index - (start_index-1)
// 					return start_index, size
// 				}
// 			}
// 		}
// 	}
// 	fmt.println("NO MORE FILES:", n)
// 	return 0, 0
// }

get_n_file_from_end :: proc(memory: ^[dynamic]Block, n: int) -> (int, int) {
	found_the_file := false
	current_file_id := -1
	next_n := 0

	start_index := 0
	end_index := 0

	#reverse for block, i in memory {
		switch type in block {
		case Space_Block:
		case File_Block:
			if current_file_id != type.id {
				// HIT NEW FILE
				// fmt.println("FOUND NEW FILE:", type.id)

				if found_the_file {
					// we have moved passed our desired file
					// fmt.println("FOUND THE FILE:", n)
					// fmt.println("start index: ", start_index)
					// fmt.println("end index: ", end_index)
					// start_index = i + 1
					size := (end_index + 1) - start_index
					// fmt.println("size: ", size)
					// start_index = i + 1
					return start_index, size
				}

				if next_n == n {
					// the new file is the one we want
					found_the_file = true
					end_index = i
					start_index = i
				}

				current_file_id = type.id
				next_n += 1
			}
			else {
				if found_the_file {
					start_index = i
				}
			}
		}
	}

	return 0, 0
}

get_first_space_block :: proc(memory: ^[dynamic]Block) -> int {
	for block, i in memory {
		switch type in block {
			case Space_Block:
			return i
			case File_Block:
		}
	}

	return 0
}

get_first_space_block_and_size :: proc(memory: ^[dynamic]Block) -> (int, int) {
	found_space_block := false
	first_index := 0
	size := 0
	for block, i in memory {
		switch type in block {
			case Space_Block:
			if !found_space_block {
				found_space_block = true
				first_index = i
			}
			size += 1
			case File_Block:
			if found_space_block {
				return first_index, size
			}
		}
	}

	return 0, 0
}

get_n_space_block_and_size :: proc(memory: ^[dynamic]Block, n: int) -> (int, int) {
	first_index := 0
	size := 0
	current_space_block := 0
	last_block_was_space := false

	for block, i in memory {
		switch type in block {
			case Space_Block:
			if !last_block_was_space {
				// START OF NEW SPACE BLOCK
				last_block_was_space = true
				first_index = i
				size = 1
			}
			else {
				// CONTINUATION OF SPACE BLOCK
				size += 1
			}
			case File_Block:
			if last_block_was_space {
				// END OF SPACE BLOCK
				if current_space_block == n {
					return first_index, size
				}
				current_space_block += 1
				last_block_was_space = false

				if current_space_block > n {
					return 0, 0
				}
			}
		}
	}

	return 0, 0
}

print_memory :: proc(memory: ^[dynamic]Block) {
	for block in memory {
		switch type in block {
			case Space_Block:
			fmt.print(".")
			case File_Block:
			fmt.print("[")
			file_block := block.(File_Block)
			fmt.print(file_block.id)
			fmt.print("]")
		}
	}
	fmt.println()
}

get_continues_file_block_size :: proc(memory: ^[dynamic]Block) -> int {
	size := 0
	for block in memory {
		switch type in block {
			case Space_Block:
			return size
			case File_Block:
			size += 1
		}
	}

	return size
}

calculate_checksum :: proc(memory: ^[dynamic]Block) -> int {
	result: int

	for block, i in memory {
		switch type in block {
			case Space_Block:
			case File_Block:
			file_block := block.(File_Block)
			result += i * file_block.id
		}
	}
	
	return result
}

print_last_n_blocks :: proc(memory: ^[dynamic]Block, n := 1) {
	count := 0
	
	for i in len(memory) - n..<len(memory) {
		block := memory[i]
		switch type in block {
			case Space_Block:
			// fmt.print(".")
			case File_Block:
			file_block := block.(File_Block)
			fmt.print(file_block.id)
		}
	}

	
}

get_all_space_blocks :: proc(memory: ^[dynamic]Block, space_blocks: ^[dynamic]Space_Block_Position) {
	n := 0
	for {
		index, size := get_n_space_block_and_size(memory, n)
		if size == 0 do break

		space_block_position: Space_Block_Position
		space_block_position.is_valid = true
		space_block_position.size = size
		space_block_position.index = index
		append(space_blocks, space_block_position)

		n += 1
	}
}

main :: proc() {
	input := read_input("input.txt")
	// input := "2333133121414131402"

	rl.InitWindow(1200, 900, "aoc day 9")

	//////////////////
	// PARSING
	memory: [dynamic]Block
	last_file_id := 0
	for r, i in input {
		is_file := i%2 == 0

		if is_file {
			file_size, ok := strconv.parse_int(input[i:i+1])
			if !ok {
				fmt.println("failed to parse file size")
				os.exit(1)
			}
			for i in 0..<file_size {
				append(&memory, File_Block{last_file_id, file_size})
			}
			last_file_id += 1
		}
		else {
			space_size, ok := strconv.parse_int(input[i:i+1])
			if !ok {
				fmt.println("failed to parse space size")
				fmt.println(space_size)
				fmt.println(input[i:i+1])
				break
			}
			for i in 0..<space_size {
				append(&memory, Space_Block{})
			}
		}
	}

	space_blocks: [dynamic]Space_Block_Position
	get_all_space_blocks(&memory, &space_blocks)

	sqrt := math.sqrt_f64(f64(len(memory)))
	MAP_SIZE := int(sqrt)

	n := 0
	for !rl.WindowShouldClose() {

		
		// for {
			file_index, file_size := get_n_file_from_end(&memory, n)
			if file_size == 0 do break

			file_moved := false
			for space_block, i in space_blocks {
				if !space_block.is_valid || space_block.size < file_size do continue
				else if space_block.index >= file_index {
					// fmt.println("SPACE BLOCK INDEX IS PASSED FILE INDEX", i)
					break
				} 
				else {

					size_dif :=  space_block.size - file_size
					assert(size_dif >= 0, "SIZE_DIF IS NEGATIVE")
					if size_dif == 0 {
						space_blocks[i].is_valid = false
					}
					else {
						
						space_blocks[i].index = (space_blocks[i].index + space_block.size) - size_dif
						space_blocks[i].size = size_dif
					}

					for j in 0..<file_size {
						memory[space_block.index+j], memory[file_index+j] = memory[file_index+j], memory[space_block.index+j]
					}

					file_moved = true
					break
				}
			}

			if !file_moved {
				n += 1
			}
		// }
		
		rl.BeginDrawing()
		defer rl.EndDrawing()
		rl.ClearBackground(rl.BLACK)

		rl.DrawCircle(100, 100, 50, rl.YELLOW)
		rl.DrawCircle(120, 120, 50, rl.BLACK)

		i := 0
		step : i32 = 3
		for y in 0..<MAP_SIZE {
			for x in 0..<MAP_SIZE {
				if _, ok := memory[i].(File_Block); ok {
					// rl.DrawRectangle(i32(x)*step, i32(y)*step, step, step, rl.BLUE)
				}
				else {
					rl.DrawRectangle(i32(x)*step, i32(y)*step, step, step, rl.WHITE)
				}
				i += 1
			}
		}
	}
	
	// print_memory(&memory)
	// fmt.println()

	checksum := calculate_checksum(&memory)
	fmt.println("CHECKSUM = ", checksum)

}

defrag_keep_file_intact :: proc(memory: ^[dynamic]Block, space_blocks: ^[dynamic]Space_Block_Position) {
	n := 0
	for {
		file_index, file_size := get_n_file_from_end(memory, n)
		if file_size == 0 do break

		file_moved := false
		for space_block, i in space_blocks {
			if !space_block.is_valid || space_block.size < file_size do continue
			else if space_block.index >= file_index {
				break
			} 
			else {

				size_dif :=  space_block.size - file_size
				assert(size_dif >= 0, "SIZE_DIF IS NEGATIVE")
				if size_dif == 0 {
					space_blocks[i].is_valid = false
				}
				else {
					
					space_blocks[i].index = (space_blocks[i].index + space_block.size) - size_dif
					space_blocks[i].size = size_dif
				}

				for j in 0..<file_size {
					memory[space_block.index+j], memory[file_index+j] = memory[file_index+j], memory[space_block.index+j]
				}

				file_moved = true
				break
			}
		}

		if !file_moved {
			n += 1
		}
	}
}
