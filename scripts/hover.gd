extends Camera3D

var current_hovered: Highlightable = null

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
		current_hovered = hit_highlightable
