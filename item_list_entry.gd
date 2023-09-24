extends HBoxContainer
@onready var character_image : TextureRect = $CharacterImage
@onready var label : Label = $Label
var own_path

func set_image(texture : Texture2D):
	character_image.set_texture(texture)

func set_label(text):
	label.set_text(text)

func set_path(path):
	own_path = path

func _on_delete_button_pressed():
	queue_free()

func get_data():
	return [label.get_text(), own_path]
