love.graphics.setLineStyle("rough")
love.graphics.setLineWidth(2)
math.randomseed(os.time())
local random,floor = math.random,math.floor
local minim=love.graphics.newFont("minimal.ttf",18)
local smol_font=love.graphics.newFont("EBGaramond.ttf", 18)
local font=love.graphics.newFont("EBGaramond.ttf", 22)
local Font=love.graphics.newFont("EBGaramond.ttf", 28)
local FONT=love.graphics.newFont("EBGaramond.ttf", 36)

local colours={{1,0,0},{0,0,1},{0,1,0},{0,0.9,1},{1,0.7,0.5},{1,0,1}}
colours[0] = {0,0,0}

local secs=0
local mins=0
local hrs =0

local x,y=5,5
local rows,cols=5,5
local wins={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local partwins_1={{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}}
local partwins_2={{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}}
local goals={"","","","","","","","","","","","","","","","","","","","","","","","",""}
local goals2={"","","","","","","","","","","","","","","","","","","","","","","","",""}
local player=1
local playerCount=2
local score={0,0,0,0,0,0}
score[0]=0
local timer=false

local resetConfirm = false
local rerollConfirm = false
local quitConfirm = false
local typingGoalsFile = false

local typingGoalsFile2 = false

local goals_W = 160
local goals_H = 160
local typing_Y = 220
local typing_Y2 = typing_Y+50
local connect_Y = typing_Y2+253
local reroll_Y = typing_Y2+56
local reset_Y = typing_Y2+145
local quit_Y = typing_Y+508

local error = ""

local function round(x,n)
    if not n then n=0 end
    x=x*10^n
    x=1+floor(x-0.5)
    return x/10^n
end

local function DIV(x,y) return floor(x/y) end
local function mod(x,y) mo=round((x/y-DIV(x,y))*y,0) if mo==0 then return y end return mo end


local enet = require "enet"
local json = require "json"

local server = nil
local connectedClients = {}

local function processLine(line)
    -- Strip surrounding CSV quotes if present
    if line:sub(1, 1) == '"' and line:sub(-1, -1) == '"' then
        line = line:sub(2, -2)
    end
    -- Unescape double quotes ("" becomes ")
    line = line:gsub('""', '"')

    if line ~= "" then return line end
end


local function loadFileToAllGoals(filename)
    filename = filename..".csv"
    local list = {}
    if love.filesystem.isFused() then
        local filepath = love.filesystem.getSourceBaseDirectory().."/"..filename
        for line in io.lines(filepath) do
            local goal = processLine(line)
            if goal then table.insert(list,goal) end
        end
    else
        for line in love.filesystem.lines(filename) do
            local goal = processLine(line)
            if goal then table.insert(list,goal) end
        end
    end
    return list
end

local fileStatus = ""
local goalsFile = ""
local fileSuccess, allGoals
local numGoals
local textTime
local inputFile = ""

local fileStatus2 = ""
local goalsFile2 = ""
local fileSuccess2, allGoals2
local numGoals2
local textTime2
local inputFile2 = ""

local function getFile(file,num)
    if num == 1 then
        fileSuccess, allGoals = pcall(loadFileToAllGoals, file)
        if fileSuccess then
            numGoals = #allGoals
        else
            love.window.showMessageBox("File not found","'"..file.."' not found. Select a csv file from the folder BINGO such as SilksongAll and type the name without .csv","error")
        end
    elseif num == 2 then
        fileSuccess2, allGoals2 = pcall(loadFileToAllGoals, file)
        if fileSuccess2 then
            numGoals2 = #allGoals2
        else
            love.window.showMessageBox("File not found","'"..file.."' not found. Select a csv file from the folder BINGO such as SilksongAll and type the name without .csv","error")
        end
    end
end 

--extracting range goals into a value
local function extractRange(input)
    for i=1,x*y do
        local str = input[i]

        -- Find the minimum and maximum numbers
        local minStr, maxStr = string.match(str, "_range_%s+(%d+)%-(%d+)")

        if minStr and maxStr then
            -- Convert strings to numbers and roll
            local min = tonumber(minStr)
            local max = tonumber(maxStr)
            local rolledValue = random(min, max)
            
            -- 2. The Replace Pattern (no parentheses needed, we just want to highlight what to delete)
            
            -- Replace "*range* X-Y" with just the rolled number
            local newStr = string.gsub(str, "_range_%s+%d+%-%d+", rolledValue)
            input[i]=newStr
        end
    end
    return input
end


local function reset()
    wins={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    partwins_1={{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}}
    partwins_2={{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}}
    score={0,0,0,0,0,0}
    score[0]=0
    secs,mins,hrs=0,0,0
    if server then
        server:broadcast("Reset")
        server:broadcast("Prepare for goals")
        server:broadcast(json.encode({goals,goals2}))
    end
end

local function rerollGoals(all)
    local goalEntry = 0
    local outgoals = {}
    while goalEntry<x*y do
        local trialGoal = all[random(#all)]
        local good=true
        for j=1,#outgoals do
            if trialGoal==outgoals[j] then
                good=false
                break
            end
        end
        if good then 
            goalEntry=goalEntry+1
            outgoals[goalEntry]=trialGoal 
        end
    end
    outgoals = extractRange(outgoals)
    reset()
    return outgoals
end


--Server side listening to client events
local function ServerListen()
    if server then 
        local event = server:service()
        while event do
            if event.type == "connect" then
                connectedClients[event.peer]=tostring(event.peer):match("(%d+%.%d+):")
                event.peer:timeout(0,1000,3000)
                server:broadcast("Rows: "..rows)
                server:broadcast("Cols: "..cols)
                reset()
            elseif event.type == "disconnect" then
                connectedClients[event.peer]=nil
            elseif event.type == "receive" then
                local datagoal, datapart, dataplayer = string.match(event.data, "^ChangeGoal: (%d+),(%d+),(%d+)")
                if datagoal and datapart and dataplayer then
                    datagoal, datapart, dataplayer = tonumber(datagoal), tonumber(datapart), tonumber(dataplayer)
                    server:broadcast("ChangeGoal: "..datagoal..","..datapart..","..dataplayer)
                    if datapart==1 then
                        if dataplayer ~=0 then
                            partwins_1[datagoal][dataplayer] = true
                            if partwins_2[datagoal][dataplayer] then
                                score[wins[datagoal]]=score[wins[datagoal]]-1
                                wins[datagoal] = dataplayer
                                score[dataplayer]=score[dataplayer]+1
                            end
                        else
                            partwins_1[datagoal][dataplayer] = false
                            if partwins_2[i][player] then
                                score[wins[datagoal]]=score[wins[datagoal]]-1
                                wins[datagoal] = 0
                            end
                        end
                    elseif datapart==2 then
                        if dataplayer ~=0 then
                            partwins_2[datagoal][dataplayer] = true
                            if partwins_1[datagoal][dataplayer] then
                                score[wins[datagoal]]=score[wins[datagoal]]-1
                                wins[datagoal] = dataplayer
                                score[dataplayer]=score[dataplayer]+1
                            end
                        else
                            partwins_2[datagoal][dataplayer] = false
                            if partwins_1[i][player] then
                                score[wins[datagoal]]=score[wins[datagoal]]-1
                                wins[datagoal] = 0
                            end
                        end
                    end
                end
                if event.data == "ToggleTimer" then 
                    timer = not timer
                    server:broadcast("ToggleTimer")
                    server:broadcast("CurrentTime: "..tostring(hrs)..","..tostring(mins)..","..tostring(secs))
                end
            end
            event = server:service()
        end
    end
end


--Updates timer and listens to client events
function love.update(dt)
    if timer then
        secs = secs + dt
        if secs>=60 then
            mins = mins+1
            secs=secs-60
            if mins>=60 then
                hrs=hrs+1
                mins=mins-60
            end
            if server then
                server:broadcast("CurrentTime: "..tostring(hrs)..","..tostring(mins)..","..tostring(secs))
            end
        end
    end
    if textTime then
        textTime = textTime + dt
    end
    if textTime2 then
        textTime2 = textTime2 + dt
    end
    ServerListen()
end

love.keyboard.setKeyRepeat(true)

function love.keypressed(key)
    --changing player with number keys 
    p=tonumber(key)
    if p then
        if p>0 and p<playerCount+1 then
            player=p
        end
    end
    if typingGoalsFile then
        if key == "backspace" then
            if inputFile ~= "" then
                inputFile = string.sub(inputFile,1,-2)
            end
        elseif key == "return" then
            goalsFile = inputFile
            typingGoalsFile = false
            inputFile = ""
            getFile(goalsFile,1)
        end
    end
    if typingGoalsFile2 then
        if key == "backspace" then
            if inputFile2 ~= "" then
                inputFile2 = string.sub(inputFile2,1,-2)
            end
        elseif key == "return" then
            goalsFile2 = inputFile2
            typingGoalsFile2 = false
            inputFile2 = ""
            getFile(goalsFile2,2)
        end
    end
end

function love.textinput(key)
    if typingGoalsFile then
        inputFile = inputFile..key
    end
    if typingGoalsFile2 then
        inputFile2 = inputFile2..key
    end
end

--MOUSE

function love.mousepressed(X,Y,butt)
    if timer then
        if X<goals_W*5 then
            if X<cols*goals_W and Y<rows*goals_H then
                i=floor(X/goals_W)+floor(Y/goals_H)*x+1
                if Y%goals_H < goals_H/2 then
                    if butt == 1 then
                        partwins_1[i][player] = true
                        if server then
                            server:broadcast("ChangeGoal: "..i..",1,"..player)
                        end
                        if partwins_2[i][player] then
                            score[wins[i]]=score[wins[i]]-1
                            wins[i] = player
                            score[player]=score[player]+1
                        end
                    elseif butt==2 then
                        partwins_1[i][player] = false
                        if partwins_2[i][player] then
                            score[wins[i]] = score[wins[i]]-1
                            wins[i] = 0
                        end
                        if server then
                            server:broadcast("ChangeGoal: "..i..",1,0")
                        end
                    end
                else
                    if butt == 1 then
                        partwins_2[i][player] = true
                        if server then
                            server:broadcast("ChangeGoal: "..i..",2,"..player)
                        end
                        if partwins_1[i][player] then
                            score[wins[i]]=score[wins[i]]-1
                            wins[i] = player
                            score[player]=score[player]+1
                        end
                    elseif butt==2 then
                        partwins_2[i][player] = false
                        if partwins_1[i][player] then
                            score[wins[i]] = score[wins[i]]-1
                            wins[i] = 0
                        end
                        if server then
                            server:broadcast("ChangeGoal: "..i..",2,0")
                        end
                    end
                end

            end
        end
    else
        if X>1000 and X<=1200 then
            X=X-1000
            if X>15 and X<185 and Y>typing_Y and Y<typing_Y+33 then
                typingGoalsFile = true
                textTime = 0
                fileSuccess = false
            else
                typingGoalsFile = false
            end
            if X>15 and X<185 and Y>typing_Y2 and Y<typing_Y2+33 then
                typingGoalsFile2 = true
                textTime2 = 0
                fileSuccess2 = false
            else
                typingGoalsFile2 = false
            end
            if Y>40 and Y<100 then
                rows = floor(X/66.67)+3
                if server then
                    server:broadcast("Rows: "..rows)
                end
            elseif Y>100 and Y<160 then
                cols = floor(X/66.67)+3
                if server then
                    server:broadcast("Cols: "..cols)
                end
            elseif X>28 and X<172 and Y>connect_Y and Y<connect_Y+50 then
                if not server then
                    server = enet.host_create("*:12003")
                else 
                    for peer,_ in pairs(connectedClients) do
                        peer:disconnect()
                    end
                    server:broadcast("ServerShutdown")
                    server:flush()
                    server:destroy()
                    server = nil
                    connectedClients = {}
                end
            end
            if not rerollConfirm then
                if X>42 and X<158 and Y>reroll_Y and Y<reroll_Y+70 and fileSuccess then 
                    rerollConfirm=true
                end
            else
                if Y>reroll_Y+4 and Y<reroll_Y+54 then
                    if X>22 and X<92 then
                        goals = rerollGoals(allGoals)
                        goals2 =rerollGoals(allGoals2)
                        rerollConfirm = false
                    elseif X>108 and X<178 then
                        rerollConfirm = false
                    end
                end
            end
            if not resetConfirm then
                if X>42 and X<158 and Y>reset_Y and Y<reset_Y+48 then
                    resetConfirm = true
                end
            else
                if Y>reset_Y and Y<reset_Y+48 then
                    if X>22 and X<92 then
                        reset()
                        resetConfirm = false
                    elseif X>108 and X<178 then
                        resetConfirm = false
                    end
                end
            end
            if X>33 and X<167 and Y>quit_Y and Y<quit_Y+48 then
                quitConfirm=true
            end
        end
        if quitConfirm then
            if Y>350 and Y<410 then
                if X>480 and X<580 then
                    quitConfirm = false
                    love.event.quit()
                elseif X>620 and X<720 then
                    quitConfirm = false
                end
            end
        end
    end

    if X>800 and X<1000 then
        X=X-800
        if Y>40 then
            if Y<160 then
                Y=Y-40
                playerCount = 1+floor(X/66.67)+3*floor(Y/60)
                if server then 
                    server:broadcast("PlayerCount: ".. playerCount)
                end
            elseif X>22 and X<178 and Y>728 and Y<776 then
                if butt == 1 then
                    timer = not timer
                    if server then
                        server:broadcast("ToggleTimer")
                    end
                elseif butt==2 and not timer then
                    hrs,mins,secs=0,0,0
                    if server then
                        server:broadcast("CurrentTime: "..tostring(hrs)..","..tostring(mins)..","..tostring(secs))
                    end
                end
            elseif X>60 and X<140 and Y>200 and Y<700 then
                for n=1,playerCount do
                    if Y>120+80*n and Y<170+80*n then
                        player=n
                    end
                end
            end
        end
    end
end




function love.draw()
    for i=1,x do
        for j=1,y do
            local win_c=colours[wins[(i-1)*5+j]]
            if i<=cols and j<=rows then
                if wins[(i-1)*5+j] ~= 0 then
                    love.graphics.setColor(win_c[1],win_c[2],win_c[3],0.4)
                    love.graphics.rectangle("fill",goals_W*(j-1),goals_H*(i-1),goals_W,goals_H)
                else
                    local numpwins1 = 0
                    print(partwins_1[(i-1)*5+j])
                    for _,w in ipairs(partwins_1[(i-1)*5+j]) do
                        if w then
                            numpwins1 = numpwins1 + 1
                        end
                    end
                    local m = 0
                    for k,w in ipairs(partwins_1[(i-1)*5+j]) do
                        if w then
                            local pwin_c=colours[k]
                            love.graphics.setColor(pwin_c[1],pwin_c[2],pwin_c[3],0.3)
                            love.graphics.rectangle("fill",goals_W*(j-1+m/numpwins1),goals_H*(i-1),goals_W/numpwins1,goals_H/2)
                            m = m+1
                        end
                    end
                    local numpwins2 = 0
                    for _,w in ipairs(partwins_2[(i-1)*5+j]) do
                        if w then
                            numpwins2 = numpwins2 + 1
                        end
                    end
                    m = 0
                    for k,w in ipairs(partwins_2[(i-1)*5+j]) do
                        if w then
                            local pwin_c=colours[k]
                            love.graphics.setColor(pwin_c[1],pwin_c[2],pwin_c[3],0.3)
                            love.graphics.rectangle("fill",goals_W*(j-1 + m/numpwins2),goals_H*(i-0.5),goals_W/numpwins2,goals_H/2)
                            m = m+1
                        end
                    end
                end

                love.graphics.setColor(1,1,1,1)
                love.graphics.printf(goals[(i-1)*5+j],smol_font,goals_W*(j-1)+4,goals_H*(i-1)+4,152,"center")
                love.graphics.printf(goals2[(i-1)*5+j],smol_font,goals_W*(j-1)+4,goals_H*(i-0.5)+4,152,"center")
                love.graphics.setColor(0.3,0.3,0.3,1)
                love.graphics.line(goals_W*(j-1), goals_H*(i-0.5), goals_W*(j), goals_H*(i-0.5))
            else 
                love.graphics.setColor(0.15,0.15,0.15,0.4)                
                love.graphics.rectangle("fill",goals_W*(j-1),goals_H*(i-1),goals_W,goals_H)
            end
        end
    end

    love.graphics.setColor(0.6,0.6,0.6,1)
    for i=1,y-1 do
        love.graphics.line(0,goals_H*(i),goals_W*5,goals_H*(i))
    end
    for i=1,x do
        love.graphics.line(goals_W*(i)-1,0,goals_W*(i)-1,goals_H*5)
    end

    love.graphics.line(1000,0,1000,800)

    love.graphics.setColor(1,1,1,1)
    love.graphics.print("Player Count:",font,835,5)
    for i=0,1 do
        for j=1,3 do
            love.graphics.setColor(0.15,0.15,0.15,1)
            love.graphics.rectangle("line",800+(j-1)*65.67+1,60*i+40,65.67,60)
            love.graphics.setColor(1,1,1,1)
            love.graphics.printf(i*3+j,Font,800+(j-1)*65.67+26,60*i+49,40)
        end
    end
    love.graphics.setColor(0.8,0.8,0.8,1)
    love.graphics.rectangle("line",801+(mod(playerCount,3)-1)*66.67,60*DIV(playerCount-1,3)+41,64.67,58)

    for n=1,playerCount do
        local c=colours[n]
        love.graphics.setColor(c[1],c[2],c[3],0.4)
        love.graphics.rectangle("fill", 860, 120+80*n, 80, 50)
        if n== player then
            love.graphics.setColor(c[1],c[2],c[3],1)
            love.graphics.rectangle("line", 860, 120+80*n, 80, 50)
        end
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf(score[n],Font,860, 120+80*n+4,80,"center")
    end

    love.graphics.setColor(1,1,1,0.1)
    love.graphics.rectangle("fill",822,728,156,48)
    if timer then love.graphics.setColor(0.1,1,0.3,1) else love.graphics.setColor(0,0.5,1,1) end
    love.graphics.printf(hrs..":"..string.format("%02d", mins)..":"..string.format("%05.2f", secs),minim,831,741,140,"center")

    love.graphics.setColor(1,1,1,1)
    love.graphics.print("Board Dimensions:",font,1017,5)
    for i=1,3 do
        for j=0,1 do
            love.graphics.setColor(0.15,0.15,0.15,1)
            love.graphics.rectangle("line",1001+(i-1)*65.67+2,40+60*j,65.67,60)
            love.graphics.setColor(1,1,1,1)
            love.graphics.printf(i+2,Font,1003+(i-1)*64,49+60*j,66.67,"center")
        end
    end
    love.graphics.setColor(0.5,0.5,0.5,1)
    love.graphics.line(1000,100,1200,100)
    love.graphics.setColor(0.8,0.8,0.8,1)
    love.graphics.line(1090,90,1110,110)
    love.graphics.line(1090,110,1110,90)
    love.graphics.rectangle("line",1001+(rows-3)*65.67+1,41,63.67,58)
    love.graphics.rectangle("line",1001+(cols-3)*65.67+1,101,63.67,58)

    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("Current Goal lists: ",font,1020,typing_Y-36,160,"center")
    if not fileSuccess then
        love.graphics.setColor(0.8,0.8,0.8,1)
        love.graphics.rectangle("line",1015,typing_Y,170,33)
        love.graphics.setColor(1,1,1,1)
        if inputFile == "" and not typingGoalsFile then
            love.graphics.setColor(0.5,0.5,0.5,1)
            love.graphics.printf("Click to type",font,1020,typing_Y,175)
            love.graphics.setColor(1,1,1,1)
        else
            if textTime % 1 < 0.5 and typingGoalsFile then
                love.graphics.print(inputFile.."_",font,1020,typing_Y)
            else
                love.graphics.print(inputFile,font,1020,typing_Y)
            end
        end
    else
        love.graphics.setColor(0.3,1,0.7,1)
        love.graphics.printf(goalsFile,font,1012,typing_Y,175,"center")
    end
    if fileStatus then
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf(fileStatus,font,1020,typing_Y,175,"center")
    end

    if not fileSuccess2 then
        love.graphics.setColor(0.8,0.8,0.8,1)
        love.graphics.rectangle("line",1015,typing_Y2,170,33)
        love.graphics.setColor(1,1,1,1)
        if inputFile2 == "" and not typingGoalsFile2 then
            love.graphics.setColor(0.5,0.5,0.5,1)
            love.graphics.printf("Click to type",font,1020,typing_Y2,175)
            love.graphics.setColor(1,1,1,1)
        else
            if textTime2 % 1 < 0.5 and typingGoalsFile2 then
                love.graphics.print(inputFile2.."_",font,1020,typing_Y2)
            else
                love.graphics.print(inputFile2,font,1020,typing_Y2)
            end
        end
    else
        love.graphics.setColor(0.3,1,0.7,1)
        love.graphics.printf(goalsFile2,font,1012,typing_Y2,175,"center")
    end
    if fileStatus2 then
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf(fileStatus2,font,1020,typing_Y2,175,"center")
    end

    if not resetConfirm then
        love.graphics.setColor(0.2,0.2,0.6,0.4)
        love.graphics.rectangle("fill",1042,reset_Y,116,48)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("Reset",font,1050,reset_Y+8,100, "center")
    else
        love.graphics.setColor(0.2,0.8,0.4,0.4)
        love.graphics.rectangle("fill",1022,reset_Y,70,48)
        love.graphics.setColor(0.8,0.2,0.4,0.4)
        love.graphics.rectangle("fill",1108,reset_Y,70,48)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("Yes",Font,1022,reset_Y+4,70,"center")
        love.graphics.printf("No",Font,1108,reset_Y+4,70,"center")
    end

    if not rerollConfirm then
        if fileSuccess and fileSuccess2 then
            love.graphics.setColor(0.6,0.4,0.6,0.4)
            love.graphics.rectangle("fill",1042,reroll_Y,116,70)
            love.graphics.setColor(1,1,1,1)
            love.graphics.printf("Generate Goals",font,1050,reroll_Y+4,100, "center")
        else
            love.graphics.setColor(0.6,0.4,0.6,0.2)
            love.graphics.rectangle("fill",1042,reroll_Y,116,70)
            love.graphics.setColor(0.5,0.5,0.5,1)
            love.graphics.printf("Generate Goals",font,1050,reroll_Y+4,100, "center")
        end
        
    else 
        love.graphics.setColor(0.2,1,0.2,0.4)
        love.graphics.rectangle("fill",1022,reroll_Y+4,70,50)
        love.graphics.setColor(0.8,0.4,0.6,0.4)
        love.graphics.rectangle("fill",1108,reroll_Y+4,70,50)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("Yes",Font,1022,reroll_Y+8,70, "center")
        love.graphics.printf("No",Font,1108,reroll_Y+8,70, "center")
    end

    love.graphics.setColor(0.6,0.2,0.2,0.4)
    love.graphics.rectangle("fill",1033,quit_Y,134,48)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("Quit Bingo",font,1030,quit_Y+8,140, "center")

    if not server then
        love.graphics.setColor(0,0.4,0,1)
        love.graphics.rectangle("fill", 1028,connect_Y,144,50)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("Start Hosting", font,1030,connect_Y+10,140, "center")
    else
        love.graphics.setColor(0.4,0,0,1)
        love.graphics.rectangle("fill", 1028,connect_Y,144,50)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("Stop Hosting", font,1030,connect_Y+10,140, "center")
        love.graphics.print("Clients:", font, 1025,connect_Y+57)
        local c=0
        for peer,tag in pairs(connectedClients) do
            c=c+1
            love.graphics.print(tag, font,1025,connect_Y+57+23*c)
        end
    end


    if timer then
        love.graphics.setColor(0.2,0.2,0.2,0.6)
        love.graphics.rectangle("fill",1001,0,200,800)
    end

    if quitConfirm then
        love.graphics.setColor(0.25,0.1,0.1,0.9)
        love.graphics.rectangle("fill",0,0,1200,800)
        love.graphics.setColor(0.6,0,0,1)
        love.graphics.rectangle("fill", 480,350,100,60)
        love.graphics.setColor(0,0.6,0,1)
        love.graphics.rectangle("fill", 620,350,100,60)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("QUIT BINGO?!?",FONT,450,280,300, "center")
        love.graphics.printf("YES",Font,480,360,100, "center")
        love.graphics.printf("NO",Font,620,360,100, "center")
    end

    love.graphics.setColor(0.7,0.7,0.7,1)
    love.graphics.rectangle("line",1,1,1198,798)
end