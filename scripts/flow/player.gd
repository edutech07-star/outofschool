extends CharacterBody2D
## 픽셀아트 플레이어 - 4방향 이동.
##
## 입력: 방향키 또는 WASD. 상호작용: Space / Enter / E.
## ui_left / ui_right / ui_up / ui_down 는 project.godot 의 InputMap 에서
## 화살표 + WASD 양쪽으로 매핑되어 있다.

@export var speed: float = 160.0

@onready var sprite_body: Polygon2D = $Body if has_node("Body") else null
@onready var sprite_head: Polygon2D = $Head if has_node("Head") else null

var _bob_time: float = 0.0

func _ready() -> void:
	# 씬 재진입 시 잔존 속도를 확실히 초기화.
	velocity = Vector2.ZERO
	set_physics_process(true)
	process_mode = Node.PROCESS_MODE_INHERIT

func _physics_process(delta: float) -> void:
	var input := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down"),
	)
	if input.length() > 0.0:
		input = input.normalized()
		_bob_time += delta * 8.0
	velocity = input * speed
	move_and_slide()

	if sprite_body:
		var bob := sin(_bob_time) * 1.5 if velocity.length() > 1.0 else 0.0
		sprite_body.position.y = bob
		if sprite_head:
			sprite_head.position.y = bob - 0.5

		if velocity.x < -1.0:
			sprite_body.scale.x = -1
			if sprite_head:
				sprite_head.scale.x = -1
		elif velocity.x > 1.0:
			sprite_body.scale.x = 1
			if sprite_head:
				sprite_head.scale.x = 1
