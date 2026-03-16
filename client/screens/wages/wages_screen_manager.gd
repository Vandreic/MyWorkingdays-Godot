class_name WagesScreenManager
extends BaseScreenTemplateManager
## Manages the wages screen where users enter hourly wage, tax percentage, personal allowance (fradrag),
## and optional evening/night supplement wages with time windows.
##
## Loads values from [member SaveData.save_data_dict] and persists via [method SaveData.set_wage_settings]
## and [method SaveData.set_supplement_settings]. A home button in the nav bar returns to the home screen.

## Preloaded TimePickerPopup scene for time window selection.
const TIME_PICKER_SCENE: PackedScene = preload("res://components/popups/time_picker/time_picker_popup.tscn")
## Preloaded [code]LocaleUtils[/code] for number formatting and parsing.
const LOCALE_UTILS = preload("res://utilities/locale_utils.gd")

## Label showing the screen title.
@onready var title_label: Label = %TitleLabel
## LineEdit for hourly wage input.
@onready var hourly_wage_input: LineEdit = %HourlyWageInput
## Label for the hourly wage field.
@onready var hourly_wage_label: Label = %HourlyWageLabel
## LineEdit for tax percentage input (0-100).
@onready var tax_percentage_input: LineEdit = %TaxPercentageInput
## Label for the tax percentage field.
@onready var tax_percentage_label: Label = %TaxPercentageLabel
## LineEdit for personal allowance (fradrag) input.
@onready var personal_allowance_input: LineEdit = %PersonalAllowanceInput
## Label for the personal allowance field.
@onready var personal_allowance_label: Label = %PersonalAllowanceLabel
## Button to save wage settings.
@onready var save_button: Button = %SaveButton
## ScrollContainer for the wages form; used for keyboard-aware scroll.
@onready var wages_scroll_container: ScrollContainer = %WagesScrollContainer
## Evening supplement inputs.
@onready var evening_wage_input: LineEdit = %EveningWageInput
@onready var evening_wage_label: Label = %EveningWageLabel
@onready var evening_start_button: Button = %EveningStartButton
@onready var evening_end_button: Button = %EveningEndButton
@onready var evening_window_from_label: Label = %EveningWindowFromLabel
@onready var evening_window_to_label: Label = %EveningWindowToLabel
## Night supplement inputs.
@onready var night_wage_input: LineEdit = %NightWageInput
@onready var night_wage_label: Label = %NightWageLabel
@onready var night_start_button: Button = %NightStartButton
@onready var night_end_button: Button = %NightEndButton
@onready var night_window_from_label: Label = %NightWindowFromLabel
@onready var night_window_to_label: Label = %NightWindowToLabel
## Saturday supplement inputs.
@onready var saturday_wage_input: LineEdit = %SaturdayWageInput
@onready var saturday_wage_label: Label = %SaturdayWageLabel
@onready var saturday_start_button: Button = %SaturdayStartButton
@onready var saturday_end_button: Button = %SaturdayEndButton
@onready var saturday_window_from_label: Label = %SaturdayWindowFromLabel
@onready var saturday_window_to_label: Label = %SaturdayWindowToLabel
## Sunday supplement inputs.
@onready var sunday_wage_input: LineEdit = %SundayWageInput
@onready var sunday_wage_label: Label = %SundayWageLabel
@onready var sunday_start_button: Button = %SundayStartButton
@onready var sunday_end_button: Button = %SundayEndButton
@onready var sunday_window_from_label: Label = %SundayWindowFromLabel
@onready var sunday_window_to_label: Label = %SundayWindowToLabel
## Button in the nav bar that navigates back to the home screen.
@onready var home_button: Button = %HomeButton
## Button to open the wages screen (refresh when already on wages).
@onready var wages_button: Button = %WagesButton
## Button to open the salary screen.
@onready var salary_button: Button = %SalaryButton

## Cached [code]{hour, minute}[/code] dict for the evening window start.
var _evening_start_time: Dictionary = {"hour": 18, "minute": 0}
## Cached [code]{hour, minute}[/code] dict for the evening window end.
var _evening_end_time: Dictionary = {"hour": 22, "minute": 0}
## Cached [code]{hour, minute}[/code] dict for the night window start.
var _night_start_time: Dictionary = {"hour": 22, "minute": 0}
## Cached [code]{hour, minute}[/code] dict for the night window end.
var _night_end_time: Dictionary = {"hour": 6, "minute": 0}
## Cached [code]{hour, minute}[/code] dict for the Saturday window start.
var _saturday_start_time: Dictionary = {"hour": 0, "minute": 0}
## Cached [code]{hour, minute}[/code] dict for the Saturday window end.
var _saturday_end_time: Dictionary = {"hour": 23, "minute": 59}
## Cached [code]{hour, minute}[/code] dict for the Sunday window start.
var _sunday_start_time: Dictionary = {"hour": 0, "minute": 0}
## Cached [code]{hour, minute}[/code] dict for the Sunday window end.
var _sunday_end_time: Dictionary = {"hour": 23, "minute": 59}
## Shared TimePickerPopup instance; created on first use.
var _time_picker_popup: TimePickerPopup
## Target identifier when the time picker returns (e.g. [code]"evening_start"[/code]).
var _time_picker_target: String = ""
## Overlay that catches taps outside Saturday/Sunday inputs; removed when tapped or when focus exits.
var _dismiss_overlay: Control
## Input that has focus when overlay is shown; released when overlay is tapped.
var _focused_weekend_input: LineEdit
## Spacer added to FieldsContainer when Saturday/Sunday is focused; removed on unfocus.
var _keyboard_spacer: Control
## Scroll position before focus; restored when unfocusing.
var _scroll_position_before_focus: int = 0
## Last known virtual keyboard height; used to detect keyboard dismiss on mobile.
var _last_keyboard_height: int = 0


func _ready() -> void:
	super._ready()
	_load_values_from_save_data()
	_update_ui_with_new_language()
	_connect_signals()
	apply_navbar_button_styles([home_button, wages_button, salary_button], wages_button)


func _get_settings_return_screen() -> int:
	return ScreenManager.Screen.WAGES_SCREEN


## Polls virtual keyboard height on mobile.[br]
## When keyboard is dismissed while a weekend input has focus: removes spacer, overlay, and restores scroll.[br]
## When keyboard reappears and a weekend input owns focus: re-adds spacer and scroll (handles re-tap after dismiss).
func _process(_delta: float) -> void:
	if not _is_mobile_os():
		return
	var current := DisplayServer.virtual_keyboard_get_height()
	# Keyboard was dismissed while weekend input had focus.
	if is_instance_valid(_focused_weekend_input) and is_instance_valid(_keyboard_spacer):
		if _last_keyboard_height > 0 and current == 0:
			_remove_keyboard_spacer()
			_remove_dismiss_overlay()
			_focused_weekend_input = null
			_last_keyboard_height = 0
			var restore_val := clampi(_scroll_position_before_focus, 0, int(wages_scroll_container.get_v_scroll_bar().max_value))
			wages_scroll_container.set_deferred("scroll_vertical", restore_val)
		else:
			_last_keyboard_height = current
		return
	# Keyboard appeared again; user tapped the same weekend input. Re-add spacer and scroll.
	if _last_keyboard_height == 0 and current > 0:
		var focused := get_viewport().gui_get_focus_owner()
		if focused == saturday_wage_input or focused == sunday_wage_input:
			_on_weekend_input_focused(focused)
	_last_keyboard_height = current


## Loads wage values from [member SaveData.save_data_dict] into the input fields.
func _load_values_from_save_data() -> void:
	hourly_wage_input.text = LOCALE_UTILS.format_number(float(SaveData.save_data_dict["hourly_wage"]), 2, true)
	tax_percentage_input.text = LOCALE_UTILS.format_number(float(SaveData.save_data_dict["tax_percentage"]), 2, false)
	personal_allowance_input.text = LOCALE_UTILS.format_number(float(SaveData.save_data_dict["personal_allowance"]), 2, true)
	evening_wage_input.text = LOCALE_UTILS.format_number(float(SaveData.save_data_dict["evening_wage"]), 2, true)
	night_wage_input.text = LOCALE_UTILS.format_number(float(SaveData.save_data_dict["night_wage"]), 2, true)
	_evening_start_time = _sanitize_time_dict(SaveData.save_data_dict.get("evening_window_start", {"hour": 18, "minute": 0}))
	_evening_end_time = _sanitize_time_dict(SaveData.save_data_dict.get("evening_window_end", {"hour": 22, "minute": 0}))
	_night_start_time = _sanitize_time_dict(SaveData.save_data_dict.get("night_window_start", {"hour": 22, "minute": 0}))
	_night_end_time = _sanitize_time_dict(SaveData.save_data_dict.get("night_window_end", {"hour": 6, "minute": 0}))
	_saturday_start_time = _sanitize_time_dict(SaveData.save_data_dict.get("saturday_window_start", {"hour": 0, "minute": 0}))
	_saturday_end_time = _sanitize_time_dict(SaveData.save_data_dict.get("saturday_window_end", {"hour": 23, "minute": 59}))
	_sunday_start_time = _sanitize_time_dict(SaveData.save_data_dict.get("sunday_window_start", {"hour": 0, "minute": 0}))
	_sunday_end_time = _sanitize_time_dict(SaveData.save_data_dict.get("sunday_window_end", {"hour": 23, "minute": 59}))
	saturday_wage_input.text = LOCALE_UTILS.format_number(float(SaveData.save_data_dict.get("saturday_wage", 0.0)), 2, true)
	sunday_wage_input.text = LOCALE_UTILS.format_number(float(SaveData.save_data_dict.get("sunday_wage", 0.0)), 2, true)
	_refresh_time_buttons()


## Ensures [param d] has valid hour (0-23) and minute (0-59).[br]
## Returns a safe copy.
func _sanitize_time_dict(d: Dictionary) -> Dictionary:
	var h: int = clampi(int(d.get("hour", 0)), 0, 23)
	var m: int = clampi(int(d.get("minute", 0)), 0, 59)
	return {"hour": h, "minute": m}


## Updates labels with translated strings.
func _update_ui_with_new_language() -> void:
	title_label.text = tr("WAGES_TITLE")
	home_button.get_node("VBoxContainer/Label").text = tr("NAV_HOME")
	wages_button.get_node("VBoxContainer/Label").text = tr("NAV_WAGES")
	salary_button.get_node("VBoxContainer/Label").text = tr("NAV_SALARY")
	hourly_wage_label.text = tr("WAGES_HOURLY_LABEL")
	tax_percentage_label.text = tr("WAGES_TAX_LABEL")
	personal_allowance_label.text = tr("WAGES_PERSONAL_ALLOWANCE_LABEL")
	evening_wage_label.text = tr("WAGES_EVENING_SUPPLEMENT_LABEL")
	night_wage_label.text = tr("WAGES_NIGHT_SUPPLEMENT_LABEL")
	evening_window_from_label.text = tr("WAGES_WINDOW_FROM")
	evening_window_to_label.text = tr("WAGES_WINDOW_TO")
	night_window_from_label.text = tr("WAGES_WINDOW_FROM")
	night_window_to_label.text = tr("WAGES_WINDOW_TO")
	saturday_wage_label.text = tr("WAGES_SATURDAY_SUPPLEMENT_LABEL")
	sunday_wage_label.text = tr("WAGES_SUNDAY_SUPPLEMENT_LABEL")
	saturday_window_from_label.text = tr("WAGES_WINDOW_FROM")
	saturday_window_to_label.text = tr("WAGES_WINDOW_TO")
	sunday_window_from_label.text = tr("WAGES_WINDOW_FROM")
	sunday_window_to_label.text = tr("WAGES_WINDOW_TO")
	save_button.text = tr("WAGES_SAVE_BUTTON")
	home_button.tooltip_text = tr("WAGES_HOME_BUTTON_TOOLTIP")


## Returns [param time_dict] formatted as HH:MM.
func _format_time(time_dict: Dictionary) -> String:
	return "%02d:%02d" % [time_dict["hour"], time_dict["minute"]]


## Updates all time window buttons with current values.
func _refresh_time_buttons() -> void:
	evening_start_button.text = _format_time(_evening_start_time)
	evening_end_button.text = _format_time(_evening_end_time)
	night_start_button.text = _format_time(_night_start_time)
	night_end_button.text = _format_time(_night_end_time)
	saturday_start_button.text = _format_time(_saturday_start_time)
	saturday_end_button.text = _format_time(_saturday_end_time)
	sunday_start_button.text = _format_time(_sunday_start_time)
	sunday_end_button.text = _format_time(_sunday_end_time)


## Returns the shared TimePickerPopup instance, creating it on first use.
func _get_time_picker_popup() -> TimePickerPopup:
	if _time_picker_popup == null:
		_time_picker_popup = TIME_PICKER_SCENE.instantiate() as TimePickerPopup
		_time_picker_popup.time_selected.connect(_on_time_picker_selected)
		add_child(_time_picker_popup)
	return _time_picker_popup


## Handles time selection from the picker; updates the target field and button.
func _on_time_picker_selected(time_dict: Dictionary) -> void:
	match _time_picker_target:
		"evening_start":
			_evening_start_time = time_dict
		"evening_end":
			_evening_end_time = time_dict
		"night_start":
			_night_start_time = time_dict
		"night_end":
			_night_end_time = time_dict
		"saturday_start":
			_saturday_start_time = time_dict
		"saturday_end":
			_saturday_end_time = time_dict
		"sunday_start":
			_sunday_start_time = time_dict
		"sunday_end":
			_sunday_end_time = time_dict
	_refresh_time_buttons()


## Connects button signals to handlers.
func _connect_signals() -> void:
	save_button.pressed.connect(_on_save_pressed)
	home_button.pressed.connect(_on_home_pressed)
	wages_button.pressed.connect(_on_wages_button_pressed)
	salary_button.pressed.connect(_on_salary_button_pressed)
	hourly_wage_input.text_changed.connect(_on_hourly_wage_text_changed)
	tax_percentage_input.text_changed.connect(_on_tax_text_changed)
	personal_allowance_input.text_changed.connect(_on_personal_allowance_text_changed)
	evening_wage_input.text_changed.connect(_on_evening_wage_text_changed)
	night_wage_input.text_changed.connect(_on_night_wage_text_changed)
	saturday_wage_input.text_changed.connect(_on_saturday_wage_text_changed)
	sunday_wage_input.text_changed.connect(_on_sunday_wage_text_changed)
	evening_start_button.pressed.connect(_on_evening_start_pressed)
	evening_end_button.pressed.connect(_on_evening_end_pressed)
	night_start_button.pressed.connect(_on_night_start_pressed)
	night_end_button.pressed.connect(_on_night_end_pressed)
	saturday_start_button.pressed.connect(_on_saturday_start_pressed)
	saturday_end_button.pressed.connect(_on_saturday_end_pressed)
	sunday_start_button.pressed.connect(_on_sunday_start_pressed)
	sunday_end_button.pressed.connect(_on_sunday_end_pressed)
	saturday_wage_input.focus_entered.connect(_on_weekend_input_focused.bind(saturday_wage_input))
	sunday_wage_input.focus_entered.connect(_on_weekend_input_focused.bind(sunday_wage_input))
	saturday_wage_input.focus_exited.connect(_on_weekend_input_unfocused)
	sunday_wage_input.focus_exited.connect(_on_weekend_input_unfocused)


## Returns [code]true[/code] if running on Android or iOS.
func _is_mobile_os() -> bool:
	var os_name := OS.get_name()
	return os_name == "Android" or os_name == "iOS"


## When Saturday or Sunday input gains focus: shows overlay; on mobile, adds spacer and scrolls to bottom.[br]
## [param input] is the weekend [LineEdit] that gained focus.
func _on_weekend_input_focused(input: LineEdit) -> void:
	_add_dismiss_overlay(input)
	if not _is_mobile_os():
		return
	_scroll_position_before_focus = wages_scroll_container.scroll_vertical
	_remove_keyboard_spacer()
	var fields_container := wages_scroll_container.get_child(0) as VBoxContainer
	if not fields_container:
		return
	_keyboard_spacer = Control.new()
	var viewport_h: float = get_viewport().size.y
	if input == saturday_wage_input:
		_keyboard_spacer.custom_minimum_size = Vector2(0, int(viewport_h * 0.06))
	else:
		_keyboard_spacer.custom_minimum_size = Vector2(0, int(viewport_h * 0.125))
	fields_container.add_child(_keyboard_spacer)
	call_deferred("_scroll_to_bottom")
	


## When Saturday or Sunday input loses focus: removes overlay; on mobile, removes spacer and restores scroll.
func _on_weekend_input_unfocused() -> void:
	_remove_dismiss_overlay()
	_last_keyboard_height = 0
	if not _is_mobile_os():
		return
	_remove_keyboard_spacer()
	var restore_val := clampi(_scroll_position_before_focus, 0, int(wages_scroll_container.get_v_scroll_bar().max_value))
	wages_scroll_container.set_deferred("scroll_vertical", restore_val)


## Adds a full-screen transparent overlay that catches taps.[br]
## When tapped outside [param input], releases focus and removes itself.
func _add_dismiss_overlay(input: LineEdit) -> void:
	_remove_dismiss_overlay()
	_focused_weekend_input = input
	_dismiss_overlay = Control.new()
	_dismiss_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dismiss_overlay.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_dismiss_overlay.grow_vertical = Control.GROW_DIRECTION_BOTH
	_dismiss_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_dismiss_overlay.gui_input.connect(_on_dismiss_overlay_gui_input)
	add_child(_dismiss_overlay)


## Removes [member _keyboard_spacer] from its parent and frees it if valid.
func _remove_keyboard_spacer() -> void:
	if is_instance_valid(_keyboard_spacer) and _keyboard_spacer.get_parent():
		_keyboard_spacer.get_parent().remove_child(_keyboard_spacer)
		_keyboard_spacer.queue_free()
	_keyboard_spacer = null


## Scrolls [member wages_scroll_container] to the bottom.[br]
## Call via [code]call_deferred[/code] after adding [member _keyboard_spacer].
func _scroll_to_bottom() -> void:
	var v_bar := wages_scroll_container.get_v_scroll_bar()
	wages_scroll_container.set_deferred("scroll_vertical", int(v_bar.max_value))


## Removes [member _dismiss_overlay] and clears [member _focused_weekend_input] if overlay exists.
func _remove_dismiss_overlay() -> void:
	if is_instance_valid(_dismiss_overlay):
		if _dismiss_overlay.gui_input.is_connected(_on_dismiss_overlay_gui_input):
			_dismiss_overlay.gui_input.disconnect(_on_dismiss_overlay_gui_input)
		_dismiss_overlay.queue_free()
		_dismiss_overlay = null
	_focused_weekend_input = null


## Handles tap on [member _dismiss_overlay]: releases focus and removes overlay.[br]
## Ignores taps on [member _focused_weekend_input]'s rect so re-tapping the field does not dismiss.[br]
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
	if not is_tap or not is_instance_valid(_focused_weekend_input):
		return
	# Do not dismiss if user tapped on the input field itself (e.g. to reposition cursor).
	if _focused_weekend_input.get_global_rect().has_point(tap_position):
		return
	_focused_weekend_input.release_focus()
	_remove_dismiss_overlay()
	get_viewport().set_input_as_handled()


## Filters input to digits, locale decimal separator, and thousand separator only.
## Allows only the locale-appropriate decimal separator. [param line_edit] is the LineEdit to filter.
func _filter_non_negative_float_input(line_edit: LineEdit) -> void:
	var dec_sep: String = LOCALE_UTILS.get_decimal_separator()
	var thous_sep: String = LOCALE_UTILS.get_thousand_separator()
	var filtered := ""
	var has_decimal := false
	for c in line_edit.text:
		if c == dec_sep and not has_decimal:
			filtered += c
			has_decimal = true
		elif c == thous_sep:
			filtered += c
		elif c >= "0" and c <= "9":
			filtered += c
	if filtered != line_edit.text:
		var caret := line_edit.caret_column
		line_edit.text = filtered
		line_edit.caret_column = mini(caret, filtered.length())


## Filters tax input to digits, locale decimal separator, and clamps value to 0-100.
## [param line_edit] is the LineEdit to filter.
func _filter_tax_input(line_edit: LineEdit) -> void:
	_filter_non_negative_float_input(line_edit)
	if not line_edit.text.is_empty():
		var val: float = LOCALE_UTILS.parse_localized_float(line_edit.text)
		if val > 100.0:
			line_edit.text = LOCALE_UTILS.format_number(100.0, 2, false)
			line_edit.caret_column = line_edit.text.length()


## Filters [member hourly_wage_input] to non-negative float.
func _on_hourly_wage_text_changed(_new_text: String) -> void:
	_filter_non_negative_float_input(hourly_wage_input)


## Filters [member tax_percentage_input] to 0-100.
func _on_tax_text_changed(_new_text: String) -> void:
	_filter_tax_input(tax_percentage_input)


## Filters [member personal_allowance_input] to non-negative float.
func _on_personal_allowance_text_changed(_new_text: String) -> void:
	_filter_non_negative_float_input(personal_allowance_input)


## Filters [member evening_wage_input] to non-negative float.
func _on_evening_wage_text_changed(_new_text: String) -> void:
	_filter_non_negative_float_input(evening_wage_input)


## Filters [member night_wage_input] to non-negative float.
func _on_night_wage_text_changed(_new_text: String) -> void:
	_filter_non_negative_float_input(night_wage_input)


## Filters [member saturday_wage_input] to non-negative float.
func _on_saturday_wage_text_changed(_new_text: String) -> void:
	_filter_non_negative_float_input(saturday_wage_input)


## Filters [member sunday_wage_input] to non-negative float.
func _on_sunday_wage_text_changed(_new_text: String) -> void:
	_filter_non_negative_float_input(sunday_wage_input)


## Opens the time picker for the evening start time.
func _on_evening_start_pressed() -> void:
	_time_picker_target = "evening_start"
	_get_time_picker_popup().show_for_time(_evening_start_time)


## Opens the time picker for the evening end time.
func _on_evening_end_pressed() -> void:
	_time_picker_target = "evening_end"
	_get_time_picker_popup().show_for_time(_evening_end_time)


## Opens the time picker for the night start time.
func _on_night_start_pressed() -> void:
	_time_picker_target = "night_start"
	_get_time_picker_popup().show_for_time(_night_start_time)


## Opens the time picker for the night end time.
func _on_night_end_pressed() -> void:
	_time_picker_target = "night_end"
	_get_time_picker_popup().show_for_time(_night_end_time)


## Opens the time picker for the Saturday start time.
func _on_saturday_start_pressed() -> void:
	_time_picker_target = "saturday_start"
	_get_time_picker_popup().show_for_time(_saturday_start_time)


## Opens the time picker for the Saturday end time.
func _on_saturday_end_pressed() -> void:
	_time_picker_target = "saturday_end"
	_get_time_picker_popup().show_for_time(_saturday_end_time)


## Opens the time picker for the Sunday start time.
func _on_sunday_start_pressed() -> void:
	_time_picker_target = "sunday_start"
	_get_time_picker_popup().show_for_time(_sunday_start_time)


## Opens the time picker for the Sunday end time.
func _on_sunday_end_pressed() -> void:
	_time_picker_target = "sunday_end"
	_get_time_picker_popup().show_for_time(_sunday_end_time)


## Parses [param text] as a float using locale-appropriate separators. Returns 0.0 if invalid.
func _parse_float_safe(text: String) -> float:
	return LOCALE_UTILS.parse_localized_float(text)


## Validates inputs (clamps to valid ranges), updates SaveData, and persists to file.
func _on_save_pressed() -> void:
	var hourly_wage: float = maxf(0.0, _parse_float_safe(hourly_wage_input.text))
	var tax_percentage: float = clampf(_parse_float_safe(tax_percentage_input.text), 0.0, 100.0)
	var personal_allowance: float = maxf(0.0, _parse_float_safe(personal_allowance_input.text))
	var evening_wage: float = maxf(0.0, _parse_float_safe(evening_wage_input.text))
	var night_wage: float = maxf(0.0, _parse_float_safe(night_wage_input.text))
	var saturday_wage: float = maxf(0.0, _parse_float_safe(saturday_wage_input.text))
	var sunday_wage: float = maxf(0.0, _parse_float_safe(sunday_wage_input.text))
	SaveData.set_wage_settings(hourly_wage, tax_percentage, personal_allowance)
	SaveData.set_supplement_settings(evening_wage, _evening_start_time, _evening_end_time, night_wage, _night_start_time, _night_end_time)
	SaveData.set_weekend_supplement_settings(saturday_wage, _saturday_start_time, _saturday_end_time, sunday_wage, _sunday_start_time, _sunday_end_time)
	hourly_wage_input.text = LOCALE_UTILS.format_number(hourly_wage, 2, true)
	tax_percentage_input.text = LOCALE_UTILS.format_number(tax_percentage, 2, false)
	personal_allowance_input.text = LOCALE_UTILS.format_number(personal_allowance, 2, true)
	evening_wage_input.text = LOCALE_UTILS.format_number(evening_wage, 2, true)
	night_wage_input.text = LOCALE_UTILS.format_number(night_wage, 2, true)
	saturday_wage_input.text = LOCALE_UTILS.format_number(saturday_wage, 2, true)
	sunday_wage_input.text = LOCALE_UTILS.format_number(sunday_wage, 2, true)


## Navigates back to the home screen.
func _on_home_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.HOME_SCREEN)


## Navigates to the wages screen (refreshes when already on wages).
func _on_wages_button_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.WAGES_SCREEN)


## Navigates to the salary screen.
func _on_salary_button_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.SALARY_SCREEN)
