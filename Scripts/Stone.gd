extends MeshInstance

onready var tween = get_node("Tween")

var row : int
var col : int
var sideUp: String

var flipHeight : float
var flipDuration : float
var flipStones = []
var flipped = false

var light : Light

# warning-ignore:unused_argument
var flankDirections = []

func to_string():
	return sideUp + ": " + String(row) + "" + String(col)

func equals(otherStone : MeshInstance):
	return row == otherStone.row and col == otherStone.col and sideUp == otherStone.sideUp

func flip():
	flipped = false
	var startRotation = int(get_rotation_degrees().x)
	
	flipDuration = get_parent().flipDuration
	flipHeight = get_parent().flipHeight
	
	tween.interpolate_property(self, "translation:y", 0, flipHeight, flipDuration / 2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.interpolate_property(self, "rotation_degrees:x", startRotation, startRotation - 90, flipDuration / 2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()
	
	yield(tween, "tween_completed")
	tween.interpolate_property(self, "translation:y", flipHeight, 0, flipDuration / 2, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.interpolate_property(self, "rotation_degrees:x", startRotation - 90, startRotation - 180, flipDuration / 2, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()
	
	yield(tween, "tween_all_completed")

func finish_flip():
	if sideUp == "Black":
		sideUp = "White"
	elif sideUp == "White":
		sideUp = "Black"
	
	if abs(int(get_rotation_degrees().x)) >= 360:
		set_rotation_degrees(Vector3(abs(int(get_rotation_degrees().x)) - 360, 0, 0))
	
	flipped = true