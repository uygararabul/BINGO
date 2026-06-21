love.graphics.setLineStyle("rough")
love.graphics.setLineWidth(2)
math.randomseed(os.time())
local random,floor = math.random,math.floor
local minim=love.graphics.newFont("minimal.ttf",18)
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
local player=1
local playerCount=2
local score={0,0,0,0,0,0}
score[0]=0
local timer=false

local rerollConfirm = false
local quitConfirm = false

local error = ""

local function round(x,n)
    if not n then n=0 end
    x=x*10^n
    x=1+floor(x-0.5)
    return x/10^n
end

local function DIV(x,y) return floor(x/y) end

local function mod(x,y) mo=round((x/y-DIV(x,y))*y,0) if mo==0 then return y end return mo end



for i=1,x*y do
    table.insert(wins,0)
end

local function loadFileToString(filename)
    local file, err = io.open(filename, "r")
    if not file then
        error("Failed to open file '" .. filename .. "'. Error: " .. tostring(err))
    end
    local content = file:read("*a")
    file:close()
    return content
end

local function csvTo1DTable(csv_string)
    local list = {}
    for line in csv_string:gmatch("[^\r\n]+") do
        -- Strip surrounding CSV quotes if present
        if line:sub(1, 1) == '"' and line:sub(-1, -1) == '"' then
            line = line:sub(2, -2)
        end
        -- Unescape double quotes ("" becomes ")
        line = line:gsub('""', '"')
        -- Add to our 1D table
        if line ~= "" then
            table.insert(list, line)
        end
    end
    return list
end

local goalsFile = "SilksongAllGoals"
local target_file = "C:/Users/uygar/stuffs/love/BINGO/"..goalsFile..".csv"
local success, csv_raw_string = pcall(loadFileToString, target_file)
local allGoals = csvTo1DTable(csv_raw_string)
local numGoals = #allGoals

--extracting range goals into a value




local goals={}

while #goals<x*y do
    local trialGoal = allGoals[random(numGoals)]
    local good=true
    for i=1,#goals do
        if trialGoal==goals[i] then
            good=false
            break
        end
    end
    if good then table.insert(goals,trialGoal) end
end

local function extractRange()
    for i=1,x*y do
        local str = goals[i]

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
            goals[i]=newStr
        end
    end
end

extractRange() 

local function rerollGoals()
    local goalEntry = 0
    while goalEntry<x*y do
        local trialGoal = allGoals[random(numGoals)]
        local good=true
        for j=1,#goals do
            if trialGoal==goals[j] then
                good=false
                break
            end
        end
        if good then 
            goalEntry=goalEntry+1
            goals[goalEntry]=trialGoal 
        end
    end
    extractRange()
    wins={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    score={0,0,0,0,0,0}
    score[0]=0
    secs,mins,hrs=0,0,0
end

local enet = require "enet"
local connected = false
local recieved = "nothing"


enethost = enet.host_create("localhost:6750")
enetclient = enet.host_create()
clientpeer = enetclient:connect("localhost:6750")

local function ClientSend()
    enetclient:service(100)
    clientpeer:send("hi")
end

local function SenderListen()
    hostevent = enetclient:service(100)
    if hostevent then
        print("Server message detected type: "..hostevent.type)
        if hostevent.type == "connect" then
            connected = true
        end
        if hostevent.type == "recieve" then
            recieved = "Recieved message "..hostevent.data..hostevent.peer
        end
    end
end

function love.update(dt)
    if timer then
        secs = secs + dt
        if secs>60 then
            mins = mins+1
            secs=secs-60
            if mins>60 then
                hrs=hrs+1
                mins=mins-60
            end
        end
    end
    ClientSend()
    SenderListen()
end


function love.keypressed(key)
    p=tonumber(key)
    if p then
        error=tostring(success)
        if p>0 and p<playerCount+1 then
            player=p
        end
    end
end


--MOUSE

function love.mousepressed(X,Y,butt)
    if timer then
        if X<800 then
            if X<cols*160 and Y<rows*160 then
                i=floor(X/160)+floor(Y/160)*x+1
                if butt == 1 then
                    if wins[i]~=player then
                        if wins[i]~=0 then
                            score[wins[i]]=score[wins[i]]-1
                        end
                        wins[i] = player
                        score[player]=score[player]+1
                    end
                elseif butt==2 then
                    score[wins[i]] = score[wins[i]]-1
                    wins[i] = 0
                end
            end
        end
    else
        if X>1000 and X<=1200 then
            X=X-1000
            if Y>40 and Y<100 then
                cols = floor(X/66.67)+3
                rows = floor(X/66.67)+3
            elseif Y>650 and Y<700 then
                rerollConfirm=true
            elseif Y>720 and Y<770 then
                quitConfirm=true
            end
        end
        if rerollConfirm then
            if Y>350 and Y<410 then
                if X>480 and X<580 then
                    rerollGoals()
                    rerollConfirm = false
                elseif X>620 and X<720 then
                    rerollConfirm = false
                end
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
            elseif Y>728 and Y<776 then
                if X>22 and X<178 then
                    timer = not timer
                end
            elseif Y>200 and Y<700 then
                if X>60 and X<140 then
                    for n=1,playerCount do
                        if Y>120+80*n and Y<170+80*n then
                            player=n
                        end
                    end
                end
            end
        end
    end
end




function love.draw()
    for i=1,x do
        for j=1,y do
            local c=colours[wins[(i-1)*5+j]]
            if i<=cols and j<=rows then
                love.graphics.setColor(c[1],c[2],c[3],0.4)
                love.graphics.rectangle("fill",160*(j-1),160*(i-1),160,160)
                love.graphics.setColor(1,1,1,1)
                love.graphics.printf(goals[(i-1)*5+j],font,160*(j-1)+4,160*(i-1)+4,147,"center")
                --love.graphics.printf(wins[(i-1)*5+j],font,160*(j-1)+3,160*(i-1),154,"left")
            else 
                love.graphics.setColor(0.15,0.15,0.15,0.4)
                love.graphics.rectangle("fill",160*(j-1),160*(i-1),160,160)
            end
        end
    end

    love.graphics.setColor(0.5,0.5,0.5,1)
    for i=1,y-1 do
        love.graphics.line(0,160*(i),800,160*(i))
    end
    for i=1,x do
        love.graphics.line(160*(i)-1,0,160*(i)-1,800)
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
    love.graphics.print("Board Size:",font,1050,5)
    for i=1,3 do
        love.graphics.setColor(0.15,0.15,0.15,1)
        love.graphics.rectangle("line",1001+(i-1)*65.67+2,40,65.67,60)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf((i+2).."x"..(i+2),Font,1000+(i-1)*66.67+16,49,40)
    end
    love.graphics.setColor(0.8,0.8,0.8,1)
    love.graphics.rectangle("line",1001+(rows-3)*65.67+1,41,63.67,58)
    
    love.graphics.printf("Current goal list: "..goalsFile,font,1020,140,160,"center")

    love.graphics.setColor(0.6,0.4,0.6,0.4)
    love.graphics.rectangle("fill",1030,650,140,50)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("Reroll Goals",font,1030,659,140, "center")

    love.graphics.setColor(0.6,0.2,0.2,0.4)
    love.graphics.rectangle("fill",1030,720,140,50)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("Quit Bingo",font,1030,729,140, "center")

    if timer then
        love.graphics.setColor(1,1,1,0.1)
        love.graphics.rectangle("fill",1001,0,200,800)
    end

    if rerollConfirm then
        love.graphics.setColor(0.2,0.1,0.2,0.9)
        love.graphics.rectangle("fill",0,0,1200,800)
        love.graphics.setColor(0.6,0,0,1)
        love.graphics.rectangle("fill", 480,350,100,60)
        love.graphics.setColor(0,0.6,0,1)
        love.graphics.rectangle("fill", 620,350,100,60)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("REROLL GOALS?",FONT,450,280,300, "center")
        love.graphics.printf("YES",Font,480,360,100, "center")
        love.graphics.printf("NO",Font,620,360,100, "center")
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

    love.graphics.printf(clientpeer:state(),100,300,200)
end