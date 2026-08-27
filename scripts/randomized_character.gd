extends CharacterBody3D

const SPEED = 2.0
const ROTATION_SPEED = 5.0

const STUCK_CHECK_TIME = 1.5
const STUCK_DISTANCE_THRESHOLD = 0.05
const RANDOM_ESCAPE_TIME = 1.0
const RANDOM_ESCAPE_SPEED = 2.0

@export var is_seated := false
@export var character_models: Array[PackedScene] = []

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var seat_detection: Area3D = $SeatDetection
@onready var model_container: Node3D = $Model

var direction := Vector3.ZERO
var direction_timer := 0.0
var target_seat: Area3D = null

# Detección de atasco
var stuck_timer := 0.0
var last_stuck_position := Vector3.ZERO

# Escape
var escape_timer := 0.0
var escape_direction := Vector3.ZERO


func _ready() -> void:
	_randomize_model()

	animation_tree.active = true

	seat_detection.area_entered.connect(
		_on_seat_detection_area_entered
	)

	last_stuck_position = global_position


func _randomize_model() -> void:
	if character_models.is_empty():
		push_warning("No hay modelos configurados")
		return

	var model_scene = character_models.pick_random()
	var model = model_scene.instantiate()

	model_container.add_child(model)

	var animation_player := model.find_child(
		"AnimationPlayer",
		true,
		false
	) as AnimationPlayer

	if animation_player == null:
		push_warning("No se encontró AnimationPlayer en el modelo")
		return

	print("AnimationPlayer path: ", animation_player.get_path())

	animation_tree.anim_player = animation_player.get_path()
	animation_tree.active = true


func _physics_process(delta: float) -> void:
	# Gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Sentado
	if is_seated:
		_stop_movement()
		_set_seated_animation()
		move_and_slide()
		return

	# Escape de atasco
	if escape_timer > 0.0:
		_escape_movement(delta)
		move_and_slide()
		return

	# Ir hacia el asiento
	if target_seat != null:
		_move_to_seat(delta)
		move_and_slide()
		_check_if_stuck(delta)
		return

	# Movimiento random
	_random_movement(delta)

	move_and_slide()


func assign_seat(seat: Area3D) -> void:
	target_seat = seat

	stuck_timer = 0.0
	last_stuck_position = global_position


func _move_to_seat(delta: float) -> void:
	var target_position := target_seat.global_position

	var direction_to_seat := (
		target_position - global_position
	)

	direction_to_seat.y = 0

	if direction_to_seat.length() > 0.001:
		direction_to_seat = direction_to_seat.normalized()

	direction = direction_to_seat

	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED

	# Rotar hacia el asiento
	if direction != Vector3.ZERO:
		var target_rotation := atan2(
			direction.x,
			direction.z
		)

		rotation.y = lerp_angle(
			rotation.y,
			target_rotation,
			ROTATION_SPEED * delta
		)

	_set_walk_animation()


func _check_if_stuck(delta: float) -> void:
	# Si no está intentando moverse, no puede estar atascado
	if Vector2(velocity.x, velocity.z).length() < 0.1:
		stuck_timer = 0.0
		print(global_position)
		last_stuck_position = global_position
		_start_escape_movement()
		return

	var current_position := global_position

	var distance_moved := Vector2(
		current_position.x - last_stuck_position.x,
		current_position.z - last_stuck_position.z
	).length()

	# Si se está moviendo normalmente, reiniciamos el contador
	if distance_moved >= STUCK_DISTANCE_THRESHOLD:
		stuck_timer = 0.0
		last_stuck_position = current_position
		return

	# No se ha movido lo suficiente
	stuck_timer += delta

	# Está realmente atascado
	if stuck_timer >= STUCK_CHECK_TIME:
		_start_escape_movement()


func _start_escape_movement() -> void:
	print("Customer atascado. Intentando escapar...")

	stuck_timer = 0.0
	last_stuck_position = global_position

	escape_timer = RANDOM_ESCAPE_TIME

	var random_angle := randf_range(0.0, TAU)

	escape_direction = Vector3(
		cos(random_angle),
		0,
		sin(random_angle)
	).normalized()


func _escape_movement(delta: float) -> void:
	escape_timer -= delta

	velocity.x = escape_direction.x * RANDOM_ESCAPE_SPEED
	velocity.z = escape_direction.z * RANDOM_ESCAPE_SPEED

	# Rotar hacia la dirección de escape
	var target_rotation := atan2(
		escape_direction.x,
		escape_direction.z
	)

	rotation.y = lerp_angle(
		rotation.y,
		target_rotation,
		ROTATION_SPEED * delta
	)

	_set_walk_animation()

	if escape_timer <= 0.0:
		stuck_timer = 0.0
		last_stuck_position = global_position

		print("Customer vuelve a intentar llegar al asiento")


func _on_seat_detection_area_entered(area: Area3D) -> void:
	if area != target_seat:
		return

	_reach_seat()


func _reach_seat() -> void:
	velocity = Vector3.ZERO

	var seat = target_seat

	var seating_point: Marker3D = seat.seating_point
	var looking_point: Marker3D = seat.looking_point

	global_position = seating_point.global_position

	var look_direction := (
		looking_point.global_position - global_position
	)

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
		var target_rotation := atan2(
			direction.x,
			direction.z
		)

		rotation.y = lerp_angle(
			rotation.y,
			target_rotation,
			ROTATION_SPEED * delta
		)

	_set_walk_animation() if direction != Vector3.ZERO else _set_idle_animation()


func _stop_movement() -> void:
	velocity.x = 0
	velocity.z = 0


func _set_walk_animation() -> void:
	animation_tree.set(
		"parameters/WALK/blend_amount",
		1.0
	)

	animation_tree.set(
		"parameters/SEAT/blend_amount",
		0.0
	)


func _set_idle_animation() -> void:
	animation_tree.set(
		"parameters/WALK/blend_amount",
		0.0
	)

	animation_tree.set(
		"parameters/SEAT/blend_amount",
		0.0
	)


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

	if randf() < 0.25:
		direction = Vector3.ZERO
		return

	var random_angle := randf_range(0.0, TAU)

	direction = Vector3(
		cos(random_angle),
		0,
		sin(random_angle)
	).normalized()
