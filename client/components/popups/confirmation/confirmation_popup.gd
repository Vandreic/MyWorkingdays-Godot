class_name ConfirmationPopup
extends PopupPanel
## Reusable confirmation popup template.
##
## Displays a title, message, optional warning text, and Confirm/Cancel buttons.[br]
## Call [method show_for_confirmation] with translation keys to show the popup.[br]
## Emits [signal confirmed] when the user confirms, [signal cancelled] when they cancel.

## Emitted when the user presses the Confirm button.
signal confirmed

## Emitted when the user presses the Cancel button or closes the popup.
signal cancelled

## Root container holding all popup content.
@onready var root_container: VBoxContainer = %RootContainer
## Title label.
@onready var title_label: Label = %TitleLabel
## Main message label.
@onready var message_label: Label = %MessageLabel
## Warning label (e.g. "This action cannot be undone"); hidden when [member _warning_key] is empty.
@onready var warning_label: Label = %WarningLabel
## Button to confirm the action.
@onready var confirm_button: Button = %ConfirmButton
## Button to cancel the action.
@onready var cancel_button: Button = %CancelButton

## Stored translation keys for updating when locale changes.
var _title_key: String = ""
var _message_key: String = ""
var _warning_key: String = ""
var _confirm_key: String = ""
var _cancel_key: String = ""

## True when the user pressed Confirm or Cancel; prevents double-emitting from popup_hide.
var _user_responded: bool = false


func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_connect_signals()


func _connect_signals() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	popup_hide.connect(_on_popup_hide)


## Updates all labels and buttons with translated strings. Called when locale changes.
func _update_ui_with_new_language() -> void:
	if _title_key.is_empty():
		return
	title_label.text = tr(_title_key)
	message_label.text = tr(_message_key)
	if _warning_key.is_empty():
		warning_label.visible = false
	else:
		warning_label.visible = true
		warning_label.text = tr(_warning_key)
	confirm_button.text = tr(_confirm_key)
	cancel_button.text = tr(_cancel_key)


## Shows the confirmation popup with the given translation keys.
##
## [param title_key] is the translation key for the title.[br]
## [param message_key] is the translation key for the main message.[br]
## [param warning_key] is optional; when empty, the warning label is hidden.[br]
## [param confirm_key] is the translation key for the Confirm button.[br]
## [param cancel_key] is the translation key for the Cancel button.
func show_for_confirmation(title_key: String, message_key: String, warning_key: String = "", confirm_key: String = "CONFIRM_BUTTON", cancel_key: String = "CANCEL_BUTTON") -> void:
	_user_responded = false
	_title_key = title_key
	_message_key = message_key
	_warning_key = warning_key
	_confirm_key = confirm_key
	_cancel_key = cancel_key
	theme = ThemeManager.get_current_theme()
	_update_ui_with_new_language()
	popup_centered()


## Emits [signal confirmed] and hides the popup.
func _on_confirm_pressed() -> void:
	_user_responded = true
	hide()
	confirmed.emit()


## Emits [signal cancelled] and hides the popup.
func _on_cancel_pressed() -> void:
	_user_responded = true
	hide()
	cancelled.emit()


## When popup is hidden by clicking outside (user did not press a button), treat as cancel.
func _on_popup_hide() -> void:
	if not _user_responded:
		cancelled.emit()
