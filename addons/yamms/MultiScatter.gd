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

@export_group("MultiScatter Settings")

# The amount of multimeshes 
@export var amount : int = 100

# Seed for the RandomNumberGenerator. Setting up the seed makes the generated
# positions of each mesh deterministical.
@export var seed : int = 0

# the min-max value how high / deep the meshes are floating (if floating)
###@export var floating_min_max_y : float = 50.0

# helper to calculate the proportion percentage.
var _sum_proportion = 0

# Properties used for rayCast to calculate the height of the mesh Instance if it
# shall be dropped on floor.

# Physics Space to perform the raycast
@onready var _space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state



@export_group("")
@export var debugMessages : bool


func _ready():
	self.curve_changed.connect(_on_curve_changed)

# Helper function for debugging.	
func _debug(message):
	if debugMessages:
		print("YAMMS: MultiScatter:  %s"  %message)


# Generate the MultiScatter
func do_generate():
	_debug("Starting to generate.")
	_debug("Amount: %s" %amount)
	_debug("Seed: %s" %seed)

	_debug("Children: %s" % get_child_count())
	
	# init RandomNumberGenerator for placing the MultiMeshes randomly.
	var random = RandomNumberGenerator.new()
	random.state = 0	
	random.set_seed(seed)

	for child in self.get_children():
		if child is MultiScatterItem:
			_debug("is MultiScatterItem: " + child.get_class())
			child.debug_messages = debugMessages
			child.amount = amount
			child.random = random
			child.curve = curve
			child.excludes_list = get_excludes()

			child.generate(
				global_position,
				_space
			)
		else:
			_debug("is Not MultiScatterItem: " + child.get_class())
	
	# check if Placement mode is set

func get_excludes() -> Array[MultiScatterExclude]:
	var excludes : Array[MultiScatterExclude] = []
	for child in get_children():
		if child is MultiScatterExclude:
			excludes.append(child)
			
	_debug("---Exclude: %s" %excludes.size())
	return excludes
	
	# Iterate through each MultiScatterItem entry and generate
	# the positions for the MultiMesh instances.
#	for entry in entries:
		
		# Instantiate the required PlacementMode.
#		var pm : PlacementMode
#		var placement_mode = entry["PlacementMode"]
#	#	if placement_mode == PlacementMode.Mode.FLAT:
#			pm = PMFlat.new(self)
#			_debug("PlacementMode: FLAT")	
#		elif placement_mode == PlacementMode.Mode.FLOATING:
#			pm = PMFloating.new(self)
#			_debug("PlacementMode: FLOATING")	
#		elif placement_mode == PlacementMode.Mode.DROP_ON_FLOOR:
#			pm = PMDropOnFloor.new(self)
#			_debug("PlacementMode: DROP_ON_FLOOR")
#		elif placement_mode == PlacementMode.Mode.DROP_ON_CEILING:
#			pm = PMDropOnCeiling.new(self)
#			_debug("PlacementMode: DROP_ON_Ceiling")
#		elif placement_mode == PlacementMode.Mode.POLYGON:
#			pm = PMPolygon.new(self)
#			_debug("PlacementMode: POLYGON")		
#		_debug("Calling PlacementMode.init_placement")
		
		# Initialize PladementMode with data.
#		pm.init_placement(
#			curve,
#			collisionMask,
#			debugMessages,
#			random
#		)
	
		# ..and generated
#		_debug("Calling PlacementMode.do_generate")
#		pm.do_generate(
#			entry,
#			amount,
#			_sum_proportion,
#			_get_exclude_data(),
#			global_position, 
#			_space
#		)


# Create the transform of the Mesh
# - apply rotation, scale and position		
#func _create_transform(pos : Vector3, rotation : Vector3, scale : Vector3):
#	var transform = Transform3D(Basis(), Vector3())\
#		.rotated(Vector3.RIGHT, rotation.x)\
#		.rotated(Vector3.FORWARD, rotation.y)\
#		.rotated(Vector3.UP, rotation.z)\
#		.scaled(scale)\
#		.translated(pos)
#	return transform

	
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
##	
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
