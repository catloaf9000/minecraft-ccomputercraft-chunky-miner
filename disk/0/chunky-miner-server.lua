--- CONFIG ----
local logMode = true

--- END CONFIG ---
local miningDataPath = "/mining.data"
local isMiningDataExists = false

local serverY
local chunks
local minY
local maxY
-- iterable varialbes
local x
local z
local y

--- FUNCTIONS ---
function Log(message)
    if logMode then
        print(message)
    end
end

function Menu()
    Log("Check mining data if exists...")
    if fs.exists(miningDataPath) then
        isMiningDataExists = true
        Log("Found " .. miningDataPath)
      else
        isMiningDataExists = false
        Log("Not found " .. miningDataPath)
      end
    print("Chunky miner v.1.2")
    while true do
        print("Select option:")
        print("1 - New mining area")
        if isMiningDataExists then
            print("2 - Continue mining area")
        end
        print("0 - Exit")
        local a = tonumber(read())
        if a == 0 then error("Bye!") end
        if a == 1 and isMiningDataExists then
            print("Are you sure? This will erase existing mining data Y/[N]")
            a = read()
            if a == "Y" or a == "y" then
                Log("Setting up new mining area")
                Setup()
                break
            end
            if a == "N" or a == "n" then
                Log("New area canceled")
            end
        end
        if a == 1 and not isMiningDataExists then
            Log("Setting up new mining area")
            Setup()
            break
        end
        if a == 2 and isMiningDataExists then
            break
        end
        print("Unexpected input, try again.")
    end
    Log("Menu finished")
end

function Setup() 
    Log("Setup Menu")
    while true do
        print("Configuration")
        write("Server (this computer) Y coordinate [21; 251]: ")
        serverY = tonumber(read())
        print("Mining area (chunks):")
        print("1 - 1x1")
        print("2 - 3x3")
        print("3 - 5x5")
        print("4 - 7x7")
        print("5 - 9x9")
        print("6 - 11x11")
        print("7 - 13x13")
        print("8 - 15x15")
        print("Tip: don't select to big if your chunks distance is low")
        write("Select [1; 8]: ")
        chunks =  tonumber(read()) * 2 - 1
        write("Lowest mining Y [6; 230]: ")
        minY = tonumber(read())
        write("Highest mining Y [18; 248]: ")
        maxY = tonumber(read())        

        if not serverY or serverY < 21 or serverY > 251 then
            print("Incorrect server Y coordinate, try again.")
        elseif not chunks or chunks < 1 or chunks > 15 then
            print("Incorrect Mining area (chunks) value, try again.")
        elseif not minY or minY < 6 or minY > 230 then
            print("Incorrect Lowest mining Y coordinate, try again.")
        elseif not maxY or maxY < 18 or maxY > 248 or maxY - minY < 4 or serverY <= maxY then
            print("Incorrect Highest mining Y coordinate, tyr again.")
        else
            Log("Setup done!")
            break
        end
    end
    x = -(chunks - 1) / 2 -- relative x chunk start coordinate
    z = -(chunks - 1) / 2 -- relative z chunk start coordinate
    y = maxY
    WriteMiningDataFile(serverY, chunks, minY, maxY, x, z, y)
end

function ProcessRequests()
    -- if you select continue in Menu, then you didn't Setup vars now
    -- then you need to read those vars values before computer's shutdown from file
    if serverY == nil or chunks == nil or minY == nil or maxY == nil or x == nil or z == nil or y == nil then
        Log("No crucial vars in RAM, loading from file")
        ReadMiningDataFile()
        y = y - 3 -- when reload, give the next area to mine 
    end
    local maxX = (chunks - 1) / 2
    local maxZ = (chunks - 1) / 2
    -- if program was stopped in the middle of loop, it will restore its iterable values
    -- but that procedure is one time only, so there is a flags isLoadedZ/Y to control it
    local isLoadedZ = false
    local isLoadedY = false
    print("Waiting for turtles' requests...")
    for i_x = x, maxX do
        if not isLoadedZ then
            isLoadedZ = true
        else
            z = -maxZ
        end
        for i_z = z, maxZ do
            if not isLoadedY then
                isLoadedY = true
            else
                y = maxY
            end
            for i_y = y, minY, -3 do
                local _,_,_,_,message,_ = os.pullEvent("modem_message")
                print("Turtle, id:" .. message .. " requested mining chunck info")
                local dataToSerialize = {serverY = serverY, x = i_x, z = i_z, y = i_y}
                Modem.transmit(0, 0, textutils.serialise(dataToSerialize))
                print("Replying with serverY = " .. serverY .. " x = " .. i_x .. " z = " .. i_z .. " y = " .. i_y)
                
                WriteMiningDataFile(serverY, chunks, minY, maxY, i_x, i_z, i_y)
            end
        end
    end
    while true do
        print("Mining finished! Delete mining data file? [Y]/N")
        local a = read()
        if a == "Y" or a == "y" then
            fs.delete(miningDataPath)
            Log("File deleted")
            break
        elseif a == "N" or a == "n" then
            Log("File is not deleted")
            break
        end
        print("Incorrect input. Try again.")
    end
end

function ReadMiningDataFile()
    Log("Reading mining data file")
    local file = fs.open(miningDataPath, "r")
    serverY = tonumber(file.readLine())
    chunks = tonumber(file.readLine())
    minY = tonumber(file.readLine())
    maxY = tonumber(file.readLine())
    x = tonumber(file.readLine())
    z = tonumber(file.readLine())
    y = tonumber(file.readLine())
    file.close()
end

function WriteMiningDataFile(w_serverY, w_chunks, w_minY, w_maxY, w_x, w_z, w_y)
    Log("Writing mining data file")
    local file = fs.open(miningDataPath, "w")
    file.writeLine(w_serverY)
    file.writeLine(w_chunks)
    file.writeLine(w_minY)
    file.writeLine(w_maxY)
    file.writeLine(w_x)
    file.writeLine(w_z)
    file.writeLine(w_y)
    file.close()
end

--- MAIN BODY ---
Log("Set up Modem...")
Modem = peripheral.wrap("back")
Modem.open(0)
Menu()
ProcessRequests()
Modem.close(0)

--- END MAIN BODY ---