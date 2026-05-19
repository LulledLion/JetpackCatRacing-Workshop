#!mainFile "main.opy"

rule "Editor | Enable Checkpoint Selection":
    @Event eachPlayer
    @Condition eventPlayer == hostPlayer
    @Condition hostPlayer.WsEditorOn
	@Condition not eventPlayer.ShouldShowExportInstructions
    @Condition eventPlayer.isHoldingButton(Button.INTERACT)
	@Condition not eventPlayer.isHoldingButton(Button.ULTIMATE)
	
	
	if eventPlayer.IsMovingCheckpoint:
		smallMessage(hostPlayer, "   {0} Checkpoint Movement Cancelled".format(abilityIconString(Hero.SYMMETRA, Button.ABILITY_2)))
		playEffect(hostPlayer, DynamicEffect.RING_EXPLOSION_SOUND, Color.WHITE, Checkpoints[hostPlayer.CurrentCheckpointIdx], 100)

		StartEditorCamera()
		eventPlayer.EditCheckpointTemp = null
		destroyEffect(eventPlayer.EditCheckpointEffect)
		eventPlayer.IsMovingCheckpoint = false
		eventPlayer.ActivelyEditing = false
		return

	wait(0.5, Wait.ABORT_WHEN_FALSE)

	# If there's no checkpoints, create 1 at the player's position
    if len(Checkpoints) == 0:
        Checkpoints[0] = eventPlayer.getPosition()
        eventPlayer.CurrentCheckpointIdx = 0
        SetCheckpoints()

	eventPlayer.CurrentEditorMode = EEditorMode.MOVE if eventPlayer.CurrentEditorMode == EEditorMode.OFF else EEditorMode.OFF

	# Entering edit mode: Start the camera and stop the timer 
    if eventPlayer.CurrentEditorMode > EEditorMode.OFF:
        StartEditorCamera()
		stopChasingVariable(eventPlayer.Timer)
        wait(0.1)
		playEffect(hostPlayer, DynamicEffect.BUFF_EXPLOSION_SOUND, Color.WHITE, Checkpoints[hostPlayer.CurrentCheckpointIdx], 100)
		# stop timer
	# Exiting edit mode: Stop the camera and continue the timer
    else:
		eventPlayer.ActivelyEditing = false
		destroyEffect(eventPlayer.EditCheckpointEffect)
        StopEditorCamera()
		eventPlayer.IsMovingCheckpoint = false
		# start timer
		if len(Checkpoints) > 1:
			chaseAtRate(eventPlayer.Timer, Math.INFINITY, 1)
		wait(0.1)
		playEffect(hostPlayer, DynamicEffect.RING_EXPLOSION_SOUND, Color.WHITE, hostPlayer.getPosition(), 100)


rule "Editor | Export Data":
    @Event eachPlayer
    @Condition eventPlayer == hostPlayer
    @Condition hostPlayer.WsEditorOn
	# @Condition eventPlayer.CurrentEditorMode == EEditorMode.OFF 
    @Condition eventPlayer.isHoldingButton(Button.INTERACT)
	@Condition eventPlayer.isHoldingButton(Button.ULTIMATE)
	@Condition not eventPlayer.ShouldShowExportInstructions
	
    wait(0.5, Wait.ABORT_WHEN_FALSE)
    enableInspector()
	smallMessage(hostPlayer, "   Map Data Exporting...")
	playEffect(hostPlayer, DynamicEffect.BUFF_IMPACT_SOUND, Color.WHITE, hostPlayer.getPosition() if eventPlayer.CurrentEditorMode == EEditorMode.OFF else Checkpoints[eventPlayer.CurrentCheckpointIdx], 100)
	eventPlayer.ShouldShowExportInstructions = true
	wait(0.5)
    LeaderboardText = null
    LeaderboardEntries = null
    LeaderboardRemake = null
    ColorConfig = null
	CreatorName = null
	MapCode = null
	wait(2)
    disableInspector()
    smallMessage(hostPlayer, "   Map Data Exported - Check Inspector")
	playEffect(hostPlayer, DynamicEffect.BUFF_IMPACT_SOUND, Color.WHITE, hostPlayer.getPosition() if eventPlayer.CurrentEditorMode == EEditorMode.OFF else Checkpoints[eventPlayer.CurrentCheckpointIdx], 100)
	


rule "Editor | Hide Export instruction":
	@Event eachPlayer
    @Condition eventPlayer == hostPlayer
    @Condition hostPlayer.WsEditorOn
    @Condition eventPlayer.isHoldingButton(Button.MELEE)
	@Condition eventPlayer.ShouldShowExportInstructions
	@Condition not eventPlayer.EditMeleeButtonPressed

	eventPlayer.EditMeleeButtonPressed = true
	eventPlayer.ShouldShowExportInstructions = false
	playEffect(eventPlayer, DynamicEffect.RING_EXPLOSION_SOUND, Color.WHITE, eventPlayer.getPosition() if eventPlayer.CurrentEditorMode == EEditorMode.OFF else Checkpoints[eventPlayer.CurrentCheckpointIdx], 100)



rule "Editor | Select Checkpoint & Mode":
    @Event eachPlayer
    @Condition eventPlayer == hostPlayer
    @Condition hostPlayer.WsEditorOn
	@Condition eventPlayer.CurrentEditorMode > EEditorMode.OFF
	@Condition not eventPlayer.ActivelyEditing
    @Condition (eventPlayer.getThrottle().z > 0.5 or eventPlayer.getThrottle().z < -0.5 or 
            	eventPlayer.getThrottle().x > 0.5 or eventPlayer.getThrottle().x < -0.5)
	
	if eventPlayer.EditMeleeButtonPressed:
		return

    if eventPlayer.getThrottle().z > 0.5:
        eventPlayer.CurrentCheckpointIdx += 1
        if eventPlayer.CurrentCheckpointIdx >= len(Checkpoints):
            eventPlayer.CurrentCheckpointIdx = 0

    elif eventPlayer.getThrottle().z < -0.5:
        eventPlayer.CurrentCheckpointIdx -= 1
        if eventPlayer.CurrentCheckpointIdx < 0:
            eventPlayer.CurrentCheckpointIdx = len(Checkpoints) - 1
    
    elif eventPlayer.getThrottle().x > 0.5:
        eventPlayer.CurrentEditorMode += 1
        if eventPlayer.CurrentEditorMode >= len(EEditorMode):
            eventPlayer.CurrentEditorMode = EEditorMode.MOVE

    elif eventPlayer.getThrottle().x < -0.5:
        eventPlayer.CurrentEditorMode -= 1
        if eventPlayer.CurrentEditorMode < EEditorMode.MOVE:
            eventPlayer.CurrentEditorMode = len(EEditorMode) - 1
    
    SetCheckpoints()

	wait(0.1)
	playEffect(eventPlayer, DynamicEffect.BUFF_EXPLOSION_SOUND, Color.WHITE, Checkpoints[hostPlayer.CurrentCheckpointIdx], 100)



rule "Editor | Enable Checkpoint Edit":
    @Event eachPlayer
    @Condition eventPlayer == hostPlayer
    @Condition hostPlayer.WsEditorOn
    @Condition eventPlayer.CurrentEditorMode == EEditorMode.MOVE
	@Condition eventPlayer.isHoldingButton(Button.MELEE)
	@Condition not eventPlayer.EditMeleeButtonPressed

	eventPlayer.EditMeleeButtonPressed = true
    eventPlayer.ActivelyEditing = not eventPlayer.ActivelyEditing
    
	if eventPlayer.ActivelyEditing:
        smallMessage(hostPlayer, "   {0} Checkpoint Moving Enabled".format(abilityIconString(Hero.SYMMETRA, Button.ABILITY_2)))
        StartEditorCamera2()
        eventPlayer.EditCheckpointTemp = Checkpoints[eventPlayer.CurrentCheckpointIdx]
        createEffect(eventPlayer, Effect.GOOD_AURA, Color.ROSE, eventPlayer.EditCheckpointTemp, RingSize-0.15, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
        eventPlayer.EditCheckpointEffect = getLastCreatedEntity()
		eventPlayer.IsMovingCheckpoint = true
    else:
        smallMessage(hostPlayer, "   {0} Checkpoint Placed".format(abilityIconString(Hero.SYMMETRA, Button.ABILITY_2)))
        StartEditorCamera()
        Checkpoints[eventPlayer.CurrentCheckpointIdx] = eventPlayer.EditCheckpointTemp
        SetCheckpoints()
        eventPlayer.EditCheckpointTemp = null
        destroyEffect(eventPlayer.EditCheckpointEffect)
		eventPlayer.IsMovingCheckpoint = false



rule "Editor | Start Editing Position":
    @Event eachPlayer
    @Condition eventPlayer == hostPlayer
    @Condition hostPlayer.WsEditorOn
    @Condition eventPlayer.CurrentEditorMode == EEditorMode.MOVE
	@Condition eventPlayer.ActivelyEditing
	@Condition not eventPlayer.EditMeleeButtonPressed

    while not hostPlayer.isHoldingButton(Button.MELEE) and eventPlayer.ActivelyEditing:
        eventPlayer.EditCheckpointTemp += eventPlayer.flyMovementDelta()
        wait(0)


rule "Editor | Remove Checkpoint":
    @Event eachPlayer
    @Condition eventPlayer == hostPlayer
    @Condition hostPlayer.WsEditorOn
    @Condition eventPlayer.CurrentEditorMode == EEditorMode.REMOVE
	@Condition eventPlayer.isHoldingButton(Button.MELEE)
	@Condition not eventPlayer.EditMeleeButtonPressed

	wait(0.5, Wait.ABORT_WHEN_FALSE)
    smallMessage(hostPlayer, "   {0} Checkpoint Removed".format(iconString(Icon.TRASHCAN)))
	eventPlayer.EditMeleeButtonPressed = true
    del Checkpoints[eventPlayer.CurrentCheckpointIdx]
    
	# If deleted the last checkpoint, reset the first checkpoint to be the player's current position
	if len(Checkpoints) == 0:
		eventPlayer.CurrentEditorMode = EEditorMode.OFF
		playEffect(hostPlayer, DynamicEffect.RING_EXPLOSION_SOUND, Color.WHITE, eventPlayer.getPosition(), 100)
		eventPlayer.ActivelyEditing = false
        StopEditorCamera()
		eventPlayer.CurrentCheckpointIdx = 0
		return

	if eventPlayer.CurrentCheckpointIdx >= len(Checkpoints):
		eventPlayer.CurrentCheckpointIdx = len(Checkpoints) - 1

	SetCheckpoints()


rule "Editor | Insert Checkpoint (After Current Checkpoint)":
    @Event eachPlayer
    @Condition hostPlayer.WsEditorOn
    @Condition eventPlayer == hostPlayer
    @Condition eventPlayer.CurrentEditorMode == EEditorMode.INSERT
	@Condition eventPlayer.isHoldingButton(Button.MELEE)
    @Condition not eventPlayer.EditMeleeButtonPressed

	smallMessage(hostPlayer, "   {0} Checkpoint Inserted".format(iconString(Icon.HALO)))
	eventPlayer.EditMeleeButtonPressed = true
    Checkpoints.insertAt(eventPlayer.CurrentCheckpointIdx, Checkpoints[eventPlayer.CurrentCheckpointIdx])
    eventPlayer.CurrentCheckpointIdx += 1
    SetCheckpoints()
    eventPlayer.CurrentEditorMode = EEditorMode.MOVE
    eventPlayer.ActivelyEditing = true
    StartEditorCamera2()
    eventPlayer.EditCheckpointTemp = Checkpoints[eventPlayer.CurrentCheckpointIdx]
    createEffect(eventPlayer, Effect.GOOD_AURA, Color.ROSE, eventPlayer.EditCheckpointTemp, RingSize-0.15, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    eventPlayer.EditCheckpointEffect = getLastCreatedEntity()
	eventPlayer.IsMovingCheckpoint = true


rule "Editor | When stopped pressing melee, set EditMeleeButtonPressed back to true so next melee button can be presssed":
	@Event eachPlayer
    @Condition hostPlayer.WsEditorOn
    @Condition eventPlayer == hostPlayer
	@Condition not eventPlayer.isHoldingButton(Button.MELEE)

	eventPlayer.EditMeleeButtonPressed = false


#!define cam_distance 8
# calcultes distance between cam and wall and subtracts 1 to make sure you are not inside the wall
# if nothing is hit then it just returns max length
# parameter is the start position
#!define cam_dist_calc(start) (distance(start, raycast(start, start + eventPlayer.getFacingDirection() * - cam_distance,null,null,false).getHitPosition()) - 1)

def StartEditorCamera():
    @Name "Editor | Start Editor 3rd Person Camera"
    
    eventPlayer.setInvisibility(Invis.ALL)
    DisableAbilities()

    eventPlayer.startCamera(
        eventPlayer.CurrentCheckpoint + updateEveryFrame(eventPlayer.getFacingDirection() * - cam_dist_calc(eventPlayer.CurrentCheckpoint) ),
        eventPlayer.CurrentCheckpoint, 
        500
    )
    

def StartEditorCamera2():
    @Name "Editor | Start Editor 3rd Person Camera | Checkpoint Movement"

    eventPlayer.startCamera(
        eventPlayer.EditCheckpointTemp + (
            updateEveryFrame(eventPlayer.getFacingDirection()) * -6
        ), 
        eventPlayer.EditCheckpointTemp, 
        25
    )

def StopEditorCamera():
    @Name "Editor | Stop Editor 3rd Person Camera"
    eventPlayer.stopCamera()
    eventPlayer.setInvisibility(Invis.NONE)
    EnableAbilities()


def DisableAbilities():
    @Name "Editor | Disable Movement and Abilities"
    eventPlayer.setJumpEnabled(false)
    eventPlayer.setCrouchEnabled(false)
    eventPlayer.setPrimaryFireEnabled(false)
    eventPlayer.setSecondaryFireEnabled(false)
    eventPlayer.disallowButton(Button.SECONDARY_FIRE)
    eventPlayer.setAbility1Enabled(false)
    eventPlayer.setAbility2Enabled(false)
    eventPlayer.setMoveSpeed(0)

def EnableAbilities():
    @Name "Editor | Enable Movement and Abilities"
    eventPlayer.setJumpEnabled(true)
    eventPlayer.setCrouchEnabled(true)
    eventPlayer.setPrimaryFireEnabled(true)
    eventPlayer.setSecondaryFireEnabled(true)
    eventPlayer.allowButton(Button.SECONDARY_FIRE)
    eventPlayer.setAbility1Enabled(false) # This stays off always
    eventPlayer.setAbility2Enabled(true)
    eventPlayer.setMoveSpeed(100)
