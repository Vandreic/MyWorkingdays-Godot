class_name BaseScreenTemplateManager
extends Node
## Base template for all screens.
##
## Applies safe area margins to handle device notches and curved screen edges.[br]
## Extend this class to create new screens with consistent safe area handling.[br]
## Child screens must call [code]super._ready()[/code] at the start of their [method _ready] and may override
## [method _get_settings_return_screen] to pass the correct return screen when opening settings.


## Returns the application version from [code]application/config/version[/code] (Project Settings).
func _get_app_version() -> String:
	return ProjectSettings.get_setting("application/config/version")


## Sets up the settings button in the top-right. Child screens must call [code]super._ready()[/code] first.
func _ready() -> void:
	var settings_btn: TextureButton = get_node_or_null("%SettingsButton") as TextureButton
	if settings_btn:
		settings_btn.modulate = ThemeManager.get_nav_icon_normal()
		settings_btn.pressed.connect(_on_settings_button_pressed)


## Returns the screen to return to when the user taps "Go back" from settings.
## Override in child screens (Home, Wages, Salary) to return the correct screen.
func _get_settings_return_screen() -> int:
	return ScreenManager.Screen.HOME_SCREEN


## Opens the settings screen, passing the return screen for the Go back button.
func _on_settings_button_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.SETTINGS_SCREEN, _get_settings_return_screen())


## Called to refresh the screen's UI when the locale changes.
##
## Override this method to update labels and other text in the screen.
func _update_ui_with_new_language() -> void:
	pass


## Applies Material Design–aligned styles to navbar buttons.
##
## Styles the [param selected_button] with the theme's selected color and disables it.
## All other buttons get the theme's normal color and remain enabled. Pass [code]null[/code] for
## [param selected_button] when no button should be styled as selected (e.g. settings screen).
## Each button must have a VBoxContainer with TextureRect and Label children for icon/label styling.
func apply_navbar_button_styles(buttons: Array[Button], selected_button: Button = null) -> void:
	var normal_color: Color = ThemeManager.get_nav_icon_normal()
	var selected_color: Color = ThemeManager.get_nav_icon_selected()
	for button in buttons:
		if button == null:
			continue
		var texture_rect: TextureRect = button.get_node_or_null("VBoxContainer/TextureRect") as TextureRect
		var label: Label = button.get_node_or_null("VBoxContainer/Label") as Label
		var color: Color = selected_color if button == selected_button else normal_color
		if texture_rect:
			texture_rect.modulate = color
		if label:
			label.modulate = color
		button.disabled = (button == selected_button)
