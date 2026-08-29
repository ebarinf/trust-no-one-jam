extends CharacterBody3D

const SPEED = 2.0
const ROTATION_SPEED = 5.0

const STUCK_CHECK_TIME = 0.2
const STUCK_DISTANCE_THRESHOLD = 0.05
const RANDOM_ESCAPE_TIME = 1.0
const RANDOM_ESCAPE_SPEED = 2.0


enum CharacterStatus {
	VICTIM,
	PERPETRATOR
}


@export var is_seated := false


@export_category("Character")
@export var character_models: Array[PackedScene] = []
@export var character_textures: Array[Texture2D] = []


@export_category("Drink")
@export var drink_min_time := 3.0
@export var drink_max_time := 8.0


@export_category("Suspicious")
@export var sus_min_time := 20.0
@export var sus_max_time := 45.0


@onready var animation_tree: AnimationTree = $AnimationTree
@onready var seat_detection: Area3D = $SeatDetection
@onready var model_container: Node3D = $Model


var status: CharacterStatus

var direction := Vector3.ZERO
var direction_timer := 0.0
var target_seat: Area3D = null


# Stuck detection
var stuck_timer := 0.0
var last_stuck_position := Vector3.ZERO


# Escape
var escape_timer := 0.0
var escape_direction := Vector3.ZERO


# Drink
var drink_timer := 0.0


# Sus
var sus_timer := 0.0


func _ready() -> void:

	_randomize_status()

	_randomize_model()

	animation_tree.active = true

	seat_detection.area_entered.connect(
		_on_seat_detection_area_entered
	)

	last_stuck_position = global_position

	_reset_drink_timer()
	_reset_sus_timer()


# ============================================================
# CHARACTER STATUS
# ============================================================

func _randomize_status() -> void:

	status = CharacterStatus.values().pick_random()

	print(
		"Customer status: ",
		CharacterStatus.keys()[status]
	)


# ============================================================
# MODEL
# ============================================================

func _randomize_model() -> void:

	if character_models.is_empty():
		push_warning("No character models configured")
		return

	var model_scene = null

	if status == CharacterStatus.VICTIM:

		model_scene = character_models.pick_random()

	else:

		model_scene = character_models.get(0)

		print("IS_PERPETRATOR!!")

	var model: Node = model_scene.instantiate()

	model_container.add_child(model)


	# --------------------------------------------------------
	# AnimationPlayer
	# --------------------------------------------------------

	var animation_player := model.find_child(
		"AnimationPlayer",
		true,
		false
	) as AnimationPlayer

	if animation_player == null:

		push_warning(
			"No AnimationPlayer found in model: "
			+ model.name
		)

	else:

		print(
			"AnimationPlayer path: ",
			animation_player.get_path()
		)

		animation_tree.anim_player = animation_player.get_path()
		animation_tree.active = true


	# --------------------------------------------------------
	# Random texture
	# --------------------------------------------------------

	_randomize_texture(model)


func _randomize_texture(model: Node) -> void:

	if character_textures.is_empty():
		push_warning("No character textures configured")
		return

	var texture: Texture2D = null

	if status == CharacterStatus.VICTIM:

		texture = character_textures.pick_random()

	else:

		texture = character_textures.get(0)


	var mesh_instances := model.find_children(
		"*",
		"MeshInstance3D",
		true,
		false
	)


	for mesh_node in mesh_instances:

		var mesh_instance := mesh_node as MeshInstance3D

		if mesh_instance == null:
			continue

		if mesh_instance.mesh == null:
			continue


		var surface_count := mesh_instance.mesh.get_surface_count()


		for surface_index in range(surface_count):

			var material := mesh_instance.get_active_material(
				surface_index
			)

			if material == null:
				continue


			var new_material := material.duplicate()


			if new_material is StandardMaterial3D:

				new_material.albedo_texture = texture

				mesh_instance.set_surface_override_material(
					surface_index,
					new_material
				)


# ============================================================
# PHYSICS / MOVEMENT
# ============================================================

func _physics_process(delta: float) -> void:

	# Gravity
	if not is_on_floor():

		velocity += get_gravity() * delta


	# --------------------------------------------------------
	# Seated
	# --------------------------------------------------------

	if is_seated:

		_stop_movement()

		_set_seated_animation()

		_update_drink(delta)
		_update_sus(delta)

		move_and_slide()

		return


	# --------------------------------------------------------
	# Escape
	# --------------------------------------------------------

	if escape_timer > 0.0:

		_escape_movement(delta)

		move_and_slide()

		return


	# --------------------------------------------------------
	# Go to seat
	# --------------------------------------------------------

	if target_seat != null:

		_move_to_seat(delta)

		move_and_slide()

		_check_if_stuck(delta)

		return


	# --------------------------------------------------------
	# Random movement
	# --------------------------------------------------------

	_random_movement(delta)

	move_and_slide()


# ============================================================
# SEAT
# ============================================================

func assign_seat(seat: Area3D) -> void:

	target_seat = seat

	stuck_timer = 0.0
	last_stuck_position = global_position

	print(
		"Customer assigned to seat: ",
		seat.name
	)


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


	# Rotate towards seat
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


func _on_seat_detection_area_entered(area: Area3D) -> void:

	if area != target_seat:
		return

	_reach_seat()


func _reach_seat() -> void:

	velocity = Vector3.ZERO

	var seat := target_seat

	var seating_point: Marker3D = seat.seating_point
	var looking_point: Marker3D = seat.looking_point


	# Position exactly at seating point
	global_position = seating_point.global_position


	# Look towards looking point
	var look_direction := (
		looking_point.global_position
		- global_position
	)

	look_direction.y = 0


	if look_direction.length() > 0.001:

		look_direction = look_direction.normalized()

		rotation.y = atan2(
			look_direction.x,
			look_direction.z
		)


	is_seated = true

	_reset_drink_timer()
	_reset_sus_timer()

	_set_seated_animation()


	print(
		"Customer seated at: ",
		target_seat.name
	)


# ============================================================
# DRINK
# ============================================================

func _reset_drink_timer() -> void:

	drink_timer = randf_range(
		drink_min_time,
		drink_max_time
	)


func _update_drink(delta: float) -> void:

	drink_timer -= delta

	if drink_timer > 0.0:
		return

	_play_drink_animation()

	_reset_drink_timer()


func _play_drink_animation() -> void:

	animation_tree.set(
		"parameters/DRINK/request",
		AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	)

	print("Customer is drinking")


# ============================================================
# SUS
# ============================================================

func _reset_sus_timer() -> void:

	sus_timer = randf_range(
		sus_min_time,
		sus_max_time
	)


func _update_sus(delta: float) -> void:

	sus_timer -= delta

	if sus_timer > 0.0:
		return

	_play_sus_animation()

	_reset_sus_timer()


func _play_sus_animation() -> void:

	animation_tree.set(
		"parameters/SUS/request",
		AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	)

	print("Customer is acting suspicious")


# ============================================================
# STUCK DETECTION
# ============================================================

func _check_if_stuck(delta: float) -> void:

	var current_position := global_position

	var distance_moved := Vector2(
		current_position.x - last_stuck_position.x,
		current_position.z - last_stuck_position.z
	).length()


	if distance_moved >= STUCK_DISTANCE_THRESHOLD:

		stuck_timer = 0.0

		last_stuck_position = current_position

		return


	stuck_timer += delta


	if stuck_timer >= STUCK_CHECK_TIME:

		_start_escape_movement()


func _start_escape_movement() -> void:

	print(
		"Customer stuck. Trying to escape..."
	)

	stuck_timer = 0.0

	last_stuck_position = global_position

	escape_timer = RANDOM_ESCAPE_TIME


	var random_angle := randf_range(
		0.0,
		TAU
	)


	escape_direction = Vector3(
		cos(random_angle),
		0,
		sin(random_angle)
	).normalized()


func _escape_movement(delta: float) -> void:

	escape_timer -= delta


	velocity.x = (
		escape_direction.x
		* RANDOM_ESCAPE_SPEED
	)

	velocity.z = (
		escape_direction.z
		* RANDOM_ESCAPE_SPEED
	)


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

		print(
			"Customer trying to reach the seat again"
		)


# ============================================================
# RANDOM MOVEMENT
# ============================================================

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


		_set_walk_animation()

	else:

		_set_idle_animation()


# ============================================================
# ANIMATION
# ============================================================

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


func _stop_movement() -> void:

	velocity.x = 0
	velocity.z = 0


# ============================================================
# RANDOM DIRECTION
# ============================================================

func _set_random_direction() -> void:

	direction_timer = randf_range(
		1.0,
		4.0
	)


	# 25% chance of staying still
	if randf() < 0.25:

		direction = Vector3.ZERO

		return


	var random_angle := randf_range(
		0.0,
		TAU
	)


	direction = Vector3(
		cos(random_angle),
		0,
		sin(random_angle)
	).normalized()
