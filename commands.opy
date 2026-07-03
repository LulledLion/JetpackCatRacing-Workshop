#!mainFile "main.opy"



rule "Reset Single Checkpoint":
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



rule "Reset Full":
    @Event eachPlayer
	# @Condition not hostPlayer.WsEditorOn
	@Condition eventPlayer.EditorCurrentMode == EEditorMode.OFF
    @Condition eventPlayer.isHoldingButton(Button.RELOAD)

    wait(0.5, Wait.ABORT_WHEN_FALSE)
    FullReset()



rule "Spectate":
    @Event eachPlayer
    @Condition eventPlayer.isHoldingButton(Button.INTERACT)
    wait(0.5, Wait.ABORT_WHEN_FALSE)
    eventPlayer.CommandSpectate = not eventPlayer.CommandSpectate
    if eventPlayer.CommandSpectate:
        #eventPlayer.setDamageReceived(100)
        kill(eventPlayer, null)
        #eventPlayer.setDamageReceived(0)
    else:
        eventPlayer.resurrect()
        GoToResetPoint()