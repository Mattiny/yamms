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
extends Node3D
class_name PlacementMode

enum scale_type_enum {None, Proportional, Unproportional}
@export var random_scale_type : scale_type_enum = scale_type_enum.None

@export var density_map : Texture2D = null:
	set(value):
		density_map = value
		_update_visuals()
		_update_material()


# TODO: Max Rotation maximum is 3.1415 (PI = 1 complete rotation,  min  = 0
# TODO: Min Rotation minimum is -3.1415, max = 0
@export_group("Rotation")
@export var randomize_rotation : bool = false
@export var max_random_rotation : Vector3 = Vector3(0,0,0)
@export var min_random_rotation : Vector3 = Vector3(0,0,0) 



# TODO: Scale shall always be larger than 0
# TODO: Scale max shall be larger than min
@export_group("Proportional Random Scale")
@export var max_random_scale : float = 1.0
@export var min_random_scale : float = 0.5
@export var scale_curve : Curve

# TODO: Scale shall always be larger than 0
# TODO: Scale max shall be larger than min
@export_group("Unproportional Random Scale")
@export var max_unproportional_scale : Vector3 = Vector3(1, 1, 1)
@export var min_unproportional_scale : Vector3 = Vector3(0.5, 0.5, 0.5)

var curve : Curve3D
var ms_item_pos : Vector3

# Additional scene Data.
var enableAdditionalScene : bool = false

#  TargetNode where the additional scene is going to be placed.
var targetNode: Node3D

#  The scene which is going to be placed as additional scene to the same
#  position where the multimesh item is going to be placed.
var additionalScene: PackedScene


var exclude_list : Array[MultiScatterExclude]

#  Debug messages
var debug_messages : bool = false : set = _set_debug
func _set_debug(debug) :
	debug_messages = debug
	

func _debug(message):
	if debug_messages:
		print("YAMMS: PlacementMode:  " + message)

# Random NR generator
var random : RandomNumberGenerator : set = _set_random 
func _set_random(randomInstance):
	random = randomInstance
	
	
# amount of items to be generated
var amount : int : set = _set_amount 
func _set_amount(am):
	amount = am

var multimesh_item : MultiMesh : set = _set_multimesh_item
func _set_multimesh_item(value):
	multimesh_item = value

var mstransform : MultiScatterTransform : set = _set_multiscatter_transform
func _set_multiscatter_transform(value : MultiScatterTransform):
	mstransform = value
	
	
#func _set(property: StringName, value) -> bool:
#	if property == "rotation":
#		var new_value = value as Vector3
#		new_value.x = 0
#		new_value.z = 0
#		new_value.y = snapped(new_value.y, deg_to_rad(90))
#		
#		super.set_rotation(new_value)  # Original Setter aufrufen
#		return true  # Gibt an, dass die Eigenschaft gesetzt wurde
#	return false  # Standardverhalten für andere Properties beibehalten
	
var ms_position : Vector3
var ms_item_position : Vector3

var space

var density_map_node : Node3D = null



#  Average height of the polygon curve
var _avg_height : float = 0.0

# Number of points in the polygon.
var _nrOfPoints : int

var polygon_min : Vector3 
var polygon_max : Vector3

# Array with the points of the polygon.
var _polygon = []

func generate() :
	_debug("Generating")
	
	
func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	_update_visuals()
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE and Engine.is_editor_hint():
		_update_visuals()
	elif what == NOTIFICATION_EXIT_TREE and Engine.is_editor_hint():
		_remove_visuals()	

func create_density_map_node():
	pass
	
func remove_density_map():
	pass

func _update_visuals():
	if density_map_node == null:
		create_density_map_node()

	
func _remove_visuals():
	if density_map_node and density_map_node.is_inside_tree():
		remove_density_map()


func _update_material():
	pass
	
func get_plane_size() -> Vector2:
	if density_map_node is MeshInstance3D and density_map_node.mesh is PlaneMesh:
		var plane_mesh: PlaneMesh = density_map_node.mesh
		var returnValue = Vector2(plane_mesh.size.x, plane_mesh.size.y)
		return returnValue
	return Vector2.ZERO
	
func should_spawn_at(global_x: float, global_z: float) -> bool:
	if not density_map or not density_map.get_image():
		return true  # Keine Textur → Immer true

	var image: Image = density_map.get_image()
	if image == null:
		density_map = density_map.duplicate()  # Erzwingt das Laden der Textur
		image = density_map.get_image()

	# Falls die Textur komprimiert ist, dekomprimieren
	if image.is_compressed():
		image.decompress()

	# Globale Position in lokale umwandeln
	
	var local_pos = to_local(Vector3(global_x, 0, global_z) + ms_position) 


	# Plane-Größe abrufen (unabhängig von Typ)
	var plane_size = get_plane_size()

	if plane_size == Vector2.ZERO:
		return false  # Falls keine Größe bestimmt werden kann, nichts spawnen

	var scale = density_map_node.scale  # Skalierung

	# Skalierung berücksichtigen
	local_pos.x /= scale.x
	local_pos.z /= scale.z

	# Rotation um Y-Achse bestimmen (nur 90°-Schritte)
	var rotation_y = int(rotation_degrees.y) % 360  # Nur 0, 90, 180, 270 erlaubt
	var uv_x = 0.0
	var uv_y = 0.0
	
	uv_x = (local_pos.x / plane_size.x) + 0.5
	uv_y = (local_pos.z / plane_size.y) + 0.5
	
#	match rotation_y:
#		0:
#			_debug("-----Rotation 0")
#			uv_x = (local_pos.x / plane_size.x) + 0.5
#			uv_y = (local_pos.z / plane_size.y) + 0.5
#		90:
#			_debug("-----Rotation 90")
#			uv_x = (local_pos.z / plane_size.y) + 0.5
#			uv_y = 1.0 - ((local_pos.x / plane_size.x) + 0.5)
#		180:
#			_debug("-----Rotation 180")
#			uv_x = 1.0 - ((local_pos.x / plane_size.x) + 0.5)
#			uv_y = 1.0 - ((local_pos.z / plane_size.y) + 0.5)
#		270:
#			_debug("-----Rotation 270")
#			uv_x = 1.0 - ((local_pos.z / plane_size.y) + 0.5)
#			uv_y = (local_pos.x / plane_size.x) + 0.5
#

	# UV-Koordinaten auf Texturgröße umrechnen
	var tex_width = image.get_width()
	var tex_height = image.get_height()
	var pixel_x = int(uv_x * tex_width)
	var pixel_y = int(uv_y * tex_height)


	# Sicherstellen, dass die Pixel-Koordinaten im gültigen Bereich liegen
	pixel_x = clamp(pixel_x, 0, tex_width - 1)
	pixel_y = clamp(pixel_y, 0, tex_height - 1)
	# Rot-Wert des Pixels als Wahrscheinlichkeit (0.0 bis 1.0)
	var red_value = image.get_pixel(pixel_x, pixel_y).r
	var probability = image.get_pixel(pixel_x, pixel_y).r

	# Zufallsentscheidung basierend auf der Wahrscheinlichkeit
	return randf() < probability
