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
extends PlacementMode
class_name PMDropOnCollider


# collision mask to select the layer of the ray cast.
@export_flags_3d_physics var collision_mask := 0x1:
	get: return collision_mask
	set(value):
		collision_mask = value
		
enum direction {Up, Down}
@export var placement_direction : direction = direction.Down

@export var normal_influence : float = 1.0 

@export_group("Excludes")
@export var exclude : Array[MultiScatterExclude] = []

var ray_cast_direction : Vector3

func _debug(message):
	if debug_messages:
		print("YAMMS: PMDropOnCollider:  " + message)

func generate() :
	_debug("Generating")
	# create Flat Transform
	mstransform = DropOnColliderTransform.new()
	mstransform.debug_messages = debug_messages
	mstransform.random = random
	mstransform.curve = curve
	mstransform.amount =amount
	
	mstransform.random_rotation = randomize_rotation
	mstransform.max_rotation = max_random_rotation
	mstransform.min_rotation = min_random_rotation
	
	mstransform.global_position = ms_global_position
	mstransform.exclude_list = exclude_list
	mstransform.specific_exclude_list = exclude
	
	# Pass scale information to transform
	if random_scale_type == scale_type_enum.Proportional:
		mstransform.random_prop_scale= true
		mstransform.random_unprop_scale = false
		mstransform.max_prop_scale = max_random_scale
		mstransform.min_prop_scale = min_random_scale
		mstransform.scale_curve = scale_curve
	elif random_scale_type == scale_type_enum.Unproportional:
		mstransform.random_unprop_scale = true
		mstransform.random_prop_scale = false
		mstransform.max_unprop_scale = max_unproportional_scale
		mstransform.min_unprop_scale = min_unproportional_scale
	else:
		mstransform.random_unprop_scale = false
		mstransform.random_prop_scale = false

	if placement_direction == direction.Up:
		ray_cast_direction = Vector3.UP
	elif placement_direction == direction.Down:
		ray_cast_direction = Vector3.DOWN		
	mstransform.direction = ray_cast_direction

	mstransform.collisionMask = collision_mask

	mstransform.normal_influence = normal_influence
	mstransform.space = space
	mstransform.multimesh_item = multimesh_item

	if enableAdditionalScene ==  true:
		mstransform.enableAdditionalScene = true
		mstransform.additionalScene = additionalScene
		mstransform.targetNode = targetNode
		
	# generate
	mstransform.generate_transform()
	
	# delete Floating Transform
	mstransform.queue_free()
