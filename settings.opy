#!mainFile "main.opy"
#!extension playMoreEffects
#!extension explosionSounds

settings {
    "main": {
        "description": "Jetpack Cat Racing framework.\n\nMaintained by DragonEngineer & LulledLion.\nAdapted by nebula\nOriginal credit to Jashaal & Roeesun.\n\nWorkshop website: workshop.codes/TSB2M\nDiscord: dsc.gg/jetpack\nWebsite: jetpackcat.racing",
        "modeName": f"Jetpack Cat Racing {VERSION}"
    },
    "lobby": {
        "allowPlayersInQueue": true,
        "mapRotation": "afterGame",
        "spectatorSlots": 3,
        "team1Slots": 0,
        "team2Slots": 10,
        "returnToLobby": "never",
        "swapTeamsAfterMatch": false
    },
    "gamemodes": {
        "skirmish": {
        },
		"tdm": {
            "enabledMaps": []
        },
        "general": {
            "gamemodeStartTrigger": "manual",
            "heroLimit": "off",
            "respawnTime%": 10,
            "spawnHealthPacks": "disabled",
            "enableRandomHeroes": true
        }
    },
    "heroes": {
        "allTeams": {
            "jetpackCat": {
                "secondaryFireRechargeRate%": 500,
                "enablePassiveUnlimitedFuel": true,
                "enableUlt": false,
                "enableInfiniteAmmo": true
            },
            "enabledHeroes": [
                "jetpackCat"
            ]
        }
    }
}

