extends Label

func set_error(new_text):
	set_text(new_text)
	$ErrorTime.start(3)

func _on_error_time_timeout():
	set_text("")
