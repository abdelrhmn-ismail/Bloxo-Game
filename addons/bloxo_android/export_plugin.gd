@tool
extends EditorExportPlugin
## The game is portrait-only, so Android implies the device MUST support a
## portrait screen ("android.hardware.screen.portrait"). Google Play then
## hides the game from Chromebooks, PCs and some tablets. Declaring the
## feature as optional keeps the game portrait but available everywhere.


func _get_name() -> String:
	return "BloxoAndroid"


func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform is EditorExportPlatformAndroid


func _get_android_manifest_element_contents(platform: EditorExportPlatform, debug: bool) -> String:
	return '<uses-feature android:name="android.hardware.screen.portrait" android:required="false" />\n'
