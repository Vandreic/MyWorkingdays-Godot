class_name HomeScreenManager
extends BaseScreenTemplateManager
## Controls the home screen UI after successful login.
##
## Displays the main application interface: a welcome title, list of work entries
## (date, start/end times, note indicator, open button), and an add-entry button.[br]
## Uses [code]WorkEntryRowTemplate[/code] as a template for each entry row.[br]
## Reads from [code]work_entries[/code] in [member SaveData.save_data_dict] for persistence.

## Welcome message label.
@onready var title_label: Label = %TitleLabel
## Button that navigates to the add work entry screen.
@onready var add_work_entry_button: Button = %AddWorkEntryButton
## VBoxContainer (inside ScrollContainer) that holds the entry list.
@onready var work_entries_list: VBoxContainer = %WorkEntriesList
## Template panel duplicated for each work entry; hidden when entries exist.
@onready var work_entry_row_template: Panel = %WorkEntryRowTemplate
## Header row for column labels; hidden when no entries.
@onready var work_entries_column_header: HBoxContainer = %WorkEntriesColumnHeader
## Header label for the date column (uses [code]ENTRIES_COL_DATE[/code]).
@onready var column_header_date_label: Label = %ColumnHeaderDateLabel
## Header label for the start time column (uses [code]ENTRIES_COL_START[/code]).
@onready var column_header_start_time_label: Label = %ColumnHeaderStartTimeLabel
## Header label for the end time column (uses [code]ENTRIES_COL_END[/code]).
@onready var column_header_end_time_label: Label = %ColumnHeaderEndTimeLabel
## Header label for the note column (uses [code]ENTRIES_COL_NOTE[/code]).
@onready var column_header_note_label: Label = %ColumnHeaderNoteLabel
## Button to delete all work entries (shows confirmation popup).
@onready var delete_all_button: Button = %DeleteAllButton
## Button to navigate to the home screen.
@onready var home_button: Button = %HomeButton
## Button to open the wages screen.
@onready var wages_button: Button = %WagesButton
## Button to open the salary screen.
@onready var salary_button: Button = %SalaryButton

const CONFIRMATION_POPUP_SCENE: PackedScene = preload("res://components/popups/confirmation/confirmation_popup.tscn")
## Cached confirmation popup instance; created on first use.
var _confirmation_popup: ConfirmationPopup


## Initializes the home screen and updates the UI with the current language.
func _ready() -> void:
	super._ready()
	_update_ui_with_new_language()
	_connect_signals()
	apply_navbar_button_styles([home_button, wages_button, salary_button], home_button)
	# Defer refresh so the screen is fully in the tree and SaveData is up to date.
	call_deferred("_refresh_work_entries_list")


## Refreshes the UI with the current language.
func _update_ui_with_new_language() -> void:
	title_label.text = tr("WELCOME_TO_USER").format({"name": SaveData.save_data_dict["name"]})
	home_button.get_node("VBoxContainer/Label").text = tr("NAV_HOME")
	wages_button.get_node("VBoxContainer/Label").text = tr("NAV_WAGES")
	salary_button.get_node("VBoxContainer/Label").text = tr("NAV_SALARY")
	column_header_date_label.text = tr("ENTRIES_COL_DATE")
	column_header_start_time_label.text = tr("ENTRIES_COL_START")
	column_header_end_time_label.text = tr("ENTRIES_COL_END")
	column_header_note_label.text = tr("ENTRIES_COL_NOTE")
	delete_all_button.text = tr("DELETE_ALL_ENTRIES_BUTTON")


## Connects button signals to handler functions.
func _connect_signals() -> void:
	add_work_entry_button.pressed.connect(_on_add_work_entry_button_pressed)
	delete_all_button.pressed.connect(_on_delete_all_button_pressed)
	home_button.pressed.connect(_on_home_button_pressed)
	wages_button.pressed.connect(_on_wages_button_pressed)
	salary_button.pressed.connect(_on_salary_button_pressed)


func _get_settings_return_screen() -> int:
	return ScreenManager.Screen.HOME_SCREEN


## Navigates to the home screen (refresh when already on home).
func _on_home_button_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.HOME_SCREEN)


## Called when the add work entry button is pressed.
func _on_add_work_entry_button_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.ADD_WORK_ENTRY_SCREEN)


## Returns the confirmation popup instance, creating it on first use.
func _get_confirmation_popup() -> ConfirmationPopup:
	if _confirmation_popup == null:
		_confirmation_popup = CONFIRMATION_POPUP_SCENE.instantiate() as ConfirmationPopup
		_confirmation_popup.confirmed.connect(_on_delete_all_confirmed)
		add_child(_confirmation_popup)
	return _confirmation_popup


## Called when the delete all button is pressed; shows the confirmation popup.
func _on_delete_all_button_pressed() -> void:
	_get_confirmation_popup().show_for_confirmation(
		"DELETE_ALL_ENTRIES_CONFIRM_TITLE",
		"DELETE_ALL_ENTRIES_CONFIRM_MESSAGE",
		"CANNOT_BE_UNDONE"
	)


## Called when the user confirms deletion of all work entries.
func _on_delete_all_confirmed() -> void:
	SaveData.clear_all_work_entries()
	call_deferred("_refresh_work_entries_list")


## Called when the wages button is pressed; navigates to the wages screen.
func _on_wages_button_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.WAGES_SCREEN)


## Called when the salary button is pressed; navigates to the salary screen.
func _on_salary_button_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.SALARY_SCREEN)

## Rebuilds the work entries list from [member SaveData.save_data_dict]["work_entries"].
##
## Duplicates [member work_entry_row_template] for each entry, populates labels, and connects
## the edit button. All entry rows are added as direct children of [member work_entries_list]
## (WorkEntriesList) for correct scroll behavior. Hides the template when entries exist.
func _refresh_work_entries_list() -> void:
	var entries: Array = SaveData.save_data_dict["work_entries"]

	# Remove previously created rows (keep template).
	for child in work_entries_list.get_children():
		if child != work_entry_row_template:
			child.queue_free()

	# Show/hide header based on entry count. Always hide template (it is only used for duplication).
	work_entries_column_header.visible = entries.size() > 0
	work_entry_row_template.visible = false
	if entries.size() > 0:
		# Add all entry rows to WorkEntriesList first (inside ScrollContainer for scrolling).
		for i in entries.size():
			var entry: Dictionary = entries[i]
			var row: Panel = work_entry_row_template.duplicate() as Panel
			_populate_entry_row(row, entry, i)
			work_entries_list.add_child(row)
		# Move template to end so it does not affect layout of visible rows.
		work_entries_list.move_child(work_entry_row_template, work_entries_list.get_child_count() - 1)


## Populates a duplicated entry row with [param entry] data and connects the edit button.
func _populate_entry_row(row: Panel, entry: Dictionary, index: int) -> void:
	row.visible = true  # Ensure visible; duplicates inherit template's visibility (which may be false).
	var row_content: HBoxContainer = row.get_node("WorkEntryRowContent")
	row_content.get_node("WorkEntryDateLabel").text = _format_date_short(entry)
	row_content.get_node("WorkEntryStartTimeLabel").text = _format_time(entry["start_time"])
	row_content.get_node("WorkEntryEndTimeLabel").text = _format_time(entry["end_time"])
	var note_text: String = entry["note"]
	if not note_text.strip_edges().is_empty():
		row_content.get_node("WorkEntryNoteLabel").text = "●"
	else:
		row_content.get_node("WorkEntryNoteLabel").text = "–"
	var edit_button: TextureButton = row_content.get_node("WorkEntryEditButton")
	edit_button.modulate = ThemeManager.get_nav_icon_normal()
	edit_button.pressed.connect(_on_entry_open_pressed.bind(index))


## Called when the open button on an entry row is pressed; navigates to edit screen.
func _on_entry_open_pressed(index: int) -> void:
	ScreenManager.change_screen(ScreenManager.Screen.ADD_WORK_ENTRY_SCREEN, index)


## Returns [param entry] date formatted as weekday (3 letters) + day + short month, e.g. "Man 3. mar.".
func _format_date_short(entry: Dictionary) -> String:
	var date_dict: Dictionary = entry["date"]
	if date_dict.is_empty():
		return "--"
	var year: int = int(date_dict["year"])
	var month: int = int(date_dict["month"])
	var day: int = int(date_dict["day"])
	var unix: int = int(Time.get_unix_time_from_datetime_dict({
		"year": year,
		"month": month,
		"day": day,
		"hour": 0,
		"minute": 0,
		"second": 0
	}))
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(unix)
	var weekday: int = int(dt["weekday"])
	var weekday_key: String = _get_weekday_short_key(weekday)
	var month_key: String = _get_month_short_key(month)
	return "%s %d. %s." % [tr(weekday_key), day, tr(month_key)]


## Maps Godot weekday (0=Sunday) to DATE_WEEKDAY_* key.
func _get_weekday_short_key(weekday: int) -> String:
	var keys: Array[String] = ["DATE_WEEKDAY_SUN", "DATE_WEEKDAY_MON", "DATE_WEEKDAY_TUE", "DATE_WEEKDAY_WED", "DATE_WEEKDAY_THU", "DATE_WEEKDAY_FRI", "DATE_WEEKDAY_SAT"]
	return keys[clampi(weekday, 0, 6)]


## Maps month number (1-12) to DATE_MONTH_SHORT_* key.
func _get_month_short_key(month: int) -> String:
	var keys: Array[String] = ["", "DATE_MONTH_SHORT_JAN", "DATE_MONTH_SHORT_FEB", "DATE_MONTH_SHORT_MAR", "DATE_MONTH_SHORT_APR", "DATE_MONTH_SHORT_MAY", "DATE_MONTH_SHORT_JUN", "DATE_MONTH_SHORT_JUL", "DATE_MONTH_SHORT_AUG", "DATE_MONTH_SHORT_SEP", "DATE_MONTH_SHORT_OCT", "DATE_MONTH_SHORT_NOV", "DATE_MONTH_SHORT_DEC"]
	return keys[clampi(month, 1, 12)]


## Returns [param time_dict] formatted as HH:MM.
## [param time_dict] must have keys [code]hour[/code], [code]minute[/code].
func _format_time(time_dict: Dictionary) -> String:
	if time_dict.is_empty():
		return "--"
	return "%02d:%02d" % [time_dict["hour"], time_dict["minute"]]
