require 'csv'

carcass_file    = RIO_ROOT_PATH+'/cache/Rio_carcass_components_1.4.csv'
csv_arr         = CSV.read(carcass_file)

count = 0
multi_category_internal = 0
multi_shutter           = 0
single_shutter          = 0
single_category_internal= 0

#[1..csv_arr.length].each{|csv_row|
#(1..csv_arr.length-1).each{|index|
#[1..csv_arr.length].each{|csv_row|
(1..csv_arr.length-1).each{|index|
	csv_row = csv_arr[index]
	csv_main_category 	= csv_row[0]
	csv_sub_category	= csv_row[1]
	csv_carcass_code	= csv_row[3]
	csv_shutter_code	= csv_row[4]
	csv_door_type		= csv_row[5]
	
	shut_type 			= csv_row[7]
	csv_shutter_type	= shut_type=='Yes' ? "solid" : ""
	
	csv_shutter_origin	= csv_row[11]
	#csv_internal_category=csv_row[
	options = {
		"auto_mode"=>"true",
		"auto_position"=>"bottom_right",
		"edit"=>0,
		"space_name"=>"Room#1",
		"main-category"=>csv_main_category,
		"sub-category"=>csv_sub_category,
		"carcass-code"=>csv_carcass_code,
		"door-type"=>csv_door_type,
		"shutter-code"=>csv_shutter_code,
		"shutter-type"=>csv_shutter_type,
		"shutter-origin"=>csv_shutter_origin,
		"internal-category"=>'',
		"right_internal"=>'',
		"center_internal"=>'',
	}
    code_split_arr = csv_carcass_code.split('_')
    doors = code_split_arr[1].to_i
    door_width = code_split_arr[2]

	#puts options
	internal_categories = Decor_Standards.get_internal_codes(csv_main_category, csv_sub_category, csv_carcass_code)
	if internal_categories.empty?
		# Multiple shutters
		if csv_shutter_code.include?('/')
			shutter_codes = csv_shutter_code.split('/')
			shutter_codes.each{ |s_code|
				options["shutter-code"] = s_code 
				#Decor_Standards::place_component options
                count += 1
                multi_shutter += 1
			}
		else
			#Single shutter
			#Decor_Standards::place_component options
            count += 1
            single_shutter += 1
		end
	else
		#Multiple internal category
		internal_categories.flatten!
		#puts internal_categories
		other_cats 	= internal_categories & ["7","8","10"]
		arr 		= internal_categories-["7","8","10"]
		combinations = []
		
		arr.each{ |x|
			arr.each{ |y|
				if doors == 2
					combinations << [x, y]
				elsif doors == 3
					arr.each{ |z|
						combinations << [x, y, z]
					}
				end
			}
		}

		other_cats.each{ |internal|
			file_name = "%dINT_%d_%d"%[doors, internal, door_width]
			options["left_internal"]	=file_name
			options["right_internal"]	=file_name
			options["center_internal"]	=file_name
			
			# puts "------------------------------"
			# puts options
			# puts "------------------------------"
			count += 1
            single_category_internal += 1
			#Decor_Standards::place_component options
		}
		#require 'pp'
		#pp combinations
		combinations.each{|a_comb|
			options["internal-category"] = ''
			rhs_file_name 		= "%dINT_%dRHS_%d"%[doors, a_comb[0], door_width]
			lhs_file_name 		= "%dINT_%dLHS_%d"%[doors, a_comb[1], door_width]
			center_file_name 	= "%dINT_%dLHS_RHS_%d"%[doors, a_comb[2], door_width] if doors == 3
			
			options["left_internal"]	=rhs_file_name
			options["right_internal"]	=lhs_file_name
			options["center_internal"]	=center_file_name if doors == 3
			# puts a_comb
			# puts "------------------------------"
			# puts options
			# puts "------------------------------"
			count += 1
            multi_category_internal += 1
			#Decor_Standards::place_component options
		}
	end
}

puts "\n\n\n--   All Component list     --"
puts "Warddrobe Components----------"
puts "Single Category       : #{single_category_internal}"
puts "Multi category        : #{multi_category_internal}"

puts "Other Components---------------"
puts "Single Shutter        : #{single_shutter}"
puts "Multi Shutter         : #{multi_shutter}"

puts "-------------------------------"
puts "Total                 | #{count}"
puts "-------------------------------\n\n\n"

puts "total : #{count}"

#create_comp.rb
# def self.get_internal_codes main_category, sub_category, carcass_code
	# if (main_category.include?("Sliding") == true || main_category.include?("sliding") == true)
		# getcat 	= carcass_code.split("_")
		# get_val = @db.execute("select distinct category from #{@int_table} where door_type=#{getcat[1]} and slide_width=#{getcat[2]};")
	# end

	# if get_val.nil?
		# return {}
	# else
		# return get_val 
	# end
# end

#Decor_Standards.get_internal_codes('Wardrobe_Sliding_Door', 'Wardrobe_Sliding_3Door', 'WS_3_1000')

# options = {
	# "auto_mode"=>"false", 
	# "auto_position"=>"false", 
	# "edit"=>0, 
	# "space_name"=>"Room#1", 
	# "main-category"=>"Wardrobe_Sliding_Door", 
	# "sub-category"=>"Wardrobe_Sliding_3Door", 
	# "carcass-code"=>"WS_3_1000", 
	# "door-type"=>"Triple", 
	# "shutter-code"=>"SLD3_1000", 
	# "shutter-type"=>"solid", 
	# "shutter-origin"=>"0_76_0", 
	# "internal-category"=>"2"
# }
