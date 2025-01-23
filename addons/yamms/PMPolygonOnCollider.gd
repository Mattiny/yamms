@tool
extends PlacementMode
class_name PMPolygonOnCollider


# collision mask to select the layer of the ray cast.
@export_flags_3d_physics var collision_mask := 0x1:
	get: return collision_mask
	set(value):
		collision_mask = value
		
enum direction {Up, Down, Polygon}
@export var placement_direction : direction = direction.Down

@export var normal_influence : float = 1.0 



@export var random_steps = false
@export_range(0, 5) var thickness : float = 0.3

@export_group("Excludes")
@export var exclude : Array[MultiScatterExclude] = []

var ray_cast_direction : Vector3


func _debug(message):
	if debug_messages:
		print("YAMMS: PMPolygon:  " + message)
		
func generate() :
	_debug("Generating")

	# create Flat Transform
	mstransform = PolygonOnColliderTransform.new()
	mstransform.debug_messages = debug_messages
	mstransform.random = random
	mstransform.randomize_steps = random_steps
	mstransform.curve = curve
	mstransform.amount =amount
	mstransform.thickness = thickness
	mstransform.exclude_list = exclude_list
	mstransform.specific_exclude_list = exclude
	
	mstransform.random_rotation = randomize_rotation
	mstransform.max_rotation = max_random_rotation
	mstransform.min_rotation = min_random_rotation
	mstransform.global_position = ms_global_position
	
	#  Average height of the polygon curve
	mstransform._avg_height = _avg_height

	# Number of points in the polygon.
	mstransform._nrOfPoints = _nrOfPoints

	mstransform.polygon_min = polygon_min
	mstransform.polygon_max = polygon_max

	# Array with the points of the polygon.
	mstransform.polygon = _polygon
	
	
	if placement_direction == direction.Up:
		ray_cast_direction = Vector3.UP
	elif placement_direction == direction.Down:
		ray_cast_direction = Vector3.DOWN		
	mstransform.direction = ray_cast_direction
	
	# Pass scale information to transform
	if random_scale_type == scale_type_enum.Proportional:
		mstransform.random_prop_scale= true
		mstransform.random_unprop_scale = false
		mstransform.max_prop_scale = max_random_scale
		mstransform.min_prop_scale = min_random_scale
		mstransform.scale_curve = scale_curve
	elif random_scale_type == scale_type_enum.Unproportional:
		mstransform.random_unprop_scale = true
		mstransform.random_prop_scale = false
		mstransform.max_unprop_scale = max_unproportional_scale
		mstransform.min_unprop_scale = min_unproportional_scale
	else:
		mstransform.random_unprop_scale = false
		mstransform.random_prop_scale = false
	
	mstransform.collisionMask = collision_mask

	mstransform.normal_influence = normal_influence
	mstransform.space = space
	mstransform.multimesh_item = multimesh_item

	if enableAdditionalScene ==  true:
		mstransform.enableAdditionalScene = true
		mstransform.additionalScene = additionalScene
		mstransform.targetNode = targetNode

	# generate
	mstransform.generate_transform()
	
	# delete Floating Transform
	mstransform.queue_free()
