extends CharacterBody3D

const SPEED = 2.0
const ROTATION_SPEED = 5.0

@export var is_seated := false

@onready var animation_tree: AnimationTree = $"fat-man-b-1/AnimationTree"
@onready var seat_detection: Area3D = $SeatDetection

var direction := Vector3.ZERO
var direction_timer := 0.0
var target_seat: Area3D = null


func _ready() -> void:
	animation_tree.active = true

	seat_detection.area_entered.connect(_on_seat_detection_area_entered)


func _physics_process(delta: float) -> void:
	# Gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Si está sentado
	if is_seated:
		_stop_movement()
		_set_seated_animation()
		move_and_slide()
		return

	# Si tiene un asiento asignado, ir hacia él
	if target_seat != null:
		_move_to_seat(delta)
		move_and_slide()
		return

	# Si no tiene asiento, movimiento random
	_random_movement(delta)

	move_and_slide()


func assign_seat(seat: Area3D) -> void:
	target_seat = seat


func _move_to_seat(delta: float) -> void:
	var target_position := target_seat.global_position

	var direction_to_seat := global_position.direction_to(target_position)
	direction_to_seat.y = 0
	direction_to_seat = direction_to_seat.normalized()

	direction = direction_to_seat

	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED

	# Rotar hacia el asiento
	if direction != Vector3.ZERO:
		var target_rotation := atan2(direction.x, direction.z)

		rotation.y = lerp_angle(
			rotation.y,
			target_rotation,
			ROTATION_SPEED * delta
		)

	# WALK
	animation_tree.set(
		"parameters/WALK/blend_amount",
		1.0
	)

	animation_tree.set(
		"parameters/SEAT/blend_amount",
		0.0
	)


func _on_seat_detection_area_entered(area: Area3D) -> void:
	# Solo reaccionar al asiento asignado
	if area != target_seat:
		return

	_reach_seat()


func _reach_seat() -> void:
	velocity = Vector3.ZERO

	# Obtener los puntos del asiento
	var seat = target_seat

	var seating_point: Marker3D = seat.seating_point
	var looking_point: Marker3D = seat.looking_point

	# Posicionarse exactamente en el punto donde debe sentarse
	global_position = seating_point.global_position

	# Mirar hacia el looking point
	var look_direction := looking_point.global_position - global_position
	look_direction.y = 0

	if look_direction.length() > 0.001:
		look_direction = look_direction.normalized()

		rotation.y = atan2(
			look_direction.x,
			look_direction.z
		)

	is_seated = true

	_set_seated_animation()

	print("Customer sentado en: ", target_seat.name)


func _random_movement(delta: float) -> void:
	direction_timer -= delta

	if direction_timer <= 0.0:
		_set_random_direction()

	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED

	if direction != Vector3.ZERO:
		var target_rotation := atan2(direction.x, direction.z)

		rotation.y = lerp_angle(
			rotation.y,
			target_rotation,
			ROTATION_SPEED * delta
		)

	animation_tree.set(
		"parameters/WALK/blend_amount",
		1.0 if direction != Vector3.ZERO else 0.0
	)

	animation_tree.set(
		"parameters/SEAT/blend_amount",
		0.0
	)


func _stop_movement() -> void:
	velocity.x = 0
	velocity.z = 0


func _set_seated_animation() -> void:
	animation_tree.set(
		"parameters/WALK/blend_amount",
		0.0
	)

	animation_tree.set(
		"parameters/SEAT/blend_amount",
		1.0
	)


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
