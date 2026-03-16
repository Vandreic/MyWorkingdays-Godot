extends Node
## Manages UI themes (light/dark) and applies them to screens.
##
## Reads theme preference from [member SaveData.save_data_dict]["theme"] and applies
## the corresponding theme to screens when they are loaded. Provides navbar icon
## colors per theme for [method BaseScreenTemplateManager.apply_navbar_button_styles].
## [br][br]
## [b]Autoload:[/b] Access this singleton globally via [code]ThemeManager[/code].


## Theme resource paths keyed by theme id.
const THEMES: Dictionary = {
	"light": "res://assets/themes/light_theme.tres",
	"dark": "res://assets/themes/dark_theme.tres",
}

## Navbar icon colors per theme (normal, selected). Matches theme_colors.css.
const NAV_COLORS: Dictionary = {
	"light": {
		"normal": Color(0.353, 0.396, 0.4, 1),
		"selected": Color(0.184, 0.435, 0.451, 1),
	},
	"dark": {
		"normal": Color(0.89, 0.898, 0.902, 1),
		"selected": Color(0.663, 0.886, 0.902, 1),
	},
}


## Returns the current theme id from SaveData (defaults to "light").
func get_current_theme_id() -> String:
	return SaveData.save_data_dict.get("theme", "light")


## Returns the Theme resource for the current theme.
func get_current_theme() -> Theme:
	var theme_id: String = get_current_theme_id()
	if THEMES.has(theme_id):
		return load(THEMES[theme_id]) as Theme
	return load(THEMES["light"]) as Theme


## Returns the navbar icon color for unselected buttons.
func get_nav_icon_normal() -> Color:
	var colors: Dictionary = NAV_COLORS.get(get_current_theme_id(), NAV_COLORS["light"])
	return colors.get("normal", Color(0.353, 0.396, 0.4, 1))


## Returns the navbar icon color for the selected button.
func get_nav_icon_selected() -> Color:
	var colors: Dictionary = NAV_COLORS.get(get_current_theme_id(), NAV_COLORS["light"])
	return colors.get("selected", Color(0.184, 0.435, 0.451, 1))


## Sets the theme and persists to SaveData. Applies to the current screen.
## [param theme_id] is the theme key: [code]"light"[/code] or [code]"dark"[/code].
func set_theme(theme_id: String) -> void:
	if not THEMES.has(theme_id):
		return
	SaveData.save_data_dict["theme"] = theme_id
	SaveData.save_data_to_file()
	apply_to_current_screen()


## Applies the current theme to [param screen] by setting it on BackgroundPanel
## and NavigationBarContainer. The navbar is a sibling of BackgroundPanel, so it
## must be themed explicitly; otherwise it falls back to the project default (light).
func apply_to_screen(screen: Node) -> void:
	var theme_res: Theme = get_current_theme()
	var panel: Control = screen.get_node_or_null("BackgroundPanel")
	if panel != null:
		panel.theme = theme_res
	var nav_bar: Control = screen.get_node_or_null("NavigationBarContainer")
	if nav_bar != null:
		nav_bar.theme = theme_res


## Applies the current theme to the active screen (child of Main/UI).
func apply_to_current_screen() -> void:
	var ui_node: CanvasLayer = get_node_or_null("/root/Main/UI")
	if ui_node != null and ui_node.get_child_count() > 0:
		apply_to_screen(ui_node.get_child(0))
