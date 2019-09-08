--castle://localhost:4000/main.lua
local sypri = require("sypri")
local cs = sypri.cs;
sypri.setServer(true);


local NetServer = {
    playerStates = {};
}


function NetServer.init()
    if (USE_CASTLE_CONFIG) then
        cs.server.useCastleConfig()
    else
        cs.server.enabled = true;
        cs.client.start("22122");
    end


    NetServer.sendPlayerRoutine = sypri.addRoutine({
        keys = {"x", "y", "z'"},
        protocol = sypri.RoutineProtocol.UNRELIABLE,
        mode = sypri.RoutineMode.EXACT,
        globalPriority = 2,
        serverMode = sypri.RoutineServerMode.BROADCAST
    });

    function sypri.onReceiveData(tableId, data, clientId)
        sypri.utils.copyInto(NetServer.playerStates[clientId], data);
    end

end

function cs.server.connect(clientId)
    sypri.addClient(clientId);
    NetServer.playerStates[clientId] = {
        x = 0, y = 0, z = 0
    };

    sypri.addTable("ps"..clientId, NetServer.playerStates, {
        NetServer.sendPlayerRoutine
    });
end

function NetServer.update(dt)
    sypri.update(dt);
end

function love.load()
    NetServer.init();
end

function love.update(dt)
    NetServer.update(dt);
end