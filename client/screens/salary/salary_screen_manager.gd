class_name SalaryScreenManager
extends BaseScreenTemplateManager
## Manages the salary screen showing a Danish-style payslip (lønseddel).
##
## Calculates total work hours from [member SaveData.save_data_dict]["work_entries"],
## then gross salary, Arbejdsmarkedets Tillægspension (ATP), Arbejdsmarkedsbidrag (8%), fradrag, income tax, and net salary.
## Uses hourly wage, tax percentage, and personal allowance from SaveData.

## Preloaded [code]LocaleUtils[/code] for number formatting.
const LOCALE_UTILS = preload("res://utilities/locale_utils.gd")

## Label showing the screen title.
@onready var title_label: Label = %TitleLabel
## Scroll container for the payslip content; hidden when empty.
@onready var salary_scroll_container: ScrollContainer = %SalaryScrollContainer
## Label for empty state when no work entries or hourly wage is 0.
@onready var empty_message_label: Label = %EmptyMessageLabel
## Wage breakdown rows (each has TypeLabel, HoursValue, RateValue, AmountValue or similar).
@onready var normal_hours_row: HBoxContainer = %NormalHoursRow
@onready var evening_supplement_row: HBoxContainer = %EveningSupplementRow
@onready var night_supplement_row: HBoxContainer = %NightSupplementRow
@onready var saturday_supplement_row: HBoxContainer = %SaturdaySupplementRow
@onready var sunday_supplement_row: HBoxContainer = %SundaySupplementRow
## Wage row value labels.
@onready var normal_hours_value: Label = %NormalHoursValue
@onready var normal_hours_rate_value: Label = %NormalHoursRateValue
@onready var normal_hours_amount_value: Label = %NormalHoursAmountValue
@onready var evening_supplement_hours_value: Label = %EveningSupplementHoursValue
@onready var evening_supplement_rate_value: Label = %EveningSupplementRateValue
@onready var evening_supplement_amount_value: Label = %EveningSupplementAmountValue
@onready var night_supplement_hours_value: Label = %NightSupplementHoursValue
@onready var night_supplement_rate_value: Label = %NightSupplementRateValue
@onready var night_supplement_amount_value: Label = %NightSupplementAmountValue
@onready var saturday_supplement_hours_value: Label = %SaturdaySupplementHoursValue
@onready var saturday_supplement_rate_value: Label = %SaturdaySupplementRateValue
@onready var saturday_supplement_amount_value: Label = %SaturdaySupplementAmountValue
@onready var sunday_supplement_hours_value: Label = %SundaySupplementHoursValue
@onready var sunday_supplement_rate_value: Label = %SundaySupplementRateValue
@onready var sunday_supplement_amount_value: Label = %SundaySupplementAmountValue
## Gross total and step values.
@onready var gross_total_value: Label = %GrossTotalValue
@onready var step1_gross_value: Label = %Step1GrossValue
@onready var step2_atp_value: Label = %Step2AtpValue
@onready var step3_after_atp_value: Label = %Step3AfterAtpValue
@onready var step4_am_bidrag_value: Label = %Step4AmBidragValue
@onready var step5_after_am_value: Label = %Step5AfterAmValue
@onready var step6_fradrag_value: Label = %Step6FradragValue
@onready var step7_taxable_value: Label = %Step7TaxableValue
@onready var step8_skat_value: Label = %Step8SkatValue
@onready var step9_net_value: Label = %Step9NetValue
## Section labels and type labels for translation.
@onready var type_header: Label = %TypeHeader
@onready var hours_header: Label = %HoursHeader
@onready var rate_header: Label = %RateHeader
@onready var amount_header: Label = %AmountHeader
@onready var wages_section_label: Label = %WagesSectionLabel
@onready var gross_total_label: Label = %GrossTotalLabel
@onready var tax_and_deductions_section_label: Label = %TaxAndDeductionsSectionLabel
@onready var normal_hours_type_label: Label = %NormalHoursTypeLabel
@onready var evening_supplement_type_label: Label = %EveningSupplementTypeLabel
@onready var night_supplement_type_label: Label = %NightSupplementTypeLabel
@onready var saturday_supplement_type_label: Label = %SaturdaySupplementTypeLabel
@onready var sunday_supplement_type_label: Label = %SundaySupplementTypeLabel
@onready var step1_gross_label: Label = %Step1GrossLabel
@onready var step2_atp_label: Label = %Step2AtpLabel
@onready var step3_after_atp_label: Label = %Step3AfterAtpLabel
@onready var step4_am_bidrag_label: Label = %Step4AmBidragLabel
@onready var step5_after_am_label: Label = %Step5AfterAmLabel
@onready var step6_fradrag_label: Label = %Step6FradragLabel
@onready var step7_taxable_label: Label = %Step7TaxableLabel
@onready var step8_skat_label: Label = %Step8SkatLabel
@onready var step9_net_label: Label = %Step9NetLabel
## Button in the nav bar that navigates back to the home screen.
@onready var home_button: Button = %HomeButton
## Button to open the wages screen.
@onready var wages_button: Button = %WagesButton
## Button to open the salary screen (refresh when already on salary).
@onready var salary_button: Button = %SalaryButton


func _ready() -> void:
	super._ready()
	_update_ui_with_new_language()
	_connect_signals()
	apply_navbar_button_styles([home_button, wages_button, salary_button], salary_button)
	_refresh_payslip()


func _get_settings_return_screen() -> int:
	return ScreenManager.Screen.SALARY_SCREEN


## Updates labels with translated strings.
func _update_ui_with_new_language() -> void:
	title_label.text = tr("SALARY_TITLE")
	home_button.get_node("VBoxContainer/Label").text = tr("NAV_HOME")
	wages_button.get_node("VBoxContainer/Label").text = tr("NAV_WAGES")
	salary_button.get_node("VBoxContainer/Label").text = tr("NAV_SALARY")
	empty_message_label.text = tr("SALARY_EMPTY_MESSAGE")
	home_button.tooltip_text = tr("WAGES_HOME_BUTTON_TOOLTIP")
	type_header.text = tr("SALARY_TYPE")
	hours_header.text = tr("SALARY_HOURS")
	rate_header.text = tr("SALARY_RATE")
	amount_header.text = tr("SALARY_AMOUNT")
	wages_section_label.text = tr("SALARY_WAGES_SECTION")
	gross_total_label.text = tr("SALARY_GROSS_TOTAL")
	tax_and_deductions_section_label.text = tr("SALARY_DEDUCTIONS_SECTION")
	normal_hours_type_label.text = tr("SALARY_NORMAL_HOURS")
	evening_supplement_type_label.text = tr("SALARY_EVENING_SUPPLEMENT")
	night_supplement_type_label.text = tr("SALARY_NIGHT_SUPPLEMENT")
	saturday_supplement_type_label.text = tr("SALARY_SATURDAY_SUPPLEMENT")
	sunday_supplement_type_label.text = tr("SALARY_SUNDAY_SUPPLEMENT")
	step1_gross_label.text = tr("SALARY_GROSS")
	step2_atp_label.text = tr("SALARY_ATP")
	step3_after_atp_label.text = tr("SALARY_STEP_AFTER_ATP")
	step4_am_bidrag_label.text = tr("SALARY_AM_BIDRAG")
	step5_after_am_label.text = tr("SALARY_AFTER_AM")
	step6_fradrag_label.text = tr("SALARY_FRADRAG")
	step7_taxable_label.text = tr("SALARY_TAXABLE")
	var tax_pct: float = float(SaveData.save_data_dict["tax_percentage"])
	step8_skat_label.text = tr("SALARY_TAX_PERCENT").format({"percent": str(int(snapped(tax_pct, 0.01)))})
	step9_net_label.text = tr("SALARY_NET")


## Connects button signals to handlers.
func _connect_signals() -> void:
	home_button.pressed.connect(_on_home_pressed)
	wages_button.pressed.connect(_on_wages_button_pressed)
	salary_button.pressed.connect(_on_salary_button_pressed)


## Returns the overlap in minutes between a shift and a time window.
## Handles overnight shifts and overnight windows (e.g. night 22:00-06:00).
## [param shift_start] and [param shift_end] are {hour, minute} dicts.
## [param window_start] and [param window_end] are {hour, minute} dicts.
## Window is [window_start, window_end); if window_end < window_start, window crosses midnight.
func _overlap_minutes(shift_start: Dictionary, shift_end: Dictionary, window_start: Dictionary, window_end: Dictionary) -> float:
	var shift_s: int = int(shift_start["hour"]) * 60 + int(shift_start["minute"])
	var shift_e: int = int(shift_end["hour"]) * 60 + int(shift_end["minute"])
	if shift_e <= shift_s:
		shift_e += 24 * 60
	var win_s: int = int(window_start["hour"]) * 60 + int(window_start["minute"])
	var win_e: int = int(window_end["hour"]) * 60 + int(window_end["minute"])
	if win_e <= win_s:
		win_e += 24 * 60
	var overlap_s: int = maxi(shift_s, win_s)
	var overlap_e: int = mini(shift_e, win_e)
	if overlap_e <= overlap_s:
		return 0.0
	return float(overlap_e - overlap_s)


## Ensures time dict has valid hour and minute keys. Used for backward compatibility with old save files.
func _ensure_time_dict(d: Variant) -> Dictionary:
	if not d is Dictionary:
		return {"hour": 0, "minute": 0}
	var dict: Dictionary = d
	var h: int = clampi(int(dict.get("hour", 0)), 0, 23)
	var m: int = clampi(int(dict.get("minute", 0)), 0, 59)
	return {"hour": h, "minute": m}


## Returns shift duration in minutes. Handles overnight shifts.
func _shift_minutes(start: Dictionary, end: Dictionary) -> float:
	var start_min: int = int(start["hour"]) * 60 + int(start["minute"])
	var end_min: int = int(end["hour"]) * 60 + int(end["minute"])
	if end_min <= start_min:
		end_min += 24 * 60
	return float(end_min - start_min)


## Returns weekday (0=Sun..6=Sat) for the given date dict.
func _get_weekday(date_dict: Dictionary) -> int:
	var unix: int = int(Time.get_unix_time_from_datetime_dict({
		"year": int(date_dict["year"]),
		"month": int(date_dict["month"]),
		"day": int(date_dict["day"]),
		"hour": 0,
		"minute": 0,
		"second": 0
	}))
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(unix)
	return int(dt["weekday"])


## Returns base pay + evening supplement + night supplement + Saturday/Sunday supplement for all work entries.
## Base = total hours × hourly wage. Supplements use fixed kr/h in their time windows.
## Returns gross, total_hours, and wage_lines: Array of {type_key, hours, rate, amount}.
func _compute_gross_salary() -> Dictionary:
	var hourly_wage: float = float(SaveData.save_data_dict["hourly_wage"])
	var evening_wage: float = float(SaveData.save_data_dict.get("evening_wage", 0.0))
	var night_wage: float = float(SaveData.save_data_dict.get("night_wage", 0.0))
	var saturday_wage: float = float(SaveData.save_data_dict.get("saturday_wage", 0.0))
	var sunday_wage: float = float(SaveData.save_data_dict.get("sunday_wage", 0.0))
	var evening_start: Dictionary = _ensure_time_dict(SaveData.save_data_dict.get("evening_window_start", {"hour": 18, "minute": 0}))
	var evening_end: Dictionary = _ensure_time_dict(SaveData.save_data_dict.get("evening_window_end", {"hour": 22, "minute": 0}))
	var night_start: Dictionary = _ensure_time_dict(SaveData.save_data_dict.get("night_window_start", {"hour": 22, "minute": 0}))
	var night_end: Dictionary = _ensure_time_dict(SaveData.save_data_dict.get("night_window_end", {"hour": 6, "minute": 0}))
	var saturday_start: Dictionary = _ensure_time_dict(SaveData.save_data_dict.get("saturday_window_start", {"hour": 0, "minute": 0}))
	var saturday_end: Dictionary = _ensure_time_dict(SaveData.save_data_dict.get("saturday_window_end", {"hour": 23, "minute": 59}))
	var sunday_start: Dictionary = _ensure_time_dict(SaveData.save_data_dict.get("sunday_window_start", {"hour": 0, "minute": 0}))
	var sunday_end: Dictionary = _ensure_time_dict(SaveData.save_data_dict.get("sunday_window_end", {"hour": 23, "minute": 59}))

	var total_hours: float = 0.0
	var base_pay: float = 0.0
	var evening_minutes: float = 0.0
	var night_minutes: float = 0.0
	var saturday_minutes: float = 0.0
	var sunday_minutes: float = 0.0

	for entry in SaveData.save_data_dict["work_entries"]:
		var date_dict: Dictionary = entry["date"]
		var start: Dictionary = entry["start_time"]
		var end: Dictionary = entry["end_time"]
		var shift_min: float = _shift_minutes(start, end)
		total_hours += shift_min / 60.0
		base_pay += (shift_min / 60.0) * hourly_wage
		if evening_wage > 0.0:
			evening_minutes += _overlap_minutes(start, end, evening_start, evening_end)
		if night_wage > 0.0:
			night_minutes += _overlap_minutes(start, end, night_start, night_end)

		# Weekend supplements: apply based on calendar day. Godot weekday: 0=Sun, 6=Sat.
		var start_min: int = int(start["hour"]) * 60 + int(start["minute"])
		var end_min: int = int(end["hour"]) * 60 + int(end["minute"])
		var is_overnight: bool = end_min <= start_min

		if is_overnight:
			# Segment 1: start to midnight (same calendar day as entry date).
			var midnight: Dictionary = {"hour": 0, "minute": 0}
			var seg1_overlap_sat: float = 0.0
			var seg1_overlap_sun: float = 0.0
			var weekday: int = _get_weekday(date_dict)
			if saturday_wage > 0.0 and weekday == 6:
				seg1_overlap_sat = _overlap_minutes(start, midnight, saturday_start, saturday_end)
			elif sunday_wage > 0.0 and weekday == 0:
				seg1_overlap_sun = _overlap_minutes(start, midnight, sunday_start, sunday_end)
			saturday_minutes += seg1_overlap_sat
			sunday_minutes += seg1_overlap_sun

			# Segment 2: midnight to end (next calendar day).
			var next_day_unix: int = int(Time.get_unix_time_from_datetime_dict({
				"year": int(date_dict["year"]),
				"month": int(date_dict["month"]),
				"day": int(date_dict["day"]),
				"hour": 0,
				"minute": 0,
				"second": 0
			})) + 86400
			var next_dt: Dictionary = Time.get_datetime_dict_from_unix_time(next_day_unix)
			var next_weekday: int = int(next_dt["weekday"])
			var seg2_overlap_sat: float = 0.0
			var seg2_overlap_sun: float = 0.0
			if saturday_wage > 0.0 and next_weekday == 6:
				seg2_overlap_sat = _overlap_minutes(midnight, end, saturday_start, saturday_end)
			elif sunday_wage > 0.0 and next_weekday == 0:
				seg2_overlap_sun = _overlap_minutes(midnight, end, sunday_start, sunday_end)
			saturday_minutes += seg2_overlap_sat
			sunday_minutes += seg2_overlap_sun
		else:
			# Same-day shift.
			var weekday: int = _get_weekday(date_dict)
			if saturday_wage > 0.0 and weekday == 6:
				saturday_minutes += _overlap_minutes(start, end, saturday_start, saturday_end)
			elif sunday_wage > 0.0 and weekday == 0:
				sunday_minutes += _overlap_minutes(start, end, sunday_start, sunday_end)

	var evening_pay: float = (evening_minutes / 60.0) * evening_wage if evening_wage > 0.0 else 0.0
	var night_pay: float = (night_minutes / 60.0) * night_wage if night_wage > 0.0 else 0.0
	var saturday_pay: float = (saturday_minutes / 60.0) * saturday_wage if saturday_wage > 0.0 else 0.0
	var sunday_pay: float = (sunday_minutes / 60.0) * sunday_wage if sunday_wage > 0.0 else 0.0
	var gross: float = base_pay + evening_pay + night_pay + saturday_pay + sunday_pay

	var wage_lines: Array = []
	# Normaltimer: total hours × base rate
	if total_hours > 0.0 and hourly_wage > 0.0:
		wage_lines.append({"type_key": "SALARY_NORMAL_HOURS", "hours": total_hours, "rate": hourly_wage, "amount": base_pay})
	if evening_minutes > 0.0 and evening_wage > 0.0:
		wage_lines.append({"type_key": "SALARY_EVENING_SUPPLEMENT", "hours": evening_minutes / 60.0, "rate": evening_wage, "amount": evening_pay})
	if night_minutes > 0.0 and night_wage > 0.0:
		wage_lines.append({"type_key": "SALARY_NIGHT_SUPPLEMENT", "hours": night_minutes / 60.0, "rate": night_wage, "amount": night_pay})
	if saturday_minutes > 0.0 and saturday_wage > 0.0:
		wage_lines.append({"type_key": "SALARY_SATURDAY_SUPPLEMENT", "hours": saturday_minutes / 60.0, "rate": saturday_wage, "amount": saturday_pay})
	if sunday_minutes > 0.0 and sunday_wage > 0.0:
		wage_lines.append({"type_key": "SALARY_SUNDAY_SUPPLEMENT", "hours": sunday_minutes / 60.0, "rate": sunday_wage, "amount": sunday_pay})

	return {"gross": gross, "total_hours": total_hours, "wage_lines": wage_lines}


## Returns Arbejdsmarkedets Tillægspension (ATP) amount for private månedslønnede based on total hours.
## Uses the employee portion (1/3 of total ATP). Brackets: >=117h -> 99 kr, >=78h -> 66 kr, >=39h -> 33 kr, else 0 kr.
func _compute_atp_for_private_manedsloennet(total_hours: float) -> float:
	if total_hours >= 117.0:
		return 99.00
	if total_hours >= 78.0:
		return 66.00
	if total_hours >= 39.0:
		return 33.00
	return 0.00


## Populates a wage row with hours, rate, and amount. Hides row if amount is 0.
##
## [param row] is the HBoxContainer row. [param hours_label], [param rate_label], and [param amount_label] receive formatted values. [param hours], [param rate], and [param amount] are the numeric values.
func _populate_wage_row(row: HBoxContainer, hours_label: Label, rate_label: Label, amount_label: Label, hours: float, rate: float, amount: float) -> void:
	if amount <= 0.0 and hours <= 0.0:
		row.visible = false
		return
	row.visible = true
	hours_label.text = LOCALE_UTILS.format_number(hours, 2, true)
	rate_label.text = LOCALE_UTILS.format_number(rate, 2, true)
	amount_label.text = LOCALE_UTILS.format_number(amount, 2, true)


## Recalculates payslip values and updates the UI.
func _refresh_payslip() -> void:
	var hourly_wage: float = float(SaveData.save_data_dict["hourly_wage"])
	var tax_pct: float = float(SaveData.save_data_dict["tax_percentage"])
	var fradrag: float = float(SaveData.save_data_dict["personal_allowance"])

	var gross_result: Dictionary = _compute_gross_salary()
	var total_hours: float = gross_result["total_hours"]
	var gross: float = gross_result["gross"]
	var wage_lines: Array = gross_result["wage_lines"]

	var atp: float = _compute_atp_for_private_manedsloennet(total_hours)
	var salary_after_atp: float = gross - atp
	var am_bidrag: float = salary_after_atp * 0.08
	var taxable_before_fradrag: float = salary_after_atp - am_bidrag
	var a_skat_basis: float = maxf(0.0, taxable_before_fradrag - fradrag)
	var skat: float = a_skat_basis * (tax_pct / 100.0)
	var net: float = gross - atp - am_bidrag - skat

	var has_data: bool = SaveData.save_data_dict["work_entries"].size() > 0 and hourly_wage > 0.0

	salary_scroll_container.visible = has_data
	empty_message_label.visible = not has_data

	if has_data:
		# Build lookup for wage lines by type_key
		var wage_by_type: Dictionary = {}
		for line in wage_lines:
			wage_by_type[line["type_key"]] = line

		# Populate wage rows (show/hide and set values)
		_populate_wage_row(
			normal_hours_row,
			normal_hours_value,
			normal_hours_rate_value,
			normal_hours_amount_value,
			wage_by_type.get("SALARY_NORMAL_HOURS", {}).get("hours", 0.0),
			wage_by_type.get("SALARY_NORMAL_HOURS", {}).get("rate", 0.0),
			wage_by_type.get("SALARY_NORMAL_HOURS", {}).get("amount", 0.0)
		)
		_populate_wage_row(
			evening_supplement_row,
			evening_supplement_hours_value,
			evening_supplement_rate_value,
			evening_supplement_amount_value,
			wage_by_type.get("SALARY_EVENING_SUPPLEMENT", {}).get("hours", 0.0),
			wage_by_type.get("SALARY_EVENING_SUPPLEMENT", {}).get("rate", 0.0),
			wage_by_type.get("SALARY_EVENING_SUPPLEMENT", {}).get("amount", 0.0)
		)
		_populate_wage_row(
			night_supplement_row,
			night_supplement_hours_value,
			night_supplement_rate_value,
			night_supplement_amount_value,
			wage_by_type.get("SALARY_NIGHT_SUPPLEMENT", {}).get("hours", 0.0),
			wage_by_type.get("SALARY_NIGHT_SUPPLEMENT", {}).get("rate", 0.0),
			wage_by_type.get("SALARY_NIGHT_SUPPLEMENT", {}).get("amount", 0.0)
		)
		_populate_wage_row(
			saturday_supplement_row,
			saturday_supplement_hours_value,
			saturday_supplement_rate_value,
			saturday_supplement_amount_value,
			wage_by_type.get("SALARY_SATURDAY_SUPPLEMENT", {}).get("hours", 0.0),
			wage_by_type.get("SALARY_SATURDAY_SUPPLEMENT", {}).get("rate", 0.0),
			wage_by_type.get("SALARY_SATURDAY_SUPPLEMENT", {}).get("amount", 0.0)
		)
		_populate_wage_row(
			sunday_supplement_row,
			sunday_supplement_hours_value,
			sunday_supplement_rate_value,
			sunday_supplement_amount_value,
			wage_by_type.get("SALARY_SUNDAY_SUPPLEMENT", {}).get("hours", 0.0),
			wage_by_type.get("SALARY_SUNDAY_SUPPLEMENT", {}).get("rate", 0.0),
			wage_by_type.get("SALARY_SUNDAY_SUPPLEMENT", {}).get("amount", 0.0)
		)

		# Gross total and step-by-step deductions
		gross_total_value.text = LOCALE_UTILS.format_number(gross, 2, true)
		step1_gross_value.text = LOCALE_UTILS.format_number(gross, 2, true)
		step2_atp_value.text = LOCALE_UTILS.format_number(atp, 2, true)
		step3_after_atp_value.text = LOCALE_UTILS.format_number(salary_after_atp, 2, true)
		step4_am_bidrag_value.text = LOCALE_UTILS.format_number(am_bidrag, 2, true)
		step5_after_am_value.text = LOCALE_UTILS.format_number(taxable_before_fradrag, 2, true)
		step6_fradrag_value.text = LOCALE_UTILS.format_number(fradrag, 2, true)
		step7_taxable_value.text = LOCALE_UTILS.format_number(a_skat_basis, 2, true)
		step8_skat_label.text = tr("SALARY_TAX_PERCENT").format({"percent": str(int(snapped(tax_pct, 0.01)))})
		step8_skat_value.text = LOCALE_UTILS.format_number(skat, 2, true)
		step9_net_value.text = LOCALE_UTILS.format_number(net, 2, true)


## Navigates back to the home screen.
func _on_home_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.HOME_SCREEN)


## Navigates to the wages screen.
func _on_wages_button_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.WAGES_SCREEN)


## Navigates to the salary screen (refreshes when already on salary).
func _on_salary_button_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.SALARY_SCREEN)
