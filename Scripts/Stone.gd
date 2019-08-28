extends MeshInstance

export var flipHeight : float
export var flipDuration : float

onready var tween = get_node("Tween")

var row : int
var col : int
var sideUp: String

var flipped : bool = false

func to_string():
	return String(row) + "" + String(col) + "\t" + sideUp

func flip():
	flipped = false
	var startRotation = int(get_rotation_degrees().x)
	
	tween.interpolate_property(self, "translation:y", 0, flipHeight, flipDuration / 2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.interpolate_property(self, "rotation_degrees:x", startRotation, startRotation - 90, flipDuration / 2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()
	
	yield(tween, "tween_completed")
	tween.interpolate_property(self, "translation:y", flipHeight, 0, flipDuration / 2, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.interpolate_property(self, "rotation_degrees:x", startRotation - 90, startRotation - 180, flipDuration / 2, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()
	
	yield(tween, "tween_all_completed")

func finish_flip():
	sideUp = get_parent().enemy_of(sideUp)
	flipped = true