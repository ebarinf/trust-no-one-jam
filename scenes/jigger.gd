extends Highlightable
class_name Jigger

var is_held: bool = false
var fixed_x: float = 0.0
var _rest_transform: Transform3D
@onready var hover_shape: CollisionShape3D = $HoverArea/CollisionShape3D

func _ready():
	super._ready()
	_rest_transform = global_transform
	fixed_x = global_position.x

func _process(_delta):
	if not is_held:
		return
	var cam = get_viewport().get_camera_3d()
	if not cam:
		return
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = cam.project_ray_origin(mouse_pos)
	var ray_dir = cam.project_ray_normal(mouse_pos)
	var denom = ray_dir.x
	if abs(denom) < 0.0001:
		return
	var t = (fixed_x - ray_origin.x) / denom
	if t <= 0:
		return
	var hit_point = ray_origin + ray_dir * t
	global_position = Vector3(fixed_x, hit_point.y, hit_point.z)

func pick_up():
	is_held = true
	fixed_x = global_position.x
	hover_shape.disabled = true

func put_down():
	is_held = false
	global_transform = _rest_transform
	hover_shape.disabled = false

func on_left_click():
	if not is_held:
		pick_up()
