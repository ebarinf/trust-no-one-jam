extends Node
class_name RecipeBuilder

signal recipe_submitted(is_correct: bool)
signal new_recipe(display_text: String)

var recipes: Array = [
	["whisky", "rum", "rum", "whisky"],
	["rum", "rum"],
	["whisky", "whisky", "rum"],
]

var current_recipe_index: int = 0
var target_recipe: Array[String] = []
var current_recipe: Array[String] = []

func _ready():
	_load_current_recipe()

func _load_current_recipe():
	target_recipe.clear()
	for ingredient in recipes[current_recipe_index]:
		target_recipe.append(ingredient)
	current_recipe.clear()

func add_ingredient(ingredient_name: String):
	current_recipe.append(ingredient_name)

func submit_recipe():
	var is_correct = current_recipe == target_recipe
	recipe_submitted.emit(is_correct)
	current_recipe.clear()

	await get_tree().create_timer(2.0).timeout

	current_recipe_index = (current_recipe_index + 1) % recipes.size()
	_load_current_recipe()
	new_recipe.emit(get_recipe_display_text())

func get_recipe_display_text() -> String:
	return "Whisky glass\n" + ", ".join(target_recipe)
