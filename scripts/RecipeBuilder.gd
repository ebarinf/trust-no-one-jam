extends Node
class_name RecipeBuilder

var target_recipe: Array[String] = ["whisky", "rum", "rum", "whisky"]
var current_recipe: Array[String] = []

func add_ingredient(ingredient_name: String):
	current_recipe.append(ingredient_name)
	print("Ingrediente agregado: ", ingredient_name, " -> ", current_recipe)

func submit_recipe():
	print("Receta actual: ", current_recipe)
	print("Receta objetivo: ", target_recipe)
	if current_recipe == target_recipe:
		print("¡RECETA CORRECTA!")
	else:
		print("Receta incorrecta.")
	current_recipe.clear()
