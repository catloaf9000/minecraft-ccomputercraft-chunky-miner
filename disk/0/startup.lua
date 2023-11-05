print("### FOUND startup.lua FILE ON DISK ###")
if turtle then
    print("I'm a turtle!")
    print("Loading a turtle script...")
    shell.run("/disk/chunky-miner-turtle.lua")
else
    print("I'm a server!")
    os.setComputerLabel("miner server")
    print("Loading a server script...")
    shell.run("/disk/chunky-miner-server.lua")
end
