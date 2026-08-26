extends CharacterBody3D

const SPEED = 2.0
const ROTATION_SPEED = 5.0

@onready var animation_tree: AnimationTree = $"fat-man-b-1/AnimationTree"

var direction := Vector3.ZERO
var direction_timer := 0.0


func _ready() -> void:
	animation_tree.active = true


func _physics_process(delta: float) -> void:
	# Gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Elegir nueva dirección
	direction_timer -= delta

	if direction_timer <= 0.0:
		_set_random_direction()

	# Movimiento
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED

	# Rotación
	if direction != Vector3.ZERO:
		var target_rotation := atan2(direction.x, direction.z)

		rotation.y = lerp_angle(
			rotation.y,
			target_rotation,
			ROTATION_SPEED * delta
		)

	# AnimationTree
	if direction != Vector3.ZERO:
		animation_tree.set(
			"parameters/WALK/blend_amount",
			1.0
		)
	else:
		animation_tree.set(
			"parameters/WALK/blend_amount",
			0.0
		)

	move_and_slide()


func _set_random_direction() -> void:
	direction_timer = randf_range(1.0, 4.0)

	# 25% de probabilidad de quedarse quieto
	if randf() < 0.25:
		direction = Vector3.ZERO
		return

	var random_angle := randf_range(0.0, TAU)

	direction = Vector3(
		cos(random_angle),
		0,
		sin(random_angle)
	).normalized()
