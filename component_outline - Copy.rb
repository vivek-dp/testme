module RioIntDim
    extend self

    sk_ents         = Sketchup.active_model.entities
    selected_comp   = fsel
    @visible_comps  = []

    def set_visible_comps comp
        @visible_comps << comp
    end

    def unset_visible_comps
        @visible_comps=[]
    end

    def get_visible_comps
        @visible_comps
    end

    def get_transformation_hash rotz=0

        transform_hash = {
            :front_bounds => [],
            :back_bounds => [],
            :left_bounds => [],
            :right_bounds => [],
            :top_bounds => [],
            :bottom_bounds => [],

            :front_side_vector => nil,
            :front_side_vector_reverse => nil,
            :back_side_vector => nil,
            :back_side_vector_reverse => nil,
            :left_side_vector => nil,
            :left_side_vector_reverse => nil,
            :right_side_vector => nil,
            :right_side_vector_reverse => nil,
            :top_side_vector => nil,
            :top_side_vector_reverse => nil,
            :bottom_side_vector => nil,
            :bottom_side_vector_reverse => nil,


            :front_face_index_pts => [],
            :left_face_index_pts => [],
            :right_face_index_pts => [],
            :back_face_index_pts => [],
            :bottom_face_index_pts => [],
            :top_face_index_pts => [],

            :front_dim_vector => nil,
            :back_dim_vector => nil,
            :right_dim_vector => nil,
            :left_dim_vector => nil,
            :top_dim_vector => nil,
            :bottom_dim_vector => nil,

            :front_all_points => []
        }

        case rotz
        when 0
            transform_hash[:front_bounds]       = [0, 1, 5, 4]
            transform_hash[:front_dim_vector]   = X_AXIS
            transform_hash[:front_side_vector]  = Y_AXIS.reverse
            transform_hash[:front_all_points]   = [0,1,5,4,8,17,10,16,22]
        when 90
        when -90
        when 180, -180
        end
        transform_hash
    end

    def get_face_edge_vectors face
        face_edges  = face.outer_loop.edges
        edge_array = []
        (0..face_edges.length-1).each{ |index|
            curr_edge = face_edges[index]
            next_egde = face_edges[index-1]

            common_vertex 	= (curr_edge.vertices & next_egde.vertices)[0]
            other_vertex    = curr_edge.vertices - [common_vertex]
            other_vertex    = other_vertex[0]

            vector  = common_vertex.position.vector_to other_vertex
            pt 		= next_egde.bounds.center.offset vector, 10.mm
            res  	= face.classify_point(pt)

            if res == Sketchup::Face::PointInside || res == Sketchup::Face::PointOnFace
                vector = vector.reverse
            end
            edge_array << [curr_edge, vector]
        }
        edge_array
    end

    def get_face_perpendicular_edge_vector face
        face_edges  = face.outer_loop.edges
        edge_array = []
        (0..face_edges.length-1).each{ |index|
            curr_edge = face_edges[index]
            next_edge = face_edges[index-1]
            vector = next_edge.line[1]

            pt 		= curr_edge.bounds.center.offset vector, 10.mm
            res  	= face.classify_point(pt)
            if res == Sketchup::Face::PointInside || res == Sketchup::Face::PointOnFace
                vector = vector.reverse
            end
            edge_array << [curr_edge, vector]
        }
        edge_array
    end

    def get_edge_vectors face
        face_edges  = face.outer_loop.edges

        edges_arr = []
        face_edges.each{|edge| edges_arr << edge}

        edges_arr.length.times {|index|
            curr_edge 	=  	edges_arr[0]
            next_edge 	=	edges_arr[1]
            if MRP::check_perpendicular(curr_edge, next_edge)
                break
            else
                edges_arr.rotate!
            end
        }

        #Start with the perpendicular edge
        edges_arr.rotate!

        edge_list  	= []
        last_edge 	= nil
        vector 		= nil
        first_edge  = edges_arr[0]


        face_edges.each{|edge|
            if edge_list.empty?
                edge_list << edge
                last_edge = edge
            else
                curr_edge = edge
                #puts "curr_edge : #{curr_edge} : #{last_edge} : #{edge_list}"
                if MRP::check_perpendicular(curr_edge, last_edge)
                    #puts "perpendicular : #{curr_edge} : #{last_edge}"
                    common_vertex 	= (curr_edge.vertices & last_edge.vertices)[0]
                    other_vertex = curr_edge.vertices - [common_vertex]
                    other_vertex = other_vertex[0]

                    vector  = common_vertex.position.vector_to other_vertex
                    pt 		= last_edge.bounds.center.offset vector, 10.mm
                    res  	= floor_face.classify_point(pt)

                    if res == Sketchup::Face::PointInside || res == Sketchup::Face::PointOnFace
                        vector = vector.reverse
                    end
                    #puts res, vector.reverse

                    #puts "edge_list #{edge_list} : #{vector}"
                    edge_list = [curr_edge]
                    last_edge = curr_edge
                else
                    edge_list << curr_edge
                    last_edge = curr_edge
                end
            end
        }

    end

    def add_extra_offset_lines face, offset_distance
        sk_ents     = Sketchup.active_model.entities
        edge_arr    = get_face_perpendicular_edge_vector face
        edge_arr.each{ |edge_pair|
            face_edge, offset_vector = edge_pair
            edge_vertices = face_edge.vertices
            edge_vertices.each { |edge_vert|
                current_pt = edge_vert.position
                offset_pt = current_pt.offset(offset_vector, offset_distance.mm)
                sk_ents.add_line(current_pt, offset_pt)
            }
        }
    end

    def add_extra_offset_faces face, offset_distance
        sk_ents     = Sketchup.active_model.entities
        edge_arr    = get_face_perpendicular_edge_vector face
        edge_arr.each{ |edge_pair|
            face_edge, offset_vector = edge_pair
            next if offset_vector.z != 0
            edge_vertices = face_edge.vertices
            pt1 = edge_vertices[0]
            pt2 = edge_vertices[1]
            pt3 = pt2.position.offset(offset_vector, offset_distance.mm)
            pt4 = pt1.position.offset(offset_vector, offset_distance.mm)
            offset_face = sk_ents.add_face(pt1, pt2, pt3, pt4)
            offset_face.set_attribute(:rio_atts, 'offset_face', true)
        }

    end

    def traverse_comp(entity, transformation = IDENTITY)
        #puts "Entity type : #{entity}"
        if entity.is_a?( Sketchup::Model)
            entity.entities.each{ |child_entity|
                traverse_comp(child_entity, transformation)
            }
        elsif entity.is_a?(Sketchup::Group)
            if entity.attribute_dictionaries
                if entity.attribute_dictionaries['rio_atts']
                    if entity.attribute_dictionaries['rio_atts']['inner_dimension_visible_flag']
                        set_visible_comps(entity)
                    end
                end
            end
            transformation *= entity.transformation
            entity.definition.entities.each{ |child_entity|
                traverse_comp(child_entity, transformation.clone)
            }
        elsif entity.is_a?(Sketchup::ComponentInstance)
            transformation *= entity.transformation
            entity.definition.entities.each{ |child_entity|
                traverse_comp(child_entity, transformation.clone)
            }
        elsif entity.is_a?(Sketchup::Face)
            #puts "Face : "
        end
    end

    def add_depth_dimension entity, rotz=nil
        index_arr = [0,4]
        rotz = entity.transformation.rotz unless rotz

        pt1 = TT::Bounds.point(entity.bounds, 0)
        pt2 = TT::Bounds.point(entity.bounds, 4)
        distance = pt1.distance pt2
        if distance > 99.mm
            #pt1.z    += 5000.mm; pt2.z    += 5000.mm
            trans_hash = get_transformation_hash
            front_vector = trans_hash[:front_dim_vector].clone
            front_vector.length=100.mm
            dim_l = Sketchup.active_model.entities.add_dimension_linear(pt1, pt2, front_vector)
            dim_l.material.color = 'red'
        end
    end

    def add_internal_outlines input_comp
        visible_layers      = ['SHELF_FIX', 'SHELF_NORM', 'SHELF_INT', 'SIDE_NORM', 'DRAWER_FRONT']
        comp_trans          = input_comp.transformation
        comp_origin         = comp_trans.origin

        trans_hash      = get_transformation_hash comp_trans.rotz

        front_bounds    = trans_hash[:front_bounds]
        front_vector    = trans_hash[:front_side_vector]
        front_all_sides = trans_hash[:front_all_points]

        comp_edges = []

        unset_visible_comps
        puts "visible_comps : #{get_visible_comps}"

        traverse_comp(input_comp)
        visible_comps = get_visible_comps
        puts "visible_comps : #{visible_comps}"

        extra_line_layers = ['SHELF_FIX', 'SHELF_INT', 'DRAWER_FRONT']
        visible_comps.each{ |visible_comp|
            comp_bbox       = visible_comp.bounds
            visible_comp_trans_hash      = get_transformation_hash visible_comp.transformation.rotz
            front_bounds    = visible_comp_trans_hash[:front_bounds]

            #puts "front_bounds : #{front_bounds} : #{visible_comp}"
            face_pts = []
            front_bounds.each{ |index|
                pt = comp_bbox.corner(index)
                #puts "bounds point : #{pt}"
                original_transformation = comp_trans * visible_comp.transformation
                #res_vector              = pt.vector_to(original_transformation.origin)
                #original_point          = Geom::Point3d.new(res_vector.to_a)
                original_point = original_transformation.origin

                original_point.x += pt.x
                original_point.y += pt.y
                original_point.z += pt.z

                original_point.z += 5000.mm
                #pt = 0.000000;original_point.y     = pt.mm
                #original_point = pt
                face_pts << original_point
            }

            ent_layer_name      = visible_comp.layer.name
            ent_layer_ending    = ent_layer_name.split('_IM_')[1]

            #puts "face_pts : #{face_pts}"
            visible_face = Sketchup.active_model.entities.add_face(face_pts)

            if ent_layer_ending == 'DRAWER_FRONT'
                visible_face.set_attribute(:rio_atts, 'drawer_face', true)
                add_extra_offset_faces visible_face, 1
                add_depth_dimension visible_face, comp_trans.rotz
            elsif ent_layer_ending == 'SHELF_INT'
                visible_face.set_attribute(:rio_atts, 'shelf_face', true)
                add_extra_offset_faces visible_face, 0.5
            elsif ent_layer_ending == 'SHELF_FIX' || ent_layer_ending == 'SHELF_NORM'
                visible_face.set_attribute(:rio_atts, 'shelf_face', true)
            elsif ent_layer_ending =='SIDE_NORM'
                visible_face.set_attribute(:rio_atts, 'side_norm_face', true)
            end

            comp_edges << visible_face.edges
        }

        prev_ents = [];Sketchup.active_model.entities.each{|x| prev_ents << x}
        unless comp_edges.empty?
            comp_edges.flatten!.uniq!
            comp_edges.each{|c_edge|
                c_edge.find_faces
            }
        end
        curr_ents = [];Sketchup.active_model.entities.each{|x| curr_ents << x}


        newer_ents = curr_ents - prev_ents
        puts "newer : #{newer_ents}"

        newer_ents.select!{|x| x.is_a?(Sketchup::Face)}
        newer_ents.each{|ent_face| add_depth_dimension(ent_face, comp_trans.rotz)}

    end

    def add_internal_gaps comp

    end

    def add_internal_dimensions comp

    end

end











