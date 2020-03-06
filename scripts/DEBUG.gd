extends Node

# Optionnal, displays various informations, indicate the message and color =====

func display_info(text, type):
	if get_tree().get_root().find_node("DisplayVertically", true, false) == null:
		var display_vertically = VBoxContainer.new()
		add_child(display_vertically)
		display_vertically.name = "DisplayVertically"

	var debug_node = Label.new()
	get_node("DisplayVertically").add_child(debug_node)
	debug_node.text = text
	
	if type == "error":
		debug_node.set("custom_colors/font_color", Color.red)
	else:
		debug_node.set("custom_colors/font_color", Color(0, 0.5, 0))
	
	yield(get_tree().create_timer(5), "timeout")
	debug_node.queue_free()
