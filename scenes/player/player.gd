extends variables_player

# Code auto run when game start
func _ready() -> void:
	if !is_on_floor(): anim.play("fall")
	# setup animation
	anim.visible = true
	anim_at.visible = false
	# disable fx at start
	fx_wall_slide.visible = false
	fx_crouch.visible = false
	fx_run.visible = false

# Main movement handle for player
func _physics_process(delta: float) -> void:
	# mix basic setup
	var on_floor := is_on_floor()
	var direction := Input.get_axis("left", "right")
	var moving_left := Input.is_action_pressed("left")
	var moving_right := Input.is_action_pressed("right")
	var face_direction := -1 if anim.flip_h else 1

	# FX visibility reset
	fx_run.visible = false
	fx_crouch.visible = false
	
	# Gravity & floor
	if is_on_floor():
		jump_left = 2
		dash_left = 1
	else:
		velocity.y += GRAVITY * delta * 2
	
	# Flip sprite
	if direction != 0:
		anim.flip_h = direction < 0
		anim_at.flip_h = direction < 0
		fx_run.flip_h = anim.flip_h
		fx_crouch.flip_h = anim.flip_h
		fx_wall_slide.flip_h = anim.flip_h

	# Dash handling
	if is_dashing:
		dash_timer -= delta
		velocity.x = dash_speed * dash_dir
		velocity.y = 0
		if dash_timer <= 0: is_dashing = false
		move_and_slide()
		return

	# --- wall slide setup ---
	var touching_wall_left = $sensors/wall_check_left.is_colliding()
	var touching_wall_right = $sensors/wall_check_right.is_colliding()
	var near_wall = touching_wall_left or touching_wall_right
	var pressing_into_wall = (touching_wall_left and moving_left) or (touching_wall_right and moving_right)

	# Skip movement if rolling
	if is_rolling:
		move_and_slide()
		return

		# Attack push handling
	if attack_push_timer > 0:
		attack_push_timer -= delta
		velocity.x = face_direction * attack_push_speed
	elif attack_push_timer <= 0 and is_on_floor():
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# --- Roll / Dash ---
	var head_blocked = $sensors/ceiling_check.is_colliding()
	var wants_to_crouch := Input.is_action_pressed("down")
	var wants_to_run := Input.is_action_pressed("run")
	var wants_to_roll := Input.is_action_just_pressed("roll")
	if wants_to_roll:
		if on_floor and (wants_to_crouch or head_blocked):
			velocity.x = face_direction * SPEED * RUN_MULTIPLIER
			is_rolling = true
			_set_crouch_state(true)
			anim.play("roll")
			_spawn_fx(fx_scene_roll, pos_g, anim.flip_h, Vector2(16, 0), true)
		elif not on_floor and wants_to_crouch:
			velocity.x = face_direction * SPEED * RUN_MULTIPLIER
			velocity.y += 400
			is_rolling = true
			_set_crouch_state(true)
			anim.play("roll")
		elif on_floor and not wants_to_crouch and not head_blocked:
			is_dashing = true
			dash_dir = face_direction
			dash_timer = dash_distance / dash_speed
			velocity.x = dash_speed * dash_dir
			_set_crouch_state(false)
			anim.play("dash")
			_spawn_fx(fx_scene_dash, pos_g, anim.flip_h)
		elif not on_floor and not wants_to_crouch and not head_blocked and dash_left > 0:
			is_dashing = true
			dash_dir = face_direction
			dash_timer = dash_distance / dash_speed
			velocity.x = dash_speed * dash_dir
			_set_crouch_state(false)
			anim.play("dash")
			dash_left -= 1

	# --- Movement ---
	elif direction != 0:
		velocity.x = direction * SPEED
		if on_floor:
			if wants_to_crouch or head_blocked:
				_set_crouch_state(true)
				anim.play("crouch_walk")
				fx_crouch.visible = true
				fx_crouch.play("crouch_dust")
			elif wants_to_run:
				velocity.x *= RUN_MULTIPLIER
				_set_crouch_state(false)
				anim.play("run")
				fx_run.visible = true
				fx_run.play("run_dust")
			else:
				_set_crouch_state(false)
				anim.play("walk")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if on_floor:
			if wants_to_crouch or head_blocked:
				_set_crouch_state(true)
				anim.play("crouch")
			else:
				_set_crouch_state(false)
				anim.play("idle")

	# --- Jumping ---
	if Input.is_action_just_pressed("jump") and !wall_sliding and jump_left > 0:
		if jump_left == 1:
			velocity.y = JUMP_VELOCITY - 150
			anim.play("front_flip")
			_spawn_fx(fx_scene_jump, pos_g, anim.flip_h)
			is_doing_frontflip = true
		else:
			velocity.y = JUMP_VELOCITY
			anim.play("jump")
		jump_left -= 1
	elif not on_floor and !is_dashing and !is_rolling and velocity.y > 0:
		if anim.animation != "front_flip":
			anim.play("fall")

	# --- Wall Slide ---
	if not is_on_floor() and not is_rolling and not is_dashing:
		if pressing_into_wall and not wall_sliding:
			wall_sliding = true
			fx_wall_slide.visible = true
			jump_left = 1  # reset jump
			dash_left = 1  # reset dash
			anim.play("wall_slide")
			fx_wall_slide.play("fx_wall_slide")
	if wall_sliding:
		if is_on_floor() or not near_wall:
			wall_sliding = false
			fx_wall_slide.visible = false
			if velocity.y > 0:
				anim.play("fall")
		else:
			velocity.y = min(velocity.y, 75)  # limit falling speed
			anim.play("wall_slide")

	# --- Attack ---
	if is_on_floor() and not (wants_to_crouch or wants_to_roll or wants_to_run or wall_sliding):
		# slash handle
		if Input.is_action_just_pressed("slash") and attackpoint_slash == 3:
			attack_timer.start()
			anim_at.visible = true
			anim.visible = false
			anim_at.play("slash_1")
			attackpoint_slash -= 1
		elif Input.is_action_just_pressed("slash") and attackpoint_slash == 2:
			attack_timer.start()
			anim_at.visible = true
			anim.visible = false
			anim_at.play("slash_2")
			attackpoint_slash -= 1
			attack_push_timer = 0.2
			velocity.x = face_direction * attack_push_speed
		elif Input.is_action_just_pressed("slash") and attackpoint_slash == 1:
			attack_timer.start()
			anim_at.visible = true
			anim.visible = false
			anim_at.play("slash_4")
			attackpoint_slash -= 1
		# strike handle
		if Input.is_action_just_pressed("strike") and attackpoint_strike == 5:
			attack_timer.start()
			anim_at.visible = true
			anim.visible = false
			anim_at.play("strike_1")
			attackpoint_strike -= 1
			attack_push_timer = 0.2
			velocity.x = face_direction * attack_push_speed
		elif Input.is_action_just_pressed("strike") and attackpoint_strike == 4:
			attack_timer.start()
			anim_at.visible = true
			anim.visible = false
			anim_at.play("strike_2")
			attackpoint_strike -= 1
		elif Input.is_action_just_pressed("strike") and attackpoint_strike == 3:
			attack_timer.start()
			anim_at.visible = true
			anim.visible = false
			anim_at.play("strike_3")
			attackpoint_strike -= 1
			attack_push_timer = 0.2
			velocity.x = face_direction * attack_push_speed
		elif Input.is_action_just_pressed("strike") and attackpoint_strike == 2:
			attack_timer.start()
			anim_at.visible = true
			anim.visible = false
			anim_at.play("strike_4")
			attackpoint_strike -= 1
		elif Input.is_action_just_pressed("strike") and attackpoint_strike == 1:
			attack_timer.start()
			anim_at.visible = true
			anim.visible = false
			anim_at.play("strike_5")
			attackpoint_strike -= 1
			attack_push_timer = 0.2
			velocity.x = face_direction * attack_push_speed
	
	if not is_on_floor() and not (wants_to_roll or wants_to_run or wall_sliding):
		if Input.is_action_just_pressed("slash") and wants_to_crouch and attackpoint_air == 1:
			attack_timer.start()
			anim_at.visible = true
			anim.visible = false
			anim_at.play("air_slash_down")
			attackpoint_air -= 1
		elif Input.is_action_just_pressed("slash") and Input.is_action_pressed("up") and attackpoint_air == 1:
			anim_at.visible = true
			anim.visible = false
			anim_at.play("air_slash_up")
			attackpoint_air -= 1
		elif Input.is_action_just_pressed("slash") and attackpoint_air == 1:
			anim_at.visible = true
			anim.visible = false
			anim_at.play("air_slash_side")
			attackpoint_air -= 1
	move_and_slide()

# FX Spawn Helper
func _spawn_fx(scene: PackedScene, marker, flip_h: bool = false, offset := Vector2.ZERO, use_offset := false) -> void:
	var fx_instance = scene.instantiate()
	get_tree().current_scene.add_child(fx_instance)
	var spawn_pos = marker.global_position
	if use_offset:
		offset.x *= -1 if flip_h else 1
		spawn_pos += offset
	fx_instance.global_position = spawn_pos
	if fx_instance.has_node("AnimatedSprite2D"):
		fx_instance.get_node("AnimatedSprite2D").flip_h = flip_h

# Crouch Mode Switch
func _set_crouch_state(crouch: bool) -> void:
	normal_shape.disabled = crouch
	crouch_shape.disabled = not crouch

# Animation finished reset
func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "roll":
		is_rolling = false
	elif anim.animation == "dash":
		is_dashing = false
	elif anim.animation == "front_flip":
		is_doing_frontflip = false

# FX animation reset
func _on_fx_move_animation_finished() -> void:
	fx_run.visible = false
	fx_crouch.visible = false
	fx_wall_slide.visible = false

# attack animation reset
func _on_anim_attack_animation_finished() -> void:
# slash attack animation handle
	if anim_at.animation == "slash_1" or anim_at.animation == "slash_2":
		anim_at.visible = false
		anim.visible = true
	elif anim_at.animation == "slash_4":
		anim_at.visible = false
		anim.visible = true
		attackpoint_slash = 3
# strike attack animation handle
	if anim_at.animation == "strike_1" or anim_at.animation == "strike_2" or anim_at.animation == "strike_3" or anim_at.animation == "strike_4":
		anim_at.visible = false
		anim.visible = true
	elif anim_at.animation == "strike_5":
		anim_at.visible = false
		anim.visible = true
		attackpoint_strike = 5
# air attack animation handle
	if anim_at.animation == "air_slash_down" or anim_at.animation == "air_slash_up" or anim_at.animation == "air_slash_side":
		anim_at.visible = false
		anim.visible = true
		attackpoint_air = 1

# attack animation time out
func _on_attack_timer_timeout() -> void:
	attackpoint_slash = 3
	attackpoint_strike = 5
	attackpoint_air = 1
