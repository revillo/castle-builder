local Agent = {};

Agent.TYPES = {
    "SpringHead",
    "Platform"
}

local Image = {
    agents = love.graphics.newImage("agents.png"),
    agentsBump = love.graphics.newImage("agents.png")
}

local now = love.timer.getTime;

Image.agents:setFilter("nearest", "nearest");
Image.agentsBump:setFilter("linear", "linear");
local sign = cpml.utils.sign;

local mat4 = cpml.mat4;
local vec3 = cpml.vec3;

local CUBE_EXTENTS = vec3(0.5, 0.5, 0.5);
local CUBE_EXTENTS_EPSI = vec3(0.495, 0.495, 0.495);

local tempMat4 = mat4.new();
local rot90Mat4 = mat4.from_angle_axis(math.pi / 2, vec3(0, 1, 0));


local tempVec3 = vec3();

local tempPos = vec3();
local tempVel = vec3();

local AGENT_VIEW_DISTANCE = 6;

local SPRING_HEAD_SPEED = 1.0; 
local SPRING_HEAD_SIZE = 0.4;
local SPRING_IMPULSE = 16.0;
local SPRING_HEAD_MESH = Mesh.makeCube(SPRING_HEAD_SIZE, SPRING_HEAD_SIZE, SPRING_HEAD_SIZE, 0.0, 0.0);
local SPRING_PLATFORM_MESH = Mesh.makeCube(SPRING_HEAD_SIZE, SPRING_HEAD_SIZE, SPRING_HEAD_SIZE, {
    {2.0, 1.0},
    {2.0, 1.0},
    {2.0, 1.0},
    {1.0, 1.0},
    {2.0, 1.0},
    {2.0, 1.0}
});

local PLATFORM_MESH = Mesh.makeCube(0.5, 0.5, 0.5, {
    {4.0, 0.0},
    {4.0, 0.0},
    {4.0, 0.0},
    {3.0, 0.0},
    {4.0, 0.0},
    {4.0, 0.0}
});

SPRING_HEAD_MESH:setTexture(Image.agents);
SPRING_PLATFORM_MESH:setTexture(Image.agents);
PLATFORM_MESH:setTexture(Image.agents);

local function AgentCanWalk(agent, x, y, z, size)
    
    local shsg = size * 0.5;

    local abb_ground = {
        ll = {x - shsg, y - shsg - 0.5, z - shsg },
        ur = {x + shsg, y + shsg - 0.5, z + shsg }
    };

    local aab_body = {
        ll = {x - size, y - size + 0.01, z - size },
        ur = {x + size, y + size, z + size }
    }

    local onGround = false;

    Voxel.intersectGridAABB(State.grid, abb_ground, function(vox)
        local props = Voxel.getPropertyForType(vox.type);

        if (not props.fluid) then
            onGround = true;
        end
    end);

    local clipping = false;

    Gameplay.globalIntersectAABB(aab_body, function()
        clipping = true;
    end, function(otherAgent)
        if (otherAgent ~= agent) then
            clipping = true;
        end
    end)

    --[[
    Voxel.intersectGridAABB(State.grid, aab_body, function(vox)
        clipping = true;
    end);
    ]]

    return onGround and not clipping;

end



Agent.TYPE_PROPERTIES = {
    SpringHead = {

        --[[
        new = function(x, y, z)
            return {
                center = {x,y,z},
                --rotY = 0
            }
        end,
        ]]

        attributes = {
            mobile = {type="bool", default=true}
        },

        getAABB = function(agent)
            local shs = SPRING_HEAD_SIZE;
            return  Voxel.makeAABB(agent.center, {shs, shs, shs});
        end,

        getAABB_CPML = function(agent)
            local shs = SPRING_HEAD_SIZE;
            return {
                min = vec3(agent.center[1] - shs, agent.center[2] - shs, agent.center[3]  - shs),
                max = vec3(agent.center[1] + shs, agent.center[2] + shs, agent.center[3]  + shs)
            };
        end,

        fluid = false,

        canStand = false,

        onPlayerStep = function(agent, player)
            agent.popStart = now();
            player.velocity.y = SPRING_IMPULSE;
        end,

        update = function(agent, dt)

            if (not agent.mobile) then
                return;
            end

            tempVec3:set(agent.center[1], agent.center[2], agent.center[3]);
            local center = tempVec3;
           
            local toPlayer = State.player1.position - tempVec3;
            local distance = vec3.len(toPlayer);

            if (distance < AGENT_VIEW_DISTANCE and distance > 1.5) then
                local speed = SPRING_HEAD_SPEED * dt / distance;
                local nx = center.x + toPlayer.x * speed;
                local nz = center.z + toPlayer.z * speed;
                local shs = SPRING_HEAD_SIZE;
                
                if AgentCanWalk(agent, nx, center.y, nz, shs) then
                    agent.center[1] = nx;
                    agent.center[3] = nz;
                elseif AgentCanWalk(agent, center.x, center.y, center.z + sign(toPlayer.z) * SPRING_HEAD_SPEED * dt, shs) then
                    agent.center[3] = nz;
                elseif AgentCanWalk(agent, center.x + sign(toPlayer.x) * SPRING_HEAD_SPEED * dt, center.y, center.z, shs) then
                    agent.center[1] = nx;
                end                
            end
            
        end,

        draw = function(agent)
            
            GFX.setShader(Shaders.Agents);
            GFX.setUniform("bumpTex", Image.agentsBump);
            
            tempVec3:set(agent.center[1], agent.center[2], agent.center[3]);
            local center = tempVec3;

            --todo rotate?
            mat4.identity(tempMat4);
            tempMat4[13] = center.x;
            tempMat4[14] = center.y - 0.1;
            tempMat4[15] = center.z;

            local popHeight = 0.0;

            if (agent.popStart) then
                local t = (now() - agent.popStart) / 1.0;
                if (t > 1.0) then
                    agent.popStart = nil;
                end
                popHeight = (1.0 - t) * 0.5;
            end

            GFX.drawMesh(SPRING_HEAD_MESH, tempMat4);

            tempMat4[14] = tempMat4[14] + 0.55 + popHeight;
            tempMat4[6] = 0.1;

            GFX.drawMesh(SPRING_PLATFORM_MESH, tempMat4);

            
            tempMat4[14] = tempMat4[14] - 0.15
            tempMat4[1] = 0.2;
            tempMat4[11] = 0.2;
            tempMat4[6] = 0.3;

            GFX.drawMesh(SPRING_PLATFORM_MESH, tempMat4);

        end,
    }, 

    Platform = {
        fluid = false,
        
        canStand = true,

        attributes = {
            direction = {type="option", default="left_right", options = {"left_right", "forward_back"}}
        },

        onPlayerStep = function(agent, player)

            agent.inv = agent.inv or 1;
            
            if (agent.direction == "left_right") then
                tempVel:set(0.5 * agent.inv, 0, 0);
            elseif (agent.direction == "forward_back") then
                tempVel:set(0, 0, 0.5 * agent.inv);
            end

            player.velocityMatch = player.velocityMatch or vec3();
            player.velocityMatch:set(tempVel.x, tempVel.y, tempVel.z);
        end,

        update = function(agent, dt)
            tempPos:set(agent.center[1], agent.center[2], agent.center[3]);

            agent.inv = agent.inv or 1;

            if (agent.direction == "left_right") then
                tempVel:set(0.5 * agent.inv, 0, 0);
            elseif (agent.direction == "forward_back") then
                tempVel:set(0, 0, 0.5 * agent.inv);
            end

            local newPos = tempPos + tempVel * dt;
            local abb = Voxel.makeAABB_CPML(newPos, CUBE_EXTENTS_EPSI);
            abb.ll[2]= abb.ll[2] + 0.01;
            local didHit = false;

            --todo self intersections
            Gameplay.globalIntersectAABB(abb, function()
                didHit = true;
            end, function (otherAgent) 
                if (otherAgent ~= agent) then
                    didHit = true;
                end
            end);

            if (didHit) then
                agent.inv = agent.inv * -1;
            else
                agent.center[1], agent.center[2], agent.center[3] = newPos.x, newPos.y, newPos.z;
            end
        end,

        draw = function(agent)
            GFX.setShader(Shaders.Agents);
            GFX.setUniform("bumpTex", Image.agentsBump);
            
            local mat = tempMat4;
            if (agent.direction == "left_right") then
                mat = rot90Mat4;
            else
                mat4.identity(mat);
            end
            
            mat[13] = agent.center[1];
            mat[14] = agent.center[2];
            mat[15] = agent.center[3];

            GFX.drawMesh(PLATFORM_MESH, mat);
        end
    }
}

for _, props in pairs(Agent.TYPE_PROPERTIES) do
    props.getAABB = props.getAABB or function(agent)
        return Voxel.makeAABB(agent.center, {0.5, 0.5, 0.5});
    end;

    props.getAABB_CPML = props.getAABB_CPML or function(agent)
        return {
            min = vec3(agent.center[1] - 0.5, agent.center[2] - 0.5, agent.center[3]  - 0.5),
            max = vec3(agent.center[1] + 0.5, agent.center[2] + 0.5, agent.center[3]  + 0.5)
        };
    end;
end

function Agent.getProperties(agent)
    return Agent.TYPE_PROPERTIES[agent.typeName];
end

function Agent.intersectSystemAABB(sys, aabb, callback)
    for _, ag in pairs(sys.agents) do

        local props = Agent.getProperties(ag);
        local abb = props.getAABB(ag);

        if (Voxel.intersectAABBs(aabb, abb)) then
            callback(ag);
        end
    end
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

    ray.position = ray.origin;

    for _, ag in pairs(sys.agents) do
        local props = Agent.getProperties(ag);
        local abb = props.getAABB_CPML(ag);
        local pos, hit =   cpml.intersect.ray_aabb(ray, abb);
        if (hit) then
            hitCount = hitCount + 1;

            hits[hitCount] = {
                distance = hit,
                agent = ag
            };
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

function Agent.removeAgent(sys, agent)
    for i, ag in pairs(sys.agents) do
        if (agent == ag) then
            sys.agents[i] = nil;
        end
    end
end

function Agent.updateSystem(sys, dt)

    if (Editor.isActive and Editor.agentsPaused) then
        return;
    end

    for _, ag in pairs(sys.agents) do
        local props = Agent.getProperties(ag);
        props.update(ag, dt);
    end
end

function Agent.newAgentSystem()
    return {
        agentIndex = 0,
        agents = {}
    };
end

function Agent.resetSystem(sys)
    for _, agent in pairs(sys.agents) do
        agent.center[1], agent.center[2], agent.center[3] = agent.start[1], agent.start[2], agent.start[3];
    end
end

function Agent.addAgent(sys, typeName, x, y, z)

    local ag = {
        typeName = typeName,
        center = {x, y, z},
        start = {x,y,z}
    };

    sys.agentIndex = sys.agentIndex + 1;
    sys.agents[sys.agentIndex] = ag;

    return ag;
end

function Agent.unpostify(sys)
    return sys;
end

function Agent.postify(sys)
    return sys;
end

return Agent;