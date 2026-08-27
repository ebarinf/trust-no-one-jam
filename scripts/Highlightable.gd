extends Node3D
class_name Highlightable

signal clicked(item: Highlightable)

@export var outline_material: ShaderMaterial
@onready var sfx_player: AudioStreamPlayer3D = $SFXPlayer
@export var item_type: String = "ingredient" 
@export var item_name: String = "" 

var _was_highlighted: bool = false
var _outline_instances: Array = []
var mesh_ref: MeshInstance3D = null

func _ready():
	_apply_outline_to_children(self)
	
func _apply_outline_to_children(node: Node):
	for child in node.get_children():
		if child is MeshInstance3D:
			if mesh_ref == null:
				mesh_ref = child
			for i in range(child.get_surface_override_material_count()):
				var mat = child.get_active_material(i)
				if mat:
					var mat_unique = mat.duplicate()
					mat_unique.next_pass = outline_material.duplicate()
					child.set_surface_override_material(i, mat_unique)
					_outline_instances.append(mat_unique.next_pass)
		_apply_outline_to_children(child)

func set_highlighted(is_highlighted: bool):
	for outline_pass in _outline_instances:
		outline_pass.set_shader_parameter("outline_enabled", 1.0 if is_highlighted else 0.0)
		
	if is_highlighted and not _was_highlighted:
		sfx_player.play()
	_was_highlighted = is_highlighted
	
func trigger_click():
	clicked.emit(self)
