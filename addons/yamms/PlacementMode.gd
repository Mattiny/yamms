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

# PlacmentMode. Abstract class which implements the algorythm to generate
# MultiMesh instances.
@tool
extends Node3D
class_name PlacementMode

enum scale_type_enum {None, Proportional, Unproportional}
@export var random_scale_type : scale_type_enum = scale_type_enum.None


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
		

# TODO: Max Rotation maximum is 3.1415 (PI = 1 complete rotation,  min  = 0
# TODO: Min Rotation minimum is -3.1415, max = 0
@export_group("Rotation")
@export var randomize_rotation : bool = false
@export var max_random_rotation : Vector3 = Vector3(0,0,0)
@export var min_random_rotation : Vector3 = Vector3(0,0,0) 



var curve : Curve3D


# Additional scene Data.
var enableAdditionalScene : bool = false

#  TargetNode where the additional scene is going to be placed.
var targetNode: Node3D

#  The scene which is going to be placed as additional scene to the same
#  position where the multimesh item is going to be placed.
var additionalScene: PackedScene

# Array of exclude areas.
var exclude_list : Array[MultiScatterExclude]

#  setter for debug messages
var debug_messages : bool = false : set = _set_debug
func _set_debug(debug) :
	debug_messages = debug

# write a debug message.
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

# The MultiMesh
var multimesh_item : MultiMesh : set = _set_multimesh_item
func _set_multimesh_item(value):
	multimesh_item = value

# The transform information of the Object to be spawned.
var mstransform : MultiScatterTransform : set = _set_multiscatter_transform
func _set_multiscatter_transform(value : MultiScatterTransform):
	mstransform = value
	
# Position/Rotation of the MultiScatter
var ms_position : Vector3
var ms_rotation : float

# Position/Rotation of the MultiScatterItem.
var ms_item_position : Vector3
var ms_item_rotation : float

# Space. Required for Raycasts.
var space

#  Average height of the polygon curve
var _avg_height : float = 0.0

# Number of points in the polygon.
var _nrOfPoints : int

# Array with the points of the polygon.
var _polygon = []

# MultiScatter Polygon min/max. Sets up the min/max position of the MultiScatter
# Polygon. All randomly generated positions will be inside this area.
var polygon_min : Vector3 
var polygon_max : Vector3

# Keep track of the last rotation. Whenever rotation changed: x and z rotation
# is set back to 0. Only rotation around y axis is allowed.
var last_rotation := Vector3.ZERO

# Interface method to generate the MultiMesh position. Nothing to do here.
# Actual implementation will be done in subclasses.
func generate() :
	_debug("Generating")
	
# ready - stores rotation information and adds notification on rotation in order
# to overwrite rotation behaviour. Only rotation on y axis is allowed.
func _ready() -> void:
	if not Engine.is_editor_hint():
		return
		
	if Engine.is_editor_hint():
		set_notify_transform(true)  # Aktiviert Transform-Änderungsbenachrichtigungen
		last_rotation = rotation  # Anfangswert speichern
	
# overwrites the rotation on Gizmo in editor. Only rotation on y axis allowed.
# Rotation of all other axis is set to 0
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		var new_rotation = rotation
		# Check if rotation changed.
		if not last_rotation.is_equal_approx(new_rotation):
			new_rotation.x = 0
			new_rotation.z = 0
			rotation = new_rotation  # set the correction rotation
			last_rotation = new_rotation 
			
# overwrites the rotation on Inspector in editor. Only rotation on y axis allowed.
# Rotation of all other axis is set to 0	
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
	
