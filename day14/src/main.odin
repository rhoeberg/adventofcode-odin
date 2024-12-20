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

MAP_SIZE : Vec2 : {101, 103}
quadrant_top_left : [2]Vec2 :  {{0                        , 0}, {MAP_SIZE.x / 2, MAP_SIZE.y / 2}}
quadrant_top_right : [2]Vec2 : {{MAP_SIZE.x - MAP_SIZE.x/2, 0}, {MAP_SIZE.x    , MAP_SIZE.y / 2}}
quadrant_bottom_left : [2]Vec2 : {{0,MAP_SIZE.y - MAP_SIZE.y/2}, {MAP_SIZE.x/2, MAP_SIZE.y}}
quadrant_bottom_right : [2]Vec2 : {{MAP_SIZE.x - MAP_SIZE.x/2  , MAP_SIZE.y - MAP_SIZE.y/2}, {MAP_SIZE.x, MAP_SIZE.y}}

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

Robot :: struct {
	pos: Vec2,
	vel: Vec2,
}

main :: proc() {
	input := read_input("input.txt")

	//////////////////
	// PARSING
	robots: [dynamic]Robot
	for line in strings.split_lines_iterator(&input) {
		if len(line) <= 0 do break

		robot: Robot

		pos_vel := strings.split(line, " ")
		pos_str := strings.split(pos_vel[0][2:], ",")
		vel_str := strings.split(pos_vel[1][2:], ",")

		robot.pos.x, _ = strconv.parse_int(pos_str[0])
		robot.pos.y, _ = strconv.parse_int(pos_str[1])
		robot.vel.x, _ = strconv.parse_int(vel_str[0])
		robot.vel.y, _ = strconv.parse_int(vel_str[1])
		// fmt.println(pos_str)
		// fmt.println(robot)
		append(&robots, robot)

	}

	// part1(&robots)
	part2(&robots)
}

move_robot :: proc(robot: ^Robot) {
	robot.pos += robot.vel
	robot.pos %%= MAP_SIZE 
}
move_robot_reverse :: proc(robot: ^Robot) {
	robot.pos -= robot.vel
	robot.pos %%= MAP_SIZE 
}

get_robots_in_quadrant :: proc(robots: ^[dynamic]Robot, quadrant: [2]Vec2) -> int {
	result := 0
	for robot in robots {
		if robot.pos.x >= quadrant[0].x &&
			robot.pos.x < quadrant[1].x &&
			robot.pos.y >= quadrant[0].y &&
			robot.pos.y < quadrant[1].y {
				result += 1
			}
	}

	return result
}

part1 :: proc(robots: ^[dynamic]Robot) {
	for i in 0..<100 {
		// fmt.println(robots[0])
		for &robot in robots {
			move_robot(&robot)
		}
	}

	total_robots := get_robots_in_quadrant(robots, quadrant_top_left)
	total_robots *= get_robots_in_quadrant(robots, quadrant_top_right)
	total_robots *= get_robots_in_quadrant(robots, quadrant_bottom_left)
	total_robots *= get_robots_in_quadrant(robots, quadrant_bottom_right)

	fmt.println("amount of robots:", len(robots))
	fmt.println("total robots:", total_robots)
}

// start 53
// start 98

part2 :: proc(robots: ^[dynamic]Robot) {

	start_x := 98
	start_y := 53
	start_xes := make(map[int]struct{})
	for i in 0..<1000 {
		// fmt.println(i)
		fmt.println(start_x, start_y)
		start_xes[start_x] = {}

		start_x += 101
	}
	for i in 0..<1000 {
		if start_y in start_xes {
			fmt.println("FOUND SAME VALUE:", start_y)
			break
		}
		start_y += 103
	}
	// assert(false)

	SCALE :: 8
	HALF_SCALE :: SCALE / 2
	last_step: f64
	STEP_DURATION :: 0.1
	rl.InitWindow(1000, 1000, "aoc day 15")
	frame := 0

	for i in 0..<7572 {
		frame = i
		for &robot in robots {
			move_robot(&robot)
		}
	}

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.BLACK)

		for x in 0..<MAP_SIZE.x {
			for y in 0..<MAP_SIZE.y {
				rl.DrawRectangleLines(i32(x) * SCALE, i32(y) * SCALE, SCALE, SCALE, rl.WHITE)
			}
		}

		for robot in robots {
			rl.DrawCircle(i32(robot.pos.x * SCALE) + HALF_SCALE, i32(robot.pos.y * SCALE) + HALF_SCALE, HALF_SCALE, rl.GREEN)
		}

		// if last_step + STEP_DURATION < rl.GetTime() && frame < 7572 {
		// 	frame += 1
		// 	last_step = rl.GetTime()
		// 	for &robot in robots {
		// 		move_robot(&robot)
		// 	}
		// }

		if rl.IsKeyDown(rl.KeyboardKey.RIGHT) && last_step + STEP_DURATION < rl.GetTime(){
			frame += 1
			last_step = rl.GetTime()
			for &robot in robots {
				move_robot(&robot)
			}
		}
		if rl.IsKeyDown(rl.KeyboardKey.LEFT)  && last_step + STEP_DURATION < rl.GetTime(){
			frame -= 1
			last_step = rl.GetTime()
			for &robot in robots {
				move_robot_reverse(&robot)
			}
		}

		frame_text := rl.TextFormat("%d", frame)
		rl.DrawText(frame_text, 0, 0, 20, rl.BLUE)
	}
}
