local sypri = require("sypri")
local cs = sypri.cs;
sypri.setServer(false);

local NetClient = {

    playerShare = {
    },
    
    otherPlayers = {

    },
    
    playerPhotos = {

    },

    otherPlayerMesh = Mesh.makeCube(0.5, 0.5, 0.5, 0, 0),

    id = -1,

    started = false,

    csClient = cs.client

};

function NetClient.changeLevel()
    NetClient.otherPlayers = {};
end

function NetClient.init()
    if (USE_CASTLE_CONFIG) then
        cs.client.useCastleConfig();
    else
        cs.client.enabled = true;
        cs.client.start("localhost:22122");
    end
    print("Client Init");
end

function NetClient.start()
    if (cs.client.id) then
        print("Client Start");
        NetClient.started = true;
        
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


        sypri.addTable(NetClient.playerShareId, NetClient.playerShare, {
            NetClient.playerShareRoutine
            --,NetClient.playerLevelRoutine
        });

        function sypri.onReceiveEvent(event)
            if (event.cl) then
                NetClient.otherPlayers[event.cl] = nil;
            end
        end

        function sypri.onReceiveData(tableId, data)
            local arr = sypri.utils.splitString(tableId, " ");
            --print("Receive", tableId, data.x);
            if (arr[1] == "ps") then
                local opid = arr[2];
                NetClient.otherPlayers[opid] = NetClient.otherPlayers[opid] or {};
                sypri.utils.copyInto(NetClient.otherPlayers[opid], data);
            end
        end
    end
end

local mat4 = cpml.mat4;
local tempMat4 = mat4();

function NetClient.draw()

    for opid, op in pairs(NetClient.otherPlayers) do

        mat4.identity(tempMat4);
        tempMat4[13] = op.x;
        tempMat4[14] = op.y;
        tempMat4[15] = op.z;

        if (NetClient.playerPhotos[opid]) then
            NetClient.otherPlayerMesh:setTexture(NetClient.playerPhotos[opid])
        else
            --Set default player texture
        end

        GFX.drawMesh(NetClient.otherPlayerMesh, tempMat4);

    end

end

function NetClient.update(dt)

    if (not NetClient.started) then
        NetClient.start();
        return;
    end

    local pc = NetClient.playerShare;
    local player = State.player1;

    pc.x = player.position.x;
    pc.y = player.position.y;
    pc.z = player.position.z;
    
    pc.lvl = player.levelId;

    sypri.update(dt);

end

return NetClient;