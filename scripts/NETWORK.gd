extends Node

const SERVER_PORT = 4242
const MAX_PLAYERS = 32

var map_scene = "res://scenes/Map.tscn"
var player_scene = "res://scenes/Player.tscn"
var lobby_scene = "res://scenes/Lobby.tscn"

var spawn_node = null # It will search for the spawn node after loading the game to add the player

# Signals emitted by others connecting or already connected ====================
# Those signals allow to spawn and despawn you on other players' game
func _ready():
	get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_network_peer_disconnected")
	get_tree().connect("server_disconnected", self, "leave_game")

# Lobby buttons, connected from Lobby.gd =======================================

func create_server():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)
	
	load_game()
	
func join_server(SERVER_IP):
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(SERVER_IP, SERVER_PORT)
	get_tree().set_network_peer(peer)
	
	load_game()

# Enter the game ===============================================================

func load_game():
	get_tree().change_scene(map_scene)

	# Wait for the map to load, then search for the Spawn node
	yield(get_tree().create_timer(0.01), "timeout")
	spawn_node = get_tree().get_root().find_node("Spawn", true, false)

	if spawn_node != null: # If we have a spawn node in the map
		
		# If this is not the host, spawn the player locally, remove this condition and the signal condition if the host plays too
		if not get_tree().is_network_server():
			spawn_player( get_tree().get_network_unique_id() )
	
		# Other players and host will receive a signal to spawn you

	else:
		DEBUG.display_info("Error: Spawn node missing in the map, can't spawn Players!", "error")

# Spawn the player locally after loading the game and remotely from a signal ===

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
	if id != 1: # Do not spawn from the signal of the host connected (id = 1) because he has no player to control
		spawn_player(id)
	
	DEBUG.display_info("+ " + str(id) + " has connected!", "")
	DEBUG.display_info("= Total connected: " + str( get_tree().get_network_connected_peers().size() ), "")

# If a client id emitted the signal of disconnecting, remove the player remotely
func _on_network_peer_disconnected(id):
	spawn_node.get_node(str(id)).queue_free()
	
	DEBUG.display_info("- " + str(id) + " has left!", "")
	DEBUG.display_info("= Total connected: " + str( get_tree().get_network_connected_peers().size() ), "")
