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
extends MultiMeshInstance3D
class_name MultiScatterItem

# The MultiScatterItem is a MultiMesh3D.
# 
# Additionally it holds some parameters how the mesh instances shall be placed.
# Placing the mesh instances then is done by the child placement mode.

# Percentage how many mesh instances of this MultiScatterItem shall be placed. 
# This is useful if a MultiScatter has more than one MultiScatterItem. 
@export_range(0, 100) var percentage : float = 100 :
	set(value):
		percentage = value

@export_group("Additional Scene")
@export var enableAdditionalScene : bool = false
@export var targetNode: Node3D
@export var additionalScene: PackedScene


# ready: Add notification on transform changes to overwrite rotation to 0
# Because the MultiScatterItem is not supposed to be rotated.
func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	if Engine.is_editor_hint():
		set_notify_transform(true) 

# set - overwrite rotation to 0 when changed in editor inspector.
func _set(property: StringName, value) -> bool:
	if property == "rotation":
		var new_value = value as Vector3
		new_value.x = 0
		new_value.z = 0
		new_value.y = 0
		return true  # Gibt an, dass die Eigenschaft gesetzt wurde
	return false  # Standardverhalten für andere Properties beibehalten

# notification - overwrite rotation to 0 when changed by gizmo in editor.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		rotation.x = 0
		rotation.y = 0
		rotation.z = 0

# Multiscatter position. Required to keep track of the position of each item in
# the MultiScatter setup.
var ms_position : Vector3

# Multiscatter rotation. Required to keep track of the position of each item in
# the MultiScatter setup.
var ms_rotation : float

# Debug messages on/off
var debug_messages : bool = false : set = set_debug
func set_debug(debug : bool):
	debug_messages = debug

# Setting the total amount of items to be generated. This is the 100% amount.
var amount : int : set = set_amount
func set_amount(number):
	amount = number

# Setting the random number generator
var random : RandomNumberGenerator : set = set_random
func set_random(rnd):
	random = rnd

# Sets the curve of the MultiScatter
var curve : Curve3D : set = set_curve
func set_curve(crv : Curve3D):
	curve = crv
	
# Exclude list.
var excludes_list : Array[MultiScatterExclude]

#  Average height of the polygon curve
var _avg_height : float = 0.0

# Number of points in the polygon.
var _nrOfPoints : int

# Min Max position of the points of the MultiScatter polygon.
var polygon_min : Vector3
var polygon_max : Vector3

# Array with the points of the polygon.
var _polygon = []

# Write a debug message.
func _debug(message):
	if debug_messages:
		print("YAMMS: MultiScatterItem:  " + message)

# Preparation of the MultiMesh generating process.
# Done once before each time generating.
# Set to 0 to remove all previously generated instance.
# The actual instance_count will be set by the MultiScatterTransform
func _prepare_multimesh():
	clear()
	
# Delete all previously generated multi mesh instances.
func clear():
	multimesh.instance_count = 0
	
# Generate the MultiMesh instances.
func generate(
			global_position : Vector3,
			space
):
	# Calculate the actual amount of MultiMesh instances depending on the 
	# percentage of the amount.
	var actual_amount :int = amount * (percentage /100)
	_debug("Generating %s percent of %s items: %s items" %[percentage, amount, actual_amount])
	
	# Get the placement mode.
	var placement = _get_placement()
	if placement != null:

		_debug("PlacementMode found.")
		_prepare_multimesh()

		# Pass all required data to the placement mode.
		placement.debug_messages = debug_messages
		placement.amount = actual_amount
		placement.random = random
		placement.multimesh_item = multimesh
		placement.curve = curve
		placement._avg_height = _avg_height
		placement._nrOfPoints = _nrOfPoints
		placement.polygon_min = polygon_min
		placement.polygon_max = polygon_max
		placement._polygon = _polygon
		
		if enableAdditionalScene == true:
			placement.enableAdditionalScene = true
			placement.targetNode = targetNode
			placement.additionalScene = additionalScene
		else:
			placement.enableAdditionalScene = false
		
		placement.ms_position = ms_position
		placement.ms_item_position = position
		placement.ms_rotation = ms_rotation
		placement.ms_item_rotation = rotation_degrees.y
		
		placement.space = space
		placement.exclude_list = excludes_list
		
		# All set up. Now generate.
		placement.generate()

	else:
		_debug("No PlacementMode set")


# Gets the first child of type "PlacementMode".
# All other PlacementMode instances are ignored.
func _get_placement() -> PlacementMode:
	for child in get_children():
		if child is PlacementMode:
			return child
	return null
			

# Show warning in editor in case set up is not complete.
func _get_configuration_warnings() -> PackedStringArray:
	if not self.multimesh or not self.multimesh.mesh:
		return ["No MultiMesh is set up."]
	else:
		if (enableAdditionalScene):
			if (targetNode == null and additionalScene != null):
				return ["Additional scene is set up, but no target node."]	
			if (targetNode != null and additionalScene == null):
				return ["Target node is set up, but no additional scene."]	
		if (_get_placement() == null):
			return ["No placement mode as child node."]
		return []


# Clear target node in case "Additional Scene" is enabled and target
# node is set up.
func clear_target_node():
	if enableAdditionalScene == true && targetNode != null:
		_debug("Clear targetNode")
		for child in targetNode.get_children():
			targetNode.remove_child(child)
			child.queue_free()
