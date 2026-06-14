extends Node
## 공간 왜곡: 복도 루프, 맵 변형, 문 위치 변경.

var distortion_strength: float = 0.0
var corridor_loop_enabled: bool = false
var map_mutation_enabled: bool = false
var door_relocation_enabled: bool = false

func apply_config(cfg: Dictionary) -> void:
	distortion_strength = cfg["space_distortion"]
	corridor_loop_enabled = cfg["corridor_loop_enabled"]
	map_mutation_enabled = cfg["map_mutation_enabled"]
	door_relocation_enabled = cfg["door_relocation_enabled"]

func should_loop_corridor() -> bool:
	return corridor_loop_enabled and randf() < distortion_strength

func should_mutate_map() -> bool:
	return map_mutation_enabled and randf() < distortion_strength * 0.5

func should_relocate_door() -> bool:
	return door_relocation_enabled and randf() < distortion_strength * 0.3
