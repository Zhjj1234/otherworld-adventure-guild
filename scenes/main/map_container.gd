extends Node2D

class_name MapContainer

signal map_container_registered(map_container: MapContainer)

func _ready() -> void:
	map_container_registered.connect(MapLoaderManager.on_map_container_registered)
	map_container_registered.emit(self)

func _exit_tree() -> void:
	map_container_registered.disconnect(MapLoaderManager.on_map_container_registered)
