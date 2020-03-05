extends Node

const SERVER_PORT = 4242

var map_scene = "res://scenes/Map.tscn"
var player_scene = "res://scenes/Player.tscn"

var spawner_node = null


# Lobby buttons ================================================================

func create_server(max_players):
	if max_players < 1:
		max_players = 1
	
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, max_players)
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
	spawner_node = get_tree().get_root().find_node("Spawner", true, false)

	# If this is not the host, spawn the player locally
	if not get_tree().is_network_server():
		spawn_player( get_tree().get_network_unique_id() )

	# Other players and host will receive a signal to spawn you
	get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_network_peer_disconnected")

func spawn_player(id):
	var player_instance = load(player_scene).instance()
	player_instance.name = str(id)
	
	if spawner_node != null:
		spawner_node.add_child(player_instance)
	else:
		print("Error: Spawner node missing in the map!")

# Remote =======================================================================

# If a client id emitted the signal of connecting spawn the player remotely:
func _on_network_peer_connected(id):
	if id != 1:
		spawn_player(id)

# If a client id emitted the signal of deconnecting remove the player remotely:
func _on_network_peer_disconnected(id):
	if spawner_node.has_node(str(id)):
		spawner_node.get_node(str(id)).queue_free()