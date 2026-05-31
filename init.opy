#!mainFile "main.opy"


rule "Init Global":
    if not INSPECTOR_ON:
        disableInspector()
    disableAnnouncer()
    disableGamemodeCompletion()
    disableScoring()
    RestartLobbyTime = (
        createWorkshopSettingBool("Lobby Setting", "Infinite Lobby Time", false, 1) * Math.INFINITY +
        createWorkshopSettingInt("Lobby Setting", "Restart Lobby After X minutes", 15, 1, 60, 0) - 1
    )
    wait(1)
    startForcingSpawn(Team.ALL, 0)
    startForcingSpawn(Team.ALL, 1)
    startForcingSpawn(Team.ALL, 2)

    LeaderboardText = null
    LeaderboardEntries = []
    LeaderboardRemake = null

	setMatchTime(900)

    wait(ELoadOrder.SETUP)
    
	if Checkpoints == 0:
    	Checkpoints = []


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
    eventPlayer.setMoveSpeed(162) #@@
	eventPlayer.GoalCheckpoint = vect(0,-100,0)
	
	wait(ELoadOrder.SETUP + 0.1)
	
    eventPlayer.PersonalBest = null
    waitUntil(getTotalTimeElapsed() > 1, 1) # map variables need to load first
    FullReset()


rule "After 3s if the checkpoints are empty then provide a warning":
    @Condition getTotalTimeElapsed() > ELoadOrder.MISSING_DATA
	@Condition len(Checkpoints) == 0 
	hudHeader(null if localPlayer == hostPlayer and hostPlayer.WsEditorOn else localPlayer, " {0} Warning: Map has no data ".format(iconString(Icon.WARNING)), HudPosition.TOP, 5, Color.RED, HudReeval.VISIBILITY, SpecVisibility.DEFAULT)