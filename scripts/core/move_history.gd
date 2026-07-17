extends RefCounted
class_name MoveHistory

var _stack: Array = []
const MAX_HISTORY := 50 # cap so it can't grow unbounded

func push(snapshot: Dictionary) -> void:
	_stack.append(snapshot)
	if _stack.size() > MAX_HISTORY:
		_stack.pop_front()

func pop() -> Dictionary:
	if _stack.is_empty():
		return {}
	return _stack.pop_back()

func can_undo() -> bool:
	return not _stack.is_empty()

func clear() -> void:
	_stack.clear()