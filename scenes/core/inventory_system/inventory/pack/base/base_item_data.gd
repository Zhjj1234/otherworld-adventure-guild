extends Resource
class_name BaseItemData

enum ITEM_TYPE {
	WEAPON,
	ARMOR,
	ACCESSORY,
	FOOD,
	DRINK,
	TOOL,
	MATERIAL,
	QUEST_ITEM,
	OTHER,
}

@export var item_id: StringName
@export var item_name: String = ""
@export var item_type: ITEM_TYPE = ITEM_TYPE.OTHER
@export var item_description: String = ""
@export var item_icon: Resource = null
@export var item_price: int = 0
