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

# Raycaster - The Raycaster performs a raycast from a given position in a 
# given direction.
# It then provides information of the hit-position, the surface orientation (normal)
# etc.
# This is being used for Transform classes which generate multimesh instances
# on collider objects.
@tool
extends Node
class_name RayCaster

# --- input values ---

# global position of the MultiScatter item
var global_position : Vector3

# Collision mask for the collider
var collisionMask

# Direction of the raycast
var direction : Vector3

# 3D Space in which the raycast takes place.
var space 

# Debug messages on/off
var debug_messages : bool = false

# start position of the raycast.
var position : Vector3

# --- output values ---

# hit position where the ray caster hit the collision object. (if it hit something)
var hit_position : Vector3

# normal rotion - the surface orientation of the collider object at the hit position
var normal_rotation : Vector3


# Output of debug messages.
func _debug(message):
	if debug_messages:
		print("YAMMS: RayCaster:  " + message)

# performs the raycast and returns true if the raycast was successful (hit
# collider object).
# If successful the output values (hit_position, normal_rotation) are set.
func generate_height() -> bool:
	_debug("Raycasting for height information.")
	var ray_cast_position = position + global_position
	var ray_cast_target = position + direction * 10000
	_debug("Raycasting at position %s" %ray_cast_position)
	
	var ray := PhysicsRayQueryParameters3D.create(
			ray_cast_position,
			ray_cast_position + ray_cast_target,
			collisionMask)
	var hit = space.intersect_ray(ray)
	if hit.is_empty():
		# Raycast did not hit anything. Item cannot be placed.
		_debug("Raycast did not hit a collision object. Trying again.")
		return false
	else:
		# Raycast hit a collision object. Placing it there.
		var hit_pos = hit["position"]
		var multimesh_scatter_pos = global_position
		hit_position = hit_pos - multimesh_scatter_pos
		_debug("Set position to %s" %[hit_pos])
		
		# Raycast gets the normal value of the hit surface to align the
		# generated multimesh items. Rotation to align the object will be done 
		# in generate_plane_positions
		normal_rotation = hit["normal"]
		
		return true
