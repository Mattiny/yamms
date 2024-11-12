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
extends MultiScatterTransform
class_name PlaneBasedPlacement

# used for calculating the initial plane.
var _min_x : float = 0.0
var _max_x : float = 0.0
var _min_z : float = 0.0
var _max_z : float = 0.0
var _avg_height : float = 0.0
var _nrOfPoints :int = 0

#Polygon
var _polygon = []

var current_index


var debug_messages : bool = false : set = _set_debug
func _set_debug(debug) :
	debug_messages = debug

func _debug(message):
	if debug_messages:
		print("YAMMS: PlaneBasedPlacement:  " + message)



func generate_height() -> bool:
	return false
	
func _check_polygon_nr() -> bool:
	return (curve.get_point_count() > 2)


func _calc_plane_min_max() :
	_avg_height = 0.0
	_nrOfPoints = curve.get_point_count()
	_polygon = []
	for i in _nrOfPoints:
		var point : Vector3 = curve.get_point_position(i)
		_avg_height += point.y
		_polygon.append(Vector2(point.x, point.z))
		if point.x < _min_x:
			_min_x = point.x
		if point.x > _max_z:
			_max_x = point.x
		if point.z < _min_z:
			_min_z = point.z
		if point.z > _max_z:
			_max_z = point.z
		
	_avg_height = _avg_height / _nrOfPoints
	_debug("Plane min_x = %s, max_x = %s, min_z = %s, max_z = %s" % [_min_x, _max_x, _min_z, _max_z])
	_debug("Plane height average: %s" %_avg_height)


	
func _generate_plane_positions():
	_debug("Generating plane position for %s elements." %amount)
	for index in amount:
		current_index = index
		var is_point_in_polygon = false
				
		var attempts : int = 0 # Nr of attempts to place mesh inside of the polygon
		var pos : Vector2 
		while not is_point_in_polygon:
			attempts += 1
			if attempts == 100:
				var message = "Cannot drop MultiMesh. Please check: " \
					+ "1) Is the polygon area large enough? " \
					+ "2) Is the whole polygon area hidden by an exclude area? " \
					+ "3) Drop on Floor: is there a large object with collision object underneath?" \
					+ "4) Drop on Ceiling: is there a large object with collision object above?"
					
				_debug(message)
				push_warning(message)
				return
				
			# Generate random 2D coordinates in the range of min max
			var x = generate_random(_min_x, _max_x)
			var z = generate_random(_min_z, _max_z)
			pos = Vector2(x ,z)
			
			is_point_in_polygon = Geometry2D.is_point_in_polygon(pos, _polygon)
		_debug("Position: x=%s, y=%s is in polygon: %s" %[pos.x, pos.y, is_point_in_polygon])
		
		# Set up the the 3 required transform parameters:
		position = Vector3(pos.x, _avg_height, pos.y)
		
		scale = Vector3(1.0, 1.0, 1.0)
		generate_scale()
		
		rotation = Vector3(0.0, 0.0, 0.0)
		generate_rotation()
		
		generate_height()
		
		var transform : Transform3D = create_transform(
			position,
			rotation,
			scale
		)
		_debug("Setting transform: Index = %s" %index)
		_debug("Multimesh: %s" %multimesh_item)
		multimesh_item.set_instance_transform(index, transform)
		_debug("Done.")

	
func generate_transform():
	if _check_polygon_nr():
		_debug("Generating Plane")
		_calc_plane_min_max()
		_generate_plane_positions()
		
	else:
		_debug("Not generating plane. Minimum of 3 points in polygon required.")
		
