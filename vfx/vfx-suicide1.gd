extends Node2D

var nframes = 0
var death_time = 2
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	nframes +=1
	if nframes >= death_time: self.queue_free()
