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

# MultiScatter is the main node of this plugin. It provides a Path3D (Polygon)
# to set up the area where the MultiMeshes shall spawn.
@tool
extends Path3D

class_name  MultiScatter

@export_group("MultiScatter Settings")

# The amount of multimeshes 
@export var amount : int = 100

# Seed for the RandomNumberGenerator. Setting up the seed makes the generated
# positions of each mesh deterministical.
@export var seed : int = 0

# helper to calculate the proportion percentage.
var _sum_proportion = 0

# Properties used for rayCast to calculate the height of the mesh Instance if it
# shall be dropped on floor.

# Physics Space to perform the raycast
var _space: PhysicsDirectSpaceState3D = null



# Data about the polygon curve.

#  Average height of the polygon curve
var _avg_height : float = 0.0

# Number of points in the polygon.
var _nrOfPoints : int

var polygon_min : Vector3 = Vector3(0, 0, 0)
var polygon_max : Vector3 = Vector3(0, 0, 0)

# Array with the points of the polygon.
var _polygon = []


@export_group("")
@export var debugMessages : bool
var shall_generate = false

func _ready():
	self.curve_changed.connect(_on_curve_changed)
	
func get_space_state() -> PhysicsDirectSpaceState3D:
	if _space == null:
		_space = get_world_3d().direct_space_state
	return _space
	
	
# Helper function for debugging.	
func _debug(message):
	if debugMessages:
		print("YAMMS: MultiScatter:  %s"  %message)

func _physics_process(delta):
	if shall_generate:
		do_generate()
		shall_generate = false

func generate():
	shall_generate = true
	

# Generate the MultiScatter
func do_generate():
	_debug("Starting to generate.")
	_debug("Amount: %s" %amount)
	_debug("Seed: %s" %seed)
	
	_calc_plane_min_max()
	
	# init RandomNumberGenerator for placing the MultiMeshes randomly.
	var random = RandomNumberGenerator.new()
	random.state = 0	
	random.set_seed(seed)

	# Loop through all children of type MultiScatterItem to clear
	# target nodes if they are configured.
	for child in self.get_children():
		if child is MultiScatterItem:
			child.debug_messages = debugMessages
			child.clear_target_node()

			
	# Loop through all children of type MultiScatterItem to generate
	# the multimesh instance.
	for child in self.get_children():
		if child is MultiScatterItem:
			_debug("Found MultiScatterItem.")

			child.amount = amount
			child.random = random
			child.curve = curve
			child.excludes_list = get_excludes()
			
			#  Average height of the polygon curve
			child._avg_height = _avg_height

			# Number of points in the polygon.
			child._nrOfPoints = _nrOfPoints

			child.polygon_min = polygon_min
			child.polygon_max = polygon_max

			# Array with the points of the polygon.
			child._polygon = _polygon
			
			child.ms_position = global_position


			child.generate(
				global_position,
				get_space_state()
			)
		else:
			_debug("is Not MultiScatterItem: " + child.get_class())

func get_excludes() -> Array[MultiScatterExclude]:
	var excludes : Array[MultiScatterExclude] = []
	for child in get_children():
		if child is MultiScatterExclude:
			excludes.append(child)
			
	_debug("Exclude array contains  %s elements." %excludes.size())
	return excludes
	
	
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
#
# Configuration check: Do I have at least one MultiScatterItem as child?
func _check_scatter_items():
	return (_count_scatter_items() > 0)


# Curve changed. Trigger a check of the configuration warning, so that the
# exclamation mark is shown in case there are not enough points in polygon.
func _on_curve_changed():
	if is_inside_tree():
		get_tree().emit_signal("node_configuration_warning_changed", self)

# Get config warnings if something is missing
# or empty warning array if erverything is OK.
func _get_configuration_warnings() -> PackedStringArray:
	var return_value = []
	
	if not _check_scatter_items():
		return_value.append("At least one MultiScatterItem is required.")
		
	return return_value


# Calculates the plane borders depending on the polygon.
# The plane is defined by the min/max x and z coordinates
# the plane height is the average y  value of all points of the polygon.
func _calc_plane_min_max() :
	_nrOfPoints = curve.get_point_count()
	
	# set the initinal min max values.
	if _nrOfPoints > 0:
		polygon_min = Vector3(curve.get_point_position(0))
		polygon_max = Vector3(curve.get_point_position(0))
	
	_polygon = []
	for i in _nrOfPoints:
		var point : Vector3 = curve.get_point_position(i)
		_avg_height += point.y
		_polygon.append(Vector2(point.x, point.z))
		if point.x < polygon_min.x:
			polygon_min.x = point.x
		if point.x > polygon_max.x:
			polygon_max.x = point.x
		if point.z < polygon_min.z:
			polygon_min.z = point.z
		if point.z > polygon_max.z:
			polygon_max.z = point.z
		
		if point.y < polygon_min.y:
			polygon_min.y = point.y
		if point.y > polygon_max.y:
			polygon_max.y = point.y
		
		
	_avg_height = _avg_height / _nrOfPoints
