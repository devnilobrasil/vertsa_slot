extends Control

# ------------------------------
# CONFIGURAÇÕES
# ------------------------------
var is_spinning: bool = false
var stop_requested: bool = false

var spin_speed: float = 0.0
var target_speed: float = 2000.0
var accel: float = 2400.0
var decel: float = 2600.0
var min_speed_to_snap: float = 180.0

var symbol_height: float = 300.0
var visible_symbols: int = 3
var buffer_symbols: int = 30

var symbols: Array = []
var rng := RandomNumberGenerator.new()
var result_symbol: int = -1

var scroll_offset: float = 0.0

# timeout de segurança
var rotation_time: float = 18.0
var time_left: float = 0.0

# sprites
var symbol_scenes: Array[Texture2D] = [
	preload("res://assets/images/symb1.png"),
	preload("res://assets/images/symb2.png"),
	preload("res://assets/images/symb3.png")
]

# ORDEM FIXA DO STRIP (repete infinitamente)
var strip_order: Array[int] = [0, 1, 2]  # symb1 -> symb2 -> symb3 -> (repete)
var strip_start_offset: int = 0          # onde começamos na faixa

# ------------------------------
# REFS DE CENA
# ------------------------------
@onready var reel_viewport: Control = $ReelViewport
@onready var slot: Control = $ReelViewport/SlotContainer
@onready var btn_start: Button = $ButtonsContainer/ButtonStart
@onready var btn_stop: Button = $ButtonsContainer/ButtonStop
@onready var congrats_label: Control = $CongratsLabel
@onready var tryagain_label: Control = $TryAgainLabel

# ------------------------------
# READY
# ------------------------------
func _ready():
	rng.randomize()
	congrats_label.visible = false
	tryagain_label.visible = false

	reel_viewport.clip_contents = true
	reel_viewport.custom_minimum_size.y = symbol_height * visible_symbols

	slot.custom_minimum_size.y = symbol_height * visible_symbols
	slot.position.y = -buffer_symbols * symbol_height

	create_initial_symbols()

	btn_start.pressed.connect(_on_button_start_pressed)
	btn_stop.pressed.connect(_on_button_stop_pressed)

	_set_ui_state("idle")

# ------------------------------
# UI STATE
# ------------------------------
func _set_ui_state(state: String) -> void:
	match state:
		"idle":
			btn_start.disabled = false
			btn_stop.disabled = true
		"spinning":
			btn_start.disabled = true
			btn_stop.disabled = false
		"stopping":
			btn_start.disabled = true
			btn_stop.disabled = true

# ------------------------------
# CRIAÇÃO DE SÍMBOLOS (SEQUÊNCIA/STRIP)
# ------------------------------
func create_initial_symbols():
	for s in symbols:
		s.queue_free()
	symbols.clear()

	# começamos em um ponto aleatório da faixa (só para variar a "foto" inicial)
	strip_start_offset = rng.randi_range(0, strip_order.size() - 1)

	var total := visible_symbols + buffer_symbols * 2
	for i in range(total):
		var tr := TextureRect.new()

		# pega o índice da faixa de forma cíclica
		var idx := strip_order[(strip_start_offset + i) % strip_order.size()]
		tr.texture = symbol_scenes[idx]

		tr.expand = true
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(0, symbol_height)

		slot.add_child(tr)

		tr.position = Vector2(0, (i - buffer_symbols) * symbol_height)
		tr.size = Vector2(reel_viewport.size.x, symbol_height)

		symbols.append(tr)

	scroll_offset = 0.0

# ------------------------------
# RECICLAGEM (SEM TROCAR TEXTURA)
# ------------------------------
func _recycle_if_needed():
	while scroll_offset >= symbol_height:
		scroll_offset -= symbol_height

		# move o primeiro nó para o final, sem alterar a textura
		var first: TextureRect = symbols.pop_front()
		symbols.append(first)
		slot.move_child(first, slot.get_child_count() - 1)

		# reflow da pilha
		var y := -buffer_symbols * symbol_height
		for n in symbols:
			n.position.y = y
			y += symbol_height

# ------------------------------
# LOOP
# ------------------------------
func _process(delta):
	if is_spinning:
		if not stop_requested and spin_speed < target_speed:
			spin_speed = min(target_speed, spin_speed + accel * delta)

		scroll_offset += spin_speed * delta
		_recycle_if_needed()

		var base_y := -buffer_symbols * symbol_height
		slot.position.y = base_y + fposmod(scroll_offset, symbol_height)

		# timeout de segurança
		if not stop_requested and time_left > 0.0:
			time_left -= delta
			if time_left <= 0.0:
				request_stop()

		# frenagem
		if stop_requested:
			spin_speed = max(min_speed_to_snap, spin_speed - decel * delta)
			if spin_speed <= min_speed_to_snap:
				_do_snap_and_stop()

# ------------------------------
# CONTROLES (Padrão 1 + Timeout)
# ------------------------------
func start_spinning():
	if is_spinning:
		return
	is_spinning = true
	stop_requested = false

	_set_ui_state("spinning")

	# resultado decidido no START (fair)
	result_symbol = rng.randi_range(0, symbol_scenes.size() - 1)

	spin_speed = 400.0
	time_left = rotation_time

func request_stop():
	if is_spinning and not stop_requested:
		stop_requested = true
		_set_ui_state("stopping")

func _do_snap_and_stop():
	# offset fracionário atual
	var off := fposmod(scroll_offset, symbol_height)
	var remaining := symbol_height - off
	if is_equal_approx(remaining, symbol_height):
		remaining = 0.0

	# se ainda falta "remaining", o centro final ficará 1 símbolo adiante
	var steps_ahead := 1 if remaining > 0.0 else 0
	var center_index: int = buffer_symbols + int(visible_symbols / 2) + steps_ahead

	# força o símbolo sorteado no centro FINAL
	var chosen := symbols[center_index] as TextureRect
	chosen.texture = symbol_scenes[result_symbol]

	var target_y: float = slot.position.y + remaining
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(slot, "position:y", target_y, 0.35)

	is_spinning = false
	stop_requested = false
	tween.finished.connect(func ():
		scroll_offset = 0.0
		spin_speed = 0.0

		# feedback
		if chosen.texture == symbol_scenes[0]:
			congrats_label.visible = true
			tryagain_label.visible = false
			$VictorySound.play()
			$BackgroundSound.stop()
		else:
			congrats_label.visible = false
			tryagain_label.visible = true

		print("Resultado:", chosen.texture.resource_path)

		# reinicia visual depois de 1.5s
		var timer := get_tree().create_timer(1.5)
		timer.timeout.connect(func ():
			congrats_label.visible = false
			tryagain_label.visible = false
			$VictorySound.stop()
			$BackgroundSound.play()
			_set_ui_state("idle")))
# ------------------------------
# BOTÕES
# ------------------------------
func _on_button_start_pressed():
	start_spinning()

func _on_button_stop_pressed():
	request_stop()
