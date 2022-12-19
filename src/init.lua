do
    ---@return boolean
    local function playerIsPlaying()
        return ( GetPlayerSlotState(GetFilterPlayer()) == PLAYER_SLOT_STATE_PLAYING )
    end
    
    ---@return boolean
    local function playerIsUser()
        if ( not ( GetPlayerController(GetEnumPlayer()) == MAP_CONTROL_USER ) ) then
            return false
        end
        return true
    end
    
    local function initializePlayer()
        if ( playerIsUser() ) then
            -- Add player to force
            ForceAddPlayerSimple( GetEnumPlayer(), Players )
            -- Create starting units
            CreateUnit(GetEnumPlayer(),FourCC('h001'), 300, -300, 0)
            -- Set starting resources
            SetPlayerStateBJ( GetEnumPlayer(), PLAYER_STATE_RESOURCE_GOLD, 125 )
            SetPlayerStateBJ( GetEnumPlayer(), PLAYER_STATE_RESOURCE_FOOD_CAP, 8 )
            SetPlayerStateBJ( GetEnumPlayer(), PLAYER_STATE_RESOURCE_LUMBER, 55 )
            SetPlayerMaxHeroesAllowed( 1, GetEnumPlayer() )
            SetPlayerTechMaxAllowedSwap( FourCC('h00C'), 1, GetEnumPlayer() )
            SetPlayerTechMaxAllowedSwap( FourCC('h003'), 1, GetEnumPlayer() )
        else
        end
    end
    
    local function gameInit()
        SetPlayerMaxHeroesAllowed( 1, Player(0) )
        PlayMusicBJ( gg_snd_IllidansTheme )
        CreateFogModifierRectBJ( true, Player(PLAYER_NEUTRAL_AGGRESSIVE), FOG_OF_WAR_VISIBLE, GetPlayableMapRect() )
        ForForce( GetPlayersMatching(Condition(playerIsPlaying)), initializePlayer )
        StartTimerBJ( GameStartTimer, false, I2R(PREPERATION_TIME_SECONDS) )
        GameStartTimerDialogue = CreateTimerDialogBJ( GameStartTimer, string.format('Game starts...'))
    end
    
    local function initGate()
        local startupTrig = CreateTrigger(  )
        TriggerAddAction( startupTrig, gameInit )
        TriggerExecuteBJ(startupTrig, false)
    end

    function Main()
        print("Init main start")
        initGate()
        print("init main end")
    end
end