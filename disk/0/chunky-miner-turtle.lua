print("Chunky miner turtle v.1.0")
-- x and z - chunk coords, y - world coords, f - facing angle to south
local turtleCoords = {x = 0, y = 0, z = 0, f = 0}
local targetCoords = {x = 0, y = 0, z = 0}

function GetTargetInfo()
    local modem = peripheral.wrap("left")
    modem.open(0)
    modem.transmit(0, 0, os.getComputerID())
    local timeout = os.startTimer(2)
    while true do
        local event,timer,_,_,message,_ = os.pullEvent()
        if event == "modem_message" then
            return textutils.unserialize(message)
        elseif event == "timer" and timer == timeout then
            return nil
        end
    end
end

--- MAIN BODY ---
while true do
    print("Requesting mining chunk coords...")
    local receivedTable = GetTargetInfo()
    if receivedTable == nil then
        print("Server is not repsonding.")
        return
    else
        turtleCoords.y = receivedTable.serverY + 1
        targetCoords.x = receivedTable.x
        targetCoords.z = receivedTable.z
        targetCoords.y = receivedTable.y
    end
    print("turtleCoords.y:", turtleCoords.y)
    print("targetCoords.x:", targetCoords.x)
    print("targetCoords.z:", targetCoords.z)
    print("targetCoords.y:", targetCoords.y)
    read()
end

--- END MAIN BODY ---