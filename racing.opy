#!mainFile "main.opy"

def SetCheckpoints():
    eventPlayer.CurrentCheckpoint = Checkpoints[eventPlayer.CurrentCheckpointIdx].last()
    eventPlayer.GoalCheckpoint = Checkpoints[eventPlayer.CurrentCheckpointIdx + 1][0]
    eventPlayer.AfterNextCheckpoint = Checkpoints[eventPlayer.CurrentCheckpointIdx + 2][0]



def GoToResetPoint(): # go to CurrentCheckpoint
    eventPlayer.ResetSpeed()
	# If there's no checkpoint set then ignore it
	if eventPlayer.CurrentCheckpoint == null:
		eventPlayer.respawn()
		return

    eventPlayer.teleport(eventPlayer.CurrentCheckpoint)
    eventPlayer.startForcingPosition(eventPlayer.CurrentCheckpoint)
    wait()
    if not eventPlayer.CurrentEditorMode:
        eventPlayer.setFacing(directionTowards(eventPlayer.getEyePosition(),  eventPlayer.GoalCheckpoint), Relativity.TO_WORLD)
    eventPlayer.stopForcingPosition()



def FullReset():
    #stopChasingVariable(eventPlayer.Timer)
    eventPlayer.CurrentCheckpointIdx = 0
    SetCheckpoints()
    #eventPlayer.Timer = 0
    eventPlayer.StartTime = 0
    eventPlayer.StopTime = 0
    eventPlayer.IsRacing = false
    GoToResetPoint() # CurrentCheckpoint is first reset so this works

    waitUntil(eventPlayer.isMoving() and eventPlayer.CurrentEditorMode == EEditorMode.OFF, Math.INFINITY)
    eventPlayer.IsRacing = true
    if len(Checkpoints) <= 1:
        return
    eventPlayer.StartTime = getTotalTimeElapsed()



rule "Save previous position":
    @Event playerJoined
    eventPlayer.OldPosition = eventPlayer.CurrentPosition
    eventPlayer.CurrentPosition = eventPlayer.getPosition()
    wait(0)
    loop()



rule "Arrive at Checkpoint":
    @Event eachPlayer
    @Condition eventPlayer.CurrentEditorMode == EEditorMode.OFF
	@Condition eventPlayer.GoalCheckpoint != null
    @Condition eventPlayer.isAlive()
    @Condition distance(eventPlayer.GoalCheckpoint, updateEveryFrame(eventPlayer.getEyePosition())) <= RingSize #2.65

    playEffect(eventPlayer, DynamicEffect.BUFF_EXPLOSION_SOUND, Color.WHITE, eventPlayer.getEyePosition(), 100)
    
    eventPlayer.ModifySpeed(3) #$$ TODO: Map adjustable actual speed percent

    eventPlayer.CurrentCheckpointIdx += 1
    SetCheckpoints()
    if len(Checkpoints[eventPlayer.CurrentCheckpointIdx]) == 2:
        eventPlayer.teleport(eventPlayer.CurrentCheckpoint)



rule "Finish":
    @Event eachPlayer
    @Condition eventPlayer.CurrentEditorMode == EEditorMode.OFF
    @Condition len(Checkpoints) > 1
    @Condition eventPlayer.GoalCheckpoint == null
    @Condition eventPlayer.CurrentCheckpointIdx == len(Checkpoints) - 1 
    #@Condition eventPlayer.isAlive()
    #stopChasingVariable(eventPlayer.Timer)
    eventPlayer.IsRacing = false
    eventPlayer.StopTime = getTotalTimeElapsed()
    eventPlayer.StopTime -= eventPlayer.StartTime
    eventPlayer.StopTime -= 0.016
    eventPlayer.StopTime += (0.016
        * max(0, min(1, line_segmentXsphere(eventPlayer.OldPosition, eventPlayer.CurrentPosition, Checkpoints.last(), RingSize)
        / distance(eventPlayer.OldPosition, eventPlayer.CurrentPosition))))
	if eventPlayer.WsEditorOn: # Don't record editor times
		return

    if "{0}".format(eventPlayer) in LeaderboardEntries.map(lambda e: e[0]):
        # you already have a time
        if eventPlayer.StopTime > LeaderboardEntries.filter(lambda e: e[0] == f"{eventPlayer}")[0][1]: 
            bigMessage(eventPlayer, "Completion time: {}".format(eventPlayer.StopTime.numberString()))
            return # new time worse
        bigMessage(eventPlayer, "New personal best: {}".format(eventPlayer.StopTime.numberString()))
        LeaderboardEntries.remove(LeaderboardEntries.filter(lambda e: e[0] == f"{eventPlayer}"))
    else: # you are not in list yet
            bigMessage(eventPlayer, "Completion time: {}".format(eventPlayer.StopTime.numberString()))
        if len(LeaderboardEntries) < 25 or eventPlayer.StopTime < LeaderboardEntries[24][1]: # board has room for more or faster than last entry
            del LeaderboardEntries[24]
        else:
            return # your time lower than last entry

    eventPlayer.PersonalBest = eventPlayer.StopTime.numberString()
    # new top 5 if faster or entry doesnt exist yet    
    if (LeaderboardEntries[0][1] > eventPlayer.StopTime or not LeaderboardEntries[0] or
        LeaderboardEntries[1][1] > eventPlayer.StopTime or not LeaderboardEntries[1] or
        LeaderboardEntries[2][1] > eventPlayer.StopTime or not LeaderboardEntries[2] or
        LeaderboardEntries[3][1] > eventPlayer.StopTime or not LeaderboardEntries[3] or
        LeaderboardEntries[4][1] > eventPlayer.StopTime or not LeaderboardEntries[4]):
        bigMessage(getAllPlayers(), "New top 5 time: {} by {}!".format(eventPlayer.StopTime.numberString(), eventPlayer))
    
    LeaderboardEntries.append( [["{0}".format(eventPlayer), eventPlayer.StopTime]] )
    LeaderboardRemake = true



rule "Reset - Single Checkpoint":
    @Event eachPlayer
	# @Condition not hostPlayer.WsEditorOn
	@Condition eventPlayer.CurrentEditorMode == EEditorMode.OFF
    @Condition eventPlayer.isHoldingButton(Button.RELOAD)

    waitUntil(not eventPlayer.isHoldingButton(Button.RELOAD), 0.3)
    if eventPlayer.isHoldingButton(Button.RELOAD):
        return
    if eventPlayer.CurrentCheckpointIdx:
        GoToResetPoint()
    else:
        FullReset()



rule "Reset - Full":
    @Event eachPlayer
	# @Condition not hostPlayer.WsEditorOn
	@Condition eventPlayer.CurrentEditorMode == EEditorMode.OFF
    @Condition eventPlayer.isHoldingButton(Button.RELOAD)

    wait(0.5, Wait.ABORT_WHEN_FALSE)
    FullReset()



rule "Handle Death":
    @Event playerDied
    eventPlayer.respawn()
    GoToResetPoint()



rule "[Timer] After RestartLobbyTime minutes has passed, restart the lobby":
	@Condition not hostPlayer.WsEditorOn
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