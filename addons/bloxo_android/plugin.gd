@tool
extends EditorPlugin
## Registers the Android export tweaks below. Editor-only: not part of the game.

var _export_plugin: EditorExportPlugin


func _enter_tree() -> void:
	_export_plugin = preload("res://addons/bloxo_android/export_plugin.gd").new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null
