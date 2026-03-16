class_name FileHandler
## Handles reading and writing files, primarily the save file.
##
## Provides static methods to persist dictionary data to a JSON file and to
## load it back. Uses [constant DEFAULT_STORAGE_ROOT_PATH], [constant SAVE_STORAGE_FOLDER_NAME],
## and [constant SAVE_FILE_NAME] to construct the save file path. Creates the
## save directory if it does not exist. [br][br]
##
## Because all methods are static, this class operates only on absolute paths
## (e.g. [code]user://[/code] or [code]res://[/code] Godot paths, or OS paths).


## Root path for user-persistent storage (Maps to the OS user data folder. 
## See [url]https://docs.godotengine.org/en/latest/tutorials/io/data_paths.html#accessing-persistent-user-data-user[/url]
## for more information).
const DEFAULT_STORAGE_ROOT_PATH: String = "user://"
## Name of the subfolder that holds the save file.
const SAVE_STORAGE_FOLDER_NAME: String = "save_data/"
## Name of the JSON save file.
const SAVE_FILE_NAME: String = "save_data.json"


## Writes [param save_data] to the save file as formatted JSON.
## Creates the save directory if needed.[br]
## Call [method load_data_from_json_file] to read the data back. [br][br]
##
## [b]Debug:[/b] Prints progress; pushes errors on failure.
static func save_data_to_json_file(save_data: Dictionary) -> void:
	print("[SAVE] Save start")

	var save_file = _open_file_for_write(_get_save_file_path())

	# If save file succesfully opened, store save data
	if typeof(save_file) == Variant.Type.TYPE_OBJECT: # If save file is successfully, then returns as Object type
		var json_string = JSON.stringify(save_data, "\t")
		save_file.store_line(json_string)
		print("[SAVE] Save OK: %s (Native OS: %s)" % [_get_save_file_path(), _get_native_os_save_file_path()])
	else:
		push_error("[SAVE] Save failed")


## Loads and parses the save file into a [Dictionary].
## Returns the parsed data if the file exists and contains valid JSON.
## Returns an empty [Dictionary] if the file is missing, empty, or invalid. [br][br]
##
## [b]Debug:[/b] Prints progress; pushes warnings and errors on failure.
static func load_data_from_json_file() -> Dictionary:
	print("[SAVE] Load start")

	var save_file_path: String = _get_save_file_path()
	var native_os_save_file_path: String = _get_native_os_save_file_path()

	var save_file = _open_file_for_read(save_file_path)

	if save_file != null:
		var save_file_as_text: String = save_file.get_as_text()

		if save_file_as_text.is_empty() == true:
			push_warning("[SAVE] JSON file is empty. File: %s (Native OS: %s)" % [save_file_path, native_os_save_file_path])
			return {}
		else:
			var save_file_data_dict: Dictionary = _parse_json_text_to_godot_variant(save_file_as_text)
			if save_file_data_dict.is_empty() == true:
				print("[SAVE] Parsed JSON data is empty. File: %s (Native OS: %s)" % [save_file_path, native_os_save_file_path])
				return {}
			else:
				print("[SAVE] Load OK: %s (Native OS: %s)" % [save_file_path, native_os_save_file_path])
				return save_file_data_dict
	else:
		push_error("[SAVE] Load failed")
		return {}


## Writes [code]SaveData.save_data_dict[/code] to the save file using [method save_data_to_json_file].
## Overwrites any existing save data. [br][br]
##
## [b]Note:[/b] Use this to create or replace the save file.
static func create_new_save_file() -> void:
	save_data_to_json_file(SaveData.save_data_dict)


## Returns the full Godot path to the save file. Combines [constant DEFAULT_STORAGE_ROOT_PATH], 
## [constant SAVE_STORAGE_FOLDER_NAME], and [constant SAVE_FILE_NAME]. [br][br]
## 
## Default save file path: [code]user://save_data/save_data.json[/code].
static func _get_save_file_path() -> String:
	return DEFAULT_STORAGE_ROOT_PATH + SAVE_STORAGE_FOLDER_NAME + SAVE_FILE_NAME


## Returns the save file path as an absolute OS path using [method ProjectSettings.globalize_path]. [br][br]
##
## [b]Note:[/b] This method does not check if the path is already an absolute OS path.
static func _get_native_os_save_file_path() -> String:
	return ProjectSettings.globalize_path(_get_save_file_path())


## Converts [param path] to an absolute OS path using [method ProjectSettings.globalize_path]. [br][br]
##
## [b]Note:[/b] This method does not check if the path is already an absolute OS path.
static func _get_absolute_native_os_path(path: String) -> String:
	return ProjectSettings.globalize_path(path)


## Opens the file at [param file_path] for writing.
## Creates the parent directory if it does not exist. Returns the [FileAccess]
## if the file opens successfully, or [code]null[/code] on failure. [br][br]
##
## [b]Debug:[/b] Prints on success; pushes errors on failure.
static func _open_file_for_write(file_path: String) -> FileAccess:
	var native_os_file_path: String = _get_absolute_native_os_path(file_path)
	
	# Check if directory exist
	if _check_if_directory_exist(file_path.get_base_dir()) == true: # Directory exist
		var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)

		# Return file if successfully opened. Else, return null
		if file != null:
			print("[FILE] Open write OK: %s (Native OS: %s)" % [file_path, native_os_file_path])
			return file
		else:
			# TODO: Keep "error_string()" or remove it depending on what ".get_open_error()" returns
			push_error("[FILE] Open write failed: %s (Native OS: %s)\n[FILE] Error: %s - %s" % [file_path, native_os_file_path, FileAccess.get_open_error(), error_string(FileAccess.get_open_error())])
			return null

	# Try to create directory if not existing
	else:
		if _create_directory(file_path.get_base_dir()) == Error.OK:
			var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)

			if file != null:
				print("[FILE] Open write OK: %s (Native OS: %s)" % [file_path, native_os_file_path])
				return file
			else:
				# TODO: Keep "error_string()" or remove it depending on what ".get_open_error()" returns
				push_error("[FILE] Open write failed: %s (Native OS: %s)\n[FILE] Error: %s - %s" % [file_path, native_os_file_path, FileAccess.get_open_error(), error_string(FileAccess.get_open_error())])
				return null
		else: # Warning is handled in the _check_if_directory_exist()
			return null


## Opens the file at [param file_path] for reading.
## Returns the [FileAccess] if the file exists and opens, or [code]null[/code]
## if the file is missing or cannot be opened. [br][br]
##
## [b]Debug:[/b] Prints on success; pushes errors on failure.
static func _open_file_for_read(file_path: String) -> FileAccess:
	var native_os_file_path: String = _get_absolute_native_os_path(file_path)
	
	# Check if directory exist
	if _check_if_directory_exist(file_path.get_base_dir()) == true: # Directory exist
		# Check if file exist
		if FileAccess.file_exists(file_path) == true:
			var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)

			# Return file is successfully opened. Else, return null				
			if file != null:
				print("[FILE] Open read OK: %s (Native OS: %s)" % [file_path, native_os_file_path])
				return file
			else:
				# TODO: Keep "error_string()" or remove it depending on what ".get_open_error()" returns
				push_error("[FILE] Open read failed: %s (Native OS: %s)\n[FILE] Error: %s - %s" % [file_path, native_os_file_path, FileAccess.get_open_error(), error_string(FileAccess.get_open_error())])
				return null
			
		else:
			push_error("[FILE] Missing: %s (Native OS: %s)" % [file_path, native_os_file_path])
			return null
	else: # Warning is handled in the _check_if_directory_exist()
		return null


## Returns [code]true[/code] if the directory at [param directory_path] exists. [br][br]
##
## [b]Debug:[/b] Prints on success; pushes warning if missing.
static func _check_if_directory_exist(directory_path: String) -> bool:
	var native_os_directory_path: String = _get_absolute_native_os_path(directory_path)
	
	if DirAccess.dir_exists_absolute(directory_path) == true:
		print("[DIR] Exists: %s (Native OS: %s)" % [directory_path, native_os_directory_path])
		return true
	else:
		push_warning("[DIR] Missing: %s (Native OS: %s)" % [directory_path, native_os_directory_path])
		return false


## Creates the directory at [param directory_path].[br][br]
##
## Tries [method DirAccess.make_dir_absolute] first, then
## [method DirAccess.make_dir_recursive_absolute] if needed. [br][br]
## 
## Returns one of the [enum Error] code constants ([constant OK] on success).[br][br]
## 
## [b]Note:[/b] This method does not check if the directory already exists. Use [method _check_if_directory_exist] to check if the directory exists before creating it. [br][br]
##
## [b]Debug:[/b] Prints on success; pushes warnings and errors on failure.
static func _create_directory(directory_path: String) -> Error:
	var native_os_directory_path: String = _get_absolute_native_os_path(directory_path)
	
	var create_directory_result: Error = DirAccess.make_dir_absolute(directory_path)

	if create_directory_result == Error.OK:
		print("[DIR] Create OK: %s (Native OS: %s)" % [directory_path, native_os_directory_path])
		return Error.OK
	else:
		push_warning("[DIR] Create failed: %s (Native OS: %s)\n[DIR] Error: %s - %s" % [directory_path, native_os_directory_path, create_directory_result, error_string(create_directory_result)])
		var recursive_create_directory_result: Error = DirAccess.make_dir_recursive_absolute(directory_path)

		if recursive_create_directory_result == Error.OK:
			print("[DIR] Recursive create OK: %s (Native OS: %s)" % [directory_path, native_os_directory_path])
			return Error.OK
		else:
			push_error("[DIR] Recursive create failed: %s (Native OS: %s)\n[DIR] Error: %s - %s" % [directory_path, native_os_directory_path, error_string(recursive_create_directory_result)])
			return recursive_create_directory_result


## Parses [param json_text] into a [Dictionary]. 
## Returns the parsed data if valid, or an empty [Dictionary] if the input is
## empty or the JSON is invalid. [br][br]
##
## [b]Debug:[/b] Prints on success; pushes errors on invalid JSON.
static func _parse_json_text_to_godot_variant(json_text: String) -> Dictionary:
	var _json: JSON = JSON.new()

	# Return empty dict if provided json text is empty. Else, return dict
	if json_text.is_empty() == true:
		print("[JSON] Empty input to parse")
		return {}
	else:
		var _parsed_text: Error = _json.parse(json_text, true)

		if _parsed_text == Error.OK:
			print("[JSON] Parse OK")
			return _json.data
		else:
			push_error("[JSON] Parse failed: line %s - %s" % [_json.get_error_line(), _json.get_error_message()])
			return {}
