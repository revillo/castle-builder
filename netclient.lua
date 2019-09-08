local sypri = require("sypri")
local cs = sypri.cs;
sypri.setServer(false);

local NetClient = {

    playerShare = {
    },
    
    otherPlayers = {

    },

    id = -1,

    inited = false

};


function NetClient.init()

    if (cs.client.id >= 0) then
        NetClient.inited = true;
        
        NetClient.id = cs.client.id;
        NetClient.playerShareId = "pc"..NetClient.id;

        NetClient.playerShareRoutine = sypri.addRoutine({
            keys = {"x", "y", "z"},
            protocol = sypri.RoutineProtocol.UNRELIABLE,
            mode = sypri.RoutineMode.EXACT,
            globalPriority = 2
        });

        NetClient.playerLevelRoutine = sypri.addRoutine({
            keys = {"lvl"},
            protocol = sypri.RoutineProtocol.RELIABLE,
            mode = sypri.RoutineMode.DIFF,
            globalPriority = 1
        });

        if (USE_CASTLE_CONFIG) then
            cs.client.useCastleConfig();
        else
            cs.client.enabled = true;
            cs.client.start("localhost:22122");
        end

        function sypri.onReceiveData(tableId, data)
            local arr = sypri.utils.splitString(tableId, " ");
            if (arr[1] == "ps") then
                local opid = arr[2];
                NetClient.otherPlayers[opid] = NetClient.otherPlayers[opid] or {};
                sypri.utils.copyInto(NetClient.otherPlayers[opid], data);
            end
        end
    end
end


function NetClient.update(dt)

    if (not NetClient.inited) then
        NetClient.init();
        return;
    end

    local pc = NetClient.playerShare;
    local player = State.player1;

    pc.x = player.position.x;
    pc.y = player.position.y;
    pc.z = player.position.z;

    sypri.update(dt);

end