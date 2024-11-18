@tool
extends PlaneBasedTransform
class_name DropOnColliderTransform

var min_max_height : float = 0

var collisionMask
var direction : Vector3

var space 
var normal_influence : float


# Overwrite rotation: Additionally the normal influence must be assigned
# This means: During the raycast to get the height of the mesh instance, the
# oriantation of the surface (normal) will be saved. The spawned mesh instance
# then aligns to the normal orientation.
# The factor "normal_influence" defines how strong the normal orientation influences
# the MultiMesh instance. 0 = no alignment at all, 1.0 = align exactly to the surface.
func generate_rotation():
	super.generate_rotation()
	
	normal_rotation = Vector3(
		direction.y * -1 * asin(normal_rotation.z ),
		direction.y * -1 * asin(normal_rotation.x ), 
		0.0
	) * normal_influence 
	
	var rotation_quaternion = Quaternion().from_euler(rotation)
	var normal_rotation_quaternion = Quaternion().from_euler(normal_rotation)
	var combined_quaternion = normal_rotation_quaternion * rotation_quaternion
	rotation = Basis(combined_quaternion).get_euler()
	
func generate_height() -> bool:
	_debug("Raycasting for height information.")
	var ray_cast_position = position + global_position
	var ray_cast_target = position + direction * 10000
	
	var ray := PhysicsRayQueryParameters3D.create(
			ray_cast_position,
			ray_cast_position + ray_cast_target,
			collisionMask)
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
		
		# Raycast gets the normal value of the hit surface to align the
		# generated multimesh items. Rotation to align the object will be done 
		# in generate_plane_positions
		normal_rotation = hit["normal"]
		
		return true
