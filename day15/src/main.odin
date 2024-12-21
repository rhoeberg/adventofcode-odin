package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:sort"
import "core:slice"
import "core:math"
import "core:time"
import "core:math/linalg"
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

Tile :: struct {
	has_box: bool,
	is_wall: bool,
}

MAP_SIZE :: 50

main :: proc() {
	input := read_input("input.txt")

	//////////////////
	// PARSING
	map_directions_str := strings.split(input, "\n\n")
	tile_map: [MAP_SIZE][MAP_SIZE]Tile
	robot_pos: Vec2
	y := 0
	for line in strings.split_lines_iterator(&map_directions_str[0]) {
		if len(line) <= 0 do break
		
		for x in 0..<MAP_SIZE {
			column := line[x]

			tile: Tile
			if column == '#' {
				tile.is_wall = true
			}
			else if column == 'O' {
				tile.has_box = true
			}
			else if column == '@' {
				robot_pos = {x, y}
			}

			tile_map[x][y] = tile
		}
		y += 1
	}

	// solve(robot_pos, map_directions_str[1], tile_map)
	visualize(robot_pos, map_directions_str[1], tile_map)
}

print_map :: proc(tile_map: [MAP_SIZE][MAP_SIZE]Tile) {
	for y in 0..<MAP_SIZE {
		for x in 0..<MAP_SIZE {
			tile := tile_map[x][y]
			if tile.has_box {
				fmt.print("O")
			}
			else if tile.is_wall {
				fmt.print("#")
			}
			else {
				fmt.print(".")
			}
		}
		fmt.println()
	}
}

try_move_robot :: proc(world: ^[MAP_SIZE][MAP_SIZE]Tile, current_pos, dir: Vec2) -> Vec2{

	hit_wall := false
	step := 0
	next_pos := current_pos
	for {
		next_pos += dir
		tile := world[next_pos.x][next_pos.y]
		if tile.is_wall {
			hit_wall = true
			break
		} 
		else if !tile.has_box {
			break
		}
		else if tile.has_box {
			step += 1
		}
	}

	if !hit_wall {
		new_robot_pos := current_pos + dir
		tile := &world[new_robot_pos.x][new_robot_pos.y]
		tile.has_box = false

		if step > 0 {
			last_box_pos := current_pos + dir + dir*step
			last_tile := &world[last_box_pos.x][last_box_pos.y]
			last_tile.has_box = true
		}
		
		return current_pos + dir
	}

	return current_pos
}

count_boxes :: proc(world: ^[MAP_SIZE][MAP_SIZE]Tile) -> int {
	result := 0
	for y in 0..<MAP_SIZE {
		for x in 0..<MAP_SIZE {
			tile := world[x][y]
			if tile.has_box do result += 1
		}
	}

	return result
}


visualize :: proc(robot_pos: Vec2, directions: string, tile_map: [MAP_SIZE][MAP_SIZE]Tile) {
	robot_pos := robot_pos
	tile_map := tile_map

	to_rl_vec :: proc(v: Vec2) -> rl.Vector2 {
		return {f32(v.x) * TILE_SIZE, f32(v.y) * TILE_SIZE}
	}

	////////////
	// GRAPHICS
	TILE_SIZE :: 19
	rl.InitWindow(1000, 1000, "aoc day 15")
	current_instruction := 0
	// SPEED :: 0.03
	speed := 0.2
	// speed := 0.0001
	max_speed := 0.01
	last_step : f64 = 0
	simulation_done := false
	camera: rl.Camera2D

	current_camera_pos : rl.Vector2 = to_rl_vec(robot_pos)
	camera.offset = {500, 500}
	camera.zoom = 5
	camera.target = to_rl_vec(robot_pos)

	start := false

	fmt.println("AMOUNT OF BOXES:", count_boxes(&tile_map))
	for !rl.WindowShouldClose() {

		if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
			start = true
		}

		if start {
			if !simulation_done && last_step + speed < rl.GetTime() {
				last_step = rl.GetTime()

				instruction: rune
				get_instruction: for {
					if current_instruction >= len(directions) {
						simulation_done = true
						fmt.println("AMOUNT OF BOXES:", count_boxes(&tile_map))
						break
					}

					instruction = rune(directions[current_instruction])
					current_instruction += 1
					switch instruction {
					case '<', '>', 'v', '^': {
						break get_instruction
					}
					}
				}

				if !simulation_done {
					// fmt.println("instruction:", instruction)
					switch instruction {
					case '<':
						robot_pos = try_move_robot(&tile_map, robot_pos, {-1, 0})
					case '>':
						robot_pos = try_move_robot(&tile_map, robot_pos, {1, 0})
					case 'v':
						robot_pos = try_move_robot(&tile_map, robot_pos, {0, 1})
					case '^': 
						robot_pos = try_move_robot(&tile_map, robot_pos, {0, -1})
					}
				}
			}

			current_camera_pos = linalg.lerp(to_rl_vec(robot_pos), current_camera_pos, 0.999)
			// camera.target = {f32(robot_pos.x) * TILE_SIZE, f32(robot_pos.y) * TILE_SIZE}
			camera.target = current_camera_pos
			camera.zoom = linalg.lerp(camera.zoom, 0.6, 0.1 * rl.GetFrameTime())
			speed = linalg.lerp(speed, max_speed, 0.04 * f64(rl.GetFrameTime()))
		}

		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.BeginMode2D(camera)
		defer rl.EndMode2D()

		rl.ClearBackground(rl.BLACK)


		for y in 0..<MAP_SIZE {
			for x in 0..<MAP_SIZE {
				tile := tile_map[x][y]

				rl.DrawRectangle(i32(x)*TILE_SIZE, i32(y)*TILE_SIZE, TILE_SIZE, TILE_SIZE, rl.WHITE)
				// rl.DrawRectangleLines(i32(x)*TILE_SIZE, i32(y)*TILE_SIZE, TILE_SIZE, TILE_SIZE, rl.BLACK)

				if tile.is_wall {
					rl.DrawRectangle(i32(x)*TILE_SIZE, i32(y)*TILE_SIZE, TILE_SIZE, TILE_SIZE, rl.DARKGRAY)
				}
				else if tile.has_box {
					rl.DrawRectangle(i32(x)*TILE_SIZE, i32(y)*TILE_SIZE, TILE_SIZE, TILE_SIZE, rl.BROWN)
				}
			}
		}
		rl.DrawRectangle(i32(robot_pos.x)*TILE_SIZE, i32(robot_pos.y)*TILE_SIZE, TILE_SIZE, TILE_SIZE, rl.RED)
	}
}

get_box_coordinates :: proc(tile_map: ^[MAP_SIZE][MAP_SIZE]Tile) -> int {
	total_gps := 0
	for y in 0..<MAP_SIZE {
		for x in 0..<MAP_SIZE {
			tile := tile_map[x][y]
			if tile.has_box {
				gps := (y*100) + x
				total_gps += gps
			}
		}
	}

	return total_gps
}

solve :: proc(robot_pos: Vec2, instructions: string, tile_map: [MAP_SIZE][MAP_SIZE]Tile) {
	robot_pos := robot_pos
	tile_map := tile_map

	current_instruction := 0
	main_loop: for {
		instruction: rune
		get_instruction: for {
			if current_instruction >= len(instructions) {
				break main_loop
			}

			instruction = rune(instructions[current_instruction])
			current_instruction += 1
			switch instruction {
			case '<', '>', 'v', '^': {
				break get_instruction
			}
			}
		}

		fmt.println("instruction:", instruction)
		switch instruction {
		case '<':
			robot_pos = try_move_robot(&tile_map, robot_pos, {-1, 0})
		case '>':
			robot_pos = try_move_robot(&tile_map, robot_pos, {1, 0})
		case 'v':
			robot_pos = try_move_robot(&tile_map, robot_pos, {0, 1})
		case '^': 
			robot_pos = try_move_robot(&tile_map, robot_pos, {0, -1})
		}
	}

	fmt.println("TOTAL GPS:", get_box_coordinates(&tile_map))
}
