extends Node3D

@onready var seg_bit = preload("res://seg_bit.tscn")

@onready var damage_todo = 0
@onready var start_life = 500
@onready var life = start_life
@onready var player = get_parent().find_child("player")
@onready var spawn_next = preload("res://end_screen.tscn")


var max_segment = 30
#var segments = [[100,100,100,100,100],
#[100,100,100,100,100]]
var segments = []
var dead = false
# Called when the node enters the scene tree for the first time.
func _ready():
	segments.append([])
	for i in range(0,max_segment):
		segments[-1].append(100)
	for index in range(0, len(segments)):
		var segment = segments[index]
		var segment_bits = get_segments_bits(index)
		if len(segment) > len(segment_bits):
			var needed = len(segment) - len(segment_bits)
			print("need to spawn: " + str(needed))
			print(index)
			for seg_index in range(len(segment_bits), len(segment_bits) + needed):
				var name = "segy_" + str(index) + "_" + str(seg_index)
				var parent_seg = "segy_" + str(index) + "_" + str(seg_index - 1)
				print("swapn: " + name)
				var new_seg_bit = seg_bit.instantiate()
				new_seg_bit.name = name
				new_seg_bit.index = index
				new_seg_bit.seg_index = seg_index
				new_seg_bit.set_deferred("global_position", global_position + Vector3(seg_index,0,seg_index))
				if seg_index == 0:
					new_seg_bit.is_head = true
				else:
					new_seg_bit.parent_seg = parent_seg
				add_child(new_seg_bit)

func get_target():
	return(player.global_position + Vector3(0,.2,0))

func get_segments_bits(index):
	var found = []
	for body in get_children():
		if "segy" in body.name and "segy_" + str(index) in body.name:
			found.append(body)
	return(found)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var active_bits = 0
	for body in get_children():
		if "segy" in body.name:
			if body.not_dead:
				active_bits += 1
	if active_bits == 0:
		print("Boss dead")
		var next_spawn = spawn_next.instantiate()
		get_parent().add_child(next_spawn)
		dead = true
