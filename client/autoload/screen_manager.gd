extends Node
## Loads and switches between application screens.
##
## Reads [constant SCREENS_FOLDER_PATH] for screen scenes on initialization
## and stores them in [member screens_dict]. Use [method change_screen] to
## transition between screens.
## [br][br]
## [b]Autoload:[/b] Access this singleton globally via [code]ScreenManager[/code]. [br][br]
##
## [b]Adding New Screens:[/b] [br]
## 1. Create [code]screens/{feature}/[/code] folder [br]
## 2. Add [code]{feature}_screen.tscn[/code] (instance [code]base_screen_template.tscn[/code] as root) [br]
## 3. Add [code]{feature}_screen_manager.gd[/code] extending [code]BaseScreenTemplateManager[/code] [br]
## 4. Add enum value to [enum Screen] [br]
## 5. Add match case in [method change_screen] mapping the enum to [code]"{feature}_screen"[/code] [br][br]
##
## [b]Adding New Popups:[/b] [br]
## 1. Create [code]components/popups/{feature}/[/code] folder [br]
## 2. Add [code]{feature}_popup.tscn[/code] (instance [code]base_popup_template.tscn[/code] as root) [br]
## 3. Add [code]{feature}_popup.gd[/code] with your popup logic [br]

## Available screens in the application.
enum Screen {
	## The landing screen where users select their language.
	LANGUAGE_SELECTION_SCREEN,
	## The login screen where users enter access codes.
	LOGIN_SCREEN,
	## The name entry screen where user writes their name.
	NAME_ENTRY_SCREEN,
	## The home screen displayed after successful login.
	HOME_SCREEN,
	## The add work entry screen where users can add work entries.
	ADD_WORK_ENTRY_SCREEN,
	## The wages screen where users enter hourly wage, tax, and personal allowance.
	WAGES_SCREEN,
	## The salary screen showing calculated payslip (lønseddel).
	SALARY_SCREEN,
	## The settings screen for language, theme, and other preferences.
	SETTINGS_SCREEN,

}


## The folder path containing all screen subdirectories.
const SCREENS_FOLDER_PATH: String = "res://screens/"

## The node path to the UI container that holds the active screen.
const UI_NODE_PATH: String = "/root/Main/UI"


## Maps screen names to their scene file paths.
## [br][br]
## Keys use the format [code]"folder_name_screen"[/code] (e.g., [code]"login_screen"[/code]).[br]
## Values contain the full resource path to the [code].tscn[/code] file.
var screens_dict: Dictionary = {}


## Calls [method _load_screens_from_folder] to load all screen scenes from the [constant SCREENS_FOLDER_PATH] folder.
func _init() -> void:
	_load_screens_from_folder(SCREENS_FOLDER_PATH)


## Reads a folder for screen scenes and populates [member screens_dict].
##
## Loops through subdirectories in [param folder_path] and searches for
## [code].tscn[/code] files matching the pattern [code]folder_name_screen.tscn[/code].
## [br][br]
## For example, [code]res://screens/login/[/code] loads [code]login_screen.tscn[/code].
func _load_screens_from_folder(folder_path: String) -> void:
	var dir: DirAccess = DirAccess.open(folder_path)

	if dir != null:
		# Start reading files from the folder
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		
		# Iterate through all items in the folder
		while file_name != "":
			
			# Only process directories (skip individual files)
			if dir.current_is_dir():
				
				# Build the full path to this screen directory
				var full_path: String = folder_path.path_join(file_name)

				# Construct the expected scene file name: "folder_name_screen.tscn"
				# E.g., "login" directory -> "login_screen.tscn"
				var scene_path: String = full_path.path_join(file_name + "_screen.tscn")
				
				# Check if the scene file exists in this directory
				if ResourceLoader.exists(scene_path):
					# Add the scene to our screens dictionary
					# Key: "folder_name_screen" (e.g., "login_screen")
					# Value: full path to the scene file
					screens_dict[file_name + "_screen"] = scene_path
					print("[ScreenManager] Loaded screen: %s -> %s" % [file_name + "_screen.tscn", scene_path])
			
			# Move to the next file/folder in the directory
			file_name = dir.get_next()
	
	else:
		push_error("[ScreenManager] Open directory failed: %s\n[ScreenManager] Error: %s - %s" % [folder_path, DirAccess.get_open_error(), error_string(DirAccess.get_open_error())])


## Transitions to a different screen. [br][br]
##
## Removes the current screen from the UI node and instantiates the
## screen specified by [param screen]. The new screen becomes a child
## of the node at [constant UI_NODE_PATH]. If [param metadata] is provided
## and the new screen has [method set_edit_data], it is called with [param metadata]
## before the screen is added to the tree.
func change_screen(screen: Screen, metadata: Variant = null) -> void:
	# Get UI node
	var ui_node: CanvasLayer = get_node_or_null(UI_NODE_PATH)

	# Check if UI node exists
	if ui_node == null:
		push_error("[ScreenManager] UI node not found")
		return
	
	# Get current screen
	var current_screen: Node = ui_node.get_child(0)

	# Determine screen name based on enum
	var screen_name: String = ""
	match screen:
		Screen.LANGUAGE_SELECTION_SCREEN:
			screen_name = "language_selection_screen"
		Screen.LOGIN_SCREEN:
			screen_name = "login_screen"
		Screen.NAME_ENTRY_SCREEN:
			screen_name = "name_entry_screen"
		Screen.HOME_SCREEN:
			screen_name = "home_screen"
		Screen.ADD_WORK_ENTRY_SCREEN:
			screen_name = "add_work_entry_screen"
		Screen.WAGES_SCREEN:
			screen_name = "wages_screen"
		Screen.SALARY_SCREEN:
			screen_name = "salary_screen"
		Screen.SETTINGS_SCREEN:
			screen_name = "settings_screen"
		_:
			push_error("[ScreenManager] Invalid screen enum: %s" % screen)
			return

	# Check if requested screen exists
	if screens_dict.has(screen_name):
		# Remove current screen
		current_screen.queue_free()
		# Load new screen
		var new_screen: Node = load(screens_dict[screen_name]).instantiate()
		if metadata != null and new_screen.has_method("set_edit_data"):
			new_screen.set_edit_data(metadata)
		ThemeManager.apply_to_screen(new_screen)
		# Add new screen
		ui_node.add_child(new_screen)
