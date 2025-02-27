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
	
	
func _set(property: StringName, value) -> bool:
	if property == "rotation":
		var new_value = value as Vector3
		new_value.x = 0
		new_value.z = 0
		new_value.y = value.y
		rotation = new_value  # Direkt den Setter aufrufen
		last_rotation = new_value  # Aktualisiert den gespeicherten Wert
		return true  # Gibt an, dass die Eigenschaft gesetzt wurde
	return false  # Standardverhalten für andere Properties beibehalten
	

	
	
	
var ms_position : Vector3
var ms_rotation : float
var ms_item_position : Vector3
var ms_item_rotation : float

var space

var density_map_node : Node3D = null



#  Average height of the polygon curve
var _avg_height : float = 0.0

# Number of points in the polygon.
var _nrOfPoints : int

var polygon_min : Vector3 
var polygon_max : Vector3
var last_rotation := Vector3.ZERO  # Speichert die letzte gültige Rotation


# Array with the points of the polygon.
var _polygon = []

func generate() :
	_debug("Generating")
	
	
func _ready() -> void:
	if not Engine.is_editor_hint():
		return
		
	if Engine.is_editor_hint():
		set_notify_transform(true)  # Aktiviert Transform-Änderungsbenachrichtigungen
		last_rotation = rotation  # Anfangswert speichern

	
func _notification(what: int) -> void:

	if what == NOTIFICATION_TRANSFORM_CHANGED:
		var new_rotation = rotation
		# Prüfen, ob sich die Rotation verändert hat
		if not last_rotation.is_equal_approx(new_rotation):
			new_rotation.x = 0
			new_rotation.z = 0
			rotation = new_rotation  # Korrigierte Rotation setzen
			last_rotation = new_rotation  # Aktualisierten Wert speichern

		
		


	
func get_plane_size() -> Vector2:
	if density_map_node is MeshInstance3D and density_map_node.mesh is PlaneMesh:
		var plane_mesh: PlaneMesh = density_map_node.mesh
		var returnValue = Vector2(plane_mesh.size.x, plane_mesh.size.y)
		return returnValue
	return Vector2.ZERO
	
