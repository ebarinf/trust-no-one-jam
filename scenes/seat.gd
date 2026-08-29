extends Area3D

@export var looking_point: Marker3D
@export var seating_point: Marker3D
@export var table: StaticBody3D

func _ready() -> void:
	looking_point = $"../LookingPoint"
	seating_point = $Marker3D
	table = $".."
	pass 
