package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:sort"
import rl "vendor:raylib"

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

Tile_Pos :: struct {
	x: i32,
	y: i32,
}

Guard :: struct {
	pos: Tile_Pos,
	vel_x: i32,
	vel_y: i32,
}

Tile :: struct {
	tile_empty: bool,
	visited: bool,
}

tile_map: [dynamic][dynamic]Tile

next_tile :: proc(guard: Guard) -> Tile_Pos {
	return Tile_Pos{(guard.pos.x + guard.vel_x), (guard.pos.y + guard.vel_y)}
}

get_tile :: proc(tile_map: ^[dynamic][dynamic]Tile, pos: Tile_Pos) -> ^Tile {
	return &tile_map[pos.y][pos.x]
}

turn_guard_90 :: proc(vel_x, vel_y: i32) -> (x:i32, y:i32) {
	assert(abs(vel_x) + abs(vel_y) == 1, "velocity is more than 1")

	if vel_x == 1 {
		// looking right
		return 0, 1
	}
	else if vel_y == 1 {
		// looking down
		return -1, 0
	}
	else if vel_x == -1 {
		// looking left
		return 0, -1
	}
	else if vel_y == -1 {
		// looking up
		return 1, 0
	}

	unreachable()
}

get_amount_of_visited :: proc(tile_map: ^[dynamic][dynamic]Tile) -> int {
	result := 0
	for row in tile_map {
		for tile in row {
			if tile.visited do result += 1
		}
	}

	return result
}

test_all_manual_obstruction_positions :: proc(tile_map: ^[dynamic][dynamic]Tile, guard: Guard) -> int {
	amount_of_looping_possibilities := 0
	visit_reports := make(map[Guard]bool)

	for row, y in tile_map {
		for column, x in row {
			clear(&visit_reports)
			test_pos := Tile_Pos{i32(x), i32(y)}
			if test_pos != guard.pos && test_manuel_obstruction(tile_map, &visit_reports, test_pos, guard.pos, guard.vel_x, guard.vel_y) {
				amount_of_looping_possibilities += 1
			}
		}
	}

	return amount_of_looping_possibilities
}

test_manuel_obstruction :: proc(tile_map: ^[dynamic][dynamic]Tile, visit_reports: ^map[Guard]bool, test_pos: Tile_Pos, start_pos: Tile_Pos, start_vel_x, start_vel_y: i32) -> bool {
	fmt.println("CHECKING NEW OBStrUCTION POSITION: ", test_pos)

	rows := i32(len(tile_map))
	columns := i32(len(tile_map[0]))

	temp_guard := Guard{start_pos, start_vel_x, start_vel_y}

	visit_reports[temp_guard] = true

	for {
		if next_tile(temp_guard).x >= columns || next_tile(temp_guard).x < 0 || next_tile(temp_guard).y  >= rows || next_tile(temp_guard).y < 0 {
			// out of bounds / not loopin
			break
		}
		else if get_tile(tile_map, next_tile(temp_guard)).tile_empty && next_tile(temp_guard) != test_pos {
			// next tile is empty keep velocity and move guard
			temp_guard.pos = next_tile(temp_guard)
		}
		else {
			temp_guard.vel_x, temp_guard.vel_y = turn_guard_90(temp_guard.vel_x, temp_guard.vel_y)
		}

		// check if we are looping
		if temp_guard in visit_reports {
			return true
		}
		visit_reports[temp_guard] = true
	}

	return false
}

guard_walk_simulation :: proc(guard: Guard) {
	guard := guard

	TILE_DRAWING_SIZE :: 7


	last_step: f64 = 0
	STEP_SPEED :: 0.00001
	moving_guard := true

	for !rl.WindowShouldClose() {
		// length of rows
		rows := i32(len(&tile_map))
		columns := i32(len(&tile_map[0]))
		if moving_guard && last_step + STEP_SPEED < rl.GetTime() {
		// if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
			last_step = rl.GetTime()


			if next_tile(guard).x >= columns || next_tile(guard).x < 0 || next_tile(guard).y  >= rows || next_tile(guard).y < 0 {
				// out of bounds
				fmt.println("GUARD OUT OF BOUNDS")
				moving_guard = false
				fmt.println("tiles visited: ", get_amount_of_visited(&tile_map))
			}
			else if get_tile(&tile_map, next_tile(guard)).tile_empty {
				// next tile is empty keep velocity and move guard
				guard.pos = next_tile(guard)
				get_tile(&tile_map, guard.pos).visited = true
			}
			else {
				guard.vel_x, guard.vel_y = turn_guard_90(guard.vel_x, guard.vel_y)
			}
		}


		rl.BeginDrawing()
		defer rl.EndDrawing()

		// DRAW MAP
		for row, y in tile_map {
			for tile, x in row {
				if tile.tile_empty {
					if tile.visited {
						rl.DrawRectangle(i32(x) * TILE_DRAWING_SIZE, i32(y) * TILE_DRAWING_SIZE, TILE_DRAWING_SIZE, TILE_DRAWING_SIZE, rl.RED)
					}
					else {
						rl.DrawRectangle(i32(x) * TILE_DRAWING_SIZE, i32(y) * TILE_DRAWING_SIZE, TILE_DRAWING_SIZE, TILE_DRAWING_SIZE, rl.BEIGE)
					}
				}
				else {
					rl.DrawRectangle(i32(x) * TILE_DRAWING_SIZE, i32(y) * TILE_DRAWING_SIZE, TILE_DRAWING_SIZE, TILE_DRAWING_SIZE, rl.BLUE)
				}


			}
		}

		for row, y in tile_map {
			for tile, x in row {
				current_x := i32(x) * TILE_DRAWING_SIZE
				current_y := i32(y) * TILE_DRAWING_SIZE
				rl.DrawRectangleLines(current_x, current_y, TILE_DRAWING_SIZE, TILE_DRAWING_SIZE, rl.BLACK)
			}
		}

		// DRAW GUARD
		guard_pos_x := (guard.pos.x * TILE_DRAWING_SIZE) + TILE_DRAWING_SIZE/2
		guard_pos_y := (guard.pos.y * TILE_DRAWING_SIZE) + TILE_DRAWING_SIZE/2
		rl.DrawCircle(guard_pos_x, guard_pos_y, TILE_DRAWING_SIZE / 2, rl.YELLOW)

	}
}

main :: proc() {

	rl.InitWindow(1200, 900, "christmas guard")

	input := read_input("input.txt")

	guard: Guard
	current_y: int
	// current_y: int
	for line in strings.split_lines_iterator(&input) {
		map_row: [dynamic]Tile
		for char, x in line {
			tile: Tile
			if char == '.' {
				tile.tile_empty = true
			}
			else if char == '^' {
				guard.pos.x = i32(x)

				guard.pos.y = i32(current_y)
				guard.vel_x = 0
				guard.vel_y = -1
				tile.tile_empty = true
			}
			else if char == '>' {
				guard.pos.x = i32(x)
				guard.pos.y = i32(current_y)
				guard.vel_x = 1
				guard.vel_y = 0
				tile.tile_empty = true
			}
			else if char == 'V' {
				guard.pos.x = i32(x)
				guard.pos.y = i32(current_y)
				guard.vel_x = 0
				guard.vel_y = 1
				tile.tile_empty = true
			}
			else if char == '<' {
				guard.pos.x = i32(x)
				guard.pos.y = i32(current_y)
				guard.vel_x = -1
				guard.vel_y = 0
				tile.tile_empty = true
			}
			else {
				tile.tile_empty = false
			}
			append(&map_row, tile)
		}
		append(&tile_map, map_row)

		current_y += 1
	}

	fmt.println("GUARD START POS: ", guard.pos)
	get_tile(&tile_map, guard.pos).visited = true
	// guard_walk_simulation(guard)

	amount_of_loops := test_all_manual_obstruction_positions(&tile_map, guard)
	fmt.println("AMOUNT OF LOOPS: ", amount_of_loops)
}
