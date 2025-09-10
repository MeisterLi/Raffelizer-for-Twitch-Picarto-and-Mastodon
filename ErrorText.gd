extends Label

func set_error(new_text: String, timeout : int):
	set_text(new_text)
	$ErrorTime.start(timeout)

func _on_error_time_timeout():
	set_text("")
