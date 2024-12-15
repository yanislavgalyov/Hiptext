extends Resource
class_name Buglist

@export var saved_text: Array[String] = [""]
@export var text_names: Array[String] = [""]
@export var caret_line: Array[int] = [0]
@export var caret_column: Array[int] = [0]
@export var scroll: Array[int] = [0]
@export var active_index: int = -1
