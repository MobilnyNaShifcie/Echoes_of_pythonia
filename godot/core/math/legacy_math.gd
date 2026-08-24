class_name LegacyMath
extends RefCounted


static func python_roundi(value: float) -> int:
	var lower := floori(value)
	var fraction := value - lower
	if fraction < 0.5 and not is_equal_approx(fraction, 0.5):
		return lower
	if fraction > 0.5 and not is_equal_approx(fraction, 0.5):
		return lower + 1
	return lower if lower % 2 == 0 else lower + 1
