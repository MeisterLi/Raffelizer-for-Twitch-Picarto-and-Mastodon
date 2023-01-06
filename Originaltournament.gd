extends Sprite2D

func _init():
	load_png("user://battlefield.png")

func load_png(file):
	var png_file = FileAccess.open(file, FileAccess.READ)
	if FileAccess.file_exists(file):
		var img = Image.new()
		var err = img.load(file)
		if err != OK:
			print("Image load error")
		var newTexture = ImageTexture.create_from_image(img)
		texture = newTexture
