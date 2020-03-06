extends Control

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_HostButton_pressed():
	NETWORK.create_server()

func _on_JoinButton_pressed():
	NETWORK.join_server($Menu/JoinIP/ToIP.text)
