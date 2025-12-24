extends Node
class_name UIInputBlocker

#* 管控的目标节点（owner）：默认取父节点
var _owner: Node
#* 输入开关：true=执行owner的输入逻辑，false=不执行
var input_enabled: bool = true
#* 和owner约定的方法名（owner必须实现这个方法，参数和_input一致）
const OWNER_INPUT_METHOD: String = "handle_ui_input"

var input_nodes: Array[Node]

@export var input_group_name: String = ""
@export var disable_input_not_stack_end: bool = true
@export var ignore_handle_ui_input_warning: bool = false
@export var ignore_input_nodes_warning: bool = false

func _ready() -> void:
	#* 自动绑定父节点为owner（不用手动设）
	if _owner == null:
		_owner = get_parent()
	_owner.ready.connect(_on_owner_ready)
	
func _on_owner_ready() -> void:
	# call_deferred("_warning_info")
	_get_input_nodes()
	push_to_ui_manager_stack()

#* UIInputBlocker自己的_input方法（核心）
func _input(event: InputEvent) -> void:
	#* 开关关闭 → 直接返回，不执行任何逻辑
	if not input_enabled:
		return
	if disable_input_not_stack_end:
		#* 非栈顶 → 直接返回，不执行任何逻辑
		if UiManager.ui_blocker_name_stack.size() != 0 and (UiManager.ui_blocker_name_stack[UiManager.ui_blocker_name_stack.size() - 1] != input_group_name):
			return
	
	for node in input_nodes:
		#* 开关打开 → 调用owner的约定方法（参数和_input一致）
		if node != null and node.has_method(OWNER_INPUT_METHOD):
			node.call(OWNER_INPUT_METHOD, event) # * 直接调用owner的业务方法

#* 对外的开关控制方法（一键禁用/启用）
func disable_input() -> void:
	input_enabled = false

func enable_input() -> void:
	input_enabled = true

#* 一键停止鼠标事件
func disable_end_ui_mouse() -> void:
	if _owner is Control:
		_owner.mouse_filter = Control.MOUSE_FILTER_STOP
		print("已禁用【%s】的鼠标事件" % name)

#* 一键启用鼠标事件
func enable_end_ui_mouse() -> void:
	if _owner is Control:
		_owner.mouse_filter = Control.MOUSE_FILTER_PASS
		print("已启用【%s】的鼠标事件" % name)

#* 一键禁用：父节点+所有子节点停止运行 _process()/_physics_process()
func disable_all_child_process() -> void:
	#* 核心：设置父节点的process_mode为DISABLED，子节点会自动继承禁用
	process_mode = Node.PROCESS_MODE_DISABLED
	print("已禁用【%s】及其所有子节点的Process" % name)

#* 一键启用：恢复父节点+所有子节点的Process（子节点按自身设置运行）
func enable_all_child_process() -> void:
	#* 恢复父节点为默认的“继承”模式（子节点回到自身的process设置）
	process_mode = Node.PROCESS_MODE_INHERIT
	print("已启用【%s】及其所有子节点的Process" % name)

func push_to_ui_manager_stack() -> void:
	UiManager.ui_blocker_name_stack.append(input_group_name)

func pop_from_ui_manager_stack() -> void:
	UiManager.ui_blocker_name_stack.pop_back()

func _get_input_nodes() -> void:
	#* 校验owner是否实现了约定方法
	if _owner == null:
		push_error("UIInputBlocker：未设置 owner，无法绑定输入节点！")
		return
	if input_group_name != "":
		input_nodes = get_tree().get_nodes_in_group(input_group_name)
		print("✅ UIInputBlocker: 绑定分组 [ %s ] 内的输入节点，数量: %d" % [input_group_name, input_nodes.size()])
	else:
		push_warning("UIInputBlocker：未设置 input_group_name，无法绑定输入节点！")
		input_nodes = []
		return
	if ignore_handle_ui_input_warning == false:
		for i in range(input_nodes.size()):
			if not input_nodes[i].has_method(OWNER_INPUT_METHOD):
				push_warning("UIInputBlocker：owner【%s】未实现 %s 方法！" % [input_nodes[i].name, OWNER_INPUT_METHOD])
			else:
				print("    [%d] %s" % [i + 1, input_nodes[i].get_path()])
	if ignore_input_nodes_warning == false:
		if input_nodes.size() == 0:
			push_warning("UIInputBlocker：未设置 在【%s】中 input_nodes，无法绑定输入节点！" % [owner.name])
