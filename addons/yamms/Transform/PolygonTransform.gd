@tool
extends MultiScatterTransform
class_name PolygonTransform

func _debug(message):
	if debug_messages:
		print("YAMMS: PolygonTransform:  " + message)

var randomize_steps = false

func generate_transform():
	
	var length = curve.get_baked_length()
	

	var step = length / (amount - 1)
	
	for index in range(amount):

		# Distance determines the position of the spawned object on the polygon
		# from the beginning (0) up to the end of the polybon (length).
		# if Randomized: The object shall spawn randomly somewhere in between.
		# if not rendomized: The object shall spawn and fixed position (steps)
		var distance : float
		if randomize_steps:
			distance = generate_random(0, length)
		else:
			distance = step * index
		position = curve.sample_baked(distance)
		
		# Generate scale depending on the Placement mode settings.
		scale = Vector3(1.0, 1.0, 1.0)
		generate_scale()
		
		# Generate rotation depending on the Placement mode settings.
		rotation = Vector3(0.0, 0.0, 0.0)
		generate_rotation()

		# position, scale and rotation has been generated. Set the transform
		# for the multi-mesh instance.
		_debug("Setting position on Polygon. Index = %s, Rotation = %s" %[index,rotation])
		do_transform(index, position, rotation, scale)
