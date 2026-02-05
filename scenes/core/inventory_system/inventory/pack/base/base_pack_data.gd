extends Resource
class_name BasePackData

enum PACK_TYPE {
	SHOP,
	PACK,
	MAGIC_BOX,
	INVENTORY,
	CHARACTER_PACK,
}

@export var pack_name: String = ""
@export var pack_type: PACK_TYPE = PACK_TYPE.PACK
