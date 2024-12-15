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

get_trailhead_paths :: proc(height_map: ^[dynamic][dynamic]int, paths: ^[dynamic][dynamic][2]int, current_path: [10][2]int, pos: [2]int, height_to_check: int) -> int {
	if !map_pos_valid(height_map, pos, height_to_check) {
		return 0
	}
	else if height_to_check == 9 {
		fmt.println("APPENDING PATH TO PATHS:")
		current_path := current_path
		current_path[height_to_check] = pos

		new_path: [dynamic][2]int
		for point in current_path {
			append(&new_path, point)
		}

		append(paths, new_path)

		return 1
	}

	// fmt.println("HEIGHT TO CHECK:", height_to_check)
	current_path := current_path
	current_path[height_to_check] = pos

	under := [2]int{pos[0] + 1, pos[1]}
	over := [2]int{pos[0] - 1, pos[1]}
	left := [2]int{pos[0], pos[1] - 1}
	right := [2]int{pos[0], pos[1] + 1}

	result := 0
	result += get_trailhead_paths(height_map, paths, current_path, under, height_to_check + 1)

	// check over
	result += get_trailhead_paths(height_map, paths, current_path, over, height_to_check + 1)

	// check left
	result += get_trailhead_paths(height_map, paths, current_path, left, height_to_check + 1)

	// check right
	result += get_trailhead_paths(height_map, paths, current_path, right, height_to_check + 1)

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


	/////////////////
	// PART 1
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

	/////////////////
	// PART 2
	{
		total_score := 0
		for trailhead in trailheads {
			total_score += get_trailhead_score_distinct(&height_map, trailhead, 0)
		}

		fmt.println("TOTAL SCORE PART 2: ", total_score)
	}


	/////////////////
	// VISUALIZATION
	{
		paths: [dynamic][dynamic][2]int
		current_path: [10][2]int
		for trailhead in trailheads {
			get_trailhead_paths(&height_map, &paths, current_path, trailhead, 0)
		}

		// fmt.println("PATHS")
		// fmt.println(paths[0])

		visualization(&height_map, &paths)
	}
}

visualization :: proc(height_map: ^[dynamic][dynamic]int, paths: ^[dynamic][dynamic][2]int) {
	rl.InitWindow(1200, 900, "Aoc day 10")

    // Define our custom camera to look into our 3d world
    camera: rl.Camera
    camera.position = (rl.Vector3){ 18.0, 30.0, 18.0 }     // Camera position
    camera.target = (rl.Vector3){ 0.0, 0.0, 0.0 }          // Camera looking at point
    camera.up = (rl.Vector3){ 0.0, 1.0, 0.0 }              // Camera up vector (rotation towards target)
    camera.fovy = 45.0                                    // Camera field-of-view Y
    camera.projection = rl.CameraProjection.PERSPECTIVE                 // Camera projection type

	rows := i32(len(height_map))
	columns := i32(len(height_map[0]))
	fmt.println("ROWS:", rows)
	image := rl.GenImageColor(columns, rows, rl.BLACK)
	for y in 0..<rows {
		for x in 0..<columns {
			height := height_map[y][x]
			scaler : f32 = 1.0 / 9.0
			step := f32(height) * scaler
			pixel_color := rl.ColorLerp(rl.BLACK, rl.WHITE, step)
			rl.ImageDrawPixel(&image, x, y, pixel_color)
		}
	}
	height_map_mesh := rl.GenMeshHeightmap(image, {f32(rows), 2, f32(rows)})
	model := rl.LoadModelFromMesh(height_map_mesh)
	image_texture := rl.LoadTextureFromImage(image)
	model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = image_texture;
	// rl.ExportImage(image, "test.jpg")

	for !rl.WindowShouldClose() {

		rl.UpdateCamera(&camera, rl.CameraMode.FREE)

		rl.BeginDrawing()
		defer rl.EndDrawing()
		rl.ClearBackground(rl.BLACK)

		// rl.DrawTexture(image_texture, 0, 0, rl.WHITE)


		rl.BeginMode3D(camera)

        rl.DrawGrid(20, 1.0);

		x_offset : f32 = -25
		y_offset : f32 = -25
		// rl.DrawModel(model, {x_offset, 0, y_offset}, 1, rl.GREEN)

		for y in 0..<len(height_map) {
			for x in 0..<len(height_map[0]) {
				pos_x := f32(x) + x_offset
				pos_y := f32(y) + y_offset
				scaler : f32 = 1.0 / 9.0
				height := f32(height_map[y][x])
				rl.DrawCube({pos_x, height, pos_y}, 1, 1, 1, rl.GREEN)
			}
		}

		SCALE :: 1
		for path in paths {
			last_point: [2]int
			for point, i in path {
				if i == 0 {
					last_point = point
					continue
				}
				x := point[1]
				y := point[0]
				last_x := last_point[1]
				last_y := last_point[0]
				scaler : f32 = 1.0 / 9.0
				height := f32(height_map[y][x]) * scaler
				last_height := f32(height_map[last_y][last_x]) * scaler
				start_height := f32(height)*2 + 0.1
				start_x := f32(x)*SCALE + x_offset
				start_y := f32(y)*SCALE + y_offset
				end_height := f32(last_height)*2 + 0.1
				end_x := f32(last_x)*SCALE + x_offset
				end_y := f32(last_y)*SCALE + y_offset
				// rl.DrawLine3D({start_x, start_height, start_y}, {end_x, end_height, end_y}, rl.RED)
				rl.DrawCylinderEx({start_x, start_height, start_y}, {end_x, end_height, end_y}, 0.04, 0.04, 10, rl.RED)
				last_point = point
			}
		}

		rl.EndMode3D()
	}
}
