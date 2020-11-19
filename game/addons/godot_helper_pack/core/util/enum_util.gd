class_name EnumUtil
extends Object


static func get_id(enum_class, enum_string) -> int:
	if !enum_class.has(enum_string):
		printerr("given enum string is not in enum class")
		return -1
	return enum_class[enum_string]


static func get_string(enum_class, enum_int_value) -> String:
	var keys = enum_class.keys()
	if enum_int_value < 0 or enum_int_value >= keys.size():
		printerr("given enum int value out of range for enum class")
		return ""
	return keys[enum_int_value]
