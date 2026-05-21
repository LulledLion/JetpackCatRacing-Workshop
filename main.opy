
#!optimizeStrict

# settings ###################
#!define VERSION "1.0.0"    

#!define EDITOR_ON true
#!define INSPECTOR_ON true

# testscripts disable: ##, enable: #
#!define test_script ##


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