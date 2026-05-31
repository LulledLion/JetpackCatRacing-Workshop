#!mainFile "main.opy"

def SetCheckpoints():
    eventPlayer.CurrentCheckpoint = Checkpoints[eventPlayer.CurrentCheckpointIdx] 
    eventPlayer.GoalCheckpoint = Checkpoints[eventPlayer.CurrentCheckpointIdx + 1]
    eventPlayer.AfterNextCheckpoint = Checkpoints[eventPlayer.CurrentCheckpointIdx + 2]


#$$ Combine into GoToResetPoint()
def ResetSpeed(): 
    eventPlayer.setMoveSpeed(100)
    eventPlayer.SpeedMultiplier = 100



def GoToResetPoint(): # go to CurrentCheckpoint
	# If there's no checkpoint set then ignore it
	if eventPlayer.CurrentCheckpoint == null:
		eventPlayer.respawn()
		return
    
    eventPlayer.teleport(eventPlayer.CurrentCheckpoint) #$$ Teleport Unnecessary
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
    # TODO: Separate starting the level vs arriving at a checkpoint IN the level?
    playEffect(eventPlayer, DynamicEffect.BUFF_EXPLOSION_SOUND, Color.WHITE, eventPlayer.getEyePosition(), 100)
    
    eventPlayer.setMoveSpeed(eventPlayer.SpeedMultiplier * 2)
    eventPlayer.SpeedMultiplier += 3

    eventPlayer.CurrentCheckpointIdx += 1
    SetCheckpoints()



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



macro fence_delay = 3 # decrease to make it wait more often if you have load problems, keep at full int numbers no floats
macro fence_proj_size = 30 # projectile size, 30 is maximum possible atm
macro fence_grid = 16 # gridsize of 16 means a 16x16 grid with the point in the center
rule "Addon | Little Destructo - Fence Breaker":
    # Made by FishoFire version 1.0
	wait(ELoadOrder.DESTRUCTO) # wait to overwrite any from copy pastas
    # flag mode = both flag points, just incase
    # tdm/dm = first spawn points, the maps are not big so it just covers entire map. all teams defaults to team 1 spawn
    # push: payload and cp 0 are set but rest isnt. normal payload maps have more then 1 point.
    # rest of maps have up to 3 points
    MapVectorArray.append(
        [getFlagPosition(Team.1), getFlagPosition(Team.2)] if getCurrentGamemode() == Gamemode.CTF else
        getSpawnPoints(Team.ALL)[0] if getCurrentGamemode() in [Gamemode.TDM, Gamemode.FFA] else
        getPayloadPosition() if getPayloadPosition()[0] and not (getObjectivePosition(1) + getObjectivePosition(2)) else
        [getObjectivePosition(0), getObjectivePosition(1), getObjectivePosition(2)])
    # explode in a grid around the selected points
    while len(MapVectorArray) > 1:
        MapVectorArray[0] = 0
        while MapVectorArray[0] < (fence_grid * fence_grid):
            createProjectile(
                Projectile.ORB,  # the only orb available without fx extension
                null,
                # calculation for next explosion
                MapVectorArray[1] + fence_proj_size * vect(MapVectorArray[0] % fence_grid - 0.5 * fence_grid,
                0, floor(MapVectorArray[0] / fence_grid) - 0.5 * fence_grid),
                Vector.DOWN, Relativity.TO_WORLD, ModifyHealth.HEAL, Team.1, 0, 0, fence_proj_size,
                DynamicEffect.GOOD_EXPLOSION, # possible without extensions: bad, good, ring
                DynamicEffect.EXPLOSION_SOUND, # possible without extensions: explosion sound, buf sound, ring explosion sound
                1, 1, 0, 0, 0, 0)
            MapVectorArray[0]++
            if not (MapVectorArray[0] % fence_delay): # use modulo to only wait every x orbs keep the 0 change the other number
                wait(0)
        del MapVectorArray[1]

    # handle exceptions (looking at you new queen street)
    MapVectorArray = [vect(8.276, 4.113, 15.261), vect(-8.319, 2.624, 14.245), vect(0, 4.821, 18.513)]
    while len(MapVectorArray):
        # same as other projectile before
        createProjectile(
            Projectile.ORB,
            null,
            MapVectorArray[0],
            Vector.DOWN, Relativity.TO_WORLD, ModifyHealth.HEAL, Team.1, 0, 0, fence_proj_size,
            DynamicEffect.GOOD_EXPLOSION,
            DynamicEffect.EXPLOSION_SOUND,
            1, 1, 0, 0, 0, 0)
        del MapVectorArray[0]
        wait(0)
    MapVectorArray = null



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