# main menu handling
extends Node2D


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu_select_lv/select_lv/select_world.tscn")

func _on_button_3_pressed() -> void:
	get_tree().quit()

func _on_button_2_pressed() -> void:
	pass # Options menu
