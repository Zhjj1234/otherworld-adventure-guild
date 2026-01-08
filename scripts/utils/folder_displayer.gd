class_name FolderDisplayer

## 获得指定文件夹下的文件和文件夹信息
## @param folder_path: 文件夹路径
## @param include_files: 是否包含文件信息
## @param include_dirs: 是否包含文件夹信息
## @param recursive: 是否递归获取子文件夹下的文件和文件夹信息
## @param include_hidden: 是否包含隐藏文件/文件夹
## @return: Array 包含文件/文件夹信息的数组，每个元素为Dictionary{path, name, is_file, is_dir}
static func get_folder_content(folder_path: String, include_files: bool = true, include_dirs: bool = true, recursive: bool = false, include_hidden: bool = false) -> Array:
	var result = []
	
	# 检查路径是否有效
	if not DirAccess.dir_exists_absolute(folder_path):
		push_warning("Folder not found: " + folder_path)
		return result
	
	# 获取文件列表
	if include_files:
		for file in DirAccess.get_files_at(folder_path):
			if not include_hidden and file.begins_with("."):
				continue
			result.append({
				"path": folder_path.path_join(file),
				"name": file,
				"is_file": true,
				"is_dir": false
			})
	# 获取文件夹列表
	if include_dirs:
		for dir in DirAccess.get_directories_at(folder_path):
			if not include_hidden and dir.begins_with("."):
				continue
			result.append({
				"path": folder_path.path_join(dir),
				"name": dir,
				"is_file": false,
				"is_dir": true
			})
			
			# 递归处理子文件夹
			if recursive:
				result.append_array(get_folder_content(folder_path.path_join(dir), include_files, include_dirs, recursive, include_hidden))
	
	return result