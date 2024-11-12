@tool
extends Node
class_name MultiScatterTransform

# Random rotation variables
var random_rotation : bool = false : set = set_random_rotation
func set_random_rotation(value : bool):
	random_rotation = value
	
var max_rotation : Vector3 = Vector3(0, 0, 0) : set = set_max_rotation
func set_max_rotation(value : Vector3):
	max_rotation = value
	
var min_rotation : Vector3 = Vector3(0, 0, 0) : set = set_min_rotation
func set_min_rotation(value : Vector3):
	min_rotation = value
	
# Random proportional scale variables
var random_prop_scale : bool = false : set = set_random_prop_scale
func set_random_prop_scale(value : bool):
	random_prop_scale = value
	
var max_prop_scale : float : set = set_max_prop_scale
func set_max_prop_scale(value : float):
	max_prop_scale = value
	
var min_prop_scale : float : set = set_min_prop_scale
func set_min_prop_scale(value : float):
	min_prop_scale = value
	
var scale_curve : Curve : set = set_scale_curve
func set_scale_curve(value: Curve):
	scale_curve = value


# Random unproportional scale variables
var random_unprop_scale : bool = false : set = set_random_unprop_scale
func set_random_unprop_scale(value : bool):
	random_unprop_scale = value

var max_unprop_scale : Vector3 : set = set_max_unprop_scale
func set_max_unprop_scale(value : Vector3):
	max_unprop_scale = value
	
var min_unprop_scale : Vector3 : set = set_min_unprop_scale
func set_min_unprop_scale(value : Vector3):
	min_unprop_scale = value





# Actual position / scale / rotation
var position : Vector3
var scale : Vector3
var rotation : Vector3
	
	
# Sets the curve of the MultiScatter
var curve : Curve3D : set = set_curve
func set_curve(crv : Curve3D):
	curve = crv

# amount of items to be generated
var amount : int : set = _set_amount 
func _set_amount(am):
	amount = am
	
# the MultiMeshItem to spawn all instances
var multimesh_item : MultiMesh : set = _set_multimesh_item
func _set_multimesh_item(value):
	multimesh_item = value

# Random NR generator
var random : RandomNumberGenerator : set = _set_random 
func _set_random(randomInstance):
	random = randomInstance	
	
func generate_random(min, max): 
	return random.randf_range(min, max)

# Generate random rotation in the bounds of min/max rotation	
func generate_rotation():
	if random_rotation:
		rotation = Vector3(
			generate_random(min_rotation.x, max_rotation.x),
			generate_random(min_rotation.y, max_rotation.y),
			generate_random(min_rotation.z, max_rotation.z)
		)
		
# Generate random scale in the bounds of min/max scale
func generate_scale():
	if random_prop_scale:
		if scale_curve == null:
			var scale_nr :float = generate_random(min_prop_scale, max_prop_scale)
			scale = Vector3(scale_nr, scale_nr, scale_nr)
		else:
			var curve_samle : float = scale_curve.sample(generate_random(min_prop_scale, max_prop_scale))
			var scale_nr :float = curve_samle *(max_prop_scale - min_prop_scale) + min_prop_scale
			scale = Vector3(scale_nr, scale_nr, scale_nr)
	elif random_unprop_scale:
		scale = Vector3(
			generate_random(min_unprop_scale.x, max_unprop_scale.x),
			generate_random(min_unprop_scale.x, max_unprop_scale.x),
			generate_random(min_unprop_scale.x, max_unprop_scale.x)
		)
	
# interface function. Implementation in specific instance.
func generate_transform():
	pass
	
# Helper function to create a transform for the MultiMesh instance.
func create_transform(pos : Vector3, rotation : Vector3, scale : Vector3):
	var transform = Transform3D(Basis(), Vector3())\
		.rotated(Vector3.RIGHT, rotation.x)\
		.rotated(Vector3.FORWARD, rotation.y)\
		.rotated(Vector3.UP, rotation.z)\
		.scaled(scale)\
		.translated(pos)
	return transform
