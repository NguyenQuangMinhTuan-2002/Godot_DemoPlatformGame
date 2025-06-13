extends CharacterBody2D
class_name variables_player

# Constants
const SPEED = 200
const RUN_MULTIPLIER = 2.5
const JUMP_VELOCITY = -600
const GRAVITY = 900

# Movement basic States check
@export var jump_left := 2
@export var dash_left := 1
@export var is_rolling := false
@export var is_dashing := false
@export var is_doing_frontflip := false
@export var wall_sliding := false
@export var can_wall_jump := true
# Dash properties
@export var dash_distance := 200.0
@export var dash_speed := 1200.0
var dash_timer := 0.0
var dash_dir := 1

# Scene References
@onready var fx_scene_roll := preload("res://scenes/fx/roll/fx_roll_dust.tscn")
@onready var fx_scene_jump := preload("res://scenes/fx/double_jump/fx_double_jump.tscn")
@onready var fx_scene_dash := preload("res://scenes/fx/dash/fx_dash_dust.tscn")
@onready var fx_run = $fx_container/fx_run_dust
@onready var fx_crouch = $fx_container/fx_crouch_dust
@onready var fx_wall_slide = $fx_container/fx_wall_slide
# Node References
@onready var anim = $visual/anim_movement
@onready var anim_at = $visual/anim_attack
@onready var normal_shape = $normal_shape
@onready var crouch_shape = $crouch_shape
@onready var ceiling_check = $sensors/ceiling_check
@onready var pos_g = $fx_container/fx_pos/pos_ground
@onready var pos_b = $fx_container/fx_pos/pos_back
@onready var attack_timer = $timer/attack_timer

# attack state
var attackpoint_slash = 3
var attackpoint_strike = 5
var attackpoint_air = 1
var attack_push_timer := 0.0
var attack_push_speed := 600
