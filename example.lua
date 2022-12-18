--We create a trigger that shall print "Hello World", whenever Player 1 types "-a" into the chat.
do
    local function sayHello()
        print("Hello World")
    end

    local function createExampleTrigger()
        local trigger = CreateTrigger() --we don't even need a global trigger variable
        TriggerRegisterPlayerChatEvent(trigger, Player(0), "-a", false)
        TriggerAddAction(trigger, sayHello)
    end

    OnTrigInit(createExampleTrigger) --will execute "createExampleTrigger" during loading screen
end