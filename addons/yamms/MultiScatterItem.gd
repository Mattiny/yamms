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
# Placing the mesh instances then is done by MultiScatter.



# Proportion how many mesh instances shall be placed. This is useful if a
# MultiScatter has more than one MultiScatterItem. 
#
# From the proportion of this MultiScatterItem and the proportion of other 
# MultiScatterItem the percentage of each MultiScatterItem will be calculated. 
# Then the percentage of the MultiScatter amount results in the actual amount 
# for this MultiScatterItem
@export_range(0, 100) var percentage : float = 100 :
	set(value):
		percentage = value

@export_group("Additional Scene")
@export var enableAdditionalScene : bool = false
@export var targetNode: Node3D
@export var additionalScene: PackedScene

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
	
var excludes_list : Array[MultiScatterExclude]

func _ready():
	pass
	
func _debug(message):
	if debug_messages:
		print("YAMMS: MultiScatterItem:  " + message)

func _prepare_multimesh():
	multimesh.instance_count = amount
	
func generate(
			global_position : Vector3,
			space
):
	var actual_amount :int = amount * (percentage /100)
	_debug("Generating %s percent of %s items: %s items" %[percentage, amount, actual_amount])
	
	var placement = _get_placement()
	if placement != null:

		_debug("PlacementMode found.")
		_prepare_multimesh()

		placement.debug_messages = debug_messages
		placement.amount = actual_amount
		placement.random = random
		placement.curve = curve
		placement.multimesh_item = multimesh
		
		_debug("Setting global_position: %s" %global_position)
		placement.ms_global_position = global_position
		placement.space = space
		placement.exclude_list = excludes_list
		placement.generate()
	else:
		_debug("No PlacementMode set")



func _get_placement() -> PlacementMode:
	for child in get_children():
		if child is PlacementMode:
			return child
	return null
			
	

# sets the transform of one instance of the multimesh
# - index - The index of the mesh
# - transform - The transform containing position, rotation and scale.
#func do_transform(index : int, transform : Transform3D):

#	self.multimesh.set_instance_transform(index, transform)
	#self.multimesh.set_instance_transform(index, Transform3D(Basis(), pos))
	
func _get_configuration_warnings() -> PackedStringArray:
	if not self.multimesh or not self.multimesh.mesh:
		return ["No MultiMesh is set up."]
	else:
		if (targetNode == null and additionalScene != null):
			return ["Additional scene is set up, but no target node."]	
		if (targetNode != null and additionalScene == null):
			return ["Target node is set up, but no additional scene."]	
		if (_get_placement() == null):
			return ["No placement mode as child node."]
		return []
