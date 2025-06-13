# fx_double_jump.gd
extends Node2D

@onready var anim = $AnimatedSprite2D

func _ready():
	anim.play("double_jump")
	anim.animation_finished.connect(queue_free)
