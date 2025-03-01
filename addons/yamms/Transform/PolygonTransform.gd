# MIT License
# 
# Copyright (c) 2025 Mattiny
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# PolygonTransform - Distributes multimesh instances along a polygon.
@tool
extends MultiScatterTransform
class_name PolygonTransform

# List of Exclude areas which are assigned to this transform.
var exclude_list : Array[MultiScatterExclude]

# The actual exclude area which is applied to this transform.
# If "exclude_list" is empty (not assigned) all exclude areas underneath the
# MultiScatter item are passed to the "specific_exclude_list".
# If "exclude_list" is set (not empty), then only the exclude ares in exclude_list
# are applied and set to "specific_exclude_list".
var specific_exclude_list : Array[MultiScatterExclude]

# Flag if the distance between the generated multimesh instances on the polygon
# are randomized or distributed even.
var randomize_steps = false

# Thickness of the polygon. Multimesh instances generated on the polygon are
# randomly moved sideways. The max distance to the polygon is the thickness.
var thickness : float = 0

# Output of the debug message.
func _debug(message):
	if debug_messages:
		print("YAMMS: PolygonTransform:  " + message)
	

# Assigns the orientation of the polygon position to the multimesh instance which
# shall be placed on the polygon.
func align_rotation_to_curve(distance : float):
	var tangent_offset : float = 0.01
	var current_pos = position  # Position ist bereits der Punkt auf der Kurve
	var step_ahead = curve.sample_baked(distance + tangent_offset)
	
	var forward = (step_ahead - current_pos).normalized()
	var up = curve.sample_baked_up_vector(distance).normalized()
	var sideways = up.cross(forward).normalized()
	
	var alignment_basis = Basis(sideways, up, forward)

	basis *= alignment_basis
	
# Generates the height. Nothing to do.
func generate_height() -> bool:
	return true

# Moves the spawned multimesh instance randomly sideways (depending on the thickness).
func assign_thickness():
	var axis_sideways = basis.x.normalized()
	var actual_thickness = generate_random(-thickness, thickness)
	position = position + (axis_sideways * actual_thickness)

# Generates all position of the multimesh instances.
#
# 1) Generates the position on the polygon
#    1.1) if randomize_step is true: The position on polygon is generated 
#         randomly.
#    1.2) if randomize_step is false: The position on polygin is generated in
#         a fix step size (length of polygon / amount)
#
# 2) It is checked wether the generated position is inside an exclude area that
#    is applied to the MultiScatter item. If so it is ommited.
#    Unlike the plane based transform and placement, the instance is skipped 
#    completely because (as for fixed step size) it cannot be generated a new
#    position.
func generate_transform():
	var length = curve.get_baked_length()
	var step = length / (amount - 1)
	
	# Dictionary with all valid position information
	# When instantiating multimesh instances it needs to be known how many
	# instance will be generated.
	# So at first for each instance the position is generated and checked if it
	# is valid (No exclude area, height can be calculated etc). If it is valid
	# it is put into this dictionary. In a second loop all valid instances will
	# be generated. The amount of valid instances is known by then.
	var valid_data : Array[Dictionary]  = []
	
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

	# Loop for each multimesh instance to be generated.
	for index in range(amount):
		_debug("Setting position index %s" %index)
		basis = Basis()
		
		# calculate the distance (position) on the polygon.
		# Fixed step or random position.
		var distance 
		if randomize_steps:
			distance = generate_random(0, length) # randomized position on curve
		else:
			distance = step * index # fix step position on curve
		position = curve.sample_baked(distance)
		
		#align rotation to polygon curve
		align_rotation_to_curve(distance)
		
		# Assign polygon thickness
		if thickness > 0:
			assign_thickness()
		
		# Check if it is found in an exclude area.
		var found_in_exclude : bool = false
		
		for exclude_to_check:MultiScatterExclude in my_exclude_array:
			if found_in_exclude == false:
				var global_pos = Vector2(position.x, position.z) + Vector2(ms_position.x, ms_position.z)
				found_in_exclude = exclude_to_check.is_point_in_polygon(global_pos)
		_debug("Found in exclude: %s" %found_in_exclude)

		var itemPos = placement.ms_item_position
		position = Vector3(position.x - itemPos.x, position.y- itemPos.y, position.z -itemPos.z)
		if not found_in_exclude:

			# Check if a valid height can be calculated.
			var calculated_height = generate_height()

			if(calculated_height):
				_debug("Found valid position. Setting scale and rotation.")
					
				# Generate scale depending on the Placement mode settings.
				generate_scale()
				
				# Generate rotation depending on the Placement mode settings.
				generate_rotation()
				
				var data = {
					"position" :  position,
					"basis" : basis
				}
				valid_data.append(data)
			else:
				_debug("No valid position. Ommiting position.")
	
	# Completed looping through all Multimesh instance to find valid position.
	# Looping through valid position to do the actual transform.
	multimesh_item.instance_count = valid_data.size()
	for i in range(valid_data.size()):
		var dict_entry = valid_data[i]
		var pos = dict_entry["position"]
		var bas = dict_entry["basis"]
		do_transform(i, pos, bas)
	
