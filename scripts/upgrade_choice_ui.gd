extends Control

signal choice_selected(choice_id: StringName, offered_level: int)

const CHOICE_VITALITY: StringName = &"vitality"
const CHOICE_HASTE: StringName = &"haste"
const CHOICE_COMBAT: StringName = &"combat"
const CHOICE_IDS: Array[StringName] = [CHOICE_VITALITY, CHOICE_HASTE, CHOICE_COMBAT]
const CHOICE_METADATA: Dictionary = {
	CHOICE_VITALITY: {
		"title": "VITALITY",
		"description": "+20 maximum health\nRestore 20 health",
	},
	CHOICE_HASTE: {
		"title": "HASTE",
		"description": "+12% movement speed\nStacks multiplicatively",
	},
	CHOICE_COMBAT: {
		"title": "COMBAT ABILITY",
		"description": "Prepare a combat upgrade\nAbilities arrive in F06",
	},
}

var _buttons: Array[Button] = []
var _selection_locked: bool = true
var _offered_level: int = 0
var _combat_metadata: Dictionary = (CHOICE_METADATA[CHOICE_COMBAT] as Dictionary).duplicate(true)


func _ready() -> void:
	_buttons = [
		get_node("Center/Panel/Margin/Content/Choices/Vitality") as Button,
		get_node("Center/Panel/Margin/Content/Choices/Haste") as Button,
		get_node("Center/Panel/Margin/Content/Choices/Combat") as Button,
	]
	for index: int in range(CHOICE_IDS.size()):
		var choice_id: StringName = CHOICE_IDS[index]
		var metadata: Dictionary = CHOICE_METADATA[choice_id]
		var button: Button = _buttons[index]
		button.text = "%s\n\n%s" % [metadata["title"], metadata["description"]]
		button.pressed.connect(_on_choice_pressed.bind(choice_id))
	hide_choices()


func show_choices(level: int, combat_title: String = "", combat_description: String = "") -> void:
	_offered_level = level
	if not combat_title.is_empty() and not combat_description.is_empty():
		_combat_metadata = {
			"title": combat_title,
			"description": combat_description,
		}
	else:
		_combat_metadata = (CHOICE_METADATA[CHOICE_COMBAT] as Dictionary).duplicate(true)
	_refresh_combat_button()
	_selection_locked = false
	for button: Button in _buttons:
		button.disabled = false
	var level_label := get_node("Center/Panel/Margin/Content/Level") as Label
	level_label.text = "LEVEL %d" % level
	show()


func hide_choices() -> void:
	_selection_locked = true
	_offered_level = 0
	for button: Button in _buttons:
		button.disabled = true
	hide()


func select_choice(choice_id: StringName) -> bool:
	if not visible or _selection_locked or not CHOICE_IDS.has(choice_id):
		return false
	_selection_locked = true
	for button: Button in _buttons:
		button.disabled = true
	choice_selected.emit(choice_id, _offered_level)
	return true


func get_choice_ids() -> Array[StringName]:
	return CHOICE_IDS.duplicate()


func get_choice_metadata(choice_id: StringName) -> Dictionary:
	if not CHOICE_METADATA.has(choice_id):
		return {}
	if choice_id == CHOICE_COMBAT:
		return _combat_metadata.duplicate(true)
	return (CHOICE_METADATA[choice_id] as Dictionary).duplicate(true)


func get_offered_level() -> int:
	return _offered_level


func is_selection_locked() -> bool:
	return _selection_locked


func _on_choice_pressed(choice_id: StringName) -> void:
	select_choice(choice_id)


func _refresh_combat_button() -> void:
	if _buttons.size() < 3:
		return
	_buttons[2].text = "%s\n\n%s" % [_combat_metadata["title"], _combat_metadata["description"]]
