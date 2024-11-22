@tool
extends PlacementMode
class_name PMPolygon

@export var random_steps = false
@export_range(0, 5) var thickness : float = 0.3

@export_group("Excludes")
@export var exclude : Array[MultiScatterExclude] = []

func _debug(message):
	if debug_messages:
		print("YAMMS: PMPolygon:  " + message)
		
func generate() :
	_debug("Generating")

	# create Flat Transform
	mstransform = PolygonTransform.new()
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
	
	
	mstransform.multimesh_item = multimesh_item

	# generate
	mstransform.generate_transform()
	
	# delete Floating Transform
	mstransform.queue_free()
