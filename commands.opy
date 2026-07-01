#!mainFile "main.opy"



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