do
    local BASE_WELFARE_GOLD = 300
    local BASE_WELFARE_LUMBER = 300
    local GOLD_ON_KILL = 1
    local waveGoldBonus = 10000

    local function addGoldAndLumber()
        print("Add gold and lumber called!")
        AdjustPlayerStateBJ( BASE_WELFARE_GOLD or 1000, GetEnumPlayer(), PLAYER_STATE_RESOURCE_GOLD )
        AdjustPlayerStateBJ( BASE_WELFARE_LUMBER or 1000, GetEnumPlayer(), PLAYER_STATE_RESOURCE_LUMBER )
    end
    
    -- Adds gold and lumber to each user. Should run at end of an enemy wave. Amount of gold added is dependent on the time it took to kill the enemy special unit.
    ---@type function
    ---@returns integer
    local function distributeWelfare()
        DisplayTextToForce( GetPlayersAll(), "Welfare distributed!" )
        ForForce( Players, addGoldAndLumber )
        return 1
    end

    -- works
    local function initGoldOnKill()
        local goldOnKillTrigger = CreateTrigger( )
            -- Adds gold to the player who killed the unit

        local function addGoldOnKill()
            AdjustPlayerStateBJ( GOLD_ON_KILL, GetOwningPlayer(GetKillingUnitBJ()), PLAYER_STATE_RESOURCE_GOLD )
        end

        TriggerRegisterAnyUnitEventBJ( goldOnKillTrigger, EVENT_PLAYER_UNIT_DEATH )
        TriggerAddAction( goldOnKillTrigger, addGoldOnKill )
    end

    local function giveWaveBonusGold()
        AdjustPlayerStateBJ( waveGoldBonus, GetEnumPlayer(), PLAYER_STATE_RESOURCE_GOLD )
    end
    
    local function handleWaveCompleted()
        DisplayTextToForce( GetPlayersAll(), ( "|cff008000Round Completion Gold Bonus: |r" + I2S(udg_wave_earned_gold_bonus) ) )
        ForForce( Players, giveWaveBonusGold )
    end

    
    local function triggerSetup()
        initGoldOnKill()
    end

    -- Define a table
    ---@type {setup: function, welfare: function, waveCompletionGold: function}
    Economy = {
        setup = triggerSetup;
        welfare = distributeWelfare;
        waveCompletionGold = handleWaveCompleted;
    }
    

end
