class_name LocaleUtils
## Provides locale-aware number formatting and parsing for Danish and English.
##
## Danish: uses "." for thousands and "," for decimals (e.g. 11.456,88).
## English: uses "," for thousands and "." for decimals (e.g. 11,456.88).
## Uses [method TranslationServer.get_locale] to determine the active locale.


## Returns [code]true[/code] if the current locale is Danish.
static func is_danish_locale() -> bool:
	return TranslationServer.get_locale().begins_with("da")


## Returns the decimal separator for the current locale ([code]","[/code] for Danish, [code]"."[/code] for English).
static func get_decimal_separator() -> String:
	return "," if is_danish_locale() else "."


## Returns the thousand separator for the current locale ([code]"."[/code] for Danish, [code]","[/code] for English).
static func get_thousand_separator() -> String:
	return "." if is_danish_locale() else ","


## Formats [param value] with [param decimals] decimal places and optional thousand separators.
## Uses locale-appropriate decimal and thousand separators. If [code]true[/code], [param use_thousand_sep] inserts thousand separators.
static func format_number(value: float, decimals: int, use_thousand_sep: bool) -> String:
	var format_str: String = "%." + str(decimals) + "f"
	var base: String = format_str % value
	var dec_sep: String = get_decimal_separator()
	var thous_sep: String = get_thousand_separator()

	# Split into integer and fractional parts
	var parts: PackedStringArray = base.split(".", false, 1)
	var int_part: String = parts[0]
	var frac_part: String = parts[1] if parts.size() > 1 else ""

	if use_thousand_sep and int_part.length() > 3:
		var formatted_int: String = ""
		var i: int = int_part.length() - 1
		var count: int = 0
		while i >= 0:
			if count > 0 and count % 3 == 0:
				formatted_int = thous_sep + formatted_int
			formatted_int = int_part[i] + formatted_int
			count += 1
			i -= 1
		int_part = formatted_int

	return int_part + dec_sep + frac_part


## Parses [param text] as a float using locale-appropriate separators.
## Returns 0.0 for invalid or empty input.
static func parse_localized_float(text: String) -> float:
	text = text.strip_edges()
	if text.is_empty():
		return 0.0

	var dec_sep: String = get_decimal_separator()
	var thous_sep: String = get_thousand_separator()

	# Strip thousand separators
	var normalized: String = text.replace(thous_sep, "")
	# Replace decimal separator with period for Godot's to_float()
	normalized = normalized.replace(dec_sep, ".")

	var parsed: float = normalized.to_float()
	return parsed if not is_nan(parsed) else 0.0
