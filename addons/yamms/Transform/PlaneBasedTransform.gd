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

# PlaneBasedTransform - interface Class for all transform activities which spawns the
# multimesh instances in space on different algorithms depending on a plane defined
# by a polygon.
# The specific algorithm extends this class and implements the algorithm.
@tool
extends MultiScatterTransform
class_name PlaneBasedTransform

# current index of the spawned object.
var current_index

# List of Exclude areas which are assigned to this transform.
var exclude_list : Array[MultiScatterExclude]

# The actual exclude area which is applied to this transform.
# If "exclude_list" is empty (not assigned) all exclude areas underneath the
# MultiScatter item are passed to the "specific_exclude_list".
# If "exclude_list" is set (not empty), then only the exclude ares in exclude_list
# are applied and set to "specific_exclude_list".
var specific_exclude_list : Array[MultiScatterExclude]

# Output of debug message.
func _debug(message):
	if debug_messages:
		print("YAMMS: PlaneBasedTransform:  " + message)


# Generate height. Nothing to do. It is already a plane.
func generate_height() -> bool:
	return false

# consistency check. The polygon requires at least  3 points to set up
# an area in which the MultiMeshInstances shall be spawned.
func _check_polygon_nr() -> bool:
	return (polygon.size() > 2)

# Generates all position of the multimesh instances.
# 1) A position inside the priviously generated plane (min- max- coordinates of
#    the multiscatter polygon) is randomly generated.
#    This is a first good guess that it might be inside the polygon.
# 2) It is checked wether 
#      - the generated position is inside the polygon
#      - and the generated position is NOT inside an exclude area
#    If so: this is the position to spawn the instance.
#    Otherwise: The position is ommited and a new position is going to be
#    calculted. Hopefully it is inside the polygon now.
# 3) On a high failure rate (missed to generate a valid position 100 times) the
#    whole process is aborted: No valid area is available to spawn the objects.
func generate_plane_positions():
	_debug("Generating plane position for %s elements." %amount)
	_debug("Excludelist: %s" %exclude_list.size())
	_debug("Specific exclude list: %s" %specific_exclude_list.size())
	
	# Choose the exclude areas:
	# If specific exclude areas are configured for this MultiScatterITem:
	# use ist.
	# Otherwise use all default exclude areas.
	var my_exclude_array : Array[MultiScatterExclude]
	
	if specific_exclude_list.size() > 0:
		my_exclude_array = specific_exclude_list
	else:
		my_exclude_array = exclude_list 
	
	# Loop for each element to be spawned.
	for index in amount:
		current_index = index
		var is_point_in_polygon = false
				
		var attempts : int = 0 # Nr of attempts to place mesh inside of the polygon
		var pos : Vector2 
		
		_debug("Polygon: %s" %polygon.size())
			
		while not is_point_in_polygon:
			attempts += 1
			
			# Abort if 100 failures occured.
			if attempts == 100:
				var message = "Cannot drop MultiMesh. Please check: " \
					+ "1) Is the polygon area large enough? " \
					+ "2) Is the whole polygon area hidden by an exclude area? " \
					+ "3) Drop on Floor: is there a large object with collision object underneath?" \
					+ "4) Drop on Ceiling: is there a large object with collision object above?"
					
				_debug(message)
				push_warning(message)
				return
				
			# Generate random 2D coordinates in the range of min max
			var x = generate_random(polygon_min.x, polygon_max.x)
			var z = generate_random(polygon_min.z, polygon_max.z)
			

			pos = Vector2(x ,z) 
			
			# Check if the position is inside the polygon of the multiscatter.
			is_point_in_polygon = Geometry2D.is_point_in_polygon(pos, polygon)
			if is_point_in_polygon:
				_debug("Point is in MultiScatter Polygon. Checking for excludes.")
				
				# Check if the position is NOT inside an exclude Polygon
				var rotation_offset = -placement.ms_rotation

				var rotated_pos = pos.rotated(deg_to_rad(rotation_offset))
	
				
				var global_pos = pos + Vector2(ms_position.x, ms_position.z)
				for exclude_to_check:MultiScatterExclude in my_exclude_array:
					if is_point_in_polygon:
						var is_in_exclude = exclude_to_check.is_point_in_polygon(global_pos)
						_debug("Point is in exclude area: %s on attempt %s." %[is_in_exclude, attempts])
						is_point_in_polygon = not is_in_exclude
				
				# check if item is going to be placed according to density map.
				if is_point_in_polygon:
					
					is_point_in_polygon = placement.should_spawn_at(rotated_pos.x , rotated_pos.y )
					_debug("Density Map: %s : %s -> %s" %[global_pos.x, global_pos.y, is_point_in_polygon])
					

			else:
				_debug("Point is not in MultiScatter Polygon on attempt %s. Check for excludes skipped." %attempts)
			
			if is_point_in_polygon:
				_debug("Position: x=%s, y=%s is in polygon: %s" %[pos.x, pos.y, is_point_in_polygon])
		
				# Set up the the 3 required transform parameters:
				var itemPos = placement.ms_item_position
				var rotation_offset = placement.ms_item_rotation
				var rotated_pos = pos.rotated(deg_to_rad(rotation_offset))
				position = Vector3(rotated_pos.x - itemPos.x, _avg_height, rotated_pos.y -itemPos.z)
		
				is_point_in_polygon = generate_height()
				
				if is_point_in_polygon:
					basis = Basis()
					generate_scale()
		
					generate_rotation()

					do_transform(
						index, position, basis
					)

# generate transform data of the spawned object.
func generate_transform():
	if _check_polygon_nr():
		_debug("Generating Plane")
		multimesh_item.instance_count = amount
		generate_plane_positions()
		
	else:
		_debug("Not generating plane. Minimum of 3 points in polygon required.")
		
