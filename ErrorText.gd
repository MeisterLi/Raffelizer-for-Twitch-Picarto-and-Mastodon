extends Label

func set_error(text):
	set_text(text)
	$ErrorTime.start(3)

func _on_error_time_timeout():
	set_text("")
