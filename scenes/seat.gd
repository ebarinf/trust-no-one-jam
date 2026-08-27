extends Area3D

@export var looking_point: Marker3D
@export var seating_point: Marker3D

func _ready() -> void:
	looking_point = $"../LookingPoint"
	seating_point = $Marker3D
	pass 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
