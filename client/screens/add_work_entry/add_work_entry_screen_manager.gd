class_name AddWorkEntryScreenManager
extends BaseScreenTemplateManager
## Manages the add work entry screen.
##
## Displays a date picker (defaulting to today), start/end time pickers, and optional note.[br]
## Uses [DatePickerPopup] and [TimePickerPopup] for selection.[br]
## On submit, emits [signal work_entry_submitted] with the full entry dictionary.

signal work_entry_submitted(entry: Dictionary)

const DATE_PICKER_SCENE: PackedScene = preload("res://components/popups/date_picker/date_picker_popup.tscn")
const TIME_PICKER_SCENE: PackedScene = preload("res://components/popups/time_picker/time_picker_popup.tscn")

## Label showing the screen title (e.g. localized "Add Work Entry").
@onready var title_label: Label = %TitleLabel
## Label for the date field (e.g. localized "Date").
@onready var date_label: Label = %DateLabel
## Button that opens the date picker popup; text shows currently selected date.
@onready var date_picker_button: Button = %DatePickerButton
## Date picker popup instance; created on first use in [method _get_date_picker_popup].
var _date_picker_popup: DatePickerPopup
## Label for the start time field.
@onready var start_time_picker_label: Label = %StartTimePickerLabel
## Button that opens the start time picker; text shows currently selected start time.
@onready var start_time_picker_button: Button = %StartTimePickerButton
## Start time picker popup instance; created on first use in [method _get_start_time_picker_popup].
var _start_time_picker_popup: TimePickerPopup
## Label for the end time field.
@onready var end_time_label: Label = %EndTimeLabel
## Button that opens the end time picker; text shows currently selected end time.
@onready var end_time_picker_button: Button = %EndTimePickerButton
## End time picker popup instance; created on first use in [method _get_end_time_picker_popup].
var _end_time_picker_popup: TimePickerPopup
## Label for the note field.
@onready var note_label: Label = %NoteLabel
## LineEdit for optional note text.
@onready var note_input: LineEdit = %NoteInput
## Button to submit the work entry and return to the home screen.
@onready var submit_button: Button = %SubmitButton
## Button to cancel and return without saving; navigates back to home.
@onready var cancel_button: Button = %CancelButton
## Button to delete the work entry; only visible in edit mode.
@onready var delete_button: Button = %DeleteButton

## Index of entry being edited, or -1 for add mode.
var _edit_index: int = -1

## Currently selected date; keys: [code]year[/code], [code]month[/code], [code]day[/code].
var selected_date: Dictionary = {}
## Currently selected start time; keys: [code]hour[/code], [code]minute[/code].
var selected_start_time: Dictionary = {"hour": 8, "minute": 0}
## Currently selected end time; keys: [code]hour[/code], [code]minute[/code].
var selected_end_time: Dictionary = {"hour": 16, "minute": 0}

## Overlay that catches taps outside the note input; removed when tapped or when focus exits.
var _dismiss_overlay: Control
## Set to [member note_input] when overlay is shown; used for tap-to-dismiss and keyboard polling.
var _focused_note_input: LineEdit
## Spacer added below [member note_input] when focused on mobile; pushes input above keyboard.
var _keyboard_spacer: Control
## Last known virtual keyboard height; used to detect keyboard dismiss on mobile.
var _last_keyboard_height: int = 0


func _ready() -> void:
	if _edit_index >= 0:
		_load_entry_for_edit()
	else:
		selected_date = _get_today_dict()
	_update_ui_with_new_language()
	_connect_signals()
	# Sync button labels with current selections.
	_refresh_date_button()
	_refresh_start_time_button()
	_refresh_end_time_button()


## Polls virtual keyboard height on mobile.[br]
## When keyboard is dismissed while [member note_input] has focus: removes spacer and overlay.[br]
## When keyboard reappears and [member note_input] owns focus: re-adds spacer (handles re-tap after dismiss).
func _process(_delta: float) -> void:
	if not _is_mobile_os():
		return
	var current := DisplayServer.virtual_keyboard_get_height()
	# Keyboard was dismissed while note input had focus.
	if is_instance_valid(_focused_note_input) and is_instance_valid(_keyboard_spacer):
		if _last_keyboard_height > 0 and current == 0:
			_remove_keyboard_spacer()
			_remove_dismiss_overlay()
			_focused_note_input = null
			_last_keyboard_height = 0
		else:
			_last_keyboard_height = current
		return
	# Keyboard appeared again; user tapped the same note input.
	if _last_keyboard_height == 0 and current > 0:
		if get_viewport().gui_get_focus_owner() == note_input:
			_on_note_input_focused()
	_last_keyboard_height = current


## Called by [ScreenManager] when navigating to this screen in edit mode.
func set_edit_data(index: int) -> void:
	_edit_index = index


## Loads the entry at [member _edit_index] from SaveData into the form fields.
func _load_entry_for_edit() -> void:
	var entries: Array = SaveData.save_data_dict["work_entries"]
	if _edit_index >= 0 and _edit_index < entries.size():
		var entry: Dictionary = entries[_edit_index]
		selected_date = entry["date"].duplicate()
		selected_start_time = entry["start_time"].duplicate()
		selected_end_time = entry["end_time"].duplicate()
		note_input.text = entry["note"]


## Returns the date picker popup, creating it on first use (lazy loading).
##
## Returns the cached popup if already created.[br]
## Creating the popup only when the user clicks the date button prevents it from
## briefly appearing during the initial screen load.
func _get_date_picker_popup() -> DatePickerPopup:
	if _date_picker_popup == null:
		_date_picker_popup = DATE_PICKER_SCENE.instantiate() as DatePickerPopup
		_date_picker_popup.date_selected.connect(_on_date_selected)
		add_child(_date_picker_popup)
	return _date_picker_popup


## Returns the start time picker popup, creating it on first use (lazy loading).
func _get_start_time_picker_popup() -> TimePickerPopup:
	if _start_time_picker_popup == null:
		_start_time_picker_popup = TIME_PICKER_SCENE.instantiate() as TimePickerPopup
		_start_time_picker_popup.time_selected.connect(_on_start_time_selected)
		add_child(_start_time_picker_popup)
	return _start_time_picker_popup


## Returns the end time picker popup, creating it on first use (lazy loading).
func _get_end_time_picker_popup() -> TimePickerPopup:
	if _end_time_picker_popup == null:
		_end_time_picker_popup = TIME_PICKER_SCENE.instantiate() as TimePickerPopup
		_end_time_picker_popup.time_selected.connect(_on_end_time_selected)
		add_child(_end_time_picker_popup)
	return _end_time_picker_popup


## Returns today's date as a dictionary with [code]year[/code], [code]month[/code], [code]day[/code].
func _get_today_dict() -> Dictionary:
	var date_dict: Dictionary = Time.get_date_dict_from_system()
	return {"year": date_dict["year"], "month": date_dict["month"], "day": date_dict["day"]}


## Applies localized strings to title, labels, and buttons.
func _update_ui_with_new_language() -> void:
	date_label.text = tr("DATE_LABEL")
	start_time_picker_label.text = tr("START_TIME_LABEL")
	end_time_label.text = tr("END_TIME_LABEL")
	note_label.text = tr("NOTE_LABEL")
	note_input.placeholder_text = tr("NOTE_PLACEHOLDER")
	if _edit_index >= 0:
		title_label.text = _format_edit_title(selected_date)
		submit_button.text = tr("SAVE_ENTRY_BUTTON")
		delete_button.text = tr("DELETE")
		delete_button.visible = true
		cancel_button.visible = false
	else:
		title_label.text = tr("ADD_WORK_ENTRY")
		submit_button.text = tr("ADD_ENTRY_BUTTON")
		delete_button.visible = false
		cancel_button.visible = true
	cancel_button.text = tr("CANCEL_BUTTON")


## Connects button, picker, and [member note_input] focus signals to handlers.
func _connect_signals() -> void:
	date_picker_button.pressed.connect(_on_date_picker_button_pressed)
	start_time_picker_button.pressed.connect(_on_start_time_picker_button_pressed)
	end_time_picker_button.pressed.connect(_on_end_time_picker_button_pressed)
	submit_button.pressed.connect(_on_submit)
	cancel_button.pressed.connect(_on_cancel)
	delete_button.pressed.connect(_on_delete)
	note_input.focus_entered.connect(_on_note_input_focused)
	note_input.focus_exited.connect(_on_note_input_unfocused)


## Returns [code]true[/code] if running on Android or iOS.
func _is_mobile_os() -> bool:
	var os_name := OS.get_name()
	return os_name == "Android" or os_name == "iOS"


## When [member note_input] gains focus: shows overlay; on mobile, adds spacer below it to push input above keyboard.
func _on_note_input_focused() -> void:
	_add_dismiss_overlay()
	if not _is_mobile_os():
		return
	_remove_keyboard_spacer()
	var note_container := note_input.get_parent() as VBoxContainer
	if not note_container:
		return
	_keyboard_spacer = Control.new()
	_keyboard_spacer.custom_minimum_size = Vector2(0, int(get_viewport().size.y * 0.125))
	note_container.add_child(_keyboard_spacer)


## When [member note_input] loses focus: removes overlay; on mobile, removes spacer.
func _on_note_input_unfocused() -> void:
	_remove_dismiss_overlay()
	_last_keyboard_height = 0
	if not _is_mobile_os():
		return
	_remove_keyboard_spacer()


## Adds a full-screen transparent overlay that catches taps.[br]
## When tapped outside [member note_input], releases focus and removes itself.
func _add_dismiss_overlay() -> void:
	_remove_dismiss_overlay()
	_focused_note_input = note_input
	_dismiss_overlay = Control.new()
	_dismiss_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dismiss_overlay.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_dismiss_overlay.grow_vertical = Control.GROW_DIRECTION_BOTH
	_dismiss_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_dismiss_overlay.gui_input.connect(_on_dismiss_overlay_gui_input)
	add_child(_dismiss_overlay)


## Removes [member _keyboard_spacer] from its parent and frees it if it exists.
func _remove_keyboard_spacer() -> void:
	if is_instance_valid(_keyboard_spacer) and _keyboard_spacer.get_parent():
		_keyboard_spacer.get_parent().remove_child(_keyboard_spacer)
		_keyboard_spacer.queue_free()
	_keyboard_spacer = null


## Removes [member _dismiss_overlay] and clears [member _focused_note_input] if overlay exists.
func _remove_dismiss_overlay() -> void:
	if is_instance_valid(_dismiss_overlay):
		if _dismiss_overlay.gui_input.is_connected(_on_dismiss_overlay_gui_input):
			_dismiss_overlay.gui_input.disconnect(_on_dismiss_overlay_gui_input)
		_dismiss_overlay.queue_free()
		_dismiss_overlay = null
	_focused_note_input = null


## Handles tap on [member _dismiss_overlay]: releases focus and removes overlay.[br]
## Ignores taps on [member note_input]'s rect so re-tapping the field does not dismiss.[br]
## [param event] is the [InputEvent] (screen touch or mouse button).
func _on_dismiss_overlay_gui_input(event: InputEvent) -> void:
	var is_tap := false
	var tap_position := Vector2.ZERO
	if event is InputEventScreenTouch:
		is_tap = event.pressed
		tap_position = (_dismiss_overlay as Control).global_position + event.position
	elif event is InputEventMouseButton:
		is_tap = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
		tap_position = (_dismiss_overlay as Control).global_position + event.position
	if not is_tap or not is_instance_valid(_focused_note_input):
		return
	if _focused_note_input.get_global_rect().has_point(tap_position):
		return
	_focused_note_input.release_focus()
	_remove_dismiss_overlay()
	get_viewport().set_input_as_handled()


## Updates the date button label to show the selected date.
func _refresh_date_button() -> void:
	date_picker_button.text = _format_date(selected_date)


## Returns [param date_dict] formatted as [code]DD-MM-YYYY[/code].
func _format_date(date_dict: Dictionary) -> String:
	return "%02d-%02d-%04d" % [date_dict["day"], date_dict["month"], date_dict["year"]]


## Returns a full date string for the edit screen title, e.g. "Mandag, den 1. januar 2026" (DA) or "Monday, January 1, 2026" (EN).
func _format_edit_title(date_dict: Dictionary) -> String:
	if date_dict.is_empty():
		return tr("ADD_WORK_ENTRY")
	var unix: int = int(Time.get_unix_time_from_datetime_dict({
		"year": date_dict["year"],
		"month": date_dict["month"],
		"day": date_dict["day"],
		"hour": 0,
		"minute": 0,
		"second": 0
	}))
	var datetime_dict: Dictionary = Time.get_datetime_dict_from_unix_time(unix)
	var weekday: int = int(datetime_dict["weekday"])
	var weekday_key: String = _get_weekday_full_key(weekday)
	var month_key: String = _get_month_key(int(date_dict["month"]))
	var locale: String = TranslationServer.get_locale()
	if locale.begins_with("da"):
		return "%s, %s %d. %s %d" % [tr(weekday_key), tr("DATE_THE"), int(date_dict["day"]), tr(month_key), int(date_dict["year"])]
	else:
		return "%s, %s %d, %d" % [tr(weekday_key), tr(month_key), int(date_dict["day"]), int(date_dict["year"])]


## Maps Godot weekday (0=Sunday) to DATE_WEEKDAY_FULL_* key.
func _get_weekday_full_key(weekday: int) -> String:
	var keys: Array[String] = ["DATE_WEEKDAY_FULL_SUN", "DATE_WEEKDAY_FULL_MON", "DATE_WEEKDAY_FULL_TUE", "DATE_WEEKDAY_FULL_WED", "DATE_WEEKDAY_FULL_THU", "DATE_WEEKDAY_FULL_FRI", "DATE_WEEKDAY_FULL_SAT"]
	return keys[clampi(weekday, 0, 6)]


## Maps month number (1-12) to DATE_MONTH_* key.
func _get_month_key(month: int) -> String:
	var keys: Array[String] = ["", "DATE_MONTH_JAN", "DATE_MONTH_FEB", "DATE_MONTH_MAR", "DATE_MONTH_APR", "DATE_MONTH_MAY", "DATE_MONTH_JUN", "DATE_MONTH_JUL", "DATE_MONTH_AUG", "DATE_MONTH_SEP", "DATE_MONTH_OCT", "DATE_MONTH_NOV", "DATE_MONTH_DEC"]
	return keys[clampi(month, 1, 12)]


## Returns [param time_dict] formatted as [code]HH:MM[/code].
func _format_time(time_dict: Dictionary) -> String:
	return "%02d:%02d" % [time_dict["hour"], time_dict["minute"]]


## Updates the start time button label to show the selected start time.
func _refresh_start_time_button() -> void:
	start_time_picker_button.text = _format_time(selected_start_time)


## Updates the end time button label to show the selected end time.
func _refresh_end_time_button() -> void:
	end_time_picker_button.text = _format_time(selected_end_time)


## Opens the date picker centered on the currently selected date.
func _on_date_picker_button_pressed() -> void:
	_get_date_picker_popup().show_for_date(selected_date)


## Handles date selection from the popup; updates [member selected_date] and the button label.
func _on_date_selected(date_dict: Dictionary) -> void:
	selected_date = date_dict
	_refresh_date_button()


## Returns [param time_dict] minus one minute, wrapping at midnight (0:00 - 1 min → 23:59).
##
## Used to compute max start time: end time minus one minute so start is always before end.
func _time_minus_one_minute(time_dict: Dictionary) -> Dictionary:
	var h: int = int(time_dict["hour"])
	var m: int = int(time_dict["minute"])
	m -= 1
	if m < 0:
		m = 59
		h -= 1
	if h < 0:
		h = 23
	return {"hour": h, "minute": m}


## Opens the start time picker with the currently selected start time.
##
## Enforces maximum start time as end time - 1 minute so start is always before end.
## Passes empty min dict and max_start so user cannot pick a start time after end.
func _on_start_time_picker_button_pressed() -> void:
	var max_start: Dictionary = _time_minus_one_minute(selected_end_time)
	_get_start_time_picker_popup().show_for_time(selected_start_time, {}, max_start)


## Handles start time selection from the popup.
func _on_start_time_selected(time_dict: Dictionary) -> void:
	selected_start_time = time_dict
	_refresh_start_time_button()


## Returns [param time_dict] plus one minute, wrapping at midnight.
##
## Used to compute min end time: start time plus one minute so end is always after start.
func _time_plus_one_minute(time_dict: Dictionary) -> Dictionary:
	var h: int = int(time_dict["hour"])
	var m: int = int(time_dict["minute"])
	m += 1
	if m >= 60:
		m = 0
		h += 1
	if h >= 24:
		h = 0
	return {"hour": h, "minute": m}


## Opens the end time picker with the currently selected end time.
##
## Enforces minimum end time as start time + 1 minute so end is always after start.
## Passes min_end so user cannot pick an end time before or equal to start.
func _on_end_time_picker_button_pressed() -> void:
	var min_end: Dictionary = _time_plus_one_minute(selected_start_time)
	_get_end_time_picker_popup().show_for_time(selected_end_time, min_end)


## Handles end time selection from the popup.
func _on_end_time_selected(time_dict: Dictionary) -> void:
	selected_end_time = time_dict
	_refresh_end_time_button()


## Submits the work entry and navigates back to the home screen.
##
## Builds the entry dictionary and either updates (edit mode) or adds (add mode) to
## [SaveData], emits [signal work_entry_submitted], then switches to home screen.
func _on_submit() -> void:
	var entry: Dictionary = {
		"date": selected_date.duplicate(),
		"start_time": selected_start_time.duplicate(),
		"end_time": selected_end_time.duplicate(),
		"note": note_input.text
	}
	if _edit_index >= 0:
		SaveData.update_work_entry(_edit_index, entry)
	else:
		SaveData.add_work_entry(entry)
	work_entry_submitted.emit(entry)
	ScreenManager.change_screen(ScreenManager.Screen.HOME_SCREEN)


## Cancels adding or editing; navigates back to home without saving.
func _on_cancel() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.HOME_SCREEN)


## Deletes the work entry at [member _edit_index] and navigates back to the home screen.
func _on_delete() -> void:
	SaveData.remove_work_entry(_edit_index)
	ScreenManager.change_screen(ScreenManager.Screen.HOME_SCREEN)
