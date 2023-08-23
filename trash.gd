extends Node2D

var index = 0
var itemList : ItemList
@onready var manual : Control = $/root/Main/ManualMode

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var parentCenter = itemList.get_item_rect(index).get_center()
	set_position(Vector2(parentCenter.x + 470, parentCenter.y))

func set_index(listEntry):
	index = listEntry
	
func set_itemList(itemListEntry):
	itemList = itemListEntry

func _on_button_button_down():
	itemList.remove_item(index)
	manual.remove_item(index)
	queue_free()
