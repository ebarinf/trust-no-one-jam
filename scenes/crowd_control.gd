extends Node3D

@export var customer_scene: PackedScene

@onready var customer_spawn: Marker3D = $CustomerSpawner

var tables: Array[StaticBody3D] = []
var unused_seats: Array[Area3D] = []


func _ready() -> void:
	_get_tables()
	_update_unused_seats()

	spawn_customer()


func _get_tables() -> void:
	for i in range(1, 7):
		var table := get_node_or_null("Table" + str(i))

		if table is StaticBody3D:
			tables.append(table)
		else:
			push_warning("No se encontró Table" + str(i))


func _update_unused_seats() -> void:
	unused_seats.clear()

	for table in tables:
		unused_seats.append_array(table.unused_areas)


func spawn_customer() -> void:
	if customer_scene == null:
		push_warning("Customer scene no está asignada")
		return

	if unused_seats.is_empty():
		print("No hay asientos disponibles")
		return

	var customer = customer_scene.instantiate()

	add_child(customer)

	customer.global_transform = customer_spawn.global_transform

	customer.assign_seat(unused_seats.pick_random())
