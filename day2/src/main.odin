/*


with dampning result has to be:
bigger than 534
and smaller than 551

*/

package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:sort"

main :: proc() {
	fmt.println("hello wurld")

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


	{
		// NO DAMPNER
		safe_reports := 0 
		for report, i in reports {

			if len(report) == 0 do continue

			safe := check_report(report)

			if safe {
				safe_reports += 1
			}
			
			// fmt.printf("report(%d): %s\t=%t\n", i, report, check_report(report))
		}

		fmt.println("safe reports: ", safe_reports)
	}


	{
		// WITH DAMPNER
		fmt.println("=========================")
		safe_reports := 0 
		for report, i in reports {

			if len(report) == 0 do continue

			safe := check_report(report, true)

			if safe {
				safe_reports += 1
			}
			
			// fmt.printf("report(%d): %s\t=%t\n", i, report, safe)
		}

		fmt.println("safe reports with dampner: ", safe_reports)
	}


}

check_report :: proc(report: string, dampner := false) -> bool {
	if dampner {
		report_without_first, without_first_ok := strings.substring_from(report, strings.index(report, " ")+1)
		// report_without_first := report[strings.index(report, " ")+1:]

		ascending := check_ascending_with_dampner(report)
		// if without_first_ok {
			ascending_without_first := check_ascending(report_without_first)
			if ascending_without_first do return true
		// }

		descending := check_descending_with_dampner(report)
		// if without_first_ok {
			descending_without_first := check_descending(report_without_first)
			if descending_without_first do return true
		// }


		return ascending || descending
	}
	else {
		ascending := check_ascending(report)
		descending := check_descending(report)
		return ascending || descending
	}

}

check_ascending :: proc(report: string) -> bool {
	report := report
	report_it := &report

	count := 0
	prev_level: int
	for level in strings.split_iterator(report_it, " ") {
		level_int, parse_ok := strconv.parse_int(level)
		if !parse_ok {
			fmt.println("could not parse level: ", level)
			os.exit(1)
		}

		if count > 0 {
			dist := level_int - prev_level
			if dist < 1 || dist > 3  {
				return false
			}
		}

		prev_level = level_int
		count += 1
	}

	return true
}

check_descending :: proc(report: string) -> bool {
	report := report
	report_it := &report

	count := 0
	prev_level: int
	for level in strings.split_iterator(report_it, " ") {
		level_int, parse_ok := strconv.parse_int(level)
		if !parse_ok {
			fmt.println("could not parse level: ", level)
			os.exit(1)
		}

		if count == 0 {
			prev_level = level_int
		}
		else {
			dist := level_int - prev_level
			if dist > -1 || dist < -3 {
				return false
			}
		}

		prev_level = level_int
		count += 1
	}

	return true
}

check_ascending_with_dampner :: proc(report: string) -> bool {
	report2 := report
	report_it := &report2

	prev_level: int = -1
	dampner_used := false
	for level in strings.split_iterator(report_it, " ") {
		level_int, parse_ok := strconv.parse_int(level)
		if !parse_ok {
			fmt.println("could not parse level: ", level)
			os.exit(1)
		}

		if prev_level != -1 {
			dist := level_int - prev_level
			if dist < 1 || dist > 3  {
				if !dampner_used {
					dampner_used = true
					continue
				}
				
				if prev_level > level_int {
					fmt.println("error: ", prev_level, level_int)
					fmt.println("report: ", report)
				}
				
				return false
			}
		}

		prev_level = level_int
	}
	
	return true
}

check_descending_with_dampner :: proc(report: string) -> bool {
	report2 := report
	report_it := &report2

	prev_level: int = -1
	dampner_used := false
	for level in strings.split_iterator(report_it, " ") {
		level_int, parse_ok := strconv.parse_int(level)
		if !parse_ok {
			fmt.println("could not parse level: ", level)
			os.exit(1)
		}

		if prev_level != -1 {
			dist := level_int - prev_level
			if dist > -1 || dist < -3 {
				if !dampner_used {
					dampner_used = true
					continue
				}
				return false
			}
		}

		prev_level = level_int
	}

	return true
}
