extends Control

func _on_HostButton_pressed():
	NETWORK.create_server()

func _on_JoinButton_pressed():
	NETWORK.join_server($Menu/JoinIP/ServerIP.text)
