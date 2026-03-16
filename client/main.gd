class_name Main
extends Node
## The application's main entry point.
##
## Adjusts the window on small displays and loads save data.

## Window size used when the display height is below [constant MIN_SCREEN_HEIGHT].
const WINDOW_SIZE: Vector2i = Vector2i(540, 960)

## Minimum screen height in pixels. Triggers resize when the primary monitor is smaller.
const MIN_SCREEN_HEIGHT: int = 1280


## Initializes the application.
##
## Resizes the window on small displays (if needed), then loads save data.
func _ready():
	_resize_and_center_window_if_needed()

	SaveData.load_save_data_from_file()


## Resizes and centers the window on displays like 1920×1080.
##
## On some setups the window extends past the top of the screen and hides the
## title bar and close button.[br]
## Shrinks the window to [constant WINDOW_SIZE] to fix that.[br]
## Optional for this project's setup. Safe to remove if not needed.
func _resize_and_center_window_if_needed() -> void:
	var primary_monitor_id: int = DisplayServer.get_primary_screen()
	var screen_size = DisplayServer.screen_get_size(primary_monitor_id)
	
	if screen_size.y < MIN_SCREEN_HEIGHT:
		DisplayServer.window_set_size(WINDOW_SIZE)
		_center_window_on_screen(screen_size)


## Positions the window at the center of the screen.
##
## Uses [param screen_size] and [constant WINDOW_SIZE] to compute the position.
func _center_window_on_screen(screen_size: Vector2i):
	# Calculate center_x differently to ensure the window is centered when using two monitors.
	# If calculated the same way as center_y, the window will not be centered correctly.
	var center_x: int = int((screen_size.x - WINDOW_SIZE.x) * 1.833)
	var center_y: int = int((screen_size.y - WINDOW_SIZE.y) / 2.0)
	DisplayServer.window_set_position(Vector2i(center_x, center_y))
