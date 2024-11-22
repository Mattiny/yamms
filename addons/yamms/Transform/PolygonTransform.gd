@tool
extends MultiScatterTransform
class_name PolygonTransform

var exclude_list : Array[MultiScatterExclude]
var specific_exclude_list : Array[MultiScatterExclude]
var randomize_steps = false
var thickness : float = 0


func _debug(message):
	if debug_messages:
		print("YAMMS: PolygonTransform:  " + message)
	


func align_rotation_to_curve(distance : float):
	var tangent_offset : float = 0.01
	var current_pos = position  # Position ist bereits der Punkt auf der Kurve
	var step_ahead = curve.sample_baked(distance + tangent_offset)
	
	var forward = (step_ahead - current_pos).normalized()
	var up = curve.sample_baked_up_vector(distance).normalized()
	var sideways = up.cross(forward).normalized()
	
	var alignment_basis = Basis(sideways, up, forward)

	basis *= alignment_basis
	


func generate_transform():
	
	var length = curve.get_baked_length()
	

	var step = length / (amount - 1)
	
	var valid_data : Array[Dictionary]  = []

	for index in range(amount):
		_debug("Setting position index %s" %index)
		
		var distance 
		if randomize_steps:
			distance = generate_random(0, length) # randomized position on curve
		else:
			distance = step * index # fix step position on curve
		position = curve.sample_baked(distance)
		
		# Choose the exclude areas:
		# If specific exclude areas are configured for this MultiScatterITem:
		# use ist.
		# Otherwise use all default exclude areas.
		var my_exclude_array : Array[MultiScatterExclude]
				
		if specific_exclude_list.size() > 0:
			my_exclude_array = specific_exclude_list
			_debug("Specific exclude list")
		else:
			my_exclude_array = exclude_list 
			_debug("Generel exclude list")

		var found_in_exclude : bool = false
		var check_completed : bool = false
		var attempts : int = 0 # Nr of attempts to place mesh inside of the polygon
		
		while not found_in_exclude and not check_completed:
			attempts += 1
			_debug("Checking position. Attempt %s" %attempts)
			if attempts == 100:
				var message = "Cannot drop MultiMesh. Please check: " \
					+ "1) Is the whole polygon hidden by an exclude area? " 
				_debug(message)
				push_warning(message)
				return
			else:
				for exclude_to_check:MultiScatterExclude in my_exclude_array:
					if found_in_exclude == false:
						var global_pos = Vector2(position.x, position.z) + Vector2(global_position.x, global_position.z)
						found_in_exclude = exclude_to_check.is_point_in_polygon(global_pos)
				_debug("Found in exclude: %s" %found_in_exclude)
				if not randomize_steps:
					_debug("Fix step size. Check completed.")
					check_completed = true
				else:
					if found_in_exclude:
						_debug("Found in exclude list. Generating new random position")
						distance = generate_random(0, length) # randomized position on curve
						position = curve.sample_baked(distance)
						check_completed = true
					else:
						_debug("Not found in exclude list. Position is valid.")
				
				# loop got through all excludes. this makes the check completed
				check_completed = true
		
			if not found_in_exclude:
				_debug("Setting valid position.")
				
				basis = Basis()
				
				# Generate scale depending on the Placement mode settings.
				generate_scale()
			
				# Generate rotation depending on the Placement mode settings.
				generate_rotation()
				
				#align rotation to polygon curve
				align_rotation_to_curve(distance)
				
				if thickness > 0:
					assign_thickness()
				
				var data = {
					"position" :  position,
					"basis" : basis
				}
				valid_data.append(data)
			else:
				_debug("No valid position. Ommiting position.")
	
	multimesh_item.instance_count = valid_data.size()
	for i in range(valid_data.size()):
		var dict_entry = valid_data[i]
		var pos = dict_entry["position"]
		var bas = dict_entry["basis"]
		do_transform(i, pos, bas)
	
func assign_thickness():
	var axis_sideways = basis.x.normalized()
	var actual_thickness = generate_random(-thickness, thickness)
	position = position + (axis_sideways * actual_thickness)
