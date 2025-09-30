extends TextureRect

func _on_button_play_pressed() -> void:
	$AudioStreamPlayer.stop()
	get_tree().change_scene_to_file("res://screens/main_screen/MainScreen.tscn")


func _on_button_quit_pressed() -> void:
	get_tree().quit()
