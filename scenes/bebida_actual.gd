extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@export var glass_position: Marker3D
@export var whisky_glass_mesh: Mesh
@export var martini_glass_mesh: Mesh
@export var long_glass_mesh: Mesh

func _ready():
	visible = false

func handle_click(item: Highlightable):
	if item.item_type == "glass":
		match item.item_name:
			"whisky_glass":
				_set_glass(whisky_glass_mesh)
			"martini_glass":
				_set_glass(martini_glass_mesh)
			"long_glass":
				_set_glass(long_glass_mesh)
	elif item.item_type == "ingredient":
		pass

func _set_glass(glass_mesh: Mesh):
	mesh_instance.mesh = glass_mesh
	visible = true
	global_position = glass_position.global_position
