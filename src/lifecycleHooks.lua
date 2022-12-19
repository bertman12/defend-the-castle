do
    OnInit.root(function()
        print "This is called immediately"
    end)
    OnInit.config(function()
        print "This is called during the map config process (in game lobby)"
    end)
    OnInit.main(function()
        print "This is called during the loading screen"
    end)
    OnInit(function()
        print "All udg_ variables have been initialized"
    end)
    OnInit.trig(function()
        print "All InitTrig_ functions have been called"
    end)
    OnInit.map(function()
        print "All Map Initialization events have run"
        Main()
    end)
    OnInit.final(function()
        print "The game has now started"
        IngameConsole.createTriggers()
        Economy.setup()
        Economy.welfare()
    end)
end



