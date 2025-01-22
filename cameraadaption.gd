extends Camera2D

func _ready():
	# Example content size (replace with your desired dimensions)
	var content_width = 800
	var content_height = 600
	
	# Get the size of the current window or viewport
	var window_size = get_viewport().get_visible_rect().size
	
	# Calculate the maximum zoom factor that fits the content within the window
	var zoom_x = floor(window_size.x / content_width)
	var zoom_y = floor(window_size.y / content_height)
	
	# Use the smaller zoom factor to ensure the entire content fits
	var zoom_factor = min(zoom_x, zoom_y)
	
	# Set the camera's zoom
	zoom = Vector2(1.0 / zoom_factor, 1.0 / zoom_factor) if zoom_factor > 0 else Vector2(1, 1)
