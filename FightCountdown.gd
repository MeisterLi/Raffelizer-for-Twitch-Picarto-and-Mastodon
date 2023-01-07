extends Timer

@onready var label : Label = $/root/Main/MainUi/CountDownLabel
@onready var word_label : Label = $/root/Main/MainUi/RaffleWordLabel
var started = false

func _process(_delta):
	if !is_stopped():
		word_label.hide()
		label.show()
		started = true
		if int(time_left) == 0:
			label.text = "Fight!"
		else:
			label.text = str(int(time_left))
		
	if time_left == 0.0 && started:
		label.hide()
