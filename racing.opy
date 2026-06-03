#!mainFile "main.opy"

def SetCheckpoints():
    eventPlayer.CurrentCheckpoint = Checkpoints[eventPlayer.CurrentCheckpointIdx] 
    eventPlayer.GoalCheckpoint = Checkpoints[eventPlayer.CurrentCheckpointIdx + 1]
    eventPlayer.AfterNextCheckpoint = Checkpoints[eventPlayer.CurrentCheckpointIdx + 2]


#$$ Combine into GoToResetPoint()
def ResetSpeed(): 
    #@@ eventPlayer.setMoveSpeed(100)
    #@@ eventPlayer.SpeedMultiplier = 100



def GoToResetPoint(): # go to CurrentCheckpoint
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
    stopChasingVariable(eventPlayer.Timer)
    eventPlayer.CurrentCheckpointIdx = 0
    SetCheckpoints()
    eventPlayer.Timer = 0
    eventPlayer.IsRacing = false
    GoToResetPoint() # CurrentCheckpoint is first reset so this works
    ResetSpeed()

    waitUntil(eventPlayer.isMoving() and eventPlayer.CurrentEditorMode == EEditorMode.OFF, 99999)

	if len(Checkpoints) > 1:
		chaseAtRate(eventPlayer.Timer, Math.INFINITY, 1)
    
	eventPlayer.IsRacing = true


rule "Finish":
    @Event eachPlayer
	
    @Condition eventPlayer.GoalCheckpoint == null
	@Condition eventPlayer.CurrentEditorMode == EEditorMode.OFF
    @Condition len(Checkpoints) > 1
    @Condition eventPlayer.CurrentCheckpointIdx == len(Checkpoints) - 1 
    @Condition eventPlayer.isAlive()
    
    eventPlayer.IsRacing = false
    stopChasingVariable(eventPlayer.Timer)

	if eventPlayer.WsEditorOn: # Don't record editor times
		return

    if "{0}".format(eventPlayer) in LeaderboardEntries.map(lambda e: e[0]):
        # you already have a time
        if eventPlayer.Timer > LeaderboardEntries.filter(lambda e: e[0] == f"{eventPlayer}")[0][1]: 
            bigMessage(eventPlayer, "Completion time: {}".format(eventPlayer.Timer))
            return # new time worse
        bigMessage(eventPlayer, "New personal best: {}".format(eventPlayer.Timer))
        LeaderboardEntries.remove(LeaderboardEntries.filter(lambda e: e[0] == f"{eventPlayer}"))
        eventPlayer.PersonalBest = eventPlayer.Timer
    else: # you are not in list yet
        eventPlayer.PersonalBest = eventPlayer.Timer
            bigMessage(eventPlayer, "Completion time: {}".format(eventPlayer.Timer))
        if len(LeaderboardEntries) < 25 or eventPlayer.Timer < LeaderboardEntries[24][1]: # board has room for more or faster than last entry
            del LeaderboardEntries[24]
        else:
            return # your time lower than last entry

    # new top 5 if faster or entry doesnt exist yet    
    if (LeaderboardEntries[0][1] > eventPlayer.Timer or not LeaderboardEntries[0] or
        LeaderboardEntries[1][1] > eventPlayer.Timer or not LeaderboardEntries[1] or
        LeaderboardEntries[2][1] > eventPlayer.Timer or not LeaderboardEntries[2] or
        LeaderboardEntries[3][1] > eventPlayer.Timer or not LeaderboardEntries[3] or
        LeaderboardEntries[4][1] > eventPlayer.Timer or not LeaderboardEntries[4]):
        bigMessage(getAllPlayers(), "New top 5 time: {} by {}!".format(eventPlayer.Timer, eventPlayer))
    
    LeaderboardEntries.append( [["{0}".format(eventPlayer), eventPlayer.Timer]] )
    LeaderboardRemake = true



rule "Arrive at Checkpoint":
    @Event eachPlayer
	@Condition eventPlayer.GoalCheckpoint != null
    @Condition distance(eventPlayer.GoalCheckpoint, eventPlayer.getEyePosition()) <= RingSize #2.65
    @Condition eventPlayer.isAlive() and eventPlayer.IsRacing
    @Condition eventPlayer.CurrentEditorMode == EEditorMode.OFF
    @Condition len(Checkpoints) > 1
    eventPlayer.CurrentCheckpointIdx += 1
    SetCheckpoints()
    # TODO: Separate starting the level vs arriving at a checkpoint IN the level?
    #@@ eventPlayer.setMoveSpeed(eventPlayer.SpeedMultiplier * 2)
    #@@ eventPlayer.SpeedMultiplier += 3
    playEffect(eventPlayer, DynamicEffect.BUFF_EXPLOSION_SOUND, Color.WHITE, eventPlayer.getEyePosition(), 100)
    eventPlayer.applyImpulse(eventPlayer.getFacingDirection(), 0.25, Relativity.TO_WORLD, Impulse.INCORPORATE_CONTRARY_MOTION)
    wait()
    eventPlayer.applyImpulse(eventPlayer.getFacingDirection(), 0.25, Relativity.TO_WORLD, Impulse.INCORPORATE_CONTRARY_MOTION)
    wait()
    eventPlayer.applyImpulse(eventPlayer.getFacingDirection(), 0.25, Relativity.TO_WORLD, Impulse.INCORPORATE_CONTRARY_MOTION)
    wait()
    eventPlayer.applyImpulse(eventPlayer.getFacingDirection(), 0.25, Relativity.TO_WORLD, Impulse.INCORPORATE_CONTRARY_MOTION)
    wait()
    eventPlayer.applyImpulse(eventPlayer.getFacingDirection(), 0.25, Relativity.TO_WORLD, Impulse.INCORPORATE_CONTRARY_MOTION)
    wait()
    eventPlayer.applyImpulse(eventPlayer.getFacingDirection(), 0.25, Relativity.TO_WORLD, Impulse.INCORPORATE_CONTRARY_MOTION)
    wait()
    eventPlayer.applyImpulse(eventPlayer.getFacingDirection(), 0.25, Relativity.TO_WORLD, Impulse.INCORPORATE_CONTRARY_MOTION)
    wait()
    eventPlayer.applyImpulse(eventPlayer.getFacingDirection(), 0.25, Relativity.TO_WORLD, Impulse.INCORPORATE_CONTRARY_MOTION)
    wait()



rule "Reset - Single Checkpoint":
    @Event eachPlayer
	# @Condition not hostPlayer.WsEditorOn
	@Condition eventPlayer.CurrentEditorMode == EEditorMode.OFF
    @Condition eventPlayer.isHoldingButton(Button.RELOAD)

    waitUntil(not eventPlayer.isHoldingButton(Button.RELOAD), 0.3)
    if eventPlayer.isHoldingButton(Button.RELOAD):
        return

    GoToResetPoint()
    ResetSpeed()



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
    ResetSpeed()



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