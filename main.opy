#!optimizeStrict
##!writeToOutputFile
# warnings ###################
#!suppressWarnings w_tags
#!suppressWarnings w_lone_else
#!suppressWarnings w_enum_constant
#!suppressWarnings w_dark_color
# settings ###################
macro VERSION = "1.1.0"
macro EDITOR_ON = true
macro INSPECTOR_ON = false
#!define JS(content) __script__("js.js")

# includes ###################
#!include "settings.opy"
#!include "variables.opy"

divider(customization)
#!include "customize.opy"

divider(mapdata)
#!include "map_data.opy"

divider(code)
#!include "init.opy"
#!include "huds.opy"
#!include "racing.opy"

divider(editor)
#!include "editor.opy"

test_script!include "test_scripts.opy"
#JS((TEST=>TEST?'#!include "test_scripts.opy"':'')( false ))