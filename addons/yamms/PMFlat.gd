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

# PMFlat - A plane based placement mode generates objects on a 2D Plane set up
# by the MultiScatter polygon, the exclude areas and density map.
# It places the MultiMesh instances just on a plane at the average height of the
# polygone nodes.
@tool
extends PlaneBasedPM
class_name PMFlat

@export_group("Excludes")
@export var exclude : Array[MultiScatterExclude] = []

# debug message.
func _debug(message):
	if debug_messages:
		print("YAMMS: PMFLat:  " + message)

func generate() :
	_debug("Generating")
	# create Flat Transform
	mstransform = FlatTransform.new()
	mstransform.placement = self
	mstransform.debug_messages = debug_messages
	mstransform.random = random
	mstransform.amount =amount
	mstransform.curve = curve
	
	mstransform.random_rotation = randomize_rotation
	mstransform.max_rotation = max_random_rotation
	mstransform.min_rotation = min_random_rotation
	mstransform.exclude_list = exclude_list
	mstransform.specific_exclude_list = exclude

	mstransform.ms_position = ms_position
	mstransform.ms_item_position = ms_item_position
	mstransform.ms_pm_position = position

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
	
	
	mstransform.multimesh_item = multimesh_item
	
	if enableAdditionalScene == true:
		mstransform.enableAdditionalScene = true
		mstransform.additionalScene = additionalScene
		mstransform.targetNode = targetNode

	# generate
	mstransform.generate_transform()
	
	# delete Floating Transform
	mstransform.queue_free()
	
	
func create_density_map_node():
	density_map_node = MeshInstance3D.new()
	density_map_node.mesh = PlaneMesh.new()
		
	var material = StandardMaterial3D.new()
	if density_map:
		material.albedo_texture = density_map
	else:
		material.albedo_color = Color(1, 1, 1)  # Standardfarbe (z. B. weiß)

	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	density_map_node.material_override = material
	add_child(density_map_node)
	
	
func remove_density_map():
	density_map_node.get_parent().remove_child(density_map_node)
	density_map_node.queue_free()
	density_map_node = null
	
	
func _update_material():
	if not density_map_node:
		return  # Falls das Mesh noch nicht existiert, gibt es nichts zu aktualisieren
	var material = density_map_node.get_active_material(0)
	if not material or not material is StandardMaterial3D:
		material = StandardMaterial3D.new()
		density_map_node.material_override = material
	if density_map:
		material.albedo_texture = density_map
	else:
		material.albedo_texture = null
		material.albedo_color = Color(1, 1, 1)  # Standardfarbe
