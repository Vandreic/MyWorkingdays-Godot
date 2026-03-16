class_name TimePickerPopup
extends PopupPanel
## Reusable time picker popup.
##
## Displays hour (0-23) and minute (0-59) LineEdit fields that accept only digits.[br]
## Emits [signal time_selected] when the user confirms with OK.[br]
## Use [method show_for_time] to open with a given time.
##
## Optional constraints: pass [code]min_time_dict[/code] and [code]max_time_dict[/code] to
## [method show_for_time] to limit the selectable range (e.g. end must be after start).[br]
## When constraints are set, the selected time is clamped to the valid range on OK.

## Emitted when the user confirms the selection with OK. [br][br]
##
## [param time_dict] contains [code]hour[/code] (0-23) and [code]minute[/code] (0-59).
## The time is clamped to the valid range when constraints are set.
signal time_selected(time_dict: Dictionary)

## Label for the hour field.
@onready var hour_label: Label = %HourLabel
## LineEdit for hour selection (0-23).
@onready var hour_line_edit: LineEdit = %HourLineEdit
## Label for the minute field.
@onready var minute_label: Label = %MinuteLabel
## LineEdit for minute selection (0-59).
@onready var minute_line_edit: LineEdit = %MinuteLineEdit
## Button to confirm selection and emit [signal time_selected].
@onready var ok_button: Button = %OKButton

## When set, enforces minimum selectable time (used for end-time picker).
var _min_time: Dictionary = {}
## When set, enforces maximum selectable time (used for start-time picker).
var _max_time: Dictionary = {}


func _ready() -> void:
	# Hide PopupPanel's built-in panel background so only our scene's BackgroundPanel shows.
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_connect_signals()
	_update_ui_with_new_language()


## Connects signals to handlers.
func _connect_signals() -> void:
	hour_line_edit.text_changed.connect(_on_hour_text_changed)
	minute_line_edit.text_changed.connect(_on_minute_text_changed)
	ok_button.pressed.connect(_on_ok_pressed)


## Updates the UI with the new language.
func _update_ui_with_new_language() -> void:
	hour_label.text = tr("TIME_PICKER_HOUR")
	minute_label.text = tr("TIME_PICKER_MINUTE")
	ok_button.text = tr("TIME_PICKER_OK")


## Filters hour LineEdit to digits only, max 2 chars.
func _on_hour_text_changed(_new_text: String) -> void:
	_filter_digit_input(hour_line_edit, 2)


## Filters minute LineEdit to digits only, max 2 chars.
func _on_minute_text_changed(_new_text: String) -> void:
	_filter_digit_input(minute_line_edit, 2)


## Keeps only digits in [param line_edit], up to [param max_len] characters.
func _filter_digit_input(line_edit: LineEdit, max_len: int) -> void:
	var text := ""
	for c in line_edit.text:
		if c.is_valid_int() and text.length() < max_len:
			text += c
	if text != line_edit.text:
		var caret := line_edit.caret_column
		line_edit.text = text
		line_edit.caret_column = mini(caret, text.length())


## Returns current hour (0-23), treating empty as 0.
func _get_hour() -> int:
	return clampi(int(hour_line_edit.text) if hour_line_edit.text else 0, 0, 23)


## Returns current minute (0-59), treating empty as 0.
func _get_minute() -> int:
	return clampi(int(minute_line_edit.text) if minute_line_edit.text else 0, 0, 59)


## Sets the displayed hour and minute values.
func _set_time(hour: int, minute: int) -> void:
	hour_line_edit.text = str(clampi(hour, 0, 23))
	minute_line_edit.text = str(clampi(minute, 0, 59))


## Opens the popup with [param time_dict] pre-selected.
##
## [param time_dict] must have keys [code]hour[/code] (0-23) and [code]minute[/code] (0-59).[br]
## [param min_time_dict] optionally enforces a minimum time (e.g. end must be after start).[br]
## [param max_time_dict] optionally enforces a maximum time (e.g. start must be before end).[br]
## When constraints are provided, the pre-selected time is clamped to the valid range.
func show_for_time(time_dict: Dictionary, min_time_dict: Dictionary = {}, max_time_dict: Dictionary = {}) -> void:
	_min_time = min_time_dict
	_max_time = max_time_dict

	# Parse requested time and clamp to valid range (0-23, 0-59 and within constraints).
	var h: int = clampi(int(time_dict["hour"]), 0, 23)
	var m: int = clampi(int(time_dict["minute"]), 0, 59)

	if not _min_time.is_empty():
		var min_h: int = int(_min_time["hour"])
		var min_m: int = int(_min_time["minute"])
		if h < min_h or (h == min_h and m < min_m):
			h = min_h
			m = min_m

	if not _max_time.is_empty():
		var max_h: int = int(_max_time["hour"])
		var max_m: int = int(_max_time["minute"])
		if h > max_h or (h == max_h and m > max_m):
			h = max_h
			m = max_m

	_set_time(h, m)
	popup_centered()


## Emits [signal time_selected] with current hour/minute (clamped to constraints), then hides the popup.
func _on_ok_pressed() -> void:
	var h: int = _get_hour()
	var m: int = _get_minute()

	# Apply min/max constraints.
	if not _min_time.is_empty():
		var min_h: int = int(_min_time["hour"])
		var min_m: int = int(_min_time["minute"])
		if h < min_h or (h == min_h and m < min_m):
			h = min_h
			m = min_m

	if not _max_time.is_empty():
		var max_h: int = int(_max_time["hour"])
		var max_m: int = int(_max_time["minute"])
		if h > max_h or (h == max_h and m > max_m):
			h = max_h
			m = max_m

	time_selected.emit({"hour": h, "minute": m})
	hide()
