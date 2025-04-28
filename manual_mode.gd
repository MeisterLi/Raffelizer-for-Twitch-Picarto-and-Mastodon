extends Control

@onready var filePicker : FileDialog = $BrowseDialog
@onready var itemList = $VBoxContainer/ScrollContainer/ItemList
@onready var previewSprite : TextureRect = $VBoxContainer/HBoxContainer2/PreviewSprite
@onready var entry : LineEdit = $VBoxContainer/HBoxContainer2/LineEdit
@onready var gameField = $/root/Main/GameField
@onready var settings_node : settings = $/root/Main/Settings
@onready var main = $/root/Main
@export var items : PackedScene
var list_entries = []
var list_entries_json = []
var current_path

func _ready():
	pass
	
func reset():
	list_entries.clear()
	list_entries_json.clear()
	
func remove_item(index):
	for list_entry in list_entries:
		if list_entry[2] == index:
			list_entries.erase(list_entry)

func _on_file_dialog_file_selected(path):
	var image = Image.new()
	var image_error = image.load(path)
	current_path = path
	if image_error == OK:
		image.resize(64,64,Image.INTERPOLATE_LANCZOS)
		var texture = ImageTexture.create_from_image(image)
		previewSprite.set_texture(texture)

func _on_browse_button_button_down():
	filePicker.show()

func _on_add_button_button_down():
	if entry.get_text() != "":
		add_item(entry.get_text(), previewSprite.get_texture(), current_path)

func add_item(new_entry, new_sprite, new_path):
	var item = items.instantiate()
	itemList.add_child(item)
	item.set_image(new_sprite)
	item.set_label(new_entry)
	item.set_path(new_path)

func _on_start_button_button_down():
	hide()
	gameField.count_down.start()
	var item_list_entries = itemList.get_children()
	for child in item_list_entries:
		list_entries.append(child.get_data())
	for list_entry in list_entries:
		var image = Image.new()
		var image_error = image.load(list_entry[1])
		if image_error == OK:
			image.resize(64,64,Image.INTERPOLATE_LANCZOS)
		var image_texture = ImageTexture.create_from_image(image)
		gameField.spawn_avatar(list_entry[0], "", "", "", image_texture)
	var item_list_children = itemList.get_children()
	for child in item_list_children:
		child.queue_free()
	

func _on_save_button_pressed():
	$SaveDialog.show()


func _on_save_dialog_file_selected(path):
	var item_list_entries = itemList.get_children()
	for child in item_list_entries:
		list_entries_json.append(child.get_data())
	var json = JSON.stringify(list_entries_json)
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(json)
	file.close()

func _on_load_button_pressed():
	$LoadDialog.show()


func _on_load_dialog_file_selected(path):
	reset()
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(text)
	if error == OK:
		for list_entry in json.data:
			var image = Image.new()
			var image_error = image.load(list_entry[1])
			current_path = list_entry[1]
			if image_error == OK:
				image.resize(64,64,Image.INTERPOLATE_LANCZOS)
			var texture = ImageTexture.create_from_image(image)
			add_item(list_entry[0], texture, list_entry[1])

func _on_exit_pressed():
	settings_node._change_to_state(settings.states.SELECT_MODE)
	hide()
