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

# MultiScatterTransform - interface Class for all transform activities which spawns the
# multimesh instances in space on different algorithms.
# The specific algorithm extends this class and implements the algorithm.
@tool
extends Node
class_name MultiScatterTransform

# Global space - the actual position of the Multiscatter object.
# Node: the position of the spawned multimesh instance is relative to the
# global_position of the multiscatter. Therefore the global_position is required
# to be bassed to the MultiScatterTransform algorithm.
var ms_position : Vector3
var ms_item_position : Vector3
var ms_pm_position : Vector3

var debug_messages : bool = false : set = _set_debug
func _set_debug(debug) :
	debug_messages = debug
	
func _debug(message):
	if debug_messages:
		print("YAMMS: MultiScatterTransform:  " + message)

# Random rotation variables
var random_rotation : bool = false : set = set_random_rotation
func set_random_rotation(value : bool):
	random_rotation = value
	
var max_rotation : Vector3 = Vector3(0, 0, 0) : set = set_max_rotation
func set_max_rotation(value : Vector3):
	max_rotation = Vector3(
		deg_to_rad(value.x),
		deg_to_rad(value.y),
		deg_to_rad(value.z)
	)
	
var min_rotation : Vector3 = Vector3(0, 0, 0) : set = set_min_rotation
func set_min_rotation(value : Vector3):
	min_rotation = Vector3(
		deg_to_rad(value.x),
		deg_to_rad(value.y),
		deg_to_rad(value.z)
	)
	
# Random proportional scale variables
var random_prop_scale : bool = false : set = set_random_prop_scale
func set_random_prop_scale(value : bool):
	random_prop_scale = value
	
var max_prop_scale : float : set = set_max_prop_scale
func set_max_prop_scale(value : float):
	max_prop_scale = value
	
var min_prop_scale : float : set = set_min_prop_scale
func set_min_prop_scale(value : float):
	min_prop_scale = value
	
var scale_curve : Curve : set = set_scale_curve
func set_scale_curve(value: Curve):
	scale_curve = value
	
var curve : Curve3D
	
# Transformation basis.
var basis : Basis

# Random unproportional scale variables
var random_unprop_scale : bool = false : set = set_random_unprop_scale
func set_random_unprop_scale(value : bool):
	random_unprop_scale = value

var max_unprop_scale : Vector3 : set = set_max_unprop_scale
func set_max_unprop_scale(value : Vector3):
	max_unprop_scale = value
	
var min_unprop_scale : Vector3 : set = set_min_unprop_scale
func set_min_unprop_scale(value : Vector3):
	min_unprop_scale = value


# Actual position / scale / rotation
var position : Vector3
	

# amount of items to be generated
var amount : int : set = _set_amount 
func _set_amount(am):
	amount = am
	
# the MultiMeshItem to spawn all instances
var multimesh_item : MultiMesh : set = _set_multimesh_item
func _set_multimesh_item(value):
	multimesh_item = value

# Random NR generator
var random : RandomNumberGenerator : set = _set_random 
func _set_random(randomInstance):
	random = randomInstance	
	
func generate_random(min, max): 
	return random.randf_range(min, max)
	
	
# Additional scene Data.

var enableAdditionalScene = false

#  TargetNode where the additional scene is going to be placed.
var targetNode: Node3D

#  The scene which is going to be placed as additional scene to the same
#  position where the multimesh item is going to be placed.
var additionalScene: PackedScene

#  Average height of the polygon curve
var _avg_height : float = 0.0

# Number of points in the polygon.
var _nrOfPoints : int

var polygon_min : Vector3
var polygon_max : Vector3

# Array with the points of the polygon.
var polygon = []

var placement : PlacementMode

# Generate random rotation in the bounds of min/max rotation	
func generate_rotation():
	var rotation : Vector3
	if random_rotation:
		rotation = Vector3(
			generate_random(min_rotation.x, max_rotation.x),
			generate_random(min_rotation.y, max_rotation.y),
			generate_random(min_rotation.z, max_rotation.z)
		)
		
		var rotation_quaternion = Quaternion().from_euler(rotation)
		basis *= Basis(rotation_quaternion)
	
		
# Do the transform. After calculating position, scale and rotation
# assign the calculated transform to the specific multimesh instance.
func do_transform(index : int, pos : Vector3, basis : Basis):
	var transform : Transform3D = create_transform_by_basis(
						basis,
						pos
					)
	multimesh_item.set_instance_transform(index, transform)
	
	

	if enableAdditionalScene == true:
		var additional_transform : Transform3D = create_transform_by_basis(
			basis,
			pos + placement.ms_position + placement.ms_item_position,
		)
		_place_additional_scene(additionalScene, targetNode, additional_transform)
	
# Generate random scale in the bounds of min/max scale
func generate_scale():
	var scale
	if random_prop_scale:
		if scale_curve == null:
			var scale_nr :float = generate_random(min_prop_scale, max_prop_scale)
			scale = Vector3(scale_nr, scale_nr, scale_nr)
		else:
			var curve_samle : float = scale_curve.sample(generate_random(min_prop_scale, max_prop_scale))
			var scale_nr :float = curve_samle *(max_prop_scale - min_prop_scale) + min_prop_scale
			scale = Vector3(scale_nr, scale_nr, scale_nr)
	elif random_unprop_scale:
		scale = Vector3(
			generate_random(min_unprop_scale.x, max_unprop_scale.x),
			generate_random(min_unprop_scale.y, max_unprop_scale.y),
			generate_random(min_unprop_scale.z, max_unprop_scale.z)
		)
	else:
		scale = Vector3(1, 1, 1)
	basis = basis.scaled(scale)
	
# Helper. Create the transformation object.
func create_transform_by_basis(basis: Basis, position : Vector3):
	var transform = Transform3D(basis, position)
	return transform
	
	
func _place_additional_scene(additionalScene, targetNode : Node3D, transform):
	if (additionalScene != null and targetNode != null):
		_debug("Placing Additional Scene")
	
		var instance = additionalScene.instantiate()
		instance.transform  = transform
		
		targetNode.add_child(instance)
		
		var root = targetNode.get_tree().get_edited_scene_root()
		instance.set_owner(root)
		instance.set_name(targetNode.get_name())
	else:
		_debug("Not placing Additional Scene. No targetNode and/or additionalScene is set.")
