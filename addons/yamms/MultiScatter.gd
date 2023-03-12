# MIT License
# 
# Copyright (c) 2023 Mattiny
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
@tool
extends Path3D

# MultiScatter is the main node of this plugin. It provides a Path3D (Polygon)
# to set up the area where the MultiMeshes shall spawn.
class_name  MultiScatter


# The amount of multimeshes 
@export var amount : int = 100

# Seed for the RandomNumberGenerator. Setting up the seed makes the generated
# positions of each mesh deterministical.
@export var seed : int = 0

# PlacemoenModes:
# - Flat - generates all Meshes on a flat plane area inside the polygon
# - Floating - generates all Meshes floating in space inside the polygon with a 
#              range of the height.
# - Drop on floor - generates all meshes on a ground. Precondition: there is
#                   a large object with collision shape underneath it so that it
#                   can hold the meshes.
enum PlacementMode {FLAT, DROP_ON_FLOOR, FLOATING}
@export var placement_mode : PlacementMode = PlacementMode.DROP_ON_FLOOR

# the min-max value how high / deep the meshes are floating (if floating)
@export var floating_min_max_y : float = 50.0

# helper to calculate the proportion percentage.
var _sum_proportion = 0

# The random number generator to generate the mesh's position
var _random : RandomNumberGenerator

# Properties used for rayCast to calculate the height of the mesh Instance if it
# shall be dropped on floor.

# Physics Space to perform the raycast
@onready var _space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state

# collision mask to select the layer of the ray cast.
@export_flags_3d_physics var collision_mask := 0x1:
	get: return collision_mask
	set(value):
		collision_mask = value

func _ready():
	self.curve_changed.connect(_on_curve_changed)
	_random = RandomNumberGenerator.new()
	do_generate()

func do_generate():
	# To spawn Multimesh objects:
	# - Generate random x-z coordinates within range (min max) of the set up
	#   polygon coordinates
	# - Check if the coordinates are inside the polygon (x-z) (y (height) is
	#   ignored)
	# - Check if the coordinates are NOT inside an Exclude-Item.
	# - Calculate the initial y coordinate (height) from the average of all polygon's
	#   height (y)
	# - if floating: generate radom height
	# - if dropped on floor: raycast down and calculate the height of the surface
	#   where the raycast hit something. 


	# Only generate if the polygon check is ok.
	# Note: if statement does the same as _check_polygon. But we need the nr

	_random.state = 0   # reset random number generator
	_random.seed = seed # set seed for random number generator
	
	var nr_points = curve.get_point_count ()
	if _check_polygon_nr(nr_points):

		# Get the coordinates from the first point as reference for the min max
		# values.
		var point = curve.get_point_position(0)
		var min_x = point.x
		var max_x = point.x
		var min_y = point.z
		var max_y = point.z
		
		var avg_height = 0.0
		
		# Save all point coordinates in a 2D Polygon for the "inside polygon check"
		var polygon = []
		
		# Get the min max value of the x-z coordinates in 3D space.
		# and append to 2D polygon
		# and add height to average height.
		for i in nr_points:
			point = curve.get_point_position(i)
			avg_height += point.y
			polygon.append(Vector2(point.x, point.z))
			if point.x < min_x:
				min_x = point.x
			if point.x > max_x:
				max_x = point.x
			if point.z < min_y:
				min_y = point.z
			if point.z > max_y:
				max_y = point.z

		# get the average of the height
		avg_height = avg_height / nr_points
		
		# Get the Scatter Item Data to determine which items shall be spawned in the area
		var data = _get_scatter_items_data()
		for entry in data:
			# Calculate the amount of mesh items depending on the amount and proportion
			var percentage = (100 * entry["Proportion"]) / _sum_proportion
			var amount_for_proportion : int = float(amount) / 100 * percentage

			# set the spawn data to the MultiMeshItem to prepare generation
			# of meshes.
			var scatter_item = entry["ScatterItem"] as MultiScatterItem

			scatter_item.set_amount(amount_for_proportion)
			
			# Now generate new coordinates for each mesh in the MultiMeshInstance.
			for index in range(amount_for_proportion):
			
				# Do as long until the random 2D coordinates are inside the polygon.
				var is_point_in_polygon = false
				
				var attempts : int = 0 # Nr of attempts to place mesh inside of the polygon
				while not is_point_in_polygon:
					attempts += 1
					if attempts == 100:
						push_warning("Cannot drop MultiMesh. Please check: " \
							+ "1) Is the polygon area large enough? " \
							+ "2) Is the whole polygon area hidden by an exclude area? " \
							+ "3) Drop on Floor: is there a large object with collision object underneath?")
						return
				
					# Generate random 2D coordinates in the range of min max
					var x = _random.randf_range(min_x, max_x)
					var y = _random.randf_range(min_y, max_y)
					
					# Generate random rotation
					var _rotation = Vector3()
					if entry["RandomRotation"]:
						var max_rotation = entry["MaxRotation"]
						_rotation.x = _random.randf_range(0, max_rotation.x)
						_rotation.y = _random.randf_range(0, max_rotation.y)
						_rotation.z = _random.randf_range(0, max_rotation.z)
						
					var _scale = Vector3(1.0, 1.0, 1.0)
					if entry["RandomScale"]:
						var max_scale = entry["MaxScale"]
						_scale.x = _random.randf_range(1.0, max_scale.x)
						_scale.y = _random.randf_range(1.0, max_scale.y)
						_scale.z = _random.randf_range(1.0, max_scale.z)
						
					# Check if the coordinates are inside the polygon.
					var pos : Vector2 = Vector2(x ,y)
			
					is_point_in_polygon = Geometry2D.is_point_in_polygon(pos, polygon)
					if is_point_in_polygon:
						
						# it is inside the polygon. But also check if it is inside an
						# exclude area. If it is in the exclude area, it is NOT
						# considered to be inside the polygon.
						var excludes = _get_exclude_data()
						var excluded = false

						for ex in excludes:
							if is_point_in_polygon: # only check if point still is regarded as in polygon
								var multiScatterExclude : MultiScatterExclude = ex
								var global_pos = pos + Vector2(global_position.x, global_position.z)
								is_point_in_polygon = not multiScatterExclude.is_point_in_polygon(global_pos)

		
						if is_point_in_polygon:
							var pos_3D = Vector3(pos.x, 0, pos.y)
							if placement_mode == PlacementMode.FLAT:
								# Distribute ScatterItems flat - on average level
								pos_3D.y = avg_height
								var transform = _create_transform(pos_3D, _rotation, _scale)
								scatter_item.do_transform(index, transform)
							
							if placement_mode == PlacementMode.FLOATING:
								# Distribute ScatterItems floating - height is 
								# just a random number
								pos_3D.y = _random.randf_range(-floating_min_max_y, floating_min_max_y)
								var transform = _create_transform(pos_3D, _rotation, _scale)
								scatter_item.do_transform(index, transform)
							
							if placement_mode == PlacementMode.DROP_ON_FLOOR:
								# Distribute ScatterItems dropped on ground.
								# Do a raycast down
								pos_3D.y = avg_height
								
								var ray := PhysicsRayQueryParameters3D.create(
									pos_3D + global_position,
									pos_3D + global_position + Vector3.DOWN * 10000,
									collision_mask)
								var hit := _space.intersect_ray(ray)
								if hit.is_empty():
									# Raycast did not hit anything.
									# So treat it like it was not inside the polygon.
									is_point_in_polygon = false
								else:
									var hit_pos = hit["position"]
									var multimesh_scatter_pos = get_global_position()
									hit_pos = hit_pos - multimesh_scatter_pos
									var transform = _create_transform(hit_pos, _rotation, _scale)
									scatter_item.do_transform(index, transform)
			
	else:
		print("You need to set up a polygon with at least 3 points.")


# Create the transform of the Mesh
# - apply rotation, scale and position		
func _create_transform(pos : Vector3, rotation : Vector3, scale : Vector3):
	var transform = Transform3D(Basis(), Vector3())\
		.rotated(Vector3.RIGHT, rotation.x)\
		.rotated(Vector3.FORWARD, rotation.y)\
		.rotated(Vector3.UP, rotation.z)\
		.scaled(scale)\
		.translated(pos)
	return transform
	
# Gets all data from the child ScatterItems.
# Returns an array with Dictionary entries:
#  - Proportion
#  - RandomRotation
#  - RandomScale
#  - MaxRotation
#  - MaxScale
#  - TargetScene
#  - ScatterItem
#
# Also: Sums up proportion which is being used for the calculation of the 
# percentage of each proportion.
func _get_scatter_items_data():
	_sum_proportion = 0
	var result = []
	for child in get_children():
		if child is MultiScatterItem:
			var scatter_item = child as MultiScatterItem
			var entry = {}
			entry["Proportion"] = scatter_item.proportion
			entry["RandomRotation"] = scatter_item.randomize_rotation
			entry["RandomScale"] = scatter_item.randomize_scale
			entry["MaxRotation"] = scatter_item.max_degrees
			entry["MaxScale"] = scatter_item.max_scale
			entry["ScatterItem"] = scatter_item
			result.append(entry)
			_sum_proportion += scatter_item.proportion
	return result
	
	
func _get_exclude_data():
	var result = []
	for child in get_children():
		if child is MultiScatterExclude:
			var exclude = child as MultiScatterExclude
			result.append(exclude)
	return result
	
# Count number of scatter items
func _count_scatter_items():
	var found : int = 0
	for child in get_children():
		if child is MultiScatterItem:
			found += 1
	
	return found

# Configuration check: Do I have at least one MultiScatterItem as child?
func _check_scatter_items():
	return (_count_scatter_items() > 0)

# Configuration check: Do I have enough polygon points?
func _check_polygon() -> bool:
	var nr_points = curve.get_point_count ()
	return _check_polygon_nr(nr_points)

# Configuration check: Do I have enough polygon points?
# - at least 3 points expected to span a plane	
func _check_polygon_nr(nr_points) -> bool:
	return (nr_points > 2)

# Curve changed. Trigger a check of the configuration warning, so that the
# exclamation mark is shown in case there are not enough points in polygon.
func _on_curve_changed():
	if is_inside_tree():
		get_tree().emit_signal("node_configuration_warning_changed", self)

# Get config warnings if something is missing
# or empty warning array if erverything is OK.
func _get_configuration_warnings() -> PackedStringArray:
	var return_value = []
	if not _check_polygon():
		return_value.append("Not enough points in polygons to span a plane. At least 3 poits expected.")		
	
	if not _check_scatter_items():
		return_value.append("At least one MultiScatterItem is required.")
		
	return return_value		

