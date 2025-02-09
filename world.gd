extends Node3D
@onready var music = $music
@onready var env = $WorldEnvironment
@onready var player = $player

# Big thanks to https://github.com/fbcosentino/godot-audiostreampreview/blob/main/addons/audio_preview/voice_preview_generator.gd
# From https://godotengine.org/asset-library/asset/2257

var data
#var stream
#var this_stream
#var data_size
#var is_16bit
#var is_stereo

var final_sample_i = 0
var image_max_width = 2000
const MAX_FREQUENCY: float = 3000.0 # Maximum frequency captured
const SAMPLING_RATE = 2.0*MAX_FREQUENCY

var sound_light_data

var norm_sound_light_data = []
var hard_sound_light_data = []
var repeat = true
var hardness = 1
var made_trade = true
var lava_level = 0
var inverce_light_power = 300.0
var normal_music = preload("res://import/CC BY Mystery Mammal/Mystery Mammal - Boss Battle.wav")
var hard_end_music = preload("res://import/CC BY BoxCat Games/BoxCat Games - Battle (End).wav")
var last_boss = null
#const IMAGE_HEIGHT_FACTOR: float = float(IMAGE_HEIGHT) / 256.0 # Converts sample raw height to pixel
#const IMAGE_CENTER_Y = int(round(IMAGE_HEIGHT / 2.0))


var img_x = 0



func _get_light_data(stream):
	var new_sound_light_data = []
	var this_stream = stream.get_data
	var data = stream.data
	var reduced_data = PackedByteArray()
	var data_size = data.size()
	var sample_i = 0
	var is_16bit = (stream.format == AudioStreamWAV.FORMAT_16_BITS)
	var is_stereo = stream.stereo
	
	
	# For display reasons, lower frequencies than the sampling rate might suffice. 
	# According to the gentlemen of noble steem known as Nyquist and Shannon, 
	# we can sample at SAMPLING_RATE
	
	
	var sample_interval = 1
	if stream.mix_rate > SAMPLING_RATE:
		sample_interval = int(round(stream.mix_rate / SAMPLING_RATE))
	if is_16bit:
		sample_interval *= 2
	if is_stereo:
		sample_interval *= 2
	
	
	# We use floor(), not round(), because extra elements in the end of data
	# before next sampling interval are discarded
	var reduced_data_size = int(floor( data_size / float(sample_interval) ))
	reduced_data.resize(reduced_data_size)
	
	
	# For drawing a preview, we use only one byte left channel per sample
	# PCM16 is little endian, so MSB is index 1, not 0
	# reduced_data will contain only that one byte per sample
	var sample_in_i := 1 if is_16bit else 0
	var sample_out_i := 0
	while (sample_in_i < data_size) and (sample_out_i < reduced_data_size):
		reduced_data[sample_out_i] = data[sample_in_i]
		
		sample_in_i += sample_interval
		sample_out_i += 1
	
	
	# From now on we work only with reduced_data 
	#image_max_width
	var image_compression = ceil(reduced_data_size / float(image_max_width))

	var final_sample_i = (reduced_data_size - image_compression)

	while sample_i < final_sample_i:
		var min_val := 128
		var max_val := 128
		for block_i in range(image_compression):
			var sample_val = reduced_data[sample_i]
			# Convert signed bytes to unsigned bytes
			sample_val += 128
			if sample_val >= 256:
				sample_val -= 256
			
			# Get minmax
			if sample_val < min_val:
				min_val = sample_val
			if sample_val > max_val:
				max_val = sample_val
			
			
			sample_i += 1
		
		new_sound_light_data.append([min_val,max_val])
	return(new_sound_light_data)

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	norm_sound_light_data = _get_light_data(normal_music)
	#print(len(norm_sound_light_data))
	hard_sound_light_data = _get_light_data(hard_end_music)
	#print(len(hard_sound_light_data))
	sound_light_data = norm_sound_light_data

	
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not player or not player.level:
		queue_free()
		return
	#update lava level
	if player.level != lava_level:
		lava_level = player.level
		if lava_level == 1:
			find_child("lava").global_position.y = 130
		if lava_level == 2:
			find_child("lava").global_position.y = 70
		if lava_level == 3:
			find_child("lava").global_position.y = 0
	
	var boss_life = (float(player.boss.life)/float(player.boss.start_life))*100
	#Swich to normal music
	if last_boss != player.boss:
		last_boss = player.boss
		if music.stream == hard_end_music:
			print("Set normal music")
			music.stream = normal_music
			sound_light_data = norm_sound_light_data
	
	#Swich to hard
	if boss_life <= 50 and player.boss.life > 0:
		if music.stream == normal_music:
			print("Set hard music")
			music.stream = hard_end_music
			sound_light_data = hard_sound_light_data
		inverce_light_power = boss_life * 30
		$music.volume_db = clamp((50/player.boss.life) -1,0,4)
	else:
		inverce_light_power = 900.0
		$music.volume_db = 0
	#Update lighting
	if not made_trade:
		if $WorldEnvironment:
			$WorldEnvironment.environment.fog_enabled = false
		if $sun:
			$sun.light_energy = .3
	if made_trade:
		if not music:
			return
		#print(get_playback_position())
		if music.playing:
			var pos = music.get_playback_position()
			var length = music.stream.get_length()
			#print(pos)
			#print(length)
			#print(len(reduced_data))
			var index = (pos/length) * len(sound_light_data)
			var min_max = sound_light_data[int(index)]
			var DB = min_max[1] - min_max[0]
			#print(DB)
			if inverce_light_power == 0:
				inverce_light_power = .0001
			var light_power = DB / inverce_light_power
			$WorldEnvironment.environment.fog_light_energy  = lerp($WorldEnvironment.environment.fog_light_energy,light_power,.9)

		elif repeat:
			music.play()
		#	$WorldEnvironment.environment.fog_light_energy  = 0
