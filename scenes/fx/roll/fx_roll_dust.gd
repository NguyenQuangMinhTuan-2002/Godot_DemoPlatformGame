# fx_roll_dust.gd
extends Node2D

@onready var anim = $AnimatedSprite2D

func _ready():
	anim.play("roll_dust")
	anim.animation_finished.connect(queue_free)
