#!mainFile "main.opy"

def SetCheckpoints():
    eventPlayer.CheckpointCurrent = Checkpoints[eventPlayer.CheckpointCurrentIdx].last()
    eventPlayer.CheckpointGoal = Checkpoints[eventPlayer.CheckpointCurrentIdx + 1][0]
    eventPlayer.CheckpointAfterNext = Checkpoints[eventPlayer.CheckpointCurrentIdx + 2][0]



def GoToResetPoint(): # go to CurrentCheckpoint
    eventPlayer.ResetSpeed()
	# If there's no checkpoint set then ignore it
	if eventPlayer.CheckpointCurrent == null:
		eventPlayer.respawn()
		return

    eventPlayer.teleport(eventPlayer.CheckpointCurrent)
    eventPlayer.startForcingPosition(eventPlayer.CheckpointCurrent)
    wait()
    if not eventPlayer.EditorCurrentMode:
        eventPlayer.setFacing(directionTowards(eventPlayer.getEyePosition(),  eventPlayer.CheckpointGoal), Relativity.TO_WORLD)
    eventPlayer.stopForcingPosition()



def FullReset():
    #stopChasingVariable(eventPlayer.Timer)
    eventPlayer.CheckpointCurrentIdx = 0
    SetCheckpoints()
    #eventPlayer.Timer = 0
    eventPlayer.TimeStart = 0
    eventPlayer.TimeStop = 0
    eventPlayer.IsRacing = false
    GoToResetPoint() # CurrentCheckpoint is first reset so this works

    waitUntil(eventPlayer.isMoving() and eventPlayer.EditorCurrentMode == EEditorMode.OFF, Math.INFINITY)
    eventPlayer.IsRacing = true
    if len(Checkpoints) <= 1:
        return
    eventPlayer.TimeStart = getTotalTimeElapsed()



rule "Save previous position":
    @Event playerJoined
    eventPlayer.PositionOld = eventPlayer.PositionCurrent
    eventPlayer.PositionCurrent = eventPlayer.getPosition()
    wait(0)
    loop()



rule "Arrive at Checkpoint":
    @Event eachPlayer
    @Condition eventPlayer.EditorCurrentMode == EEditorMode.OFF
	@Condition eventPlayer.CheckpointGoal != null
    @Condition eventPlayer.isAlive()
    @Condition distance(eventPlayer.CheckpointGoal, updateEveryFrame(eventPlayer.getEyePosition())) <= RingSize #2.65

    playEffect(eventPlayer, DynamicEffect.BUFF_EXPLOSION_SOUND, Color.WHITE, eventPlayer.getEyePosition(), 100)
    
    eventPlayer.ModifySpeed(3) #$$ TODO: Map adjustable actual speed percent

    eventPlayer.CheckpointCurrentIdx += 1
    SetCheckpoints()
    if len(Checkpoints[eventPlayer.CheckpointCurrentIdx]) == 2:
        eventPlayer.teleport(eventPlayer.CheckpointCurrent)



rule "Finish":
    @Event eachPlayer
    @Condition eventPlayer.EditorCurrentMode == EEditorMode.OFF
    @Condition len(Checkpoints) > 1
    @Condition eventPlayer.CheckpointGoal == null
    @Condition eventPlayer.CheckpointCurrentIdx == len(Checkpoints) - 1 
    #@Condition eventPlayer.isAlive()
    #stopChasingVariable(eventPlayer.Timer)
    eventPlayer.IsRacing = false
    eventPlayer.TimeStop = getTotalTimeElapsed()
    eventPlayer.TimeStop -= eventPlayer.TimeStart
    eventPlayer.TimeStop -= 0.016
    eventPlayer.TimeStop += (0.016
        * max(0, min(1, line_segmentXsphere(eventPlayer.PositionOld, eventPlayer.PositionCurrent, Checkpoints.last(), RingSize)
        / distance(eventPlayer.PositionOld, eventPlayer.PositionCurrent))))
	if eventPlayer.EditorOn: # Don't record editor times
		return

    if "{0}".format(eventPlayer) in LeaderboardEntries.map(lambda e: e[0]):
        # you already have a time
        if eventPlayer.TimeStop > LeaderboardEntries.filter(lambda e: e[0] == f"{eventPlayer}")[0][1]: 
            bigMessage(eventPlayer, "Completion time: {}".format(eventPlayer.TimeStop.numberString()))
            return # new time worse
        bigMessage(eventPlayer, "New personal best: {}".format(eventPlayer.TimeStop.numberString()))
        LeaderboardEntries.remove(LeaderboardEntries.filter(lambda e: e[0] == f"{eventPlayer}"))
    else: # you are not in list yet
            bigMessage(eventPlayer, "Completion time: {}".format(eventPlayer.TimeStop.numberString()))
        if len(LeaderboardEntries) < 25 or eventPlayer.TimeStop < LeaderboardEntries[24][1]: # board has room for more or faster than last entry
            del LeaderboardEntries[24]
        else:
            return # your time lower than last entry

    eventPlayer.TimePersonalBest = eventPlayer.TimeStop.numberString()
    # new top 5 if faster or entry doesnt exist yet    
    if (LeaderboardEntries[0][1] > eventPlayer.TimeStop or not LeaderboardEntries[0] or
        LeaderboardEntries[1][1] > eventPlayer.TimeStop or not LeaderboardEntries[1] or
        LeaderboardEntries[2][1] > eventPlayer.TimeStop or not LeaderboardEntries[2] or
        LeaderboardEntries[3][1] > eventPlayer.TimeStop or not LeaderboardEntries[3] or
        LeaderboardEntries[4][1] > eventPlayer.TimeStop or not LeaderboardEntries[4]):
        bigMessage(getAllPlayers(), "New top 5 time: {} by {}!".format(eventPlayer.TimeStop.numberString(), eventPlayer))
    
    LeaderboardEntries.append( [["{0}".format(eventPlayer), eventPlayer.TimeStop]] )
    LeaderboardRemake = true



rule "Reset - Single Checkpoint":
    @Event eachPlayer
	# @Condition not hostPlayer.WsEditorOn
	@Condition eventPlayer.EditorCurrentMode == EEditorMode.OFF
    @Condition eventPlayer.isHoldingButton(Button.RELOAD)

    waitUntil(not eventPlayer.isHoldingButton(Button.RELOAD), 0.3)
    if eventPlayer.isHoldingButton(Button.RELOAD):
        return
    if eventPlayer.CheckpointCurrentIdx:
        GoToResetPoint()
    else:
        FullReset()



rule "Reset - Full":
    @Event eachPlayer
	# @Condition not hostPlayer.WsEditorOn
	@Condition eventPlayer.EditorCurrentMode == EEditorMode.OFF
    @Condition eventPlayer.isHoldingButton(Button.RELOAD)

    wait(0.5, Wait.ABORT_WHEN_FALSE)
    FullReset()



rule "Handle Death":
    @Event playerDied
    eventPlayer.respawn()
    GoToResetPoint()



rule "[Timer] After RestartLobbyTime minutes has passed, restart the lobby":
	@Condition not hostPlayer.EditorOn
	@Condition getTotalTimeElapsed() > RestartLobbyTime * 60
    bigMessage(getAllPlayers(), "   {0} Lobby is restarting in 1 minute...".format(iconString(Icon.WARNING)))
    wait(60)
	bigMessage(getAllPlayers(), "   {0} Lobby is restarting now...".format(iconString(Icon.WARNING)))
	wait(3)
	restartMatch()



rule "Anti Crash":
	@Event global
	@Condition getServerLoad() > 250
    wait(1, Wait.ABORT_WHEN_FALSE)
    smallMessage(getAllPlayers(), "anti-crash system activated")
    setSlowMotion(10)
    waitUntil(getServerLoad() < 230, Math.INFINITY)
    setSlowMotion(100)