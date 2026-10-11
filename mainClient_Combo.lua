love.graphics.setLineStyle("rough")
love.graphics.setLineWidth(2)
math.randomseed(os.time())
local random,floor = math.random,math.floor
local minim=love.graphics.newFont("minimal.ttf",18)
local smol_font=love.graphics.newFont("EBGaramond.ttf", 18)
local font=love.graphics.newFont("EBGaramond.ttf", 22)
local Font=love.graphics.newFont("EBGaramond.ttf", 28)
local FONT=love.graphics.newFont("EBGaramond.ttf", 36)
local json = require "json"
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
local player=1
local playerCount=2
local score={0,0,0,0,0,0}
score[0]=0
local IPaddress = ""
local inputIP = ""
local connecting = false
local timer=false
local quitConfirm = false

local goals_W = 160
local goals_H = 160

local function round(x,n)
    if not n then n=0 end
    x=x*10^n
    x=1+floor(x-0.5)
    return x/10^n
end

local function DIV(x,y) return floor(x/y) end

local function mod(x,y) mo=round((x/y-DIV(x,y))*y,0) if mo==0 then return y end return mo end

local goals={"","","","","","","","","","","","","","","","","","","","","","","","",""}
local goals2={"","","","","","","","","","","","","","","","","","","","","","","","",""}

local enet = require "enet"
local client = enet.host_create()
local status = ""
local textTime

local function reset()
    wins={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    partwins_1={{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}}
    partwins_2={{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}}
    score={0,0,0,0,0,0}
    score[0]=0
    secs,mins,hrs=0,0,0
end

local function connect()
    IPaddress = inputIP
    textTime = nil
    client = enet.host_create()
    local success, tryPeer = pcall(client.connect, client,IPaddress..":12003")
    if success then
        peer = tryPeer
        peer:timeout(0, 1000, 3000)
        connecting = true
    else
        status = "Invalid IP address"
    end
    typingIP = false
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
    if textTime then
        textTime = textTime + dt
    end
    if peer then
        local event=client:service()
        while event do
            if event.type == "connect" then
                status = "Connected to server"
                connecting = false
            elseif event.type == "disconnect" then
                peer=nil
                if connecting then
                    status="Couldn't connect to host"
                    connecting = false
                else
                    status="Server Offline"
                end
            elseif event.type == "receive" then
                local datagoal, datapart, dataplayer = string.match(event.data, "^ChangeGoal: (%d+),(%d+),(%d+)")
                if datagoal and datapart and dataplayer then
                    datagoal, datapart, dataplayer = tonumber(datagoal), tonumber(datapart), tonumber(dataplayer)
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
                local datahrs, datamins, datasecs = string.match(event.data, "^CurrentTime: (%d+),(%d+),(%d+%.?%d*)")
                if datahrs and datamins and datasecs then
                    hrs, mins, secs = tonumber(datahrs), tonumber(datamins), tonumber(datasecs)
                end
                local datarows = string.match(event.data, "^Rows: (%d+)")
                if datarows then 
                    rows = tonumber(datarows)
                end
                local datacols = string.match(event.data, "^Cols: (%d+)")
                if datacols then 
                    cols = tonumber(datacols)
                end
                if event.data=="ToggleTimer" then
                    timer = not timer
                elseif event.data=="ServerShutdown" then
                    peer=nil
                    status="Server Offline"
                elseif event.data=="Prepare for goals 1" then
                    event = client:service()
                    local decoded = json.decode(event.data)
                    goals = decoded[1]
                    goals2 = decoded[2]
                elseif event.data=="Reset" then
                    reset()
                end
                local dataPlayerCount = string.match(event.data, "^PlayerCount: (%d+)")
                if dataPlayerCount then
                    playerCount = tonumber(dataPlayerCount)
                end
            end
            event = client:service()
        end
    end
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
    if typingIP then
        if key == "backspace" then
            if inputIP ~= "" then
                inputIP = string.sub(inputIP,1,-2)
            end
        elseif key == "return" then
            connect()
        end
    end
end

function love.textinput(key)
    if typingIP then
        inputIP = inputIP..key
    end
end

--interactable visual buttons
function love.mousepressed(X,Y,butt)
    if timer then
        if X<goals_W*5 then
            if X<cols*goals_W and Y<rows*goals_H then
                i=floor(X/goals_W)+floor(Y/goals_H)*x+1
                if Y%goals_H < goals_H/2 then
                    if butt == 1 then
                        if peer then
                            peer:send("ChangeGoal: "..i..",1,"..player)
                        end
                    elseif butt==2 then
                        if peer then
                            peer:send("ChangeGoal: "..i..",1,0")
                        end
                    end
                else
                    if butt == 1 then
                        if peer then
                            peer:send("ChangeGoal: "..i..",2,"..player)
                        end
                    elseif butt==2 then
                        if peer then
                            peer:send("ChangeGoal: "..i..",2,0")
                        end
                    end
                end

            end
        end
    else
        if X>1000 and X<=1200 then
            X=X-1000
            if X>33 and X<167 and Y>728 and Y<776 then
                quitConfirm=true
            elseif X>28 and X<172 and Y>310 and Y<363 then
                if not peer then
                    status = "Enter Host IPv4: "  
                    if typingIP then
                        connect()
                    end                  
                else
                    peer:disconnect()
                    client:flush()
                    peer = nil
                    status="Disconnected"
                end
            end
            if X>15 and X<185 and Y>420 and Y<450 then
                typingIP = true
                textTime = 0
            end
        end
        if quitConfirm then
            if Y>350 and Y<410 then
                if X>480 and X<580 then
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
            if Y>728 and Y<776 and peer then
                if X>22 and X<178 then
                    peer:send("ToggleTimer")
                end
            elseif Y>200 and Y<700 and X>60 and X<140 then
                for n=1,playerCount do
                    if Y>120+80*n and Y<170+80*n then
                        player=n
                        break
                    end
                end
            end
        end
    end
end

function love.draw()
    --drawing the bingo board
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

    --separation lines
    love.graphics.setColor(0.5,0.5,0.5,1)
    for i=1,y-1 do
        love.graphics.line(0,160*(i),800,160*(i))
    end
    for i=1,x do
        love.graphics.line(160*(i)-1,0,160*(i)-1,800)
    end

    love.graphics.line(1000,0,1000,800)

    --list of players and scores and currently selected player
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

    --timer
    love.graphics.setColor(1,1,1,0.1)
    love.graphics.rectangle("fill",822,728,156,48)
    if timer then love.graphics.setColor(0.1,1,0.3,1) else love.graphics.setColor(0,0.5,1,1) end
    love.graphics.printf(hrs..":"..string.format("%02d", mins)..":"..string.format("%05.2f", secs),minim,831,741,140,"center")

    --quit button
    love.graphics.setColor(0.6,0.2,0.2,0.4)
    love.graphics.rectangle("fill",1033,728,134,48)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("Quit Bingo",font,1030,736,140, "center")
    
    --connect to host buttons
    if not peer then
        love.graphics.setColor(0,0.4,0,1)
        love.graphics.rectangle("fill", 1028,310,144,50)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("Connect", font,1030,320,140, "center")
    else
        love.graphics.setColor(0.4,0,0,1)
        love.graphics.rectangle("fill", 1028,310,144,50)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("Disconnect", font,1030,320,140, "center")
    end
    love.graphics.printf(status, font,1025,380,150, "center")
    if status=="Enter Host IPv4: " then
        love.graphics.setColor(1,1,1,1)
        love.graphics.rectangle("line",1015,420,170,33)
        if typingIP then
            if textTime % 1 < 0.5 then
                love.graphics.printf(inputIP,font,1020,420,175)
            else
                love.graphics.printf(inputIP.."_",font,1020,420,175)
            end
        else
            love.graphics.setColor(0.5,0.5,0.5,1)
            love.graphics.printf("Click to type",font,1020,420,175)
            love.graphics.setColor(1,1,1,1)
        end
        if connecting then
            love.graphics.printf("Connecting...",font,1015,450,175)
        end
    end

    --grey out sidebar when running
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