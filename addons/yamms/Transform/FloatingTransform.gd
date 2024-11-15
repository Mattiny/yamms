@tool
extends PlaneBasedTransform
class_name FloatingTransform

var min_max_height : float = 0


func generate_height() -> bool:
	_debug("Generating height. MinMax = %s "%min_max_height)
	var height_offset :float = generate_random(-min_max_height, min_max_height)
	_debug("Generated offset. Height = %s "%height_offset)
	position.y = position.y + height_offset
	return true
