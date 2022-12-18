do
    ---@return boolean
    local function Trig_Startup_Copy_Func004001001()
        return ( GetPlayerSlotState(GetFilterPlayer()) == PLAYER_SLOT_STATE_PLAYING )
    end
    
    ---@return boolean
    local function Trig_Startup_Copy_Func004Func001C()
        if ( not ( GetPlayerController(GetEnumPlayer()) == MAP_CONTROL_USER ) ) then
            return false
        end
        return true
    end
    
    local function Trig_Startup_Copy_Func004A()
        if ( Trig_Startup_Copy_Func004Func001C() ) then
            ForceAddPlayerSimple( GetEnumPlayer(), udg_Players )
            CreateNUnitsAtLoc( 1, FourCC('h001'), GetEnumPlayer(), GetRandomLocInRect(gg_rct_Player_Spawn), bj_UNIT_FACING )
            SetPlayerStateBJ( GetEnumPlayer(), PLAYER_STATE_RESOURCE_GOLD, 125 )
            SetPlayerStateBJ( GetEnumPlayer(), PLAYER_STATE_RESOURCE_FOOD_CAP, 8 )
            SetPlayerStateBJ( GetEnumPlayer(), PLAYER_STATE_RESOURCE_LUMBER, 55 )
            SetPlayerMaxHeroesAllowed( 1, GetEnumPlayer() )
            SetPlayerTechMaxAllowedSwap( FourCC('h00C'), 1, GetEnumPlayer() )
            SetPlayerTechMaxAllowedSwap( FourCC('h003'), 1, GetEnumPlayer() )
        else
        end
    end
    
    local function Trig_Startup_Copy_Actions()
        SetPlayerMaxHeroesAllowed( 1, Player(0) )
        PlayMusicBJ( gg_snd_IllidansTheme )
        CreateFogModifierRectBJ( true, Player(PLAYER_NEUTRAL_AGGRESSIVE), FOG_OF_WAR_VISIBLE, GetPlayableMapRect() )
        ForForce( GetPlayersMatching(Condition(Trig_Startup_Copy_Func004001001)), Trig_Startup_Copy_Func004A )
        StartTimerBJ( udg_game_start_timer, false, I2R(udg_preparation_time) )
        CreateTimerDialogBJ( udg_game_start_timer, "TRIGSTR_572" )
        udg_game_start_timer_window = GetLastCreatedTimerDialogBJ()
    end
    
    --===========================================================================
    local function InitTrig_Startup_Copy()
        gg_trg_Startup_Copy = CreateTrigger(  )
        TriggerRegisterTimerEventSingle( gg_trg_Startup_Copy, 1.00 )
        TriggerAddAction( gg_trg_Startup_Copy, Trig_Startup_Copy_Actions )
    end
    --Conversion by vJass2Lua v0.A.2.3

    function Main()
        print("Init main start")
        Trig_Startup_Copy_Func004001001()
        Trig_Startup_Copy_Func004Func001C()
        Trig_Startup_Copy_Func004A()
        Trig_Startup_Copy_Actions()
        InitTrig_Startup_Copy()
        print("init main end")
    end
end