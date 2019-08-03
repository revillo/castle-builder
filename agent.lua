local Agent = {};

Agent.TYPES = {
    "SpringHead"
}

local mat4 = cpml.mat4;
local vec3 = cpml.vec3;

local tempMat4 = mat4();
local tempVec3 = vec3();

local AGENT_VIEW_DISTANCE = 3;

local SPRING_HEAD_SPEED = 0.1; 
local SPRING_HEAD_SIZE = 0.5;
local SPRING_IMPULSE = 10.0;
local SPRING_HEAD_MESH = Mesh.makeCube(0.5, 0.5, 0.5, 0.0, 0.0);

Agent.TYPE_PROPERTIES = {
    SpringHead = {

        new = function(x, y, z)
            return {
                center = {x,y,z},
                rotY = 0
            }
        end,

        getAABB = function(agent)
            local shs = SPRING_HEAD_SIZE;
            return  Voxel.makeAABB(agent.center, {shs, shs, shs});
        end,

        fluid = false,

        canStand = false,

        onPlayerStep = function(agent, player)
            player.velocity.y = player.velocity.y + SPRING_IMPULSE;
        end,

        update = function(agent, dt)
            local center = agent.center;

            tempVec3:set(center.x, center.y, center.z);
            local toPlayer = State.player1.position - tempVec3;
            local distance = vec3.len(toPlayer);

            if (distance < AGENT_VIEW_DISTANCE) then
                local speed = SPRING_HEAD_SPEED * dt / distance;
                local nx = center.x + toPlayer.x * speed;
                local nz = center.z + toPlayer.z * speed;
                local shs = SPRING_HEAD_SIZE * 0.5;

                local abb = {
                    ll = {nx - shs, center.y - shs - 0.5, nz - shs },
                    ur = {nx + shs, center.y + shs - 0.5, nz + shs }
                };

                Voxel.intersectGridAABB(State.grid, abb, function(vox)
                    local props = Voxel.getPropertyForType(vox.type);

                    if (not props.fluid) then
                        center.x, center.z = nx, nz;
                    end
                end);
            
            end
        end,

        draw = function(agent)
            
            GFX.setShader(Shaders.Agents);

            --todo rotate
            tempMat4[13] = agent.x;
            tempMat4[14] = agent.y;
            tempMat4[15] = agent.z;
            GFX.drawMesh(Mesh.Cube, tempMat4);

        end,        
    }
}

function Agent.getProperties(agent)
    return Agent.TYPE_PROPERTIES[agent.typeName];
end

function Agent.drawSystem(sys)
    for _, ag in pairs(sys.agents) do
        local props = Agent.getProperties(ag);
        props.draw(ag)
    end
end

function Agent.collidePlayer(sys, player, callback)
    for _, ag in pairs(sys.agents) do
        callback(ag);
    end
end

function Agent.traceRay(sys, ray)
    local hits = {};
    local hitCount = 0;

    local o = ray.origin;
    local d = ray.direction;

    for _, ag in pairs(sys.agents) do
        local props = Agent.getProperties(ag);
        local abb = props.getAABB(ag);
        local hit = Voxel.intersectRayAABB(ray, abb);
        if (hit) then
            hits[hitCount] = {
                distance = hit,
                agent = ag
            };

            hitCount = hitCount + 1;
        end
    end

    local function distSorter(a, b)
        return a.distance < b.distance;
    end

    if (hitCount > 0) then
        table.sort(hits, distSorter);
        return hits[1].agent, hits[1].distance;
    else
        return nil;
    end
end

function Agent.updateSystem(sys, dt)
    for _, ag in pairs(sys.agents) do
        local props = Agent.getProperties(ag);
        props.update(ag, dt)
    end
end

function Agent.newAgentSystem()
    return {
        agentCount = 0,
        agents = {}
    };
end

function Agent.addAgent(sys, typeName, x, y, z)

    local ag = {
        typeName = typeName
    };
    sys.agents[sys.agentCount + 1] = ag;
    sys.agentCount = sys.agentCount + 1;

end

return Agent;