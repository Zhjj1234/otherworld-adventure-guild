@tool
extends Label

# 這個數值你會在屬性面板改
@export var level_number: int = 1:
	set(new_value):
		level_number = new_value
		# 只在編輯器裡執行更新
		if Engine.is_editor_hint():
			update_label()


# 記得把 Label 拖進來，或用 $Label 路徑
#@onready var label: Label = %Label   # 或寫成 $Label / ../Label 看你的結構


func _ready() -> void:
	if Engine.is_editor_hint():
		update_label()   # 場景一載入就更新一次


func update_label() -> void:
	#if label == null:
		## 保護：如果還沒找到 Label，先印警告
		#print("[@tool] Label 還沒準備好")
		#return
	
	# 這裡就是真正改文字的地方
	text = "Level " + str(level_number)
	
	# 可選：讓文字顏色隨著數字變化（只是示範）
	if level_number >= 10:
		modulate = Color.YELLOW
	else:
		modulate = Color.WHITE
