extends Node
## Stores and manages persistent user data for the application.
##
## Holds [member save_data_dict] with the user's name and language. Use
## [method save_data_to_file] to persist data and [method load_save_data_from_file]
## to load it and navigate to the appropriate screen based on what is stored.
## [br][br]
## [b]Autoload:[/b] Access this singleton globally via [code]SaveData[/code].


## Preloaded reference to the [FileHandler] utility.
const FILE_HANDLER: Resource = preload("res://utilities/file_handler.gd")


## Dictionary containing persistent user data (e.g. [code]name[/code], [code]language[/code]). [br][br]
## - [code]name[/code] is the user's name. [br]
## - [code]language[/code] is the user's language. [br]
## - [code]api_cooldown_until[/code] is a unix timestamp; cooldown is active while [code]Time.get_unix_time_from_system()[/code] is less than this value.[br]
## - [code]api_cooldown_endpoint[/code] is [code]"health"[/code] or [code]"verify"[/code] depending on which endpoint triggered the cooldown. [br]
## - [code]work_entries[/code] is an array of dictionaries, each representing a work entry. [br]
## - [code]hourly_wage[/code] is the user's hourly wage. [br]
## - [code]tax_percentage[/code] is the tax rate (0-100). [br]
## - [code]personal_allowance[/code] is the tax-free amount (fradrag). [br]
## - [code]evening_wage[/code] is the fixed evening supplement (kr/hour); 0 = not used. [br]
## - [code]evening_window_start[/code] is the evening window start [code]{hour, minute}[/code]. [br]
## - [code]evening_window_end[/code] is the evening window end [code]{hour, minute}[/code]. [br]
## - [code]night_wage[/code] is the fixed night supplement (kr/hour); 0 = not used. [br]
## - [code]night_window_start[/code] is the night window start [code]{hour, minute}[/code]. [br]
## - [code]night_window_end[/code] is the night window end [code]{hour, minute}[/code]. [br]
## - [code]saturday_wage[/code] is the fixed Saturday supplement (kr/hour); 0 = not used. [br]
## - [code]saturday_window_start[/code] and [code]saturday_window_end[/code] are [code]{hour, minute}[/code] dicts. [br]
## - [code]sunday_wage[/code] is the fixed Sunday supplement (kr/hour); 0 = not used. [br]
## - [code]sunday_window_start[/code] and [code]sunday_window_end[/code] are [code]{hour, minute}[/code] dicts. [br]
## - [code]theme[/code] is the UI theme: [code]"light"[/code] or [code]"dark"[/code].
var save_data_dict: Dictionary = {
	"name": "",
	"language": "",
	"api_cooldown_until": 0.0,
	"api_cooldown_endpoint": "",
	"work_entries": [],
	"hourly_wage": 0.0,
	"tax_percentage": 0.0,
	"personal_allowance": 0.0,
	"evening_wage": 0.0,
	"evening_window_start": {"hour": 18, "minute": 0},
	"evening_window_end": {"hour": 22, "minute": 0},
	"night_wage": 0.0,
	"night_window_start": {"hour": 22, "minute": 0},
	"night_window_end": {"hour": 6, "minute": 0},
	"saturday_wage": 0.0,
	"saturday_window_start": {"hour": 0, "minute": 0},
	"saturday_window_end": {"hour": 23, "minute": 59},
	"sunday_wage": 0.0,
	"sunday_window_start": {"hour": 0, "minute": 0},
	"sunday_window_end": {"hour": 23, "minute": 59},
	"theme": "light",
}


## Writes [member save_data_dict] to the save file.
##
## Calls [method FileHandler.save_data_to_json_file] with the current save data.
func save_data_to_file() -> void:
	FILE_HANDLER.save_data_to_json_file(save_data_dict)


## Appends [param entry] to [code]"work_entries"[/code] in [member save_data_dict] and persists to file. [br][br]
##
## [param entry] is a dictionary representing a work entry. [br][br]
## 
## Example: 
## [codeblock]
## "work_entries": [
##	{
##		"date": {
##			"day": 8,
##			"month": 3,
##			"year": 2026
##		},
##		"end_time": {
##			"hour": 16,
##			"minute": 0
##		},
##		"note": "Worked on project X",
##		"start_time": {
##			"hour": 8,
##			"minute": 0
##		}
##	},
##	...
## ]
## [/codeblock]
##
## [b]Note:[/b] This method does not validate the entry data.
func add_work_entry(entry: Dictionary) -> void:
	save_data_dict["work_entries"].append(entry)
	save_data_to_file()


## Removes the work entry at [param index] and persists to file.
## Does nothing if [param index] is out of bounds.
func remove_work_entry(index: int) -> void:
	var entries: Array = save_data_dict["work_entries"]
	if index >= 0 and index < entries.size():
		entries.remove_at(index)
		save_data_to_file()


## Clears all work entries and persists to file.
func clear_all_work_entries() -> void:
	save_data_dict["work_entries"] = []
	save_data_to_file()


## Updates wage settings and persists to file. [br][br]
##
## [param hourly_wage] is the hourly wage (non-negative). [br]
## [param tax_percentage] is the tax rate 0-100. [br]
## [param personal_allowance] is the tax-free amount (fradrag).
func set_wage_settings(hourly_wage: float, tax_percentage: float, personal_allowance: float) -> void:
	save_data_dict["hourly_wage"] = maxf(0.0, hourly_wage)
	save_data_dict["tax_percentage"] = clampf(tax_percentage, 0.0, 100.0)
	save_data_dict["personal_allowance"] = maxf(0.0, personal_allowance)
	save_data_to_file()


## Updates supplement (evening/night) wage settings and persists to file. [br][br]
##
## [param evening_wage] is the fixed evening supplement kr/hour (non-negative). [br]
## [param evening_window_start] and [param evening_window_end] are [code]{hour, minute}[/code] dicts. [br]
## [param night_wage] is the fixed night supplement kr/hour (non-negative). [br]
## [param night_window_start] and [param night_window_end] are [code]{hour, minute}[/code] dicts.
func set_supplement_settings(evening_wage: float, evening_window_start: Dictionary, evening_window_end: Dictionary, night_wage: float, night_window_start: Dictionary, night_window_end: Dictionary) -> void:
	save_data_dict["evening_wage"] = maxf(0.0, evening_wage)
	save_data_dict["evening_window_start"] = evening_window_start
	save_data_dict["evening_window_end"] = evening_window_end
	save_data_dict["night_wage"] = maxf(0.0, night_wage)
	save_data_dict["night_window_start"] = night_window_start
	save_data_dict["night_window_end"] = night_window_end
	save_data_to_file()


## Updates weekend (Saturday/Sunday) supplement wage settings and persists to file. [br][br]
##
## [param saturday_wage] is the fixed Saturday supplement kr/hour (non-negative). [br]
## [param sat_window_start] and [param sat_window_end] are [code]{hour, minute}[/code] dicts. [br]
## [param sunday_wage] is the fixed Sunday supplement kr/hour (non-negative). [br]
## [param sun_window_start] and [param sun_window_end] are [code]{hour, minute}[/code] dicts.
func set_weekend_supplement_settings(saturday_wage: float, sat_window_start: Dictionary, sat_window_end: Dictionary, sunday_wage: float, sun_window_start: Dictionary, sun_window_end: Dictionary) -> void:
	save_data_dict["saturday_wage"] = maxf(0.0, saturday_wage)
	save_data_dict["saturday_window_start"] = sat_window_start
	save_data_dict["saturday_window_end"] = sat_window_end
	save_data_dict["sunday_wage"] = maxf(0.0, sunday_wage)
	save_data_dict["sunday_window_start"] = sun_window_start
	save_data_dict["sunday_window_end"] = sun_window_end
	save_data_to_file()


## Replaces the work entry at [param index] with [param entry] and persists to file.
## Does nothing if [param index] is out of bounds.
func update_work_entry(index: int, entry: Dictionary) -> void:
	var entries: Array = save_data_dict["work_entries"]
	if index >= 0 and index < entries.size():
		entries[index] = entry
		save_data_to_file()


## Loads save data from the file and navigates to the appropriate screen.
##
## Reads the save file via [method FileHandler.load_data_from_json_file]. Updates
## [member save_data_dict] and [method TranslationServer.set_locale] with loaded
## values. If the file is empty or missing, creates a new save file.
## [br][br]
## Screen navigation: navigates to the language selection screen if [code]language[/code]
## is empty, to the login screen if [code]name[/code] is empty, or to the home
## screen if both are set.
func load_save_data_from_file() -> void:

	var _save_file_data: Dictionary = FILE_HANDLER.load_data_from_json_file()

	if _save_file_data.is_empty() != true:
		# Update save data dict from save file data
		save_data_dict["name"] = _save_file_data["name"]
		save_data_dict["language"] = _save_file_data["language"]
		save_data_dict["api_cooldown_until"] = _save_file_data["api_cooldown_until"]
		save_data_dict["api_cooldown_endpoint"] = _save_file_data["api_cooldown_endpoint"]
		save_data_dict["work_entries"] = _save_file_data["work_entries"]
		if _save_file_data.has("hourly_wage"):
			save_data_dict["hourly_wage"] = _save_file_data["hourly_wage"]
		if _save_file_data.has("tax_percentage"):
			save_data_dict["tax_percentage"] = _save_file_data["tax_percentage"]
		if _save_file_data.has("personal_allowance"):
			save_data_dict["personal_allowance"] = _save_file_data["personal_allowance"]
		if _save_file_data.has("evening_wage"):
			save_data_dict["evening_wage"] = _save_file_data["evening_wage"]
		if _save_file_data.has("evening_window_start"):
			save_data_dict["evening_window_start"] = _save_file_data["evening_window_start"]
		if _save_file_data.has("evening_window_end"):
			save_data_dict["evening_window_end"] = _save_file_data["evening_window_end"]
		if _save_file_data.has("night_wage"):
			save_data_dict["night_wage"] = _save_file_data["night_wage"]
		if _save_file_data.has("night_window_start"):
			save_data_dict["night_window_start"] = _save_file_data["night_window_start"]
		if _save_file_data.has("night_window_end"):
			save_data_dict["night_window_end"] = _save_file_data["night_window_end"]
		if _save_file_data.has("saturday_wage"):
			save_data_dict["saturday_wage"] = _save_file_data["saturday_wage"]
		if _save_file_data.has("saturday_window_start"):
			save_data_dict["saturday_window_start"] = _save_file_data["saturday_window_start"]
		if _save_file_data.has("saturday_window_end"):
			save_data_dict["saturday_window_end"] = _save_file_data["saturday_window_end"]
		if _save_file_data.has("sunday_wage"):
			save_data_dict["sunday_wage"] = _save_file_data["sunday_wage"]
		if _save_file_data.has("sunday_window_start"):
			save_data_dict["sunday_window_start"] = _save_file_data["sunday_window_start"]
		if _save_file_data.has("sunday_window_end"):
			save_data_dict["sunday_window_end"] = _save_file_data["sunday_window_end"]
		if _save_file_data.has("theme"):
			save_data_dict["theme"] = _save_file_data["theme"]

		# Update language
		TranslationServer.set_locale(save_data_dict["language"])

		# Change to language selection screen if user has not selected any language (First app opening)
		if _save_file_data["language"].is_empty():
			ScreenManager.change_screen(ScreenManager.Screen.LANGUAGE_SELECTION_SCREEN)
		# Change to login screen if user has not entered their name
		elif _save_file_data["name"].is_empty():
			ScreenManager.change_screen(ScreenManager.Screen.LOGIN_SCREEN)
		else:
		# Change to home screen if user has selected a language and entered a name
			ScreenManager.change_screen(ScreenManager.Screen.HOME_SCREEN)

	else:
		FILE_HANDLER.create_new_save_file()
