extends RefCounted
## Pure, reversible pose sampling. No gameplay, timers, RNG or save access.

const CONTACT := 0.54
const RELEASE := 0.62
const UPPER_ARM := 70.0
const FOREARM := 76.0
const THIGH := 125.0
const SHIN := 135.0
const REAR_TO_TIP := 430.0
const HAND_SPACING := 94.0
const ANKLE_HEIGHT := -56.0
const IDLE_GRIP := Vector2(-28, -307)
const STRIKE_GRIP := Vector2(80, -330)


static func sample(progress: float, target: Vector2) -> Dictionary:
	var p := clampf(progress, 0.0, 1.0)
	var strike_angle := asin(clampf((target.y - STRIKE_GRIP.y) / REAR_TO_TIP, -0.35, 0.35))
	var reach := STRIKE_GRIP.x + cos(strike_angle) * REAR_TO_TIP
	var advance := maxf(0.0, target.x - reach)
	var crouch := 0.0
	var lean := 0.0
	var travel := 0.0
	var extension := 0.0
	var lift := 0.0
	var stance := 0.0
	var recoil := 0.0
	if p < 0.16:
		var t := _ease(p / 0.16)
		crouch = t * 9.0
		lean = -0.045 * t
		recoil = t
		travel = -14.0 * t
	elif p < 0.40:
		var t := _ease((p - 0.16) / 0.24)
		travel = lerpf(-14.0, advance, t)
		crouch = lerpf(9.0, 6.0, t)
		lean = lerpf(-0.045, 0.07, t)
		stance = t
		lift = sin(t * PI) * 25.0
		recoil = 1.0 - t
	elif p < CONTACT:
		extension = _ease((p - 0.40) / (CONTACT - 0.40))
		travel = advance
		crouch = lerpf(6.0, 20.0, extension)
		lean = lerpf(0.07, 0.16, extension)
		stance = 1.0
	elif p < RELEASE:
		travel = advance
		extension = 1.0
		crouch = 20.0
		lean = 0.16
		stance = 1.0
	elif p < 0.78:
		var t := _ease((p - RELEASE) / 0.16)
		travel = advance
		extension = 1.0 - t
		crouch = lerpf(20.0, 6.0, t)
		lean = lerpf(0.16, 0.04, t)
		stance = 1.0
	else:
		var t := _ease((p - 0.78) / 0.22)
		travel = advance * (1.0 - t)
		crouch = 6.0 * (1.0 - t)
		lean = 0.04 * (1.0 - t)
		stance = 1.0 - t
		lift = sin(t * PI) * 18.0
	var hip := Vector2(20.0 * extension, -290 + crouch)
	var rear_grip := IDLE_GRIP.lerp(STRIKE_GRIP, extension) + Vector2(-20 * recoil, 0)
	var angle := lerpf(-0.12, strike_angle, extension) - 0.06 * recoil
	var axis := Vector2.RIGHT.rotated(angle)
	var front_grip := rear_grip + axis * HAND_SPACING
	var shoulder_near := hip + Vector2(-50, -116).rotated(lean)
	var shoulder_far := hip + Vector2(34, -104).rotated(lean)
	var ankle_near := Vector2(lerpf(54, 106, stance), ANKLE_HEIGHT - lift)
	var ankle_far := Vector2(lerpf(-44, -104, stance), ANKLE_HEIGHT)
	var hip_near := hip + Vector2(14, 0)
	var hip_far := hip + Vector2(-17, 0)
	return {
		"progress": p,
		"root": Vector2(travel, 0),
		"hip": hip,
		"lean": lean,
		"head_angle": -lean * 0.7,
		"cloth_angle": -lean * 0.6 - sin(p * TAU) * 0.035,
		"weapon_angle": angle,
		"rear_grip": rear_grip,
		"front_grip": front_grip,
		"tip": rear_grip + axis * REAR_TO_TIP,
		"shoulder_near": shoulder_near,
		"shoulder_far": shoulder_far,
		"elbow_near": elbow(shoulder_near, rear_grip, UPPER_ARM, FOREARM, 1),
		"elbow_far": elbow(shoulder_far, front_grip, UPPER_ARM, FOREARM, 1),
		"hip_near": hip_near,
		"hip_far": hip_far,
		"knee_near": elbow(hip_near, ankle_near, THIGH, SHIN, -1),
		"knee_far": elbow(hip_far, ankle_far, THIGH, SHIN, -1),
		"ankle_near": ankle_near,
		"ankle_far": ankle_far,
		"phase": phase_name(p),
	}


static func elbow(start: Vector2, end: Vector2, upper: float, lower: float, bend: float) -> Vector2:
	var delta := end - start
	var distance := clampf(delta.length(), absf(upper - lower) + 0.001, upper + lower - 0.001)
	var direction := delta.normalized() if delta.length() > 0.001 else Vector2.RIGHT
	var along := (upper * upper - lower * lower + distance * distance) / (2.0 * distance)
	var height := sqrt(maxf(0.0, upper * upper - along * along))
	return start + direction * along + Vector2(-direction.y, direction.x) * height * bend


static func phase_name(progress: float) -> String:
	if progress <= 0.0:
		return "POZYCJA WYJŚCIOWA"
	if progress < 0.16:
		return "PRZYGOTOWANIE"
	if progress < 0.40:
		return "DOSKOK"
	if progress < CONTACT:
		return "PCHNIĘCIE"
	if progress < RELEASE:
		return "KONTAKT GROTEM"
	if progress < 0.78:
		return "WYCOFANIE LANCY"
	if progress < 1.0:
		return "POWRÓT"
	return "GOTOWOŚĆ"


static func _ease(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
