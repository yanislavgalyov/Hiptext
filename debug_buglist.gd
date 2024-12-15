extends CanvasLayer

@onready var timer: Timer = $Timer
@onready var exit_button: Button = $Control/ExitButton
@onready var minimize_button: Button = $Control/MinimizeButton

@onready var text_edit: TextEdit = $Control/TextEdit

var typing_noise = preload("res://assets/sound/click_light.wav")

var default_resource: Buglist = preload("res://resources/default_snapshot.tres")
var default_resource_path = "user://snapshot.tres"

var current_resource: Buglist
var quit = false

var focused = false
var reminder_mode = false

@onready var tab = $Control/tab/tab.duplicate()

var size_of_all_tabs_combined = 0
var tabs = []
var current_tab_index = 0
var ms = Vector2.ZERO

var last_selected_button = null
var last_selected_button2 = null
var selected_button = null


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)

	exit_button.pressed.connect(_on_exit_button_pressed)
	minimize_button.pressed.connect(_on_minimize_button_pressed)
	timer.timeout.connect(save)

	offset = Vector2(320, 180)
	scale = Vector2(0, 31)

	current_resource = ResourceLoader.load(default_resource_path)
	if not current_resource:
		ResourceSaver.save(default_resource, default_resource_path)
		current_resource = default_resource

	print(current_resource)

	for i in range(current_resource.saved_text.size()):
		var tabs_inst = $Control/tab/tab.duplicate()
		tabs_inst.get_node("Label").text = str(current_resource.text_names[i])
		tabs.append(tabs_inst)
		tabs_inst.position.x = size_of_all_tabs_combined
		tabs_inst.position.y = 12500 * i
#
		$Control/tab/tab_container.add_child(tabs_inst)

	$Control/tab/tab.queue_free()

	if tabs.size() > 0:
		var current_tab = 0 if current_resource.active_index == -1 else current_resource.active_index
		change_tab(current_tab)
	else:
		text_edit.text = $title.text
		text_edit.editable = false
		selected_button = null
		text_edit.set_caret_column(2)
		text_edit.set_caret_line(1)

	update_tab_size()


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()
		get_tree().quit()


func propage_quit():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func update_tab_size():
	var default_colorrect_size_x = 20
	var default_colorrect3_size_x = 18
	var default_colorrect2_size_x = 18
	size_of_all_tabs_combined = 0

	for i in range(tabs.size()):
		var p = tabs[i]
		var calculated_addition = -6 + p.get_node("Label").text.length() * 5
		p.get_node("ColorRect").size.x = default_colorrect_size_x + calculated_addition
		p.get_node("ColorRect/ColorRect3").size.x = default_colorrect3_size_x + calculated_addition
		p.get_node("ColorRect2").size.x = default_colorrect2_size_x + calculated_addition
		p.get_node("Label/next").position.x = 15 + p.get_node("Label").text.length() * 5
		size_of_all_tabs_combined += p.get_node("Label/next").position.x
		current_resource.text_names[i] = p.get_node("Label").text


func _input(event: InputEvent) -> void:
	if tabs != []:
		if event is InputEventKey and event.is_pressed():
			current_resource.saved_text[current_tab_index] = text_edit.text
			current_resource.caret_line[current_tab_index] = text_edit.get_caret_line()
			current_resource.caret_column[current_tab_index] = text_edit.get_caret_column()
			$typing_noise.play()

	# todo what is this
	if last_selected_button != selected_button:
		$typing_noise2.play()
		last_selected_button = selected_button

	if selected_button != null:
		if Input.is_action_just_pressed("SCROLL_UP"):
			scroll(25)
		if Input.is_action_just_pressed("SCROLL_DOWN"):
			scroll(-25)

	if Input.is_action_just_pressed("CLICK"):
		$typing_noise.play()
	if Input.is_action_just_released("CLICK"):
		$typing_noise2.play()


func save():
	ResourceSaver.save(current_resource, default_resource_path)


func scroll(how_much = 0):
	if current_tab_index >= 0:
		current_resource.scroll[current_tab_index] += how_much


func _physics_process(delta: float) -> void:
	ms = $Control/tab.get_local_mouse_position()

	if $Control/tab/Marker2D.position.x > 5:
		$Control/tab/Marker2D.position.x += (5 - $Control/tab/Marker2D.position.x) * 0.2

	if $Control/tab/Marker2D.position.x < -size_of_all_tabs_combined:
		$Control/tab/Marker2D.position.x += (-(tabs.size() * 22) - $Control/tab/Marker2D.position.x) * 0.2

	var container_scroll = 0 if current_tab_index < 0 else current_resource.scroll[current_tab_index]
	$Control/tab/tab_container.position.x += (container_scroll - $Control/tab/tab_container.position.x) * 0.3

	for i in range(tabs.size()):
		var p = tabs[i]
		var offsets = 0

		var resulting_pos = (tabs[i - 1].position.x) + tabs[i - 1].get_node("Label/next").position.x

		if i == 0:
			resulting_pos = $Control/tab/Marker2D.position.x

		p.pos.x = resulting_pos
#		tabs[i].position = tabs[i].position.linear_interpolate($Control/tab/Position2D.position + Vector2(i * tabs[i - 1].get_node("ColorRect").rect_size.x,0),delta * 15)

#		var spacing = 0
#		spacing = tabs[i - 1].get_node("Label/next").position.x + tabs[i].position.x - 4
#		if i == 0:
#			spacing = 0

#		tabs[i].position = tabs[i].position.linear_interpolate($Control/tab/Position2D.position + Vector2(spacing,0),delta * 15)

		if i != current_tab_index:
			p.position.y += 0.5
			p.z_index = -1
			if ms.y > $Control/tab.position.y + 44:
				p.position.y += 5
#			var pusher = (tabs[current_tab_index].position - tabs[i].position).normalized() * 1
#			tabs[i].position.x -= (pusher.x - 15)
		else:
			p.position.y -= 1
			p.z_index = 0

		if ms.y < p.position.y + 10 and ms.y > p.position.y - 10:
			if ms.x > p.global_position.x - 5 and ms.x < p.global_position.x + 10 + p.get_node("Label").text.length() * 5 and ms.x < $Control/tab.size.x:
				p.position.y += -1
				p.get_node("ColorRect").modulate = Color.WHITE
				selected_button = i
			else:
				p.get_node("ColorRect").modulate = Color.DARK_GRAY
		else:
			p.get_node("ColorRect").modulate = Color.DARK_GRAY

			selected_button = null

	if $Control/ProgressBar.value < 3:
		$Control/ProgressBar.modulate = $Control/ProgressBar.modulate.lerp(Color.TRANSPARENT, delta * 15)
	else:
		$Control/ProgressBar.modulate = $Control/ProgressBar.modulate.lerp(Color.WHITE, delta * 15)

	$Control/ProgressBar.position = $Control.get_local_mouse_position() - Vector2(10, -10)
	if selected_button != null:
		if Input.is_action_just_pressed("MIDDLE_CLICK"):
			remove_tab(selected_button)
		if Input.is_action_just_pressed("CLICK"):
			change_tab(selected_button)
		if Input.is_action_just_released("CLICK"):
			if selected_button == last_selected_button2:
				tabs[selected_button].get_node("Label").editable = true
			if last_selected_button2 != selected_button:
				last_selected_button2 = selected_button
		if Input.is_action_pressed("ALT_CLICK"):
			$Control/ProgressBar.value += 5
#			fx.sfx_non_positional(typing_noise, 1 + $Control/ProgressBar.value / 20, 1 + $Control/ProgressBar.value / 10)
			if $Control/ProgressBar.value > 99:
				remove_tab(selected_button)
				$Control/ProgressBar.value = 0
#				fx.sfx_non_positional(typing_noise,15, 2)
		else:
			$Control/ProgressBar.value /= 1.1
	else:
		$Control/ProgressBar.value /= 1.1

	if tabs != []:
		if ms.y > $Control/tab.position.y + 44:
			$Control/tab/add_tab.position.y += 5
		tabs[current_tab_index].get_node("ColorRect").modulate = Color.WHITE
		$Control/tab/add_tab.position = $Control/tab/add_tab.position.lerp(
			Vector2(20 + tabs.back().global_position.x + tabs.back().get_node("Label").text.length() * 5, 22), delta * 15
		)
	else:
		$Control/tab/add_tab.position = $Control/tab/add_tab.position.lerp($Control/tab/Marker2D.global_position, delta * 15)

	if Input.is_action_just_released("New Tab"):
		add_tab()
	if Input.is_action_just_released("Change Tab"):
		var to = (current_resource.active_index + 1) % current_resource.text_names.size()
		change_tab(to)
	if $Control/tab/add_tab.global_position.distance_squared_to($Control.get_local_mouse_position()) < 100:
		$Control/tab/add_tab.scale = $Control/tab/add_tab.scale.lerp(Vector2.ONE / 1.8, delta * 25)
		$Control/tab/add_tab.modulate = Color.WHITE
		if Input.is_action_just_pressed("CLICK"):
			add_tab()
	else:
		$Control/tab/add_tab.modulate = Color.DARK_GRAY

		$Control/tab/add_tab.scale = $Control/tab/add_tab.scale.lerp(Vector2.ONE / 2, delta * 25)

	if Input.is_action_just_pressed("ui_cancel"):
		quit = true
		propage_quit()

	if quit:
#		global.player_pause = false
		get_tree().paused = false
		offset.x += (800 - offset.x) * 0.4
		if offset.x > 640:
			queue_free()

	else:
		if reminder_mode == false:
			get_tree().paused = true

		offset = offset.lerp(Vector2.ZERO, delta * 15)
		scale = scale.lerp(Vector2.ONE, delta * 15)


func add_tab():
	text_edit.editable = true
	var tab_inst = tab.duplicate()
	if tabs.size() > 0:
		tab_inst.global_position.x = size_of_all_tabs_combined + 22
		tab_inst.global_position.y = 401

	var title = str("", tabs.size())
	tab_inst.get_node("Label").text = str(title)
	tabs.append(tab_inst)
	$Control/tab/tab_container.add_child(tab_inst)

	current_resource.saved_text.append("")
	current_resource.text_names.append(title)
	current_resource.caret_line.append(0)
	current_resource.caret_column.append(0)
	current_resource.scroll.append(0)

	save()
	change_tab(tabs.size() - 1)
	update_tab_size()


func remove_tab(at = 0):
	if at < tabs.size():
		if current_tab_index > tabs.size() - 2 and current_tab_index != 0:
			current_tab_index -= 1

		var tab_to_free = tabs[at]

		tabs.pop_at(at)

		current_resource.saved_text.pop_at(at)
		current_resource.text_names.pop_at(at)
		current_resource.caret_line.pop_at(at)
		current_resource.caret_column.pop_at(at)
		current_resource.scroll.pop_at(at)
		tab_to_free.queue_free()

		if tabs.size() == 0:
			text_edit.text = $title.text
			text_edit.editable = false
			selected_button = null
		else:
			text_edit.text = str(current_resource.saved_text[current_tab_index])

		save()
		change_tab(current_tab_index)
		update_tab_size()


func change_tab(to = 0):
	if to < tabs.size():
		current_tab_index = to
		for i in range(tabs.size()):
			var p = tabs[i]
			if i != current_tab_index:
				p.get_node("ColorRect").modulate = Color.DARK_GRAY
			else:
				p.get_node("ColorRect").modulate = Color.WHITE

			p.get_node("Label").editable = false

		current_resource.active_index = current_tab_index
		text_edit.text = current_resource.saved_text[current_tab_index]
#
		text_edit.grab_focus()

		text_edit.set_caret_line(current_resource.caret_line[to])
		text_edit.set_caret_column(current_resource.caret_column[to])

		save()
		update_tab_size()


func _on_exit_button_pressed() -> void:
	quit = true
	propage_quit()


func _on_minimize_button_pressed() -> void:
	get_window().mode = Window.MODE_MINIMIZED if (true) else Window.MODE_WINDOWED


func _on_TextEdit_focus_entered() -> void:
	focused = true


func _on_TextEdit_focus_exited() -> void:
	focused = false


func _on_Label_text_changed(_new_text: String) -> void:
	update_tab_size()


func _on_Label_text_entered(_new_text: String) -> void:
	for i in tabs:
		i.get_node("Label").deselect()
		tabs[current_tab_index].get_node("Label").caret_column = 0
#		$Control/tab/tab/Label.caret_position = 0
