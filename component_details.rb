def sketchup_class_split str
	return str.split('<')[1].chop
end

def comp_details
	comp = Sketchup.active_model.selection[0]
	str_hash = {
		"Definition Name"=>comp.definition.name,
		"Selection"=>sketchup_class_split(comp.to_s),
		"Transformation"=>sketchup_class_split(comp.transformation.to_s),
		"Origin"=>comp.transformation.origin.to_s,
		"Rotz"=>comp.transformation.rotz.to_s,
		"Ent Count"=>comp.definition.entities.length.to_s,
	}
	bbox=comp.bounds
	[0,1,2,3,4,5,6,7].each{|index|
		str_hash['bbox_%d'%[index]]=bbox.corner(index)
	}
	str = "<html>\n<head>\n"
	str += 	"<link rel='stylesheet' href='https://cdnjs.cloudflare.com/ajax/libs/semantic-ui/2.4.1/semantic.css' />
			<script type='text/javascript' href='https://cdnjs.cloudflare.com/ajax/libs/semantic-ui/2.4.1/semantic.js'></script>
			<script type='text/javascript' href='https://cdnjs.cloudflare.com/ajax/libs/jquery/3.3.1/jquery.js'></script>"
	str += "\n</head>\n<body>\n<table class='ui red table'>"
	str_hash.each_pair{|key, value|
		str += "<tr>"
		str += "<td class='positive'>%s</td><td class='negative'>%s</td>"%[key,value]
		str += "</tr>\n"
	}

	str += "\n</table>\n</body>\n</html>"
	puts str
	comp_details_file_path=RIO_ROOT_PATH+'/cache/comp_details.html'
	puts "comp_details_file_path : #{comp_details_file_path}"
	File.write(comp_details_file_path, str)
	$comp_details_dialog = UI::HtmlDialog.new({:dialog_title=>"Component Details", :scrollable=>true, :resizable=>true, :style=>UI::HtmlDialog::STYLE_DIALOG})
	$comp_details_dialog.set_file(comp_details_file_path)
	$comp_details_dialog.show
end

# UI.add_context_menu_handler {|menu|
	# model = Sketchup.active_model
	# selection = model.selection[0]
	# if selection 
		# case selection
		# when Sketchup::ComponentInstance
			# menu.add_item("Rio Details"){
				# comp_details
			# }
		# end
	# end
# }