love.graphics.setLineStyle("rough")
love.graphics.setLineWidth(2)
math.randomseed(os.time())
local random,floor = math.random,math.floor
local minim=love.graphics.newFont("minimal.ttf",18)
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
local player=1
local playerCount=2
local score={0,0,0,0,0,0}
score[0]=0
local timer=false

local quitConfirm = false

local function round(x,n)
    if not n then n=0 end
    x=x*10^n
    x=1+floor(x-0.5)
    return x/10^n
end

local function DIV(x,y) return floor(x/y) end

local function mod(x,y) mo=round((x/y-DIV(x,y))*y,0) if mo==0 then return y end return mo end

local goals={"","","","","","","","","","","","","","","","","","","","","","","","",""}

local enet = require "enet"
local client = enet.host_create()
local status = ""

local function reset()
    secs, mins, hrs = 0,0,0
    wins={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    score={0,0,0,0,0,0}
    score[0]=0
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
    if peer then
        local event=client:service()
        while event do
            if event.type == "connect" then
                status = "Connected to server"
            elseif event.type == "disconnect" then
                peer=nil
                status="Server Offline"
            elseif event.type == "receive" then
                local datagoal, dataplayer = string.match(event.data, "^ChangeGoal: (%d+),(%d+)")
                if datagoal and dataplayer then
                    datagoal, dataplayer = tonumber(datagoal), tonumber(dataplayer)
                    score[wins[datagoal]] = score[wins[datagoal]] - 1
                    wins[datagoal] = dataplayer
                    score[dataplayer] = score[dataplayer] + 1
                end
                local datahrs, datamins, datasecs = string.match(event.data, "^CurrentTime: (%d+),(%d+),(%d+%.?%d*)")
                if datahrs and datamins and datasecs then
                    hrs, mins, secs = tonumber(datahrs), tonumber(datamins), tonumber(datasecs)
                end
                if event.data=="ToggleTimer" then
                    timer = not timer
                elseif event.data=="ServerShutdown" then
                    peer=nil
                    status="Server Offline"
                elseif event.data=="Prepare for goals" then
                    event = client:service()
                    goals = json.decode(event.data)
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


function love.keypressed(key)
    p=tonumber(key)
    if p then
        error=tostring(success)
        if p>0 and p<playerCount+1 then
            player=p
        end
    end
end

function love.mousepressed(X,Y,butt)
    if timer then
        if X<800 then
            if X<cols*160 and Y<rows*160 then
                i=floor(X/160)+floor(Y/160)*x+1
                if butt == 1 then
                    score[wins[i]]=score[wins[i]]-1
                    wins[i] = player
                    score[player]=score[player]+1
                    if peer then
                        peer:send("ChangeGoal: "..i..","..wins[i])
                    end
                elseif butt==2 then
                    score[wins[i]] = score[wins[i]]-1
                    wins[i] = 0
                    if peer then
                        peer:send("ChangeGoal: "..i..","..wins[i])
                    end
                end
            end
        end
    else
        if X>1000 and X<=1200 then
            X=X-1000
            if X>33 and X<167 and Y>728 and Y<776 then
                quitConfirm=true
            elseif X>28 and X<172 and Y>310 and Y<360 then
                if not peer then
                    client = enet.host_create()
                    peer = client:connect("192.168.1.85:12003")
                    peer:timeout(0, 1000, 3000)
                    status = "Enter Host IPv4: "
                else
                    peer:disconnect()
                    client:flush()
                    peer = nil
                    status="Disconnected"
                end
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
    
    love.graphics.printf("Current goal list: ".."[goalsFile]",font,1020,140,160,"center")

    love.graphics.setColor(0.6,0.2,0.2,0.4)
    love.graphics.rectangle("fill",1033,728,134,48)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("Quit Bingo",font,1030,736,140, "center")
    
    if not peer then
        love.graphics.setColor(0,0.4,0,1)
        love.graphics.rectangle("fill", 1028,310,144,50)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("Connect", font,1030,320,140, "center")
        if status=="Enter Host IPv4: " then
            love.graphics.setColor(1,1,1,1)
            love.graphics.rectangle("line",1015,360,170,25)
        end
    else
        love.graphics.setColor(0.4,0,0,1)
        love.graphics.rectangle("fill", 1028,310,144,50)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("Disconnect", font,1030,320,140, "center")
    end
    love.graphics.printf(status, font,1025,380,150, "center")

    if timer then
        love.graphics.setColor(1,1,1,0.1)
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