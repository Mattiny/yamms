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
class_name PlaneBasedPM


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
