-----------------------
----| DEBUG UTILS |----
-----------------------

--> https://www.hiveworkshop.com/threads/lua-debug-utils-ingame-console-etc.330758/

------------------------------
----| Undeclared Globals |----
------------------------------

setmetatable(_G,{__index=function(_, n) print("Trying to read undeclared global : "..tostring(n)) end,}) --Shows a message ingame, when a non-declared global is used.

-------------------
----|   TRY   |----
-------------------

do
    local lastTrace, params

    ---Gets the current stack trace and logs it for later bug reports.
    ---This is only useful in conjunction with the try-function, which upon encountering an error will print the latest trace that was logged.
    ---@param oneline_yn? boolean default:false. Setting this to true will output the trace as a one-liner instead of including linebreaks. This can improve readability, especially when printing to console.
    ---@vararg any save any information, e.g. the parameters of the function call that you are logging.
    function LogStackTrace(oneline_yn, ...)
        lastTrace = GetStackTrace(oneline_yn)
        params = table.pack(...)
        if params.n == 0 then
            params = nil --prevents try from printing this, when nothing was provided
        else
            for i = 1,params.n do
                params[i] = tostring(params[i]) --allows to use table.concat on params later
            end
        end
    end

    ---Engulf a function in a try-block to catch and print errors.
    ---Example use: Assume you have a code line like "CreateUnit(0)", which doesn't work and you want to know why.
    ---* Option 1: Change it to "try(CreateUnit, 0)", i.e. separating the function from the parameters.
    ---* Option 2: Change it to "try(function() return CreateUnit(0) end)", i.e. pack it into an anonymous function. You can leave out the "return", if you don't need to forward the return value to the try function.
    ---* Option 3: Change it to "try('return CreateUnit(0)')", i.e. engulf the function call by string-marks and pass it to the try function as a string. Again, you can skip the 'return' keyword in case you don't need the return values. Pay attention that input variables are taken from global scope, if you do it this way.
    ---When no error occured, the try-function will return all values returned by the input function.
    ---When an error occurs, try will print the resulting error.
    ---@param input function | string
    function try(input, ...)
        local execFunc = (type(input) == 'function' and input) or load(input)
        local results = table.pack(pcall(execFunc, ...)) --second return value is either the error message or the actual return value of execFunc, depending on if it executed properly.
        if not results[1] then
            if lastTrace then print("|cffff5555" .. lastTrace .. "|r") end
            print("|cffff5555" .. results[2] .. "|r")
            if params then print("|cffff5555Params: " .. table.concat(params,"; ",1,params.n) .. "|r") end
        end
        return select(2, table.unpack(results, 1, results.n)) --if the function was executed properly, we return its return values
    end
end

--Overwrite TriggerAddAction native to let it automatically apply "try" to any actionFunc.
do
    local oldTriggerAddAction = TriggerAddAction
    TriggerAddAction = function(whichTrigger, actionFunc)
        return oldTriggerAddAction(whichTrigger, function() try(actionFunc) end)
    end
end

----------------------------
----| deep table.print |----
----------------------------

---Returns a string showing all pairs included in the specified table up to the specified depth.  E.g. table.tostring( {"a", 5, {7}} ) will result in '{(1, a), (2, 5), (3, {(1, 7)})}'.
---For any non-table object x, this will return tostring(x).
---table.tostring is not multiplayer synced, so it's best used as a sole debug-utility.
---@param anyObject table | any
---@param depth? integer default: any depth. Defines, to which depth elements are made visible. Nil = unlimited (will cause stack overflow for recursive tables). 0 will not show elements (so we just return tostring(table)). 1 will show elements within the table. 2 will show elements within subtables within the table etc.
---@return string
function table.tostring(anyObject, depth)
    depth = depth or -1
    local result = tostring(anyObject)
    if depth ~= 0 and type(anyObject) == 'table' then
        local elementArray = {}
        for k,v in pairs(anyObject) do
            table.insert(elementArray, '(' .. tostring(k) .. ', ' .. table.tostring(v, depth -1) .. ')')
        end
        result = '{' .. table.concat(elementArray, ', ') .. '}'
    end
    return result
end

---Displays all pairs within the specified table up to the specified depth on screen. E.g. table.print( {"a", 5, {7}} ) will display '{(1, a), (2, 5), (3, {(1, 7)})}'.
---For any non-table object x, this will print tostring(x).
---@param anyObject any
---@param depth? integer default: any depth. Defines, to which depth elements are made visible. Nil = unlimited (will cause stack overflow for recursive tables). 0 will print tostring(table), i.e. not show any elements. 1 will show first-level elements within the table. 2 will show elements within subtables within the table etc.
function table.print(anyObject, depth)
    print(table.tostring(anyObject, depth))
end

-------------------
----| Wc3Type |----
-------------------

---Returns the type of a warcraft object as string, e.g. "location", when inputting a location.
---@param input any
---@return string
function Wc3Type(input)
    local typeString = type(input)
    if typeString == 'number' then
        return (math.type(input) =='float' and 'real') or 'integer'
    elseif typeString == 'userdata' then
        typeString = tostring(input) --toString returns the warcraft type plus a colon and some hashstuff.
        return string.sub(typeString, 1, (string.find(typeString, ":", nil, true) or 0) -1) --string.find returns nil, if the argument is not found, which would break string.sub. So we need or as coalesce.
    else
        return typeString
    end
end

-------------------------
----| GetStackTrace |----
-------------------------

---Returns the stack trace at the code position where this function is called.
---The returned string includes war3map.lua/blizzard.j.lua code positions of all functions from the stack trace in the order of execution (most recent call last). It does NOT include function names.
---Credits to: https://www.hiveworkshop.com/threads/getstacktrace.340841/
---@param oneline_yn? boolean default: false. Setting this to true will output the trace as a one-liner instead of including linebreaks. This can improve readability, especially when printing to console.
---@return string stracktrace
function GetStackTrace(oneline_yn)
    local trace, lastMsg, i, separator = "", "", 5, (oneline_yn and "; ") or "\n"
    local store = function(msg) lastMsg = msg:sub(1,-3) end --Passed to xpcall to handle the error message. Message is being saved to lastMsg for further use, excluding trailing space and colon.
    xpcall(error, store, "", 4) --starting at position 4 ensures that the functions "error", "xpcall" and "GetStackTrace" are not included in the trace.
    while lastMsg:sub(1,11) == "war3map.lua" or lastMsg:sub(1,14) == "blizzard.j.lua" do
        trace = separator .. lastMsg .. trace
        xpcall(error, store, "", i)
        i = i+1
    end
    return "Traceback (most recent call last)" .. trace
end

--[[

--------------------------
----| Ingame Console |----
--------------------------

/**********************************************
* Allows you to use the following ingame commands:
* "-exec <code>" to execute any code ingame.
* "-console" to start an ingame console interpreting any further chat input as code and showing both return values of function calls and error messages. Furthermore, the print function will print
*    directly to the console after it got started. You can still look up all print messages in the F12-log.
***********************
* -------------------
* |Using the console|
* -------------------
* Any (well, most) chat input by any player after starting the console is interpreted as code and directly executed. You can enter terms (like 4+5 or just any variable name), function calls (like print("bla"))
* and set-statements (like y = 5). If the code has any return values, all of them are printed to the console. Erraneous code will print an error message.
* Chat input starting with a hyphen is being ignored by the console, i.e. neither executed as code nor printed to the console. This allows you to still use other chat commands like "-exec" without prompting errors.
***********************
* ------------------
* |Multiline-Inputs|
* ------------------
* You can prevent a chat input from being immediately executed by preceeding it with the greater sign '>'. All lines entered this way are halted, until any line not starting with '>' is being entered.
* The first input without '>' will execute all halted lines (and itself) in one chunk.
* Example of a chat input (the console will add an additional '>' to every line):
* >function a(x)
* >return x
* end
***********************
* Note that multiline inputs don't accept pure term evaluations, e.g. the following input is not supported and will prompt an error, while the same lines would have worked as two single-line inputs:
* >x = 5
* x
***********************
* -------------------
* |Reserved Keywords|
* -------------------
* The following keywords have a reserved functionality, i.e. are direct commands for the console and will not be interpreted as code:
* - 'exit'          - will shut down the console
* - 'printtochat'   - will let the print function return to normal behaviour (i.e. print to the chat instead of the console).
* - 'printtoconsole'- will let the print function print to the console (which is default behaviour).
* - 'show'          - will show the console, after it was accidently hidden (you can accidently hide it by showing another multiboard, while the console functionality is still up and running).
* - 'help'          - will show a list of all reserved keywords along very short explanations.
* - 'clear'         - will clear all text from the console, except the word 'clear'
* - 'share'         - will share the players console with every other player, allowing others to read and write into it. Will force-close other players consoles, if they have one active.
* - 'autosize on'   - will enable automatic console resize depending on the longest string in the display. This is turned on by default.
* - 'autosize off'  - will disable automatic console resize and instead linebreak long strings into multiple lines.
* - 'textlang eng'  - lets the console use english Wc3 text language font size to compute linebreaks (look in your Blizzard launcher settings to find out)
* - 'textlang ger'  - lets the console use german Wc3 text language font size to compute linebreaks (look in your Blizzard launcher settings to find out)
*************************************************/
--]]

--1. Ingame Console

---@class IngameConsole
IngameConsole = {
    --Settings
        numRows = 20                    ---@type integer Number of Rows of the console (multiboard), excluding the title row. So putting 20 here will show 21 rows, first being the title row.
    ,   numCols = 2                     ---@type integer Number of Columns of the console (multiboard)
    ,   autosize = true                 ---@type boolean Defines, whether the width of the main Column automatically adjusts with the longest string in the display.
    ,   currentWidth = 0.5              ---@type real Current and starting Screen Share of the console main column.
    ,   mainColMinWidth = 0.3           ---@type real Minimum Screen share of the variable main console column.
    ,   mainColMaxWidth = 0.8           ---@type real Maximum Scren share of the variable main console column.
    ,   tsColumnWidth = 0.06            ---@type real Screen Share of the Timestamp Column
    ,   linebreakBuffer = 0.008         ---@type real Screen Share that is added to the multiboard text column to compensate for the small inaccuracy of the String Width function.
    ,   maxLinebreaks = 3               ---@type integer Defines the maximum amount of linebreaks, before the remaining output string will be cut and not further displayed.
    ,   printToConsole = true           ---@type boolean defines, if the print function should print to the console or to the chat
    ,   sharedConsole = false           ---@type boolean defines, if the console is displayed to each player at the same time (accepting all players input) or if all players much start their own console.
    ,   textLanguage = 'eng'            ---@type string text language of your Wc3 installation, which influences font size (look in the settings of your Blizzard launcher). Currently only supports 'eng' and 'ger'.
    ,   colors = {
            timestamp = "bbbbbb"        ---@type string Timestamp Color
        ,   singleLineInput = "ffffaa"  ---@type string Color to be applied to single line console inputs
        ,   multiLineInput = "ffcc55"   ---@type string Color to be applied to multi line console inputs
        ,   returnValue = "00ffff"      ---@type string Color applied to return values
        ,   error = "ff5555"            ---@type string Color to be applied to errors resulting of function calls
        ,   keywordInput = "ff00ff"     ---@type string Color to be applied to reserved keyword inputs (console reserved keywords)
        ,   info = "bbbbbb"             ---@type string Color to be applied to info messages from the console itself (for instance after creation or after printrestore)
        }                               ---@type table
    --Privates
    ,   player = nil                    ---@type player player for whom the console is being created
    ,   currentLine = 0                 ---@type integer Current Output Line of the console.
    ,   inputload = ''                  ---@type string Input Holder for multi-line-inputs
    ,   output = {}                     ---@type string[] Array of all output strings
    ,   outputTimestamps = {}           ---@type string[] Array of all output string timestamps
    ,   outputWidths = {}               ---@type real[] remembers all string widths to allow for multiboard resize
    ,   trigger = nil                   ---@type trigger trigger processing all inputs during console lifetime
    ,   multiboard = nil                ---@type multiboard
    ,   timer = nil                     ---@type timer gets started upon console creation to measure timestamps
    --Statics
    ,   keywords = {}                   ---@type table<string,function> saves functions to be executed for all reserved keywords
    ,   playerConsoles = {}             ---@type table<player,IngameConsole> Consoles currently being active. up to one per player.
    ,   originalPrint = print           ---@type function original print function to restore, after the console gets closed.
}
IngameConsole.__index = IngameConsole

------------------------
--| Console Creation |--
------------------------

---@param consolePlayer player player for whom the console is being created
---@return IngameConsole
function IngameConsole.create(consolePlayer)
    local new = {} ---@type IngameConsole
    setmetatable(new, IngameConsole)
    ---setup Object data
    new.player = consolePlayer
    new.output = {}
    new.outputTimestamps = {}
    new.outputWidths = {}
    --Timer
    new.timer = CreateTimer()
    TimerStart(new.timer, 3600., true, nil) --just to get TimeElapsed for printing Timestamps.
    --Trigger to be created after short delay, because otherwise it would fire on "-console" input immediately and lead to stack overflow.
    new:setupTrigger()
    --Multiboard
    new:setupMultiboard()
    --Share, if settings say so
    if IngameConsole.sharedConsole then
        new:makeShared() --we don't have to exit other players consoles, because we look for the setting directly in the class and there just logically can't be other active consoles.
    end
    --Welcome Message
    new:out('info', 0, false, "Console started. Any further chat input will be executed as code, except when beginning with \x22-\x22.")
    return new
end

function IngameConsole:setupMultiboard()
    self.multiboard = CreateMultiboard()
    MultiboardSetRowCount(self.multiboard, self.numRows + 1) --title row adds 1
    MultiboardSetColumnCount(self.multiboard, self.numCols)
    MultiboardSetTitleText(self.multiboard, "Console")
    local mbitem
    for col = 1, self.numCols do
        for row = 1, self.numRows + 1 do --Title row adds 1
            mbitem = MultiboardGetItem(self.multiboard, row -1, col -1)
            MultiboardSetItemStyle(mbitem, true, false)
            MultiboardSetItemValueColor(mbitem, 255, 255, 255, 255)    -- Colors get applied via text color code
            MultiboardSetItemWidth(mbitem, (col == 1 and self.tsColumnWidth) or self.currentWidth )
            MultiboardReleaseItem(mbitem)
        end
    end
    mbitem = MultiboardGetItem(self.multiboard, 0, 0)
    MultiboardSetItemValue(mbitem, "|cffffcc00Timestamp|r")
    MultiboardReleaseItem(mbitem)
    mbitem = MultiboardGetItem(self.multiboard, 0, 1)
    MultiboardSetItemValue(mbitem, "|cffffcc00Line|r")
    MultiboardReleaseItem(mbitem)
    self:showToOwners()
end

function IngameConsole:setupTrigger()
    self.trigger = CreateTrigger()
    TriggerRegisterPlayerChatEvent(self.trigger, self.player, "", false) --triggers on any input of self.player
    TriggerAddCondition(self.trigger, Condition(function() return string.sub(GetEventPlayerChatString(),1,1) ~= '-' end)) --console will not react to entered stuff starting with '-'. This still allows to use other chat orders like "-exec".
    TriggerAddAction(self.trigger, function() self:processInput(GetEventPlayerChatString()) end)
end

function IngameConsole:makeShared()
    local player
    for i = 0, GetBJMaxPlayers() -1 do
        player = Player(i)
        if (GetPlayerSlotState(player) == PLAYER_SLOT_STATE_PLAYING) and (IngameConsole.playerConsoles[player] ~= self) then --second condition ensures that the player chat event is not added twice for the same player.
            IngameConsole.playerConsoles[player] = self
            TriggerRegisterPlayerChatEvent(self.trigger, player, "", false) --triggers on any input
        end
    end
    self.sharedConsole = true
end

---------------------
--|      In       |--
---------------------

function IngameConsole:processInput(inputString)
    if IngameConsole.keywords[inputString] then --if the input string is a reserved keyword
        self:out('keywordInput', 1, false, inputString)
        IngameConsole.keywords[inputString](self) --then call the method with the same name. IngameConsole.keywords["exit"](self) is just self.keywords:exit().
        return
    end
    if string.sub(inputString, 1, 1) == '>' then --multiLineInput
        inputString = string.sub(inputString, 2, -1)
        self:out('multiLineInput',2, false, inputString)
        self.inputload = self.inputload .. inputString .. '\r' --carriage return
    else --singleLineInput OR last line of multiLineInput
        if self.inputload == '' then --singleLineInput
            self:out('singleLineInput', 1, false, inputString)
            self.inputload = self.inputload .. IngameConsole.preProcessInput(inputString, true) --adds return statement, if sensible
        else
            self:out('multiLineInput', 1, false, inputString) --end of multiline input gets only one '>'
            self.inputload = self.inputload .. IngameConsole.preProcessInput(inputString, false) --adds return statement, if sensible
        end
        local inputload = self.inputload
        self.inputload = '' --content of self.inputload written to local var. this allows us emptying it here and prevent it from keeping text even, when the pcall line below breaks (rare case, can for example be provoked with metatable.__tostring = {}).
        local loadfunc = load(inputload)
        local results = table.pack(pcall(loadfunc))
        --manually catch case, where the input did not define a proper Lua statement (i.e. loadfunc is nil)
        if loadfunc == nil then
            results[1], results[2] = false, "Input is not a valid Lua-statement"
        end
        --output error message (unsuccessful case) or return values (successful case)
        if not results[1] then --results[1] is the error status that pcall always returns. False stands for: error occured.
            self:out('error', 0, true, results[2]) -- second result of pcall is the error message in case an error occured
        elseif results.n > 1 then --Check, if there was at least one valid output argument. We check results.n instead of results[2], because we also get nil as a proper return value this way.
            self:out('returnValue', 0, true, select(2,table.unpack(results, 1, results.n)))
        end
    end
end

--Alter the input string, if necessary.
function IngameConsole.preProcessInput(inputString, singleLineInput)
    --Preceed the input with 'return ' to show term outputs in the console. A term t can be recognized by that "function() return t end" is a valid function, i.e. load('return ' .. t) is not nil.
    if singleLineInput and load("return " .. inputString) then --load(x) returns either a function or nil
        return "return " .. inputString
    end
    return inputString
end

----------------------
--|      Out       |--
----------------------


---@param colorTheme? string Decides about the color to be applied. Currently accepted: 'timestamp', 'singleLineInput', 'multiLineInput', 'result', nil. (nil leadsto no colorTheme, i.e. white color)
---@param numIndentations integer Number of greater signs '>' that shall preceed the output
---@param hideTimestamp boolean Set to false to hide the timestamp column and instead show a "->" symbol.
---@vararg any the things to be printed in the console.
---@return boolean hasPrintedEverything returns true, if everything could be printed. Returns false otherwise (can happen for very long strings).
function IngameConsole:out(colorTheme, numIndentations, hideTimestamp, ...)
    local outputs = table.pack(...) --we need the entry "n" to be able to for-loop and deal with nil values. Just writing {...} would force us to use ipairs (stops on first nil) or pairs(doesn't retain order and ignores nil).
    --Replace all outputs by their tostring instances
    for i = 1, outputs.n do
        outputs[i] = tostring(outputs[i])
    end
    local printOutput = table.concat(outputs, '    ')
    --add preceeding greater signs
    for i = 1, numIndentations do
        printOutput = '>' .. printOutput
    end
    --Print a space instead of the empty string. This allows the console to identify, if the string has already been fully printed (see while-loop below).
    if printOutput == '' then
        printOutput = ' '
    end
    --Compute Linebreaks.
    local linebreakWidth = ((self.autosize and self.mainColMaxWidth) or self.currentWidth )
    local numLinebreaks = 0
    local partialOutput = nil
    local maxPrintableCharPosition
    local printWidth
    while string.len(printOutput) > 0  and numLinebreaks <= self.maxLinebreaks do --break, if the input string has reached length 0 OR when the maximum number of linebreaks would be surpassed.
        --compute max printable substring (in one multiboard line)
        maxPrintableCharPosition, printWidth = IngameConsole.getLinebreakData(printOutput, linebreakWidth - self.linebreakBuffer, self.textLanguage)
        --adds timestamp to the first line of any output
        if numLinebreaks == 0 then
            partialOutput = printOutput:sub(1, numIndentations) .. ((IngameConsole.colors[colorTheme] and "|cff" .. IngameConsole.colors[colorTheme] .. printOutput:sub(numIndentations + 1, maxPrintableCharPosition) .. "|r") or printOutput:sub(numIndentations + 1, maxPrintableCharPosition)) --Colorize the output string, if a color theme was specified. IngameConsole.colors[colorTheme] can be nil.
            table.insert(self.outputTimestamps, "|cff" .. IngameConsole.colors['timestamp'] .. ((hideTimestamp and '            ->') or IngameConsole.formatTimerElapsed(TimerGetElapsed(self.timer))) .. "|r")
        else
            partialOutput = (IngameConsole.colors[colorTheme] and "|cff" .. IngameConsole.colors[colorTheme] .. printOutput:sub(1, maxPrintableCharPosition) .. "|r") or printOutput:sub(1, maxPrintableCharPosition) --Colorize the output string, if a color theme was specified. IngameConsole.colors[colorTheme] can be nil.
            table.insert(self.outputTimestamps, '            ..') --need a dummy entry in the timestamp list to make it line-progress with the normal output.
        end
        numLinebreaks = numLinebreaks + 1
        --writes output string and width to the console tables.
        table.insert(self.output, partialOutput)
        table.insert(self.outputWidths, printWidth + self.linebreakBuffer) --remember the Width of this printed string to adjust the multiboard size in case. 0.5 percent is added to avoid the case, where the multiboard width is too small by a tiny bit, thus not showing some string without spaces.
        --compute remaining string to print
        printOutput = string.sub(printOutput, maxPrintableCharPosition + 1, -1) --remaining string until the end. Returns empty string, if there is nothing left
    end
    self.currentLine = #self.output
    self:updateMultiboard()
    if string.len(printOutput) > 0 then
        self:out('info', 0, false, "The previous value could not be entirely printed, because the maximum number of linebreaks was exceeded.") --recursive call of this function, should be fine.
    end
    return string.len(printOutput) == 0 --printOutput is the empty string, if and only if everything has been printed
end

function IngameConsole:updateMultiboard()
    local startIndex = math.max(self.currentLine - self.numRows, 0) --to be added to loop counter to get to the index of output table to print
    local outputIndex = 0
    local maxWidth = 0.
    local mbitem
    for i = 1, self.numRows do --doesn't include title row (index 0)
        outputIndex = i + startIndex
        mbitem = MultiboardGetItem(self.multiboard, i, 0)
        MultiboardSetItemValue(mbitem, self.outputTimestamps[outputIndex] or '')
        MultiboardReleaseItem(mbitem)
        mbitem = MultiboardGetItem(self.multiboard, i, 1)
        MultiboardSetItemValue(mbitem, self.output[outputIndex] or '')
        MultiboardReleaseItem(mbitem)
        maxWidth = math.max(maxWidth, self.outputWidths[outputIndex] or 0.) --looping through non-defined widths, so need to coalesce with 0
    end
    --Adjust Multiboard Width, if necessary.
    maxWidth = math.min(math.max(maxWidth, self.mainColMinWidth), self.mainColMaxWidth)
    if self.autosize and self.currentWidth ~= maxWidth then
        self.currentWidth = maxWidth
        for i = 1, self.numRows +1 do
            mbitem = MultiboardGetItem(self.multiboard, i-1, 1)
            MultiboardSetItemWidth(mbitem, maxWidth)
            MultiboardReleaseItem(mbitem)
        end
        self:showToOwners() --reshow multiboard to update item widths on the frontend
    end
end

function IngameConsole:showToOwners()
    if self.sharedConsole or GetLocalPlayer() == self.player then
        MultiboardDisplay(self.multiboard, true)
        MultiboardMinimize(self.multiboard, false)
    end
end


function IngameConsole.numberToTwoDigitString(inputNumber)
    local result = tostring(math.floor(inputNumber))
    return (string.len(result) == 1 and '0'.. result) or result
end

function IngameConsole.formatTimerElapsed(elapsedInSeconds)
    return IngameConsole.numberToTwoDigitString(elapsedInSeconds // 60) .. ': ' .. IngameConsole.numberToTwoDigitString(math.fmod(elapsedInSeconds, 60.)) .. '. ' .. IngameConsole.numberToTwoDigitString(math.fmod(elapsedInSeconds, 1) * 100)
end

---Computes the max printable substring for a given string and a given linebreakWidth (regarding a single line of console).
---Returns both the substrings last char position and its total width in the multiboard.
---@param stringToPrint string the string supposed to be printed in the multiboard console.
---@param linebreakWidth real the maximum allowed width in one line of the console, before a string must linebreak
---@param textLanguage string 'ger' or 'eng'
---@return integer maxPrintableCharPosition, real printWidth
function IngameConsole.getLinebreakData(stringToPrint, linebreakWidth, textLanguage)
    local loopWidth = 0.
    local bytecodes = table.pack(string.byte(stringToPrint, 1, -1))
    for i = 1, bytecodes.n do
        loopWidth = loopWidth + string.charMultiboardWidth(bytecodes[i], textLanguage)
        if loopWidth > linebreakWidth then
            return i-1, loopWidth - string.charMultiboardWidth(bytecodes[i], textLanguage)
        end
    end
    return bytecodes.n, loopWidth
end

-------------------------
--| Reserved Keywords |--
-------------------------

function IngameConsole.keywords:exit()
    DestroyMultiboard(self.multiboard)
    DestroyTrigger(self.trigger)
    DestroyTimer(self.timer)
    IngameConsole.playerConsoles[self.player] = nil
    if table.isEmpty(IngameConsole.playerConsoles) then --set print function back to original, when no one has an active console left.
        print = IngameConsole.originalPrint
    end
end

function IngameConsole.keywords:printtochat()
    self.printToConsole = false
    self:out('info', 0, false, "The print function will print to the normal chat.")
end

function IngameConsole.keywords:printtoconsole()
    self.printToConsole = true
    self:out('info', 0, false, "The print function will print to the console.")
end

function IngameConsole.keywords:show()
    self:showToOwners() --might be necessary to do, if another multiboard has shown up and thereby hidden the console.
    self:out('info', 0, false, "Console is showing.")
end

function IngameConsole.keywords:help()
    self:out('info', 0, false, "The Console currently reserves the following keywords:")
    self:out('info', 0, false, "'exit' closes the console.")
    self:out('info', 0, false, "'printtochat' lets Wc3 print text to normal chat again.")
    self:out('info', 0, false, "'show' shows the console. Sensible to use, when displaced by another multiboard.")
    self:out('info', 0, false, "'help' shows the text you are currently reading.")
    self:out('info', 0, false, "'clear' clears all text from the console.")
    self:out('info', 0, false, "'share' allows other players to read and write into your console, but also force-closes their own consoles.")
    self:out('info', 0, false, "'autosize on' enables automatic console resize depending on the longest line in the display.")
    self:out('info', 0, false, "'autosize off' retains the current console size.")
    self:out('info', 0, false, "'textlang eng' will use english text installation font size to compute linebreaks (default).")
    self:out('info', 0, false, "'textlang ger' will use german text installation font size to compute linebreaks.")
    self:out('info', 0, false, "Preceeding a line with '>' prevents immediate execution, until a line not starting with '>' has been entered.")
end

function IngameConsole.keywords:clear()
    self.output = {}
    self.outputTimestamps = {}
    self.outputWidths = {}
    self.currentLine = 0
    self:out('keywordInput', 1, false, 'clear') --we print 'clear' again. The keyword was already printed by self:processInput, but cleared immediately after.
end

function IngameConsole.keywords:share()
    for _, console in pairs(IngameConsole.playerConsoles) do
        if console ~= self then
            IngameConsole.keywords['exit'](console) --share was triggered during console runtime, so there potentially are active consoles of others players that need to exit.
        end
    end
    self:makeShared()
    self:showToOwners() --showing it to the other players.
    self:out('info', 0,false, "The console of player " .. GetConvertedPlayerId(self.player) .. " is now shared with all players.")
end

IngameConsole.keywords["autosize on"] = function(self)
    self.autosize = true
    self:out('info', 0,false, "The console will now change size depending on its content.")
end

IngameConsole.keywords["autosize off"] = function(self)
    self.autosize = false
    self:out('info', 0,false, "The console will retain the width that it currently has.")
end

IngameConsole.keywords["textlang ger"] = function(self)
    self.textLanguage = 'ger'
    self:out('info', 0,false, "Linebreaks will now compute with respect to german text installation font size.")
end

IngameConsole.keywords["textlang eng"] = function(self)
    self.textLanguage = 'eng'
    self:out('info', 0,false, "Linebreaks will now compute with respect to english text installation font size.")
end

--------------------
--| Main Trigger |--
--------------------

do
    local function ExecCommand_Actions()
        print("Executing input.")
        local errorStatus, errorMessage = pcall(load(string.sub(GetEventPlayerChatString(),7,-1)))
        if not errorStatus then
            error(errorMessage)
        end
    end

    local function ExecCommand_Conditions()
        return string.sub(GetEventPlayerChatString(), 1, 6) == "-exec "
    end

    local function IngameConsole_Actions()
        --if the triggering player already has a console, show that console and stop executing further actions
        if IngameConsole.playerConsoles[GetTriggerPlayer()] then
            IngameConsole.playerConsoles[GetTriggerPlayer()]:showToOwners()
            return
        end
        --create Ingame Console object
        IngameConsole.playerConsoles[GetTriggerPlayer()] = IngameConsole.create(GetTriggerPlayer())
        --overwrite print function
        print = function(...)
            IngameConsole.originalPrint(...) --the new print function will also print "normally", but clear the text immediately after. This is to add the message to the F12-log.
            if IngameConsole.playerConsoles[GetLocalPlayer()] and IngameConsole.playerConsoles[GetLocalPlayer()].printToConsole then
                ClearTextMessages() --clear text messages for all players having an active console
            end
            for player, console in pairs(IngameConsole.playerConsoles) do
                if console.printToConsole and (player == console.player) then --player == console.player ensures that the console only prints once, even if the console was shared among all players
                    console:out(nil, 0, false, ...)
                end
            end
        end
    end

    function IngameConsole.createTriggers()
        --Exec
        local execTrigger = CreateTrigger()
        TriggerAddCondition(execTrigger, Condition(ExecCommand_Conditions))
        TriggerAddAction(execTrigger, ExecCommand_Actions)
        --Real Console
        local consoleTrigger = CreateTrigger()
        TriggerAddAction(consoleTrigger, IngameConsole_Actions)
        --Events
        for i = 0, GetBJMaxPlayers() -1 do
            TriggerRegisterPlayerChatEvent(execTrigger, Player(i), "-exec ", false)
            TriggerRegisterPlayerChatEvent(consoleTrigger, Player(i), "-console", true)
        end
    end
end


------------------------
----| String Width |----
------------------------

--[[
    offers functions to measure the width of a string (i.e. the space it takes on screen, not the number of chars). Wc3 font is not monospace, so the system below has protocolled every char width and simply sums up all chars in a string.
    output measures are:
    1. Multiboard-width (i.e. 1-based screen share used in Multiboards column functions)
    2. Line-width for screen prints
    every unknown char will be treated as having default width (see constants below)
--]]

do
    ----------------------------
    ----| String Width API |----
    ----------------------------

    local multiboardCharTable = {}                        ---@type table  -- saves the width in screen percent (on 1920 pixel width resolutions) that each char takes up, when displayed in a multiboard.
    local DEFAULT_MULTIBOARD_CHAR_WIDTH = 1. / 128.        ---@type real    -- used for unknown chars (where we didn't define a width in the char table)
    local MULTIBOARD_TO_PRINT_FACTOR = 1. / 36.            ---@type real    -- 36 is actually the lower border (longest width of a non-breaking string only consisting of the letter "i")

    ---Returns the width of a char in a multiboard, when inputting a char (string of length 1) and 0 otherwise.
    ---also returns 0 for non-recorded chars (like ` and ´ and ß and § and €)
    ---@param char string | integer integer bytecode representations of chars are also allowed, i.e. the results of string.byte().
    ---@param textlanguage string | nil 'ger' or 'eng' (default is 'eng'), depending on the text language in the Warcraft 3 installation settings.
    ---@return real
    function string.charMultiboardWidth(char, textlanguage)
        return multiboardCharTable[textlanguage or 'eng'][char] or DEFAULT_MULTIBOARD_CHAR_WIDTH
    end

    ---returns the width of a string in a multiboard (i.e. output is in screen percent)
    ---unknown chars will be measured with default width (see constants above)
    ---@param multichar string
    ---@param textlanguage string | nil 'ger' or 'eng' (default is 'eng'), depending on the text language in the Warcraft 3 installation settings.
    ---@return real
    function string.multiboardWidth(multichar, textlanguage)
        local chartable = table.pack(multichar:byte(1,-1)) --packs all bytecode char representations into a table
        local charWidth = 0.
        for i = 1, chartable.n do
            charWidth = charWidth + string.charMultiboardWidth(chartable[i], textlanguage)
        end
        return charWidth
    end

    ---The function should match the following criteria: If the value returned by this function is smaller than 1.0, than the string fits into a single line on screen.
    ---The opposite is not necessarily true (but should be true in the majority of cases): If the function returns bigger than 1.0, the string doesn't necessarily break.
    ---@param char string | integer integer bytecode representations of chars are also allowed, i.e. the results of string.byte().
    ---@param textlanguage string | nil 'ger' or 'eng' (default is 'eng'), depending on the text language in the Warcraft 3 installation settings.
    ---@return real
    function string.charPrintWidth(char, textlanguage)
        return string.charMultiboardWidth(char, textlanguage) * MULTIBOARD_TO_PRINT_FACTOR
    end

    ---The function should match the following criteria: If the value returned by this function is smaller than 1.0, than the string fits into a single line on screen.
    ---The opposite is not necessarily true (but should be true in the majority of cases): If the function returns bigger than 1.0, the string doesn't necessarily break.
    ---@param multichar string
    ---@param textlanguage string | nil 'ger' or 'eng' (default is 'eng'), depending on the text language in the Warcraft 3 installation settings.
    ---@return real
    function string.printWidth(multichar, textlanguage)
        return string.multiboardWidth(multichar, textlanguage) * MULTIBOARD_TO_PRINT_FACTOR
    end

    ----------------------------------
    ----| String Width Internals |----
    ----------------------------------

    ---@param char string
    ---@param lengthInScreenWidth real
    ---@return nothing
    local function setMultiboardCharWidth(charset, char, lengthInScreenWidth)
        multiboardCharTable[charset] = multiboardCharTable[charset] or {}
        multiboardCharTable[charset][char] = lengthInScreenWidth
    end

    ---numberPlacements says how often the char can be placed in a multiboard column, before reaching into the right bound.
    ---@param char string
    ---@param numberPlacements integer
    ---@return nothing
    local function setMultiboardCharWidthBase80(charset, char, numberPlacements)
        setMultiboardCharWidth(charset, char, 0.8 / numberPlacements) --1-based measure. 80./numberPlacements would result in Screen Percent.
        setMultiboardCharWidth(charset, string.byte(char), 0.8 / numberPlacements)
    end

    -- Set Char Width for all usual chars in screen width (1920 pixels). Measured on a 80percent screen width multiboard column by counting the number of chars that fit into it. I.e. actual width (in screen percent) is calculated by dividing this number by 80.
    setMultiboardCharWidthBase80('ger', "a", 144)
    setMultiboardCharWidthBase80('ger', "b", 144)
    setMultiboardCharWidthBase80('ger', "c", 144)
    setMultiboardCharWidthBase80('ger', "d", 131)
    setMultiboardCharWidthBase80('ger', "e", 144)
    setMultiboardCharWidthBase80('ger', "f", 240)
    setMultiboardCharWidthBase80('ger', "g", 120)
    setMultiboardCharWidthBase80('ger', "h", 144)
    setMultiboardCharWidthBase80('ger', "i", 360)
    setMultiboardCharWidthBase80('ger', "j", 288)
    setMultiboardCharWidthBase80('ger', "k", 144)
    setMultiboardCharWidthBase80('ger', "l", 360)
    setMultiboardCharWidthBase80('ger', "m", 90)
    setMultiboardCharWidthBase80('ger', "n", 144)
    setMultiboardCharWidthBase80('ger', "o", 131)
    setMultiboardCharWidthBase80('ger', "p", 131)
    setMultiboardCharWidthBase80('ger', "q", 131)
    setMultiboardCharWidthBase80('ger', "r", 206)
    setMultiboardCharWidthBase80('ger', "s", 180)
    setMultiboardCharWidthBase80('ger', "t", 206)
    setMultiboardCharWidthBase80('ger', "u", 144)
    setMultiboardCharWidthBase80('ger', "v", 131)
    setMultiboardCharWidthBase80('ger', "w", 96)
    setMultiboardCharWidthBase80('ger', "x", 144)
    setMultiboardCharWidthBase80('ger', "y", 131)
    setMultiboardCharWidthBase80('ger', "z", 144)
    setMultiboardCharWidthBase80('ger', "A", 103)
    setMultiboardCharWidthBase80('ger', "B", 131)
    setMultiboardCharWidthBase80('ger', "C", 120)
    setMultiboardCharWidthBase80('ger', "D", 111)
    setMultiboardCharWidthBase80('ger', "E", 144)
    setMultiboardCharWidthBase80('ger', "F", 180)
    setMultiboardCharWidthBase80('ger', "G", 103)
    setMultiboardCharWidthBase80('ger', "H", 103)
    setMultiboardCharWidthBase80('ger', "I", 288)
    setMultiboardCharWidthBase80('ger', "J", 240)
    setMultiboardCharWidthBase80('ger', "K", 120)
    setMultiboardCharWidthBase80('ger', "L", 144)
    setMultiboardCharWidthBase80('ger', "M", 80)
    setMultiboardCharWidthBase80('ger', "N", 103)
    setMultiboardCharWidthBase80('ger', "O", 96)
    setMultiboardCharWidthBase80('ger', "P", 144)
    setMultiboardCharWidthBase80('ger', "Q", 90)
    setMultiboardCharWidthBase80('ger', "R", 120)
    setMultiboardCharWidthBase80('ger', "S", 144)
    setMultiboardCharWidthBase80('ger', "T", 144)
    setMultiboardCharWidthBase80('ger', "U", 111)
    setMultiboardCharWidthBase80('ger', "V", 120)
    setMultiboardCharWidthBase80('ger', "W", 76)
    setMultiboardCharWidthBase80('ger', "X", 111)
    setMultiboardCharWidthBase80('ger', "Y", 120)
    setMultiboardCharWidthBase80('ger', "Z", 120)
    setMultiboardCharWidthBase80('ger', "1", 288)
    setMultiboardCharWidthBase80('ger', "2", 131)
    setMultiboardCharWidthBase80('ger', "3", 144)
    setMultiboardCharWidthBase80('ger', "4", 120)
    setMultiboardCharWidthBase80('ger', "5", 144)
    setMultiboardCharWidthBase80('ger', "6", 131)
    setMultiboardCharWidthBase80('ger', "7", 144)
    setMultiboardCharWidthBase80('ger', "8", 131)
    setMultiboardCharWidthBase80('ger', "9", 131)
    setMultiboardCharWidthBase80('ger', "0", 131)
    setMultiboardCharWidthBase80('ger', ":", 480)
    setMultiboardCharWidthBase80('ger', ";", 360)
    setMultiboardCharWidthBase80('ger', ".", 480)
    setMultiboardCharWidthBase80('ger', "#", 120)
    setMultiboardCharWidthBase80('ger', ",", 360)
    setMultiboardCharWidthBase80('ger', " ", 288) --space
    setMultiboardCharWidthBase80('ger', "'", 480)
    setMultiboardCharWidthBase80('ger', "!", 360)
    setMultiboardCharWidthBase80('ger', "$", 160)
    setMultiboardCharWidthBase80('ger', "&", 96)
    setMultiboardCharWidthBase80('ger', "/", 180)
    setMultiboardCharWidthBase80('ger', "(", 288)
    setMultiboardCharWidthBase80('ger', ")", 288)
    setMultiboardCharWidthBase80('ger', "=", 160)
    setMultiboardCharWidthBase80('ger', "?", 180)
    setMultiboardCharWidthBase80('ger', "^", 144)
    setMultiboardCharWidthBase80('ger', "<", 160)
    setMultiboardCharWidthBase80('ger', ">", 160)
    setMultiboardCharWidthBase80('ger', "-", 144)
    setMultiboardCharWidthBase80('ger', "+", 160)
    setMultiboardCharWidthBase80('ger', "*", 206)
    setMultiboardCharWidthBase80('ger', "|", 480) --2 vertical bars in a row escape to one. So you could print 960 ones in a line, 480 would display. Maybe need to adapt to this before calculating string width.
    setMultiboardCharWidthBase80('ger', "~", 144)
    setMultiboardCharWidthBase80('ger', "{", 240)
    setMultiboardCharWidthBase80('ger', "}", 240)
    setMultiboardCharWidthBase80('ger', "[", 240)
    setMultiboardCharWidthBase80('ger', "]", 288)
    setMultiboardCharWidthBase80('ger', "_", 144)
    setMultiboardCharWidthBase80('ger', "\x25", 111) --percent
    setMultiboardCharWidthBase80('ger', "\x5C", 206) --backslash
    setMultiboardCharWidthBase80('ger', "\x22", 240) --double quotation mark
    setMultiboardCharWidthBase80('ger', "\x40", 103) --at sign
    setMultiboardCharWidthBase80('ger', "\x60", 240) --Gravis (Accent)

    setMultiboardCharWidthBase80('eng', "a", 144)
    setMultiboardCharWidthBase80('eng', "b", 120)
    setMultiboardCharWidthBase80('eng', "c", 131)
    setMultiboardCharWidthBase80('eng', "d", 120)
    setMultiboardCharWidthBase80('eng', "e", 131)
    setMultiboardCharWidthBase80('eng', "f", 240)
    setMultiboardCharWidthBase80('eng', "g", 120)
    setMultiboardCharWidthBase80('eng', "h", 131)
    setMultiboardCharWidthBase80('eng', "i", 360)
    setMultiboardCharWidthBase80('eng', "j", 288)
    setMultiboardCharWidthBase80('eng', "k", 144)
    setMultiboardCharWidthBase80('eng', "l", 360)
    setMultiboardCharWidthBase80('eng', "m", 80)
    setMultiboardCharWidthBase80('eng', "n", 131)
    setMultiboardCharWidthBase80('eng', "o", 120)
    setMultiboardCharWidthBase80('eng', "p", 120)
    setMultiboardCharWidthBase80('eng', "q", 120)
    setMultiboardCharWidthBase80('eng', "r", 206)
    setMultiboardCharWidthBase80('eng', "s", 160)
    setMultiboardCharWidthBase80('eng', "t", 206)
    setMultiboardCharWidthBase80('eng', "u", 131)
    setMultiboardCharWidthBase80('eng', "v", 144)
    setMultiboardCharWidthBase80('eng', "w", 90)
    setMultiboardCharWidthBase80('eng', "x", 131)
    setMultiboardCharWidthBase80('eng', "y", 144)
    setMultiboardCharWidthBase80('eng', "z", 144)
    setMultiboardCharWidthBase80('eng', "A", 103)
    setMultiboardCharWidthBase80('eng', "B", 120)
    setMultiboardCharWidthBase80('eng', "C", 103)
    setMultiboardCharWidthBase80('eng', "D", 103)
    setMultiboardCharWidthBase80('eng', "E", 131)
    setMultiboardCharWidthBase80('eng', "F", 160)
    setMultiboardCharWidthBase80('eng', "G", 103)
    setMultiboardCharWidthBase80('eng', "H", 96)
    setMultiboardCharWidthBase80('eng', "I", 288)
    setMultiboardCharWidthBase80('eng', "J", 240)
    setMultiboardCharWidthBase80('eng', "K", 120)
    setMultiboardCharWidthBase80('eng', "L", 131)
    setMultiboardCharWidthBase80('eng', "M", 76)
    setMultiboardCharWidthBase80('eng', "N", 96)
    setMultiboardCharWidthBase80('eng', "O", 85)
    setMultiboardCharWidthBase80('eng', "P", 131)
    setMultiboardCharWidthBase80('eng', "Q", 85)
    setMultiboardCharWidthBase80('eng', "R", 120)
    setMultiboardCharWidthBase80('eng', "S", 131)
    setMultiboardCharWidthBase80('eng', "T", 144)
    setMultiboardCharWidthBase80('eng', "U", 103)
    setMultiboardCharWidthBase80('eng', "V", 120)
    setMultiboardCharWidthBase80('eng', "W", 76)
    setMultiboardCharWidthBase80('eng', "X", 111)
    setMultiboardCharWidthBase80('eng', "Y", 120)
    setMultiboardCharWidthBase80('eng', "Z", 111)
    setMultiboardCharWidthBase80('eng', "1", 206)
    setMultiboardCharWidthBase80('eng', "2", 131)
    setMultiboardCharWidthBase80('eng', "3", 131)
    setMultiboardCharWidthBase80('eng', "4", 111)
    setMultiboardCharWidthBase80('eng', "5", 131)
    setMultiboardCharWidthBase80('eng', "6", 120)
    setMultiboardCharWidthBase80('eng', "7", 131)
    setMultiboardCharWidthBase80('eng', "8", 111)
    setMultiboardCharWidthBase80('eng', "9", 120)
    setMultiboardCharWidthBase80('eng', "0", 111)
    setMultiboardCharWidthBase80('eng', ":", 360)
    setMultiboardCharWidthBase80('eng', ";", 360)
    setMultiboardCharWidthBase80('eng', ".", 360)
    setMultiboardCharWidthBase80('eng', "#", 103)
    setMultiboardCharWidthBase80('eng', ",", 360)
    setMultiboardCharWidthBase80('eng', " ", 288) --space
    setMultiboardCharWidthBase80('eng', "'", 480)
    setMultiboardCharWidthBase80('eng', "!", 360)
    setMultiboardCharWidthBase80('eng', "$", 131)
    setMultiboardCharWidthBase80('eng', "&", 120)
    setMultiboardCharWidthBase80('eng', "/", 180)
    setMultiboardCharWidthBase80('eng', "(", 240)
    setMultiboardCharWidthBase80('eng', ")", 240)
    setMultiboardCharWidthBase80('eng', "=", 111)
    setMultiboardCharWidthBase80('eng', "?", 180)
    setMultiboardCharWidthBase80('eng', "^", 144)
    setMultiboardCharWidthBase80('eng', "<", 131)
    setMultiboardCharWidthBase80('eng', ">", 131)
    setMultiboardCharWidthBase80('eng', "-", 180)
    setMultiboardCharWidthBase80('eng', "+", 111)
    setMultiboardCharWidthBase80('eng', "*", 180)
    setMultiboardCharWidthBase80('eng', "|", 480) --2 vertical bars in a row escape to one. So you could print 960 ones in a line, 480 would display. Maybe need to adapt to this before calculating string width.
    setMultiboardCharWidthBase80('eng', "~", 144)
    setMultiboardCharWidthBase80('eng', "{", 240)
    setMultiboardCharWidthBase80('eng', "}", 240)
    setMultiboardCharWidthBase80('eng', "[", 240)
    setMultiboardCharWidthBase80('eng', "]", 240)
    setMultiboardCharWidthBase80('eng', "_", 120)
    setMultiboardCharWidthBase80('eng', "\x25", 103) --percent
    setMultiboardCharWidthBase80('eng', "\x5C", 180) --backslash
    setMultiboardCharWidthBase80('eng', "\x22", 206) --double quotation mark
    setMultiboardCharWidthBase80('eng', "\x40", 96) --at sign
    setMultiboardCharWidthBase80('eng', "\x60", 206) --Gravis (Accent)
end