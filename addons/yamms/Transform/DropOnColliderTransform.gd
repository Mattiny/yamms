@tool
extends PlaneBasedTransform
class_name DropOnColliderTransform

var min_max_height : float = 0

var collisionMask
var direction : Vector3

var space 
var normal_influence : float

func generate_height() -> bool:
	
	var ray_cast_position = position + global_position
	_debug("Direction: %s" %direction)
		
	var ray_cast_target = position + direction * 10000
	
	_debug("Collision mask: %s" %collisionMask)
	_debug("GlobalPosition: %s" %global_position)
	_debug("Raycast position: %s" %ray_cast_position)
	_debug("Raycast target: %s" %ray_cast_target)
	var ray := PhysicsRayQueryParameters3D.create(
			ray_cast_position,
			ray_cast_position + ray_cast_target,
			collisionMask)
	_debug("Space: %s" %space)
	var hit = space.intersect_ray(ray)
	if hit.is_empty():
		# Raycast did not hit anything. Item cannot be placed.
		_debug("Raycast did not hit a collision object for index %s. Trying again." %current_index)
		return false
	else:
		# Raycast hit a collision object. Placing it there.
		var hit_pos = hit["position"]
		var multimesh_scatter_pos = global_position
		position = hit_pos - multimesh_scatter_pos
		_debug("Set position for index %s to %s" %[current_index, hit_pos])
		
		#var hit_normal = hit["normal"]
		#var normal_rot = Vector3(rad_to_deg(asin(deg_to_rad(hit_normal.z))), 0.0, -1.0 * rad_to_deg(asin(deg_to_rad(hit_normal.x))))
		#var normal_displacement : Vector3 = (normal_rot * normal_influence) ;
		

		return true
