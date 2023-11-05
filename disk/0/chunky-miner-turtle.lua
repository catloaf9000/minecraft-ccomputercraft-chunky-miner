--- CONFIG ---
local minFuelLevel = 1500
local trash = {"cobblestone", "flint", "gravel", "dirt"}
--- END CONFIG ---

-- x, z, y - world coords, f - facing angle to south
local turtleCoords = {x = 0, y = 0, z = 0, f = 0}
local targetCoords1 = {x = 0, y = 0, z = 0}
local targetCoords2 = {x = 0, y = 0, z = 0}
local serverY

function GetTargetInfo()
    local modem = peripheral.wrap("right")
    modem.open(0)
    modem.transmit(0, 0, os.getComputerID())
    local timeout = os.startTimer(2)
    while true do
        local event,timer,_,_,message,_ = os.pullEvent()
        modem.close(0)
        if event == "modem_message" then
            return textutils.unserialize(message)
        elseif event == "timer" and timer == timeout then
            return nil
        end
    end
end

function Refuel()
    for slot = 1, 16 do
        turtle.select(slot)
        turtle.refuel(64)
    end
end

function ClearTrash()
    for slot = 1, 16 do
        turtle.select(slot)
        local data = turtle.getItemDetail()
        for j = 1, table.getn(trash) do
            if data then
                local res = string.find(data.name, trash[j])
                if res ~= nil then turtle.drop() end
            end
        end
    end
end

-- while mining, turtle will look at blocks above it and below
-- if in block name is substing 'ore' - turtle will mine it
function CheckOre()
    local success_up, data_up = turtle.inspectUp() -- if any block found up
    local success_down, data_down = turtle.inspectDown() -- if any block down
    if success_up then
        local res = string.find(data_up.name, "ore")
        if res ~= nil then
            turtle.digUp()
        end
    end
    if success_down then
        local res = string.find(data_down.name, "ore")
        if res ~= nil then
            turtle.digDown()
        end
    end
end

-- advanced functions to move turtle Forward/up/down: mines block on the way,
-- updates coordinates, does not allow to mine turtles, repeats until success

-- if something is on the way, this function is being called to check, 
-- if there is turtle on the way to prevent turtle 'friendlymining'
function InspectTurtle(side)
    local success, data = 0, 0
    if side == 0 then -- inspect block in front of turtle
        success, data = turtle.inspect()
    elseif side == 1 then
        success, data = turtle.inspectUp()
    elseif side == -1 then
        success, data = turtle.inspectDown()
    end
    if success then -- success means that there is block/turtle on the side
        local res = string.find(data.name, "turtle") -- gets block name from side
        if res == nil then -- if block_name contain "turtle"
            return false
        else                -- if block_name doesn't contain "turtle"
            return true
        end
    end
    return false -- there is no block on the side, free to mine/go
end

-- responsible for coordinates x or z update when moving forward
-- depending on facing, x or z can be incremented or decremented
function UpdateXZCoords(c_turtle)
    if c_turtle.f <= 90 then -- if current facing 0 or 90
        if c_turtle.f == 0 then
            c_turtle.z = c_turtle.z + 1
        else --then it's 90
            c_turtle.x = c_turtle.x - 1
        end
    else -- then current facing 180 or 270
        if c_turtle.f == 180 then
            c_turtle.z = c_turtle.z - 1
        else -- then it's 270
            c_turtle.x = c_turtle.x + 1
        end
    end
end

function Forward(blocks)
    for i = 1, blocks do
        local is_success = false
        repeat
            if turtle.forward() then -- trying to go Forward
                UpdateXZCoords(turtleCoords)
                is_success = true
            else -- turtle doesn't go Forward, trying to solve
                -- detecting if it's not an other turtle
                if InspectTurtle(0) then -- there is turtle on a way
                    os.sleep(1)
                else -- then it's a block, mine it
                    turtle.dig()
                end
            end
        until is_success == true -- retries go Forward until success
    end
end

function Up(blocks)
    for i = 1, blocks do
        local is_success = false
        repeat
            if turtle.up() then -- trying to go up
                turtleCoords.y = turtleCoords.y + 1
                is_success = true
            else -- turtle doesn't go up, trying to solve
                if InspectTurtle(1) then -- there is turtle on a way
                    os.sleep(1)
                else -- then it's a block, mine it
                    turtle.digUp()
                end
            end
        until is_success == true -- retries go up until success
    end
end

function Down(blocks)
    for i = 1, blocks do
        local is_success = false
        repeat
            if turtle.down() then -- trying to go down
                turtleCoords.y = turtleCoords.y - 1
                is_success = true
            else -- turtle doesn't go down, trying to solve
                if InspectTurtle(-1) then -- there is turtle on a way
                    os.sleep(1)
                else -- then it's a block, mine it
                    turtle.digDown()
                end
            end
        until is_success == true -- retries go down until success
    end
end

-- anvanced functions for turning, also calculates facing
function TurnRight()
    turtle.turnRight()
    turtleCoords.f = turtleCoords.f + 90
    if turtleCoords.f >= 360 then
        turtleCoords.f = 0
    end
end

function TurnLeft()
    turtle.turnLeft()
    turtleCoords.f = turtleCoords.f - 90
    if turtleCoords.f < 0 then
        turtleCoords.f = 270
    end
end

function TurnFacing(facing)
    if facing == nil then return end
    if turtleCoords.f == facing then
        return
    end
    repeat
        TurnRight()
    until turtleCoords.f == facing
end

-- turtle will move to new coordinates
function GoTo(newCoords)
    -- firstly turtle will allign x, then z, then y
    if newCoords.x > turtleCoords.x then
        TurnFacing(270)
        Forward(newCoords.x - turtleCoords.x)
    elseif newCoords.x < turtleCoords.x then
        TurnFacing(90)
        Forward(turtleCoords.x - newCoords.x)
    end
    if newCoords.z > turtleCoords.z then
        TurnFacing(0)
        Forward(newCoords.z - turtleCoords.z)
    elseif newCoords.z < turtleCoords.z then
        TurnFacing(180)
        Forward(turtleCoords.z - newCoords.z)
    end
    if newCoords.y > turtleCoords.y then
        Up(newCoords.y - turtleCoords.y)
    elseif newCoords.y < turtleCoords.y then
        Down(turtleCoords.y - newCoords.y)
    end
    TurnFacing(newCoords.f)
end

function MineChunk()
    TurnFacing(0)
    TurnLeft()
    for i = 1, 16 do
        for j = 1, 15 do
            CheckOre()
            Forward(1)
        end
        CheckOre()
        if i == 16 then break end
        if i % 2 ~= 0 then
            TurnRight()
            Forward(1)
            TurnRight()
        else
            TurnLeft()
            Forward(1)
            TurnLeft()
            Refuel()
            ClearTrash()
        end
    end
end

function Depot()
    TurnLeft()
    Forward(2)
    Up(1)
    for i = 1, 16 do
        for j = 1, 13 do
            Forward(1)
            if turtle.down() then
                error("No answer from the server")
            end
        end
        if i == 16 then break end
        if i % 2 ~= 0 then
            TurnRight()
            Forward(1)
            TurnRight()
        else
            TurnLeft()
            Forward(1)
            TurnLeft()
        end
    end
end

--- MAIN BODY ---
while true do
    print("Chunky miner turtle v.1.0")
    while turtle.getFuelLevel() < minFuelLevel do
        print("Low fuel level!")
        print("Min:" .. minFuelLevel .. " Now:" .. turtle.getFuelLevel())
        print("Trying to refuel...")
        Refuel()
    end
    print("Fuel level OK")
    print("Waiting for redstone signal to start...")
    while redstone.getInput("back") == false do
        sleep(1)
    end
    print("I've got redstone signal, let's go!")
    print("Requesting 1 mining chunk coords...")    
    local receivedTable = GetTargetInfo()
    if receivedTable == nil then
        print("Server is not repsonding.")
        Depot()
    else
        turtleCoords.y = receivedTable.serverY
        serverY = receivedTable.serverY
        targetCoords1.x = receivedTable.x * 16
        targetCoords1.z = receivedTable.z * 16
        targetCoords1.y = receivedTable.y
        print("turtleCoords.y:", turtleCoords.y)
        print("targetCoords1.x:", targetCoords1.x)
        print("targetCoords1.z:", targetCoords1.z)
        print("targetCoords1.y:", targetCoords1.y)
    end
    -- get second target coordinates
    print("Requesting 2 mining chunk coords...")    
    receivedTable = GetTargetInfo()
    if receivedTable == nil then
        targetCoords2 = nil
    else
        targetCoords2.x = receivedTable.x * 16
        targetCoords2.z = receivedTable.z * 16
        targetCoords2.y = receivedTable.y
        print("targetCoords2.x:", targetCoords2.x)
        print("targetCoords2.z:", targetCoords2.z)
        print("targetCoords2.y:", targetCoords2.y)
    end

    
    GoTo({x = turtleCoords.x, y = targetCoords1.y - 1, z = turtleCoords.z})
    GoTo(targetCoords1)
    MineChunk()
    if targetCoords2 ~= nil then
        ClearTrash()
        GoTo({x = turtleCoords.x, y = targetCoords2.y - 1, z = turtleCoords.z})
        GoTo(targetCoords2)
        MineChunk()
    end
    Up(1)
    GoTo({x = 0; y = turtleCoords.y, z = 2})
    GoTo({x = 0; y = serverY + 1 , z = 2})
    TurnFacing(90)
    ClearTrash()
    Refuel()
    TurnLeft()
    Forward(2)
    sleep(5) -- time to drop items to storage
    Up(1)
    TurnFacing(180)
    Forward(4)
    TurnFacing(0)
    Down(2)
end

--- END MAIN BODY ---