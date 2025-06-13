# fx_dash_dust.gd
extends Node2D

@onready var anim = $AnimatedSprite2D

func _ready():
	anim.play("dash_dust")
	anim.animation_finished.connect(queue_free)
