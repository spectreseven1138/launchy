#Resource launcher addon by Nobuyuki
#For more stuff check out https://github.com/nobuyukinyuu
tool
extends EditorPlugin

var b # A class member to hold the widget control during the plugin lifecycle
var c # A class member to hold the config dialog during the plugin lifecycle
var interface = get_editor_interface()
var editor_settings = interface.get_editor_settings()
var current_object  #currently selected object in the editor
var settings = editor_settings.get_setting('editors/external/associations')  #Dict
var custom_type_cache: Dictionary = {}

const MENU_LABEL = "Launchy:  Edit Associations..."

func _ready():
	#Setup the scene instances.
	b = preload("res://addons/launchy/launchbutton.tscn").instance()
	c = b.get_node("Config")
	b.plugin = self 
	c.editor_settings = editor_settings

	add_control_to_container(CONTAINER_PROPERTY_EDITOR_BOTTOM, b)
	b.visible = false
	b.stylize()

#Setup config popup.
	#This won't work until Godot 3.1, so instead we'll load settings from the control.
#	add_tool_menu_item("Edit Associations", c, callback)
	add_tool_menu_item(MENU_LABEL, self, "launchConfigPopup", true)
	
	#We add the config dialog to the scene tree so that we can call it.
#	interface.get_editor_viewport().add_child(c, true)
	#Connect popup closing so we can update our handler to the latest associations.
	c.connect('popup_hide', self, '_on_config_popup_closing')

	#Set basic global settings for our new external editor associations.
	if editor_settings.get_setting('editors/external/associations') == null:
		editor_settings.set_setting('editors/external/associations', {})

	var property_info = {
		"name": "editors/external/associations",
		"type": TYPE_DICTIONARY,
		"hint": PROPERTY_HINT_MULTILINE_TEXT,
		"hint_string": "External resource editor associations for Launchy."
	}
	editor_settings.add_property_info(property_info)


	
	if settings.empty() == true:
		print ("Launchy: External editor associations not yet set.")
		print ("Go to Project->Tools->Launchy: Edit Associations to set some.\n")
		print ("Settings are located in Editor Settings->Editors->External->Associations.")
		c.get_node('./ConfigItems').settings = settings
		launchConfigPopup()
	else:
		print ("Launchy is loaded. Edit settings in Project->Tools->Launchy: Edit Associations.")
		c.get_node('./ConfigItems').settings = settings


#Called whenever the editor selection changes.
func edit(object):
	current_object = object

#Launchy handles Resources only.
func handles(object):
#	print("launchy handles: ", object)

	#Just checking for any base class here before stopping.
	#When choosing the application to launch, we should probably
	#go through the entire set of keys to check for if an exact class is found.
	for type in settings.keys():
		if object.is_class(type) or get_object_type(object) == type:
			return true
	return false

#What to do when visibility changes.  Called automatically if handles() returns true.
func make_visible(visible):
	if b != null:  
		b.visible = visible
		if visible == true:
			if current_object is Resource:  b.res = current_object
			#Set the launch exe to the most specific class we can get.
			if settings.has(get_object_type(current_object)):
				b.exe = settings[get_object_type(current_object)]
			else:  #Exact match not found.  Search for a base class.
				#TODO:  Maybe walk the inheretance tree recursively up to find the
				#       subclass which matches the closest to current_object type
				for type in settings.keys():
					if current_object.is_class(type):
						b.exe = settings[type]

func get_object_type(object: Object):
	
	var script: Script = object.get_script()
	if script != null:
		
		# Check cache for this object type
		if script.resource_path in custom_type_cache:
			return custom_type_cache[script.resource_path]
		
		if script is GDScript:
			
			# Parse source code to find class_name
			for line in script.source_code.split("\n"):
				if line.begins_with("class_name "):
					custom_type_cache[script.resource_path] = line.trim_prefix("class_name ").strip_edges()
					return custom_type_cache[script.resource_path]
		
		# If script has no class_name, return file name instead
		var name: String = script.resource_path.get_basename().get_file()
		if name in settings:
			custom_type_cache[script.resource_path] = name
			return name
		
	else:
		return object.get_class()

func launchConfigPopup(param=null):
	if param is bool:
		c.popup_exclusive = param
		
		
	print("Launchy: Modifying associations...")
	settings = editor_settings.get_setting('editors/external/associations')
	c.get_node('./ConfigItems').settings = settings
	c.popup_centered()
func _on_config_popup_closing():
	updateHandlerSettings()

func updateHandlerSettings():
	#Update our settings for the visibility handler.
	settings = editor_settings.get_setting('editors/external/associations')



func _exit_tree():
	# Clean-up of the plugin goes here
	remove_control_from_container(CONTAINER_PROPERTY_EDITOR_BOTTOM, b) 
	remove_tool_menu_item(MENU_LABEL)
	b = null
