#!mainFile "main.opy"

# Global variables
# Map Data
globalvar Checkpoints 0
globalvar RingSize 10

# Customization
globalvar CreatorName 20
globalvar MapCode 21
globalvar ColorConfig 22
globalvar GoalText 23

# Workshop Settings
globalvar RestartLobbyTime 50
globalvar InfiniteLobbyTime 51

# HUD Related
globalvar LeaderboardText 60 # txt entities
globalvar LeaderboardEntries 61 # # [ [name, time] ]
globalvar LeaderboardRemake 62 # trigger remake leaderboard

# Plugins
globalvar MapVectorArray 127 # Little Destructo | Fence breaker
globalvar TestBotArray 126

# Player variables

playervar WsEditorOn
playervar CurrentEditorMode
playervar Timer
playervar PersonalBest
playervar IsRacing
playervar SpeedMultiplier
playervar CurrentCheckpointIdx
playervar GoalCheckpoint
playervar AfterNextCheckpoint
playervar CurrentCheckpoint
playervar ActivelyEditing
playervar EditCheckpointEffect
playervar EditCheckpointTemp
playervar EditMeleeButtonPressed
playervar IsMovingCheckpoint
playervar ShouldShowExportInstructions

# Subroutines
subroutine FullReset
subroutine GoToResetPoint # teleport back to lastpoint
subroutine ResetSpeed
subroutine StartEditorCamera
subroutine StartEditorCamera2
subroutine StopEditorCamera
subroutine DisableAbilities
subroutine EnableAbilities
subroutine SetCheckpoints
# subroutine LeaderboardUpdate #$$ Remove

# testscripts disable: ##, enable: #
#!define test_script ##

#!define divider(x) rule "------------------------------------------------------------------------  x ------------------------------------------------------------------------ ":\
    @Delimiter\
    @Disabled

#!define LeftAlign100 "                                                                                                    "

enum ECustomize: # index in the customize array for colors and such
    CREDIT_NAME,
    CREDIT_CODE,
    DSC,
    CONTROL_HUD_1,
    PLAYER_TIME,
    AFTER_NEXT_CP,
    GOAL_CP,
    GOAL_COLOR,
    SPD_COLOR,
    PERSONAL_BEST,

enum ELoadOrder:
    MAP_DATA     = -1,
    CUSTOMIZE   = 0,
    DESTRUCTO   = 0.016 * 2,
    SETUP       = 0.016 * 32,
    #ADDON       = 0.016 * 40,
    HUDS_GLOBAL  = 0.016 * 48,
    #HUDS_PLAYER  = 0.016 * 56,
    #HUDS_EDITOR  = 0.016 * 64,
    MISSING_DATA = 3,
    EFFECTS     = 0.016 * 256,

# _END are general purpose last order huds for their side
enum EHudOrder: # hud ordering
    # hud middle ###############
    TIMER,
	EDITOR_MODE_TEXT,
	NEXT_CP_TEXT,
	NEXT_PREV_MODE_TEXT,
	FIRST_CP_TEXT,
	MODE_ACTION_TEXT,
	PREV_CP_TEXT,
	EXPORT_INFO_TEXT,

    MIDLE_END, 
    # hud left ###############
    CREDIT,
    DISC,
    SPD,
    TEST_POSITION,
    TEST_LOAD,

    LEFT_END,

    # hud right ###############
    CONTROLS,
    PERSONAL_BEST,
    TOP5,

    RIGHT_END,

enum EEditorMode:
    OFF = 0,
    ON = 1,
    MOVE = 2,
    INSERT = 3,
    REMOVE = 4,

macro Array.insertAt(index, item):
    self.append(null)
    self = self.map(lambda CAE, CAI: CAE if CAI <= index else self[CAI - 1])
    self[index] = item

macro Player.flyMovementDelta():
    ((0.096 + 0.192 * self.isHoldingButton(Button.PRIMARY_FIRE) - 0.048 * self.isHoldingButton(Button.SECONDARY_FIRE)) *
    (self.getFacingDirection() * self.getThrottle().z * (vect(1, not self.isHoldingButton(Button.ABILITY_1), 1)) +
    worldVector(self.getThrottle() * Vector.LEFT, self, Transform.ROTATION) +
    Vector.UP * (self.isHoldingButton(Button.JUMP) - self.isHoldingButton(Button.CROUCH))))

