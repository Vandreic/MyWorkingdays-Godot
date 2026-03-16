class_name DatePickerPopup
extends PopupPanel
## Reusable calendar date picker popup.
##
## Displays a month grid with day buttons in a 7-column layout (Mon-Sun). Uses Godot's
## [Time] singleton for correct date math (leap years, variable month lengths). Emits
## [signal date_selected] when the user presses a date button. Supports infinite years
## via unix timestamp conversion; no manual leap-year logic required.
##
## How the calendar is constructed:
## 1. The scene provides a [GridContainer] ([member day_grid]) with [code]columns = 7[/code].
## 2. [method _build_day_grid] is called whenever the displayed month changes.
## 3. It computes the weekday of the 1st to know how many empty cells to add before day 1,
##    using Monday-first layout (e.g. if 1st is Wednesday, add 2 spacers so it aligns).
## 4. Days-in-month is computed via unix timestamps (1st of next month - 1st of current
##    month in seconds, divided by 86400). This correctly handles 28/29/30/31 day months.
## 5. Spacer controls fill the initial cells; then one button per day is added.
## 6. Today is highlighted with [code]UI_Selected_Button[/code] theme variation.


signal date_selected(date_dict: Dictionary)

## Number of columns in the day grid (Mon-Sun). Must match the scene's GridContainer columns.
const GRID_COLUMNS: int = 7

## Button to navigate to the previous month.
@onready var prev_month_button: Button = %PrevMonthButton
## Label showing the current month and year (e.g. "2025 March").
@onready var month_year_label: Label = %MonthYearLabel
## Button to navigate to the next month.
@onready var next_month_button: Button = %NextMonthButton
## Button to jump to the current month (today).
@onready var today_button: Button = %TodayButton
## HBoxContainer holding weekday labels (Mon-Sun); populated in [method _ready].
@onready var weekday_row: HBoxContainer = %WeekdayRow
## Grid container that holds day buttons; populated dynamically by [method _build_day_grid].
## Scene defines [code]columns = 7[/code] for Monday–Sunday layout.
@onready var day_grid: GridContainer = %DayGrid

## Year of the month currently displayed in the popup.
var display_year: int = 0
## Month currently displayed in the popup (1-12).
var display_month: int = 0
## Cached today's date; used to highlight the current day in the grid.
var _today_dict: Dictionary = {}


func _ready() -> void:
	# Hide PopupPanel's built-in panel background so only our scene's BackgroundPanel shows.
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	# Cache today's date so _build_day_grid can highlight the current day.
	cache_today_dict()

	prev_month_button.text = tr("DATE_PREV_MONTH")
	next_month_button.text = tr("DATE_NEXT_MONTH")
	today_button.text = tr("DATE_TODAY")
	_connect_signals()
	_populate_weekday_row()


## Caches today's date so [method _build_day_grid] can highlight the current day.
func cache_today_dict() -> void:
	_today_dict = Time.get_date_dict_from_system()
	display_year = _today_dict["year"]
	display_month = _today_dict["month"]


func _connect_signals() -> void:
	prev_month_button.pressed.connect(_on_prev_month)
	next_month_button.pressed.connect(_on_next_month)
	today_button.pressed.connect(_on_today_pressed)


## Opens the popup centered on [param date_dict].
##
## Sets [member display_year] and [member display_month], rebuilds the day grid, updates
## the header label, then shows the popup centered on screen.
##
## [param date_dict] must have keys [code]year[/code], [code]month[/code], and [code]day[/code].
func show_for_date(date_dict: Dictionary) -> void:
	display_year = date_dict["year"]
	display_month = date_dict["month"]
	_build_day_grid()
	_refresh_month_year_label()
	popup_centered()


## Updates the header label to show the current display month and year (e.g. "2025 March").
func _refresh_month_year_label() -> void:
	month_year_label.text = "%d %s" % [display_year, _get_month_name(display_month)]


## Populates the weekday row with labels (Mon-Sun) for Monday-first layout.
## Labels use same min width as day buttons so columns align with the grid below.
func _populate_weekday_row() -> void:
	var keys: Array[String] = [
		"DATE_WEEKDAY_MON", "DATE_WEEKDAY_TUE", "DATE_WEEKDAY_WED", "DATE_WEEKDAY_THU",
		"DATE_WEEKDAY_FRI", "DATE_WEEKDAY_SAT", "DATE_WEEKDAY_SUN"
	]
	for key in keys:
		var lbl := Label.new()
		lbl.theme_type_variation = &"UI_Label_Small"
		lbl.text = tr(key)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size.x = 70.0
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		weekday_row.add_child(lbl)


## Returns the localized month name for [param month] (1-12).
##
## Uses translation keys [code]DATE_MONTH_JAN[/code] through [code]DATE_MONTH_DEC[/code].
## Falls back to [code]str(month)[/code] if out of range.
func _get_month_name(month: int) -> String:
	# Index 0 unused; indices 1-12 map to January–December.
	var keys: Array[String] = [
		"", "DATE_MONTH_JAN", "DATE_MONTH_FEB", "DATE_MONTH_MAR", "DATE_MONTH_APR",
		"DATE_MONTH_MAY", "DATE_MONTH_JUN", "DATE_MONTH_JUL", "DATE_MONTH_AUG",
		"DATE_MONTH_SEP", "DATE_MONTH_OCT", "DATE_MONTH_NOV", "DATE_MONTH_DEC"
	]
	if month >= 1 and month <= 12:
		return tr(keys[month])
	return str(month)


## Clears and rebuilds the day grid for the current [member display_year] and [member display_month]. [br][br]
##
## [b]Calendar construction algorithm:[/b]
## [br]
## 1. [b]Clear grid[/b]: Remove all existing children (spacers and day buttons from previous month).
## [br][br]
## 2. [b]Get weekday offset[/b]: Compute the weekday of the 1st (Godot: 0=Sun..6=Sat). For
##    Monday-first layout, we convert to Mon=0..Sun=6 via [code](weekday + 6) % 7[/code].
##    This gives how many empty cells to add before day 1. Example: 1st is Monday → 0 spacers.
## [br][br]
## 3. [b]Compute days in month[/b]: Use unix timestamps instead of hardcoded 28/29/30/31. [br]
##    - Get unix for 1st of current month. [br]
##    - Get unix for 1st of next month (handle December → January year wrap). [br]
##    - [code](unix_next - unix_first) / 86400[/code] = number of days. Handles leap years correctly.
## [br][br]
## 4. [b]Add spacer cells[/b]: Insert empty [Control] nodes at the start of the grid. [br]
##    The GridContainer fills left-to-right, so these push day 1 into the correct column.
## [br][br]
## 5. [b]Add day buttons[/b]: One button per day. Each button stores its date in a dictionary
##    and connects to [method _on_day_pressed]. Today gets [code]UI_Selected_Button[/code]
##    for visual highlight.
## [br][br]
## [b]Layout:[/b] Grid has 7 columns (Mon-Sun). Row 1 may have leading empty cells; row N
## may have trailing empty cells. Total children = weekday_offset + days_in_month.
func _build_day_grid() -> void:
	# Step 1: Remove existing children (spacers and day buttons from any previous build).
	for child in day_grid.get_children():
		child.queue_free()

	# Step 2: Get weekday of 1st (Godot: 0=Sun..6=Sat). Convert to Monday-first: (weekday+6)%7.
	var unix_first: int = Time.get_unix_time_from_datetime_dict({
		"year": display_year, "month": display_month, "day": 1,
		"hour": 0, "minute": 0, "second": 0
	})
	var first_dict: Dictionary = Time.get_datetime_dict_from_unix_time(unix_first)
	var weekday_offset: int = (first_dict["weekday"] + 6) % 7

	# Step 3: Compute days in current month via unix difference (handles leap years).
	var next_month: int = display_month + 1
	var next_year: int = display_year
	if next_month > 12:
		next_month = 1
		next_year += 1
	var unix_next: int = Time.get_unix_time_from_datetime_dict({
		"year": next_year, "month": next_month, "day": 1,
		"hour": 0, "minute": 0, "second": 0
	})
	var days_in_month: int = int((unix_next - unix_first) / 86400.0)

	# Step 4: Add spacer controls so day 1 aligns with its weekday column (Sun-Sat).
	for i in range(weekday_offset):
		var spacer: Control = Control.new()
		day_grid.add_child(spacer)

	# Step 5: Add one button per day; bind date dict for emission on press; highlight today.
	for day in range(1, days_in_month + 1):
		var btn: Button = Button.new()
		btn.text = str(day)
		btn.custom_minimum_size = Vector2(70, 70)
		btn.theme_type_variation = &"UI_FilledButton"
		var date_dict_for_day: Dictionary = {"year": display_year, "month": display_month, "day": day}
		if _is_today(date_dict_for_day):
			btn.theme_type_variation = &"UI_Selected_Button"
		btn.pressed.connect(_on_day_pressed.bind(date_dict_for_day))
		day_grid.add_child(btn)


## Returns [code]true[/code] if [param date_dict] matches today's date.
func _is_today(date_dict: Dictionary) -> bool:
	return date_dict["year"] == _today_dict["year"] and date_dict["month"] == _today_dict["month"] and date_dict["day"] == _today_dict["day"]


## Emits [signal date_selected] with the chosen date and hides the popup.
func _on_day_pressed(date_dict: Dictionary) -> void:
	date_selected.emit(date_dict)
	hide()


## Navigates to the previous month; wraps to December of previous year when at January.
func _on_prev_month() -> void:
	display_month -= 1
	if display_month < 1:
		display_month = 12
		display_year -= 1
	_build_day_grid()
	_refresh_month_year_label()


## Navigates to the next month; wraps to January of next year when at December.
func _on_next_month() -> void:
	display_month += 1
	if display_month > 12:
		display_month = 1
		display_year += 1
	_build_day_grid()
	_refresh_month_year_label()


## Jumps to the current month (today); refreshes the grid and header.
func _on_today_pressed() -> void:
	display_year = _today_dict["year"]
	display_month = _today_dict["month"]
	_build_day_grid()
	_refresh_month_year_label()
