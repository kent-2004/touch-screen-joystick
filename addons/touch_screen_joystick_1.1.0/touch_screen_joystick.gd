## Joystick control for mobile devices

@tool
@icon("res://addons/TouchScreenJoystick/icon.png")
extends Control
class_name TouchScreenJoystick

@export var antialiased := false : 
	set(b):
		antialiased = b
		queue_redraw()

@export_range(0, 9999, 0.1, "hide_slider") var deadzone := 25.0 : 
	set(n):
		deadzone = n
		queue_redraw()

@export_range(0, 9999, 0.1, "hide_slider")
var base_radius := 120.0 :
	set(r):
		base_radius = r
		queue_redraw()
@export_range(0, 9999, 0.1, "hide_slider")
var knob_radius := 45.0 :
	set(r):
		knob_radius = r
		queue_redraw()

@export_group("Texture Joystick")
@export var use_textures : bool :
	set(value):
		use_textures = value
		queue_redraw()

@export_subgroup("Base")
@export var base_texture : Texture2D :
	set(value):
		base_texture = value
		queue_redraw()

@export var base_scale := Vector2.ONE :
	set(value):
		base_scale = value
		queue_redraw()

@export_subgroup("Knob")
@export var knob_texture : Texture2D :
	set(value):
		knob_texture = value
		queue_redraw()


@export var knob_scale := Vector2.ONE :
	set(value):
		knob_scale = value
		queue_redraw()

@export_group("Input Actions")
@export var use_input_actions : bool
@export var action_left := "ui_left"
@export var action_right := "ui_right"
@export var action_up := "ui_up"
@export var action_down := "ui_down"

@export_group("Debug")
@export var show_debug : bool :
	set(value):
		show_debug = value
		queue_redraw()

@export var deadzone_color := Color.RED :
	set(value):
		deadzone_color = value
		queue_redraw()

@export var base_color := Color.GREEN :
	set(value):
		base_color = value
		queue_redraw()

signal on_press
signal on_release
signal on_drag(factor : float)

var knob_position : Vector2
var is_pressing : bool
var event_index := -1


func _draw() -> void:
	if not is_pressing : reset_knob()
	
	if not use_textures:
		draw_default_joystick()
	else:
		draw_texture_joystick()
	
	if show_debug : draw_debug()

func draw_default_joystick() -> void:
	# Base
	draw_circle(size / 2.0, base_radius, Color(Color.BLACK, 0.5))
	draw_circle(size / 2.0, base_radius, Color.WHITE, false, 2.0, antialiased)
	
	# Knob
	draw_circle(knob_position, knob_radius, Color.WHITE, true, -1.0, antialiased)

func draw_texture_joystick() -> void:
	# Base
	if base_texture:
		var base_size := base_texture.get_size() * base_scale
		draw_texture_rect(base_texture, Rect2(size / 2.0 - (base_size / 2.0), base_size), false)
		
	
	# Knob
	if knob_texture:
		var knob_size := knob_texture.get_size() * knob_scale
		draw_texture_rect(knob_texture, Rect2(knob_position - (knob_size / 2.0), knob_size), false)


func draw_debug() -> void:
	draw_circle(size / 2.0, deadzone, deadzone_color, false, 5.0)
	draw_circle(size / 2.0, base_radius, base_color, false, 5.0)

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint(): return
	
	if event is InputEventScreenTouch:
		on_screen_touch(event)
		
	elif event is InputEventScreenDrag:
		on_screen_drag(event)

func on_screen_touch(event : InputEventScreenTouch) -> void:
	var has_point := get_global_rect().has_point(event.position)
	
	if event.pressed and event_index == -1 and has_point:
		event_index = event.index
		touch_knob(event.position, event.index)
	else:
		release_knob(event.index)
	
	get_viewport().set_input_as_handled()


func touch_knob(pos : Vector2, index : int) -> void:
	if index == event_index: 
		move_knob(pos)
		is_pressing = true
		on_press.emit()

func release_knob(index : int) -> void:
	if index == event_index:
		reset_actions()
		reset_knob()
		event_index = -1
		is_pressing = false
		on_release.emit()

func on_screen_drag(event : InputEventScreenDrag) -> void:
	var center := size / 2.0
	var dist := center.distance_to(knob_position)
	
	if event.index == event_index and is_pressing:
		move_knob(event.position)
		get_viewport().set_input_as_handled()
		on_drag.emit(get_factor())



func move_knob(event_pos : Vector2) -> void:
	var center := size / 2.0
	var touch_pos := (event_pos - global_position) / scale
	var distance := touch_pos.distance_to(center)
	var angle := center.angle_to_point(touch_pos)
	
	if distance < base_radius:
		knob_position = touch_pos
	else:
		knob_position.x = center.x + cos(angle) * base_radius
		knob_position.y = center.y + sin(angle) * base_radius
	
	if distance > deadzone:
		trigger_actions()
	else:
		reset_actions()
	
	queue_redraw()

func trigger_actions() -> void:
	if not use_input_actions: return
	
	var direction := get_direction().normalized()
	
	if direction.x < 0.0:
		Input.action_release(action_right)
		Input.action_press(action_left, -direction.x)
	elif direction.x > 0.0:
		Input.action_release(action_left)
		Input.action_press(action_right, direction.x)
	
	if direction.y < 0.0:
		Input.action_release(action_down)
		Input.action_press(action_up, -direction.y)
	elif direction.y > 0.0:
		Input.action_release(action_up)
		Input.action_press(action_down, direction.y)
	

func reset_actions() -> void:
	Input.action_release(action_left)
	Input.action_release(action_right)
	Input.action_release(action_up)
	Input.action_release(action_down)
	

func get_direction() -> Vector2:
	var center := size / 2.0
	var direction := center.direction_to(knob_position)
	return direction

func get_distance() -> float:
	var center := size / 2.0
	var distance := center.distance_to(knob_position)
	
	return distance

func get_angle() -> float:
	var center := size / 2.0
	var angle := center.angle_to_point(knob_position)
	return angle

func get_factor() -> float:
	var center := size / 2.0
	var distance := center.distance_to(knob_position)
	return distance / base_radius

func is_in_deadzone() -> bool:
	var center := size / 2.0
	var distance := center.distance_to(knob_position)
	return distance < deadzone

func reset_knob() -> void:
	knob_position = size / 2.0
	queue_redraw()
