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

# PlaneBasedPM is an abstract PlacmentMode based on a plane which is defined by Polygon
# of the MultiScatter.
#
# This plane lays flat in 3D Space (looking from top) at the average height of
# the polygon.
#
# All random positions will be generated inside this plane. Then the height will
# will be generated depending on the specific PlacementMode.
#
# For a plane based PlacmentMode a density map can be configured to set up
# areas with a high number of MultiMesh instance or areas with a low number or
# none at all.
@tool
extends PlacementMode
class_name PlaneBasedPM

# The density map.
var density_map_node : Node3D = null

# interface function to create a density map node.
# will be implemented in subclass.
func create_density_map_node():
	pass
	
# interface function to remove a density map node.
# will be implemented in subclass.	
func remove_density_map():
	pass

# Update visuals. Density map might have been added or removed.
# so show or hide the density map.
func _update_visuals():
	if density_map_node == null:
		create_density_map_node()

	
func _remove_visuals():
	if density_map_node and density_map_node.is_inside_tree():
		remove_density_map()


func _update_material():
	pass


@export var density_map : Texture2D = null:
	set(value):
		density_map = value
		_update_visuals()
		_update_material()

func _ready() -> void:
	super._ready()
	_update_visuals()
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE and Engine.is_editor_hint():
		_update_visuals()
	elif what == NOTIFICATION_EXIT_TREE and Engine.is_editor_hint():
		_remove_visuals()	

	super._notification(what)
		
		

# Should spawn - takes a position (2D plane position)
# and determines depending on the density map if the object shall spawn
# here or not.
# The gray scale value gives the percentage of the chance wether the object
# shall spawn or not.
# If the density shows white color: It should spawn at 100%
# If the density shows black color: It should spawn at 0%
func should_spawn_at(global_x: float, global_z: float) -> bool:
	if not density_map or not density_map.get_image():
		return true  # Keine Textur → Immer true

	# Get the density map image.
	var image: Image = density_map.get_image()
	if image == null:
		density_map = density_map.duplicate()
		image = density_map.get_image()

	# Decompress if compressed.
	# TODO: This is done for every position. Should be just once when generating.
	if image.is_compressed():
		image.decompress()

	# global to local.
	var local_pos = to_local(Vector3(global_x, 0, global_z) + ms_position) 

	# Get the plane size of the density map.
	var plane_size = get_plane_size()
	if plane_size == Vector2.ZERO:
		return false  # no size - no spawn

	# Take care of the scale of the density map.
	var scale = density_map_node.scale  
	local_pos.x /= scale.x
	local_pos.z /= scale.z

	# Rotation around y axis only.
	var rotation_y = int(rotation_degrees.y) % 360
	
	# uv - the coordinates at the density map.
	var uv_x = 0.0
	var uv_y = 0.0
	
	uv_x = (local_pos.x / plane_size.x) + 0.5
	uv_y = (local_pos.z / plane_size.y) + 0.5


	# Map uv coordinates to texture size.
	var tex_width = image.get_width()
	var tex_height = image.get_height()
	var pixel_x = int(uv_x * tex_width)
	var pixel_y = int(uv_y * tex_height)


	# Take care that pixel coordinates are within valid range.
	pixel_x = clamp(pixel_x, 0, tex_width - 1)
	pixel_y = clamp(pixel_y, 0, tex_height - 1)
	
	# Get the gray scale value. Actually: get the red value
	# Could be any other of the base color because gray means: all base colors
	# are equal.
	var red_value = image.get_pixel(pixel_x, pixel_y).r
	var probability = image.get_pixel(pixel_x, pixel_y).r

	# Randomize the result with the probability.
	return randf() < probability


# Returns the size of the density map or Vector2.ZERO if no density map
# is set up.
func get_plane_size() -> Vector2:
	if density_map_node is MeshInstance3D and density_map_node.mesh is PlaneMesh:
		var plane_mesh: PlaneMesh = density_map_node.mesh
		var returnValue = Vector2(plane_mesh.size.x, plane_mesh.size.y)
		return returnValue
	return Vector2.ZERO
	
