extends BaseGameUI

class_name GameListUi

#* UI组件引用
@onready var slot_buttons := [
	$CenterContainer/Control/VBoxContainer/Slot1Button,
	$CenterContainer/Control/VBoxContainer/Slot2Button,
	$CenterContainer/Control/VBoxContainer/Slot3Button
]
@onready var back_button := $CenterContainer/Control/VBoxContainer/BackButton

func _ready() -> void:
	
	#* 连接信号
	for i in range(slot_buttons.size()):
		slot_buttons[i].pressed.connect(func(): _on_slot_button_pressed(i + 1))
	back_button.pressed.connect(_on_back_button_pressed)
	
	#* 初始化UI显示
	_update_ui_from_slot_metadata()

#* 更新UI显示槽位信息
func _update_ui_from_slot_metadata() -> void:
	#* 确保槽位元数据已更新
	SaveLoadManager._update_slot_metadata_cache_from_local()
	
	#* 更新每个槽位按钮的显示
	for i in range(slot_buttons.size()):
		var slot_id = i + 1
		var slot_data = SaveLoadManager._get_slot_metadata(slot_id)
		
		if slot_data.is_used:
			#* 格式化时间戳
			var formatted_date = Time.get_datetime_string_from_unix_time(slot_data.timestamp)
			slot_buttons[i].set_text(tr("ui_slot_format").format([slot_id, tr(slot_data.save_name), formatted_date]))
		else:
			slot_buttons[i].set_text(tr("ui_slot_empty").format([slot_id]))

#* 槽位按钮点击事件
func _on_slot_button_pressed(slot_id: int) -> void:
	SaveLoadManager.start_game(slot_id)

#* 返回按钮点击事件
func _on_back_button_pressed() -> void:
	UiManager.pop_ui()
