extends Node

const SERVER_PORT = 4242
const MAX_PLAYERS = 32

var map_scene = "res://scenes/Map.tscn"
var player_scene = "res://scenes/Player.tscn"
var lobby_scene = "res://scenes/Lobby.tscn"

var spawn_node = null

# Signals emitted by others connecting or already connected ====================

func _ready():
	get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_network_peer_disconnected")
	get_tree().connect("server_disconnected", self, "leave_game")

# Lobby buttons ================================================================

func create_server():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)
	
	load_game()
	
func join_server(to_IP):
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(to_IP, SERVER_PORT)
	get_tree().set_network_peer(peer)
	
	load_game()

# Enter the game ===============================================================

func load_game():
	get_tree().change_scene(map_scene)

	# Wait for the map to load, then search for the Spawn node
	yield(get_tree().create_timer(0.01), "timeout")
	spawn_node = get_tree().get_root().find_node("Spawn", true, false)

	if spawn_node != null: # If we have a spawn node in the map
		
		# If this is not the host, spawn the player locally
		if not get_tree().is_network_server():
			spawn_player( get_tree().get_network_unique_id() )
	
		# Other players and host will receive a signal to spawn you

	else:
		display_info("Error: Spawn node missing in the map, can't spawn Players!", "error")

# Spawn the player, get the local id or remote id from signal to spawn others ==

func spawn_player(id):
	var player_instance = load(player_scene).instance()
	player_instance.name = str(id)
	spawn_node.add_child(player_instance)

# Leave the game and return to the Lobby =======================================

func leave_game():
	get_tree().set_network_peer(null) # Sends a network_peer_disconnected signal
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene(lobby_scene)

# Remote =======================================================================

# Spawn the player remotely from connecting to another client
func _on_network_peer_connected(id):
	
	display_info("+ " + str(id) + " has connected!", "")
	display_info("= Total connected: " + str( get_tree().get_network_connected_peers().size() ), ""  )
	if id != 1: # Do not spawn from the signal of the host which is equal to 1
		spawn_player(id)

# If a client id emitted the signal of disconnecting, remove the player remotely:
func _on_network_peer_disconnected(id):
	if spawn_node.has_node(str(id)): # To avoid crashing, it checks if it exists
		display_info("- " + str(id) + " has left!", "")
		display_info("= Total connected: " + str( get_tree().get_network_connected_peers().size() ), ""  )
		spawn_node.get_node(str(id)).queue_free()

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
