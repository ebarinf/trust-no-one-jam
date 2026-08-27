extends CanvasLayer

@export var recipe_builder: RecipeBuilder
@export var recipe_label: Label

func _ready():
	recipe_label.text = recipe_builder.get_recipe_display_text()
	recipe_builder.recipe_submitted.connect(_on_recipe_submitted)
	recipe_builder.new_recipe.connect(_on_new_recipe)

func _on_recipe_submitted(is_correct: bool):
	if is_correct:
		recipe_label.text = "Thank you!"
	else:
		recipe_label.text = "This is not my drink! >:C"

func _on_new_recipe(display_text: String):
	recipe_label.text = display_text
