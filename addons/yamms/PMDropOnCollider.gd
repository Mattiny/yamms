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
extends PlaneBasedPM
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
	mstransform.placement = self
	mstransform.debug_messages = debug_messages
	mstransform.random = random
	mstransform.amount =amount
	
	mstransform.random_rotation = randomize_rotation
	mstransform.max_rotation = max_random_rotation
	mstransform.min_rotation = min_random_rotation
	
	mstransform.ms_position = ms_position
	mstransform.ms_item_position = ms_item_position
	mstransform.ms_pm_position = position

	mstransform.exclude_list = exclude_list
	mstransform.specific_exclude_list = exclude
	
	#  Average height of the polygon curve
	mstransform._avg_height = _avg_height

	# Number of points in the polygon.
	mstransform._nrOfPoints = _nrOfPoints

	mstransform.polygon_min = polygon_min
	mstransform.polygon_max = polygon_max

	# Array with the points of the polygon.
	mstransform.polygon = _polygon
	
	
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
	
	
func create_density_map_node():
	density_map_node = Decal.new()
	density_map_node.texture_albedo = density_map if density_map else _create_white_texture()
	#density_map_node.transform = Transform3D(Basis(Vector3(1, 0, 0), deg_to_rad(-90)), Vector3(0, 0, 0))  # Nach unten projizieren
	add_child(density_map_node)
	
func _create_white_texture() -> Texture2D:
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color.FIREBRICK)
	var tex := ImageTexture.create_from_image(img)
	return tex
	
func remove_density_map():
	density_map_node.get_parent().remove_child(density_map_node)
	density_map_node.queue_free()
	density_map_node = null
	
func get_plane_size() -> Vector2:
	_debug("---Getting Plane size.")
	if density_map_node is Decal:
		var returnValue = Vector2(density_map_node.size.x, density_map_node.size.z)
		_debug("---Plane size: %s" %[returnValue])
		return returnValue
	return Vector2.ZERO
	
		
func _update_material():
	if density_map_node == null:
		return

	# Setze die richtige Textur (falls keine da ist, verwende eine weiße Textur)
	density_map_node.texture_albedo = density_map if density_map else _create_white_texture()
