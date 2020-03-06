extends Node

const SERVER_PORT = 4242
const MAX_PLAYERS = 32

var map_scene = "res://scenes/Map.tscn"
var player_scene = "res://scenes/Player.tscn"
var lobby_scene = "res://scenes/Lobby.tscn"

var spawn_node = null

func _ready():
	# Signals are only received from others
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

	# Wait for the map to load, then search for the Spawner node
	yield(get_tree().create_timer(0.01), "timeout")
	spawn_node = get_tree().get_root().find_node("Spawn", true, false)

	if spawn_node != null: # If we have added a spawn node in the map
		
		# If this is not the host, spawn the player locally
		if not get_tree().is_network_server():
			spawn_player( get_tree().get_network_unique_id() )
	
		# Other players and host will receive a signal to spawn you

	else:
		display_info("Error: Spawn node missing in the map, can't spawn Players!")

func spawn_player(id):
	var player_instance = load(player_scene).instance()
	player_instance.name = str(id)
	spawn_node.add_child(player_instance)

# Leave the game and return to Lobby ===========================================

func leave_game():
	get_tree().set_network_peer(null) # Sends a network_peer_disconnected signal
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene(lobby_scene)

# Remote =======================================================================

# If a client id emitted the signal of connecting, spawn the player remotely:
func _on_network_peer_connected(id):
	display_info("Connected with " + str(id))
	if id != 1: # Do not spawn from the signal of the host
		spawn_player(id)

# If a client id emitted the signal of disconnecting, remove the player remotely:
func _on_network_peer_disconnected(id):
	if spawn_node.has_node(str(id)):
		spawn_node.get_node(str(id)).queue_free()

func display_info(text):
	var debug_node = Label.new()
	add_child(debug_node)
	debug_node.text = text
	debug_node.set("custom_colors/font_color", Color(0,0.5,0))
	yield(get_tree().create_timer(3), "timeout")
	debug_node.queue_free()
