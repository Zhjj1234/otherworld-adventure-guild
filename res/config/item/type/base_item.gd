extends Resource
class_name BaseItem

enum ITEM_TYPE {
	WEAPON,
	KEY
}

@export var item_name: String
@export var item_type: ITEM_TYPE
@export var item_price: int
