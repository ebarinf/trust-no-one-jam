extends Camera3D

var current_hovered: Highlightable = null
@export var bebida_actual: Node3D
@export var jigger: Jigger
@export var recipe_builder: RecipeBuilder

func _process(_delta):
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = project_ray_origin(mouse_pos)
	var ray_dir = project_ray_normal(mouse_pos)
	var ray_end = ray_origin + ray_dir * 100.0

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var result = space_state.intersect_ray(query)

	var hit_highlightable: Highlightable = null
	if result:
		var collider = result.collider
		var node = collider
		while node and not (node is Highlightable):
			node = node.get_parent()
		if node is Highlightable:
			hit_highlightable = node

	if hit_highlightable != current_hovered:
		if current_hovered:
			current_hovered.set_highlighted(false)
		if hit_highlightable:
			hit_highlightable.set_highlighted(true)
			if not hit_highlightable.clicked.is_connected(_on_item_clicked):
				hit_highlightable.clicked.connect(_on_item_clicked)
		current_hovered = hit_highlightable

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if jigger.is_held and current_hovered and current_hovered.item_type == "coaster":
				jigger.put_down()
			elif jigger.is_held and current_hovered and current_hovered.item_type == "ingredient":
				recipe_builder.add_ingredient(current_hovered.item_name)
			elif current_hovered:
				current_hovered.on_left_click()
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		recipe_builder.submit_recipe()

func _on_item_clicked(item: Highlightable):
	bebida_actual.handle_click(item)
