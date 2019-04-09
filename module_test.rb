def add_sliding_carcass_dimension comp
	begin
		Sketchup.active_model.start_operation 'Adding dimension to carcass'
		zvector = Geom::Vector3d.new(0, 0, 1)

		shutter_code 	= comp.get_attribute(:rio_atts, 'shutter-code')
		carcass_name 	= comp.get_attribute(:rio_atts, 'carcass-code')
		carcass_group 	= comp
		
		comp_origin 	= comp.transformation.origin
		comp_trans 			= comp.transformation.rotz
		
		dimension_points = []
		#
		dim_x_offset 	= 0.mm
		dim_y_offset 	= 0.mm
		dim_x_origin 	= 0.mm
		dim_y_origin 	= 0.mm
		if true
			
			pts 	= []
			case comp_trans
			when 0
				pts = [0,1,5,4]
				side_vector = Geom::Vector3d.new(-1, 0, 0)
				bound_index = 0
			when 90
				pts	= [1,3,7,5]
				side_vector = Geom::Vector3d.new(0, 1, 0)
				bound_index = 1
			when -90
				pts = [0,2,6,4]
				side_vector = Geom::Vector3d.new(0, -1, 0)
				bound_index = 2
			when 180, -180
				pts = [2,3,7,6]
				side_vector = Geom::Vector3d.new(1, 0, 0)
				bound_index = 3
			end

			
			#----Explode part----------------------------
			prev_ents	=[];
			Sketchup.active_model.entities.each{|ent| prev_ents << ent}

			comp.make_unique
			comp.explode
			
			post_ents 	= [];
			Sketchup.active_model.entities.each{|ent| post_ents << ent}

			exploded_ents = post_ents - prev_ents
			exploded_ents.select!{|x| !x.deleted?}
			#----Explode part----------------------------
			
			puts "exploded_ents.. : #{exploded_ents}"
			exploded_ents.select!{|ent| !ent.nil?} 
			internal_groups = exploded_ents.grep(Sketchup::ComponentInstance).select{|x| 
				x.definition.get_attribute(:rio_atts,'comp_type').end_with?('internal') if x.definition.get_attribute(:rio_atts,'comp_type')
			}
			
			carcass_group = exploded_ents.grep(Sketchup::Group).select{|x| x.definition.name.start_with?(carcass_name)}[0]
			carcass_group = exploded_ents.grep(Sketchup::ComponentInstance).select{|x| x.definition.name.start_with?(carcass_name)}[0] if carcass_group.nil?
				
			shelf_fix_entities = carcass_group.definition.entities.grep(Sketchup::Group).select{|x| x.layer.name.start_with?('72IMOSXD01_IM_SHELF_FIX')}
			shelf_fix_entities.sort_by!{|x| x.bounds.corner(0).z}
			lower_shelf_fix 	= shelf_fix_entities.first
		end
		
		puts "internal_groups : #{internal_groups}"
		
		internal_groups.each{|int_group|	
			puts "=============..===================================#{int_group.definition.name}"
			#int_group = fsel
			
			#Adjusting components to find ray test
			if true
				internal_origin = int_group.bounds.corner(0) #int_group.bounds.corner(0)
				center_pt 		= TT::Bounds.point(int_group.bounds, 9)
				internal_end 	= int_group.bounds.corner(1)
				internal_top 	= int_group.bounds.corner(4)
				
				prev_ents	=[];
				Sketchup.active_model.entities.each{|ent| prev_ents << ent}

				int_group.make_unique
				int_group.explode
				
				post_ents 	= [];
				Sketchup.active_model.entities.each{|ent| post_ents << ent}

				internal_ents = post_ents - prev_ents
				internal_ents.select!{|x| !x.deleted?}
				internal_ents.select!{|x| x.is_a?(Sketchup::Group)}
				
				case comp_trans
				when 90, -90
					dim_y_origin 	= internal_origin.y
				when 0, 180, -180
					dim_x_origin 	= internal_origin.x
				end
				
				puts "dim_x_origin : #{dim_x_origin} : #{dim_y_origin} : #{internal_origin} : #{comp_trans}"
				dim_ents 		= []
				other_ents	 	= []
				
				internal_ents.each{ |shelf_ent|
					ent_org = shelf_ent.transformation.origin
					visible_flag = false
					if shelf_ent.layer.name.end_with?('SHELF_INT') || shelf_ent.layer.name.end_with?('SHELF_FIX')
						visible_flag = true
					elsif shelf_ent.layer.name.end_with?('DRAWER_FRONT')
						visible_flag = true
					elsif shelf_ent.layer.name.end_with?('DRAWER_INT')
						other_ents << shelf_ent
					elsif shelf_ent.layer.name.end_with?('SIDE_NORM')
						
					end
					
					dim_ents << shelf_ent  if visible_flag
				}
				
				dim_ents.each{|ent|
					y_offset 	= internal_origin.y - ent.bounds.corner(0).y
					trans 		= Geom::Transformation.new([0, y_offset, 0])
					ent.transform!(trans)
				}
			end
			
			#Find the internal entities.
			if true
				internal_ray_entities = []
				
				dim_ents.sort_by!{|x| x.bounds.corner(0).z}
				
				#Usually component origin is fully upto the carcass group
				lowest_component = dim_ents.first
				puts "lowest_component.layer.name : #{lowest_component.layer.name}"
				internal_zoffset = internal_origin.z - comp_origin.z
				
				if internal_zoffset < 120.mm && lowest_component.layer.name.end_with?('DRAWER_FRONT')
					internal_ray_entities << lowest_component
					
					pt1 	= lowest_component.bounds.corner(0)
					pt2 	= lowest_component.bounds.corner(4)
					pt1.z	+=5000.mm
					pt2.z	+=5000.mm
					if dim_x_origin > 0.mm
						pt1.x = dim_x_origin
						pt2.x = dim_x_origin
						dim_l 					= Sketchup.active_model.entities.add_dimension_linear(pt1, pt2, side_vector)
					else
						pt1.y = dim_y_origin
						pt2.y = dim_y_origin
						dim_l 					= Sketchup.active_model.entities.add_dimension_linear(pt1, pt2, side_vector)
					end
					dim_l.material.color 	= 'blue'
					puts "#--dim_l dim : #{pt1} : #{pt2} : #{dim_l.text}"
				else
					if internal_zoffset < 120.mm
						ray_pt1 	= Geom.linear_combination(0.5, internal_origin, 0.5, center_pt)
						ray_pt2 	= Geom.linear_combination(0.5, internal_end, 0.5, center_pt)
					else
						#For trans 0
						lowest_component_start 	= lowest_component.bounds.corner(4)
						lowest_component_end 	= lowest_component.bounds.corner(5)
						
						ray_pt1 	= Geom.linear_combination(0.5, lowest_component_start, 0.5, center_pt)
						ray_pt2 	= Geom.linear_combination(0.5, lowest_component_end, 0.5, center_pt)
					end
					
					puts "ray_pt : #{internal_origin} : #{ray_pt1} : #{ray_pt2}"
					[ray_pt1, ray_pt2].each{ |ray_pt|
						ray 		= [ray_pt, zvector]
						hit_item 	= Sketchup.active_model.raytest(ray, true)
						
						#Get the lower most shelf entities
						if hit_item && hit_item[1][0]
							sel.add(hit_item[1][0])
							puts "hittt : #{hit_item[1][0]} : #{hit_item[1][0].layer.name}"
							if dim_ents.include?(hit_item[1][0])
								ray_comp = hit_item[1][0] 
								internal_ray_entities << ray_comp
								pt1 	= ray_pt
								pt2 	= hit_item[0]
								pt1.z	+=5000.mm
								pt2.z	+=5000.mm
								#pt1.y -= 5000.mm
								#pt2.y -= 5000.mm
								#puts 
								if (pt1.distance pt2) > 10.mm
									if dim_x_origin > 0.mm
										pt1.x = dim_x_origin
										pt2.x = dim_x_origin
										dim_l 					= Sketchup.active_model.entities.add_dimension_linear(pt1, pt2, side_vector)
									else
										pt1.y = dim_y_origin
										pt2.y = dim_y_origin
										dim_l 					= Sketchup.active_model.entities.add_dimension_linear(pt1, pt2, side_vector)
									end
									dim_l.material.color = 'blue'
									puts "points : #{pt1} : #{pt2}"
								end
								if ray_comp.layer.name.end_with?('DRAWER_FRONT')
									pt1 	= ray_comp.bounds.corner(0)
									pt2 	= ray_comp.bounds.corner(4)
									pt1.z	+=5000.mm
									pt2.z	+=5000.mm
									#pt1.y -= 5000.mm
									#pt2.y -= 5000.mm
									if dim_x_origin > 0.mm
										pt1.x = dim_x_origin
										pt2.x = dim_x_origin
										dim_l 					= Sketchup.active_model.entities.add_dimension_linear(pt1, pt2, side_vector)
									else
										pt1.y = dim_y_origin
										pt2.y = dim_y_origin
										dim_l 					= Sketchup.active_model.entities.add_dimension_linear(pt1, pt2, side_vector)
									end
									dim_l.material.color = 'blue'
									puts "#--dim_l dim : #{pt1} : #{pt2}"
								end
							end
						end
						
					}
				end
			end	
			
			puts "internal_zoffset : #{internal_zoffset}"
			#Add dimension to components
			if true
				#----------Internal ray entities loop start-----------------------	
				internal_ray_entities.each{|internal_comp|
					puts "-------------------+++++++++ : #{internal_comp}\n\n"
					continue_ray 	= true
					hit_comp 		= nil
					pt1 			= TT::Bounds.point(internal_comp.bounds, 9)
					puts "------------------------"
					# puts internal_comp.bounds.center
					# puts lower_shelf_fix.bounds.corner(4)
					if internal_zoffset > 120.mm
						a=internal_comp.bounds.center.z
						b=lower_shelf_fix.bounds.corner(4).z
						
						high_offset 	=  a - b
						pt2 = pt1.offset(zvector.reverse, high_offset)
						# pt1.y -= 5000.mm
						# pt2.y -= 5000.mm
						pt1.z	+=5000.mm
						pt2.z	+=5000.mm
						
						if dim_x_origin > 0.mm
							pt1.x = dim_x_origin
							pt2.x = dim_x_origin
							dim_l 					= Sketchup.active_model.entities.add_dimension_linear(pt1, pt2, side_vector)
						else
							pt1.y = dim_y_origin
							pt2.y = dim_y_origin
							dim_l 					= Sketchup.active_model.entities.add_dimension_linear(pt1, pt2, side_vector)
						end
						puts "#--dim_l dim : #{pt1} : #{pt2}"
						dim_l.material.color = 'blue'
						puts "comp initial : #{dim_l.text}"
					end
					
					while continue_ray
						center_pt = TT::Bounds.point(internal_comp.bounds, 10)
						next_pt 	= true
						[4,5].each{ |index| 
							break unless next_pt
							pt 			= TT::Bounds.point(internal_comp.bounds, index)
							bound_point = Geom.linear_combination(0.5, pt, 0.5, center_pt)
							ray 		= [bound_point, zvector]
							hit_item 	= Sketchup.active_model.raytest(ray, true)

							
							if hit_item && hit_item[1][0]
								#puts "inner comps : #{hit_item[0]} : #{pt} : #{bound_point}"
								sel.add(hit_item[1][0])
								if dim_ents.include?(hit_item[1][0]) 
									hit_comp 	= hit_item[1][0]
									pt1 	= bound_point
									pt2 	= hit_item[0] 
									
									#pt1 	= internal_comp.bounds.corner(4).offset(side_vector, 40.mm)
									pt1 	= pt.offset(side_vector, 40.mm)
									pt2 	= pt1.clone
									pt2.z 	= hit_item[0].z
									
									#pt1		= internal_comp.bounds.corner(0).offset(side_vector, 40.mm)
									#pt2 	= hit_item[0]
									# pt2 	= pt1; 
									# pt2.z 	= hit_item[0].z
									# pt2 	= hit_item[0]
									# pt1.y -= 5000.mm
									# pt2.y -= 5000.mm
									pt1.z	+=5000.mm
									pt2.z	+=5000.mm
									
									#pt1.z			+=5000.mm
									#pt2.z			+=5000.mm
									#puts "Add dimension : #{pt1} : #{pt2}"
									if (pt1.distance pt2) > 10.mm
										if dim_x_origin > 0.mm
											pt1.x = dim_x_origin
											pt2.x = dim_x_origin
											dim_l 					= Sketchup.active_model.entities.add_dimension_linear(pt1, pt2, side_vector)
										else
											pt1.y = dim_y_origin
											pt2.y = dim_y_origin
											dim_l 					= Sketchup.active_model.entities.add_dimension_linear(pt1, pt2, side_vector)
										end
										puts "#--dim_l dim : #{pt1} : #{pt2}"
										dim_l.material.color = 'red'
									end
									#puts "comp : #{internal_comp} : #{internal_comp.layer.name}"
									if hit_comp.layer.name.end_with?('DRAWER_FRONT')
										pt1 	= hit_comp.bounds.corner(0)
										pt2 	= hit_comp.bounds.corner(4)
										#pt1.y -= 5000.mm
										#pt2.y -= 5000.mm
										pt1.z	+=5000.mm
										pt2.z	+=5000.mm
										if dim_x_origin > 0.mm
											pt1.x = dim_x_origin
											pt2.x = dim_x_origin
											dim_l 					= Sketchup.active_model.entities.add_dimension_linear(pt1, pt2, side_vector)
										else
											pt1.y = dim_y_origin
											pt2.y = dim_y_origin
											dim_l 					= Sketchup.active_model.entities.add_dimension_linear(pt1, pt2, side_vector)
										end
										puts "#--dim_l dim : #{pt1} : #{pt2}"
										dim_l.material.color = 'red'
										#puts "Add dimension....... : #{hit_comp} : #{pt1} : #{pt2}"
									end
									internal_comp = hit_comp
									next_pt 	= false
								else
									continue_ray = false 
								end
							else
								continue_ray = false 
							end
						}
					end#While
					
					if hit_comp
						puts "hit_comp : #{hit_comp} : #{internal_top}"
						high_offset =  internal_top.z - hit_comp.bounds.corner(4).z
						if high_offset > 20.mm
							puts "high_offset : #{high_offset} : #{internal_top.z} : #{hit_comp.bounds.corner(4).z}"
							
							pt1 = TT::Bounds.point(hit_comp.bounds, 10)
							pt2 = pt1.offset(zvector, high_offset)
							puts "pt........ #{pt1} : #{pt2}"
							# pt1.y -= 5000.mm
							# pt2.y -= 5000.mm
							pt1.z	+=5000.mm
							pt2.z	+=5000.mm
							if dim_x_origin > 0.mm
								pt1.x = dim_x_origin
								pt2.x = dim_x_origin
								dim_l 					= Sketchup.active_model.entities.add_dimension_linear(pt1, pt2, side_vector)
							else
								pt1.y = dim_y_origin
								pt2.y = dim_y_origin
								dim_l 					= Sketchup.active_model.entities.add_dimension_linear(pt1, pt2, side_vector)
							end
							dim_l.material.color = 'green'
						end
					end
					
					
				}
			end
			
			
			#----------Internal ray entities loop end -----------------------
			puts "internal_ray_entities : #{internal_ray_entities}"
			internal_ray_entities.flatten!
							
			puts "dim_ents :#{dim_ents}"
			dim_ents.each { |x| puts x.layer.name}
			puts "+++++++++++++++++++++++++++++++++++++++++"
		}
	rescue Exception=>e 
		raise e
		Sketchup.active_model.abort_operation
	else
		#Sketchup.active_model.abort_operation
	end
	return true
end

