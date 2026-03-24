extends Control

# This node delegates its _draw call to the parent Hunt scene
func _draw() -> void:
	var hunt := get_node("/root/Hunt") as Node
	if hunt and hunt.has_method("_draw_grid"):
		hunt._draw_grid()
