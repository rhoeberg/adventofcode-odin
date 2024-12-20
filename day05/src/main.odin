package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:sort"

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

Page_Order_Rule :: struct {
	a: int,
	b: int,
}

main :: proc() {
	input := read_input("input.txt")
	input_parts := strings.split(input, "\n\n")
	// fmt.println(input_parts[0])


	////////////
	// GET RULES
	rules: [dynamic]Page_Order_Rule
	for line in strings.split_lines_iterator(&input_parts[0]) {
		// fmt.println(line)
		pair,_ := strings.split(line, "|")
		a, _ := strconv.parse_int(pair[0])
		b, _ := strconv.parse_int(pair[1])
		append(&rules, Page_Order_Rule{a, b})
	}



	////////////
	// GET UPDATES
	updates: [dynamic][dynamic]int
	for line in strings.split_lines_iterator(&input_parts[1]) {
		pages_str := strings.split(line, ",")
		update: [dynamic]int
		for page_str in pages_str {
			page_int,_ := strconv.parse_int(page_str)
			append(&update, page_int)
		}
		append(&updates, update)
	}

	validate_update :: proc(update: ^[dynamic]int, rules: ^[dynamic]Page_Order_Rule) -> bool {
		for page_after, i in update {
			for j in 0..<i {
				page_before := update[j]
				for rule, rule_id in rules {
					if rule.a == page_after && rule.b == page_before {
						return false
					}
				}
			}
		}
		return true
	}

	shuffle_up_page :: proc(update: ^[dynamic]int, i, j: int){
		temp := update[j]
		next := update[i]
		for current_index in j..=i {
			temp = update[current_index]
			update[current_index] = next
			next = temp
		}
	}

	validate_and_swap :: proc(update: ^[dynamic]int, rules: ^[dynamic]Page_Order_Rule) -> bool {
		rule_break := false
		for page_after, i in update {
			for j in 0..<i {
				page_before := update[j]
				did_swap := false
				for rule, rule_id in rules {
					if rule.a == page_after && rule.b == page_before {
						shuffle_up_page(update, i, j)
						rule_break = true
						did_swap = true
						break
					}
				}
				if did_swap do break
			}
		}

		return rule_break
	}


	total_middle_page_amount := 0
	for update, i in updates {
		update := update
		if validate_update(&update, &rules) {
			middle_page_nr := update[len(update)/2]
			total_middle_page_amount += middle_page_nr
		}
	}
	fmt.println("total middle of correct updates: ", total_middle_page_amount)


	total_from_swapped_updates := 0
	for update, i in updates {
		update := update
		if validate_and_swap(&update, &rules) {
			
			middle_page_nr := update[len(update)/2]
			total_from_swapped_updates += middle_page_nr
		}
	}

	fmt.println("total from swapped: ", total_from_swapped_updates)
}
