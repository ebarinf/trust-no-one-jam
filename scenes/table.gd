extends StaticBody3D

@export var areas: Array[Area3D] = []

@export var unused_areas: Array[Area3D] = []
var used_areas: Array[Area3D] = []


func _ready() -> void:
	unused_areas = areas.duplicate()

	for area in areas:
		area.body_entered.connect(_on_area_body_entered.bind(area))
		area.body_exited.connect(_on_area_body_exited.bind(area))


func _on_area_body_entered(body: Node3D, area: Area3D) -> void:
	if not body.is_in_group("npc"):
		return

	if area not in unused_areas:
		return

	unused_areas.erase(area)
	used_areas.append(area)

	print("Asiento ocupado: ", area.name)


func _on_area_body_exited(body: Node3D, area: Area3D) -> void:
	if not body.is_in_group("npc"):
		return

	if area not in used_areas:
		return

	used_areas.erase(area)
	unused_areas.append(area)

	print("Asiento liberado: ", area.name)
