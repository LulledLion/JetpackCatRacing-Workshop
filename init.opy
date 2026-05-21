#!mainFile "main.opy"


rule "Init Global":
    if not INSPECTOR_ON:
        disableInspector()
    disableAnnouncer()
    disableGamemodeCompletion()
    disableScoring()

    wait(1)
    LeaderboardText = null
    LeaderboardEntries = []
    LeaderboardRemake = false

	# Editor variable
	ModeName = [
		"Editor Off",
		"Editor On",
		"{0} Move Mode".format(abilityIconString(Hero.SYMMETRA, Button.ABILITY_2)),
		"{0} Insert Mode".format(iconString(Icon.HALO)),
		"{0} Remove Mode".format(iconString(Icon.TRASHCAN))
	]

	ModeColour = [
		Color.WHITE,
		Color.WHITE,
		Color.BLUE,
		Color.GREEN,
		Color.RED
	]

	ModeAltColour = [
		Color.WHITE,
		Color.WHITE,
		Color.SKY_BLUE,
		Color.LIME_GREEN,
		Color.ROSE
	]

	ModeActionText = [
		"",
		"",
		"Move:",
		"Insert:",
		"Remove: Hold"
	]


    setMatchTime(900)

    wait(ELoadOrder.SETUP)
    
	if Checkpoints == 0:
    	Checkpoints = []

	RestartLobbyTime = createWorkshopSettingInt("Lobby Setting", "Restart lobby after X minutes", 15, 1, 60, 0)
	InfiniteLobbyTime = createWorkshopSettingBool("Lobby Setting", "Infinite Lobby Time", false, 1)

  


rule "Init Player":
    @Event playerJoined
    @Condition eventPlayer.isDummy() == false or eventPlayer in TestBotArray
    eventPlayer.WsEditorOn = createWorkshopSettingBool("Editor", "Editor Mode Enabled", EDITOR_ON, 0)
    
	eventPlayer.disableKillFeed()
    eventPlayer.disableGamemodeHud()
    eventPlayer.disableGamemodeInWorldUi()
    eventPlayer.disableMessages()
    eventPlayer.disablePlayerCollision()
    eventPlayer.setAbility1Enabled(false)
    eventPlayer.setStatusEffect(null, Status.INVINCIBLE, 999999)
    
	eventPlayer.GoalCheckpoint = vect(0,-100,0)
	
	wait(ELoadOrder.SETUP + 0.1)
	
	# if not eventPlayer.WsEditorOn:
	# chaseAtRate(eventPlayer.Timer, 0, 1, ChaseRateReeval.NONE)
    eventPlayer.PersonalBest = null
    waitUntil(getTotalTimeElapsed() > 1, 1) # map variables need to load first
    FullReset()


rule "After 3s if the checkpoints are empty then provide a warning":
	@Condition len(Checkpoints) == 0 

	wait(3, Wait.ABORT_WHEN_FALSE)
	hudHeader(null if localPlayer == hostPlayer and hostPlayer.WsEditorOn else localPlayer, " {0} Warning: Map has no data ".format(iconString(Icon.WARNING)), HudPosition.TOP, 5, Color.RED, HudReeval.VISIBILITY, SpecVisibility.DEFAULT)