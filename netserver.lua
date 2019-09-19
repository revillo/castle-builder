--castle://localhost:4000/main.lua
local sypri = require("sypri")
local cs = sypri.cs;
sypri.setServer(true);


local NetServer = {
    playerStates = {},
    channels = {},
    csServer = cs.server
}


function NetServer.init()
    print("server init");

    if (USE_CASTLE_CONFIG) then
        cs.server.useCastleConfig()
    else
        cs.server.enabled = true;
        cs.server.start("22122");
    end

end

function NetServer.setChannelPriorities(channel, clientId, priority)
    for cid, cstate in pairs(NetServer.channels[channel]) do
        if (cid ~= clientId) then
            sypri.setClientPriority(
                NetServer.sendPlayerRoutine, 
                "ps"..clientid,
                cid,
                priority
            );

            sypri.setClientPriority(
                NetServer.sendPlayerRoutine,
                "ps"..cid,
                clientId,
                priority
            );
        end
    end
end

function NetServer.sendChannelEvent(channel, event)

    local clients = {};

    for cid, cstate in pairs(NetServer.channels[channel]) do
        clients[cid] = cid;    
    end

    sypri.sendEvent(event, clients);

end

function NetServer.changePlayerLevel(clientId, toLevel, fromLevel)
    if (toLevel == fromLevel) then return end;
    local serverTableId = "ps"..clientId;

    if (fromLevel) then
        NetServer.channels[fromLevel][clientId] = nil;
        NetServer.setChannelPriorities(fromLevel, clientId, 0);
        sypri.sendEvent({"cl" = clientId});
    end

    if (toLevel) then
        NetServer.channels[toLevel][clientId] = NetServer.playerStates[clientId];
        NetServer.setChannelPriorities(toLevel, clientId, 2);
    end

end

function NetServer.start()

    NetServer.sendPlayerRoutine = sypri.addRoutine({
        keys = {"x", "y", "z'"},
        protocol = sypri.RoutineProtocol.UNRELIABLE,
        mode = sypri.RoutineMode.EXACT,
        globalPriority = 2,
        serverMode = sypri.RoutineServerMode.INDIVIDUAL
    });

    function sypri.onReceiveData(tableId, data, clientId)
        --print("Server receive", tableId, data.x);

        if (data.lvl) then
            changePlayerLevel(clientId, data.lvl, NetServer.playerStates[clientId].lvl);
        end
        sypri.utils.copyInto(NetServer.playerStates[clientId], data);
    end

end

function cs.server.connect(clientId)
    sypri.addClient(clientId);
    print("Client Connected:", clientId);

    NetServer.playerStates[clientId] = {
        x = 0, y = 0, z = 0
    };

    sypri.addTable("ps"..clientId, NetServer.playerStates[clientId], {
        NetServer.sendPlayerRoutine
    });
end

function NetServer.update(dt)
    sypri.update(dt);
end

return NetServer;