extends ScrollContainer
## Enables scroll wheel to work when hovering over any child control.
##
## Sets child controls to [code]MOUSE_FILTER_PASS[/code] so scroll events reach the ScrollContainer.
## Interactive controls (buttons, line edits, etc.) continue to work normally.


func _ready() -> void:
	var content := _get_content_node()
	if content:
		_setup_scroll_passthrough(content)


## Returns the ScrollContainer's first child (the scrollable content), or [code]null[/code] if none.
func _get_content_node() -> Node:
	if get_child_count() > 0:
		return get_child(0)
	return null


## Recursively sets [code]mouse_filter = MOUSE_FILTER_PASS[/code] on [param node] and its children so scroll events reach the ScrollContainer.
func _setup_scroll_passthrough(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_PASS
	for child in node.get_children():
		_setup_scroll_passthrough(child)
