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

# PolygonOnColliderTransform - Distributes multimesh instances along a polygon
# and then projects the instances onto a collision object.

@tool
extends PolygonTransform
class_name PolygonOnColliderTransform

# collision Mask for the ray cast to spawn the objects.
var collisionMask

# Direction of the ray cast to spawn objects on collision object.
var direction : Vector3

# 3D space for the ray cast to spawn the objects.
var space 

# Normal influence specifies how strong the normal surface of the collision
# object influences the alignment of the spawned object.
# 0.0 = no influence
# 1.0 = full influence
# any value between is possible.
var normal_influence : float

# rotation of the spawned multimesh instance after applying the normal influence.
var normal_rotation

func _debug(message):
	if debug_messages:
		print("YAMMS: PolygonOnColliderTransform:  " + message)
		
func generate_rotation():
	super.generate_rotation()
	
	normal_rotation = Vector3(
		direction.y * -1 * asin(normal_rotation.z ),
		0.0, 
		direction.y * asin(normal_rotation.x )
	) * normal_influence 

	var normal_rotation_quaternion = Quaternion().from_euler(normal_rotation)
	basis = Basis(normal_rotation_quaternion) * basis

# Generate the height.
# - Pass all required data to the ray caster
# - Ray caster does it's work
# - get the calculated height and normal data from ray caster.
func generate_height() -> bool:
	_debug("Generating height")
	
	# Create Raycaster.
	var ray_caster = RayCaster.new()
	ray_caster.debug_messages = debug_messages
	ray_caster.collisionMask = collisionMask
	ray_caster.space = space
	ray_caster.position = position
	ray_caster.global_position =  ms_item_position + ms_position
	ray_caster.direction = direction
	
	# Do the raycast and get the hit position
	var returnValue = ray_caster.generate_height()
	position = ray_caster.hit_position 
	normal_rotation = ray_caster.normal_rotation
	ray_caster.queue_free()
	return returnValue
	
