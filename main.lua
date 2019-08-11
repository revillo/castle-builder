--castle://localhost:4000/main.lua
local PostVersion = 3;
DEVELOPER_MODE = true;

if CASTLE_PREFETCH then
    CASTLE_PREFETCH({
        'lib/list.lua',
        'lib/cpml/modules/vec3.lua',
        'lib/cpml/modules/vec2.lua',
        'lib/cpml/modules/utils.lua',
        'lib/cpml/modules/mat4.lua',
        'lib/cpml/modules/quat.lua',
        'lib/cpml/modules/constants.lua',
        'lib/cpml/init.lua',
        'tiles2.png',
        'shaders.lua',
        'editor.lua',
        'gfx3D.lua',
        'voxel.lua',
        'agent.lua',
        'mesh_util.lua',
    })
end

Sound = require('lib/sound');

Audio = {
  jump = Sound:new("audio/jump.ogg",2),
  step = Sound:new("audio/land.ogg", 5),
  spring = Sound:new("audio/spring.ogg", 2),
  boing = Sound:new("audio/boing.ogg", 3),
  scream = Sound:new("audio/scream.ogg"),
  winwarp = Sound:new("audio/win.ogg"),
  swim = Sound:new("audio/swim.ogg"),
  lava = Sound:new("audio/lava.ogg")
}

Audio.winwarp:setVolume(0.5);
Audio.step:setCooldown(0.6);
Audio.jump:setVolume(0.8);
Audio.step:setVolume(0.2);
Audio.swim:setCooldown(1.1);

function SecondsToClock(seconds)
  local seconds = tonumber(seconds)

  if seconds <= 0 then
    return " 00:00";
  else
    --hours = string.format("%02.f", math.floor(seconds/3600));
    --mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
    mins = string.format("%02.f", math.floor(seconds/60));
    --secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
    secs = string.format("%02.f", math.floor(seconds - mins * 60));
    return mins..":"..secs
  end
end

local client = love;
GFX = require("gfx3D");
cpml = GFX.cpml;
Mesh = require("mesh_util");
Shaders = require("shaders");
Voxel = require("voxel");
Agent = require("agent");
ui = castle.ui;
cjson = require("cjson");

local mat4 = cpml.mat4;
local vec3 = cpml.vec3;
local vec2 = cpml.vec2;
local PLAYER_SIZE = {x = 0.3, y = 0.75, z = 0.3};
local PLAYER_SPEED = 8;
local WORLD_Y_MIN = -10;

local cos = math.cos;
local sin = math.sin;

local UP = vec3(0.0, 1.0, 0.0);
local CAMERA_NEAR_CLIP = 0.01;
local CAMERA_FAR_CLIP = 100.0;
local GRAVITY = UP * -15;
local WATER_GRAVITY = UP * -3;
local WATER_DAMPING = 3;
local JUMP = UP * 6.4;
local MAX_BOUNCE = 10;

State = {
  time = 0;
}

local Player1 = {
  
  camera = {
    position = vec3(0.0, 2.0, -3.0),
    look_at = vec3(0.0, 2.0, 0.0),
    fovy = 70
  },
  
  size = PLAYER_SIZE,
  speed = PLAYER_SPEED,
  rotationX = 0,
  rotationY = 0,
  
  lookDir = vec3(),
  forwardDir = vec3(),
  rightDir = vec3(),
  
  velocity = vec3(0, 0, 0),
  position = vec3(0.0, 3.5, -3.0);
  headOffset = vec3(0.0, 0.73, 0.0);
}

State.player1 = Player1;

Editor = {};
Gameplay = {};
Level = {};

Editor = require("editor");

function Gameplay.globalIntersectAABB(aabb, voxelCallback, agentCallback, playerCallback)
  Voxel.intersectGridAABB(State.grid, aabb, voxelCallback);

  --todo agent to agent collisions w/o self collisions
  Agent.intersectSystemAABB(State.agentSystem, aabb, agentCallback or voxelCallback);
   
 
  local player = State.player1;

  local pbb = Voxel.makeAABB_CPML(player.position, player.size);
  if (Voxel.intersectAABBs(pbb, aabb)) then
    (playerCallback or voxelCallback)(player);
  end
 

end

function Gameplay.teleportPlayer(player, x, y, z)
    player.position:set(x,y,z);
    player.velocity:set(0,0,0);
    player.camera.position = player.position + player.headOffset;
    player.rotationX = 0;
    player.rotationY = 0;
end

function Gameplay.teleportPlayerToStart(player)
    player = player or State.player1;
    local startBlock = State.grid.startBlock;
    Gameplay.teleportPlayer(Player1, startBlock[1], startBlock[2] + 2, startBlock[3] );
    State.time = 0.0;
    State.levelFinished = false;
end

function Gameplay.setMouseControlCamera(toggle)
  love.mouse.setRelativeMode(toggle);
  State.mouseCamera = toggle;
end

function love.mousereleased(...)
  
  Editor.mousereleased(...);

end

function love.mousepressed(...)
  
  Editor.mousepressed(...);

end

function castle.uiupdate()
  
  Editor.uiupdate();

end

function Gameplay.renderScene(player)

  GFX.setCanvas3D(State.canvas3D)
  love.graphics.setDepthMode( "lequal", true );
  love.graphics.clear(0.1,0.6,1.0,1, true, true);
  
  love.graphics.setColor(1,1,1,1);
  local w, h = love.graphics.getDimensions();
  local t = love.timer.getTime();
  love.graphics.setMeshCullMode("back");
  
  GFX.setShader(Shaders.Tiles);
  GFX.setCameraView(player.camera.position, player.camera.look_at, UP);
  GFX.setCameraPerspective(player.camera.fovy, w/h, CAMERA_NEAR_CLIP, CAMERA_FAR_CLIP);
  
  Voxel.draw(State.grid);

  GFX.setCameraView(player.camera.position, player.camera.look_at, UP);
  Agent.drawSystem(State.agentSystem);

  GFX.setShader(GFX.Shader.Default);

  -- Draw Selection Highlight
  if (Editor.isActive and Editor.selection) then
    local c = Editor.selection.center;
  
    gt = mat4();
    gt[13], gt[14], gt[15] = c[1], c[2], c[3];
    gt[1], gt[6], gt[11] = 1.1, 1.1, 1.1;
    GFX.drawMesh(Mesh.Cube, gt);
  end
  
  love.graphics.setShader();
  love.graphics.setCanvas();
end

local PostProcess = {
  effect = "none"
}

function PostProcess.render()
  local w, h = love.graphics.getDimensions();
  
  if (PostProcess.effect == "fadeIn") then
    
    local t = (love.timer.getTime() - PostProcess.startTime) / PostProcess.duration;
    
    PostProcess.color[4] = (1.0 - t) * (PostProcess.startAlpha or 1.0);
    love.graphics.setColor(PostProcess.color);
    love.graphics.rectangle("fill", 0, 0, w, h);
    
    
    if (PostProcess.text) then
    
      love.math.setRandomSeed(15);
      local rndm = love.math.random;
      local amt = 100;
      
      for i = 1, 100 do
        
        love.graphics.setColor(rndm(),rndm(), rndm(), 1.0 - t);
        love.graphics.print(PostProcess.text, rndm() * w + rndm(-amt, amt) * t, rndm() * h + rndm(-amt, amt) * t);
        
      end
   end
   
   if (PostProcess.levelTime) then
   
      love.graphics.setColor(1.0, 1.0, 1.0, 1.0 - t);
      love.graphics.printf("Finish Time:", 0, 100, w, "center");
      love.graphics.printf(SecondsToClock(PostProcess.levelTime), 0, 150, w, "center");
    
   end
    
    if (t >= 1) then
      PostProcess.effect = "none";
    end
    
  elseif (PostProcess.effect == "message") then
    
     local t = (love.timer.getTime() - PostProcess.startTime) / PostProcess.duration;
    
    love.graphics.setColor(0.0, 0.0, 0.0, 0.5);
    local mx, my = w * 0.1, h * 0.1;
    
    love.graphics.rectangle("fill", mx, my, w - mx * 2, h - my * 2);

    love.graphics.setColor(1.0, 1.0, 1.0, 1.0);

   love.graphics.printf(PostProcess.text , mx * 2, my * 2, w - mx * 4);
    
    if (t >= 1) then
      PostProcess.effect = "none";
      PostProcess.levelTime = nil;
      PostProcess.text = nil;
    end
  end

end

function PostProcess.split(str, sep)
   local result = {}
   local regex = ("([^%s]+)"):format(sep)
   for each in str:gmatch(regex) do
      table.insert(result, each)
   end
   return result
end

function PostProcess.extractColor(colorText)
  
  local comps = PostProcess.split(colorText, ",");
  
  local r = comps[1] or "1";
  local g = comps[2] or "1";
  local b = comps[3] or "1";
  local a = comps[4] or "1";
  
  return {r, g, b, a};
  
end

function PostProcess.playMessageOverlay(text)
  
  PostProcess.effect = "message";
  PostProcess.duration = 1;
  PostProcess.startAlpha = 1.0;
  PostProcess.startTime = love.timer.getTime();
  local textf = PostProcess.split(text, "<");
  
  if (textf[2] == nil) then 
    PostProcess.text = text;
    return;
  end
  
  PostProcess.text = {};
  local index = 1;
  
  for i, txt in pairs(textf) do
    
    local pair = PostProcess.split(txt, ">");

    if (pair[2] == nil) then
      
      PostProcess.text[index] = {1,1,1,1};
      index = index + 1;
      PostProcess.text[index] = pair[1];
      index = index + 1;
      
    else 
    
      PostProcess.text[index] = PostProcess.extractColor(pair[1]);
      index = index + 1;
      PostProcess.text[index] = pair[2];
      index = index + 1;
    
    end
  
  end
  
end


function PostProcess.playFallOverlay()
  
  PostProcess.effect = "fadeIn";
  PostProcess.color = {1, 1, 1, 1.0};
  PostProcess.startTime = love.timer.getTime();
  PostProcess.duration = 4;
  PostProcess.startAlpha = 1.0;
  PostProcess.text = "Watch your step!";
  


end

function PostProcess.playFireOverlay()

  PostProcess.effect = "fadeIn";
  PostProcess.color = {1, 0.75, 0.0, 1.0};
  PostProcess.startTime = love.timer.getTime();
  PostProcess.duration = 4;
  PostProcess.startAlpha = 1.0;
  PostProcess.text = "Ouch!";

end

function PostProcess.playWinOverlay()

  PostProcess.effect = "fadeIn";
  PostProcess.color = {0.0, 0.0, 0.0, 1.0};
  PostProcess.startTime = love.timer.getTime();
  PostProcess.duration = 6;
  PostProcess.startAlpha = 0.5;
  PostProcess.text = "Win!!";
  PostProcess.text = nil;
  
  if (Editor.isActive) then
    PostProcess.levelTime = nil;
  else
    PostProcess.levelTime = State.time;
  end
  
end

function collidePlayerAABB(player, opbb, npbb, vbb, newPos, c, bounce, standCallback)

  local vgrid = State.grid;
  
  local vup1, vup2      = Voxel.isSolid(vgrid, c[1], c[2] + 1, c[3]), Voxel.isSolid(vgrid, c[1], c[2] + 2, c[3]);
  local vdown1, vdown2  = Voxel.isSolid(vgrid, c[1], c[2] - 1, c[3]), Voxel.isSolid(vgrid, c[1], c[2] - 2, c[3]);
  local vforward, vback = Voxel.isSolid(vgrid, c[1], c[2], c[3] + 1), Voxel.isSolid(vgrid, c[1], c[2], c[3] - 1);
  local vleft, vright   = Voxel.isSolid(vgrid, c[1] - 1, c[2], c[3]), Voxel.isSolid(vgrid, c[1] + 1, c[2], c[3]);
  
  local epsi = 0.0001;

  local hit = false;

  --Y Negative
  if (opbb.ll[2] >= vbb.ur[2] and npbb.ll[2] < vbb.ur[2] and not vup1 and not vup2) then
    local bounceAmt =  math.min(-player.velocity.y * bounce, MAX_BOUNCE);
    player.velocity.y = math.max(bounceAmt, player.velocity.y);
    newPos.y = vbb.ur[2] + PLAYER_SIZE.y + epsi;
    hit = true;
    standCallback();
  --Z Positive
  elseif (opbb.ur[3] <= vbb.ll[3] and npbb.ur[3] > vbb.ll[3] and not vback) then
    local bounceAmt =  math.max(-player.velocity.z * bounce, -MAX_BOUNCE);
    player.velocity.z = math.min(bounceAmt, player.velocity.z);
    newPos.z = vbb.ll[3] - PLAYER_SIZE.z - epsi;  
    hit = true;
  --X Positive
  elseif (opbb.ur[1] <= vbb.ll[1] and npbb.ur[1] > vbb.ll[1] and not vleft) then
    local bounceAmt =  math.max(-player.velocity.x * bounce, -MAX_BOUNCE);
    player.velocity.x = math.min(bounceAmt, player.velocity.x);
    newPos.x = vbb.ll[1] - PLAYER_SIZE.x - epsi;  
    hit = true;
  --Y Positive
  elseif (opbb.ur[2] <= vbb.ll[2] and npbb.ur[2] > vbb.ll[2] and not vdown1 and not vdown2) then
    local bounceAmt =  math.max(-player.velocity.y * bounce, -MAX_BOUNCE);
    player.velocity.y = math.min(bounceAmt, player.velocity.y);
    newPos.y = vbb.ll[2] - PLAYER_SIZE.y - epsi;   
    hit = true;
  -- Z Negative
  elseif (opbb.ll[3] >= vbb.ur[3] and npbb.ll[3] < vbb.ur[3] and not vforward) then
    local bounceAmt =  math.min(-player.velocity.z * bounce, MAX_BOUNCE);
    player.velocity.z = math.max(bounceAmt, player.velocity.z);
    newPos.z = vbb.ur[3] + PLAYER_SIZE.z + epsi;
    hit = true;
  --X Negative
  elseif (opbb.ll[1] >= vbb.ur[1] and npbb.ll[1] < vbb.ur[1] and not vright) then
    local bounceAmt =  math.min(-player.velocity.x * bounce, MAX_BOUNCE);
    player.velocity.x = math.max(bounceAmt, player.velocity.x);
    newPos.x = vbb.ur[1] + PLAYER_SIZE.x + epsi;
    hit = true;
  end  

   if (hit and bounce > 0.0) then
    Audio.boing:play();
   end
end



local newPos = vec3();

function Gameplay.collidePlayer(player, dt, collisionData)
    
  newPos =  player.position + (player.velocity * dt);

  if (player.velocityMatch) then
    newPos = newPos + player.velocityMatch * dt;
  end

  local oldPos = player.position;
  
  local opbb = Voxel.makeAABB_CPML(oldPos, PLAYER_SIZE);
  
  local npbb = Voxel.makeAABB_CPML(newPos, PLAYER_SIZE);
  
  local epbb = {
    ll = {newPos.x - PLAYER_SIZE.x * 2, newPos.y - PLAYER_SIZE.y * 2, newPos.z - PLAYER_SIZE.z * 2},
    ur = {newPos.x + PLAYER_SIZE.x * 2, newPos.y + PLAYER_SIZE.y * 2, newPos.z + PLAYER_SIZE.z * 2}
  };
    
  collisionData.standing = false;

  local standingVoxels = {
  }
  
  local vgrid = State.grid;
  
  local standVoxelCount = 0;

  player.velocityMatch = nil;


  --Todo use intersectSystemAABB instead
  Agent.collidePlayer(State.agentSystem, player, function(agent)
    
    local props = Agent.getProperties(agent);
    if (props.fluid) then
      return
    end

    local abb = props.getAABB(agent);
    
    if (not Voxel.intersectAABBs(npbb, abb)) then
      return;
    end

    collidePlayerAABB(player, opbb, npbb, abb, newPos, agent.center, props.bounciness or 0, function()
    
      if (props.canStand) then
        collisionData.standing = true;
      end

      if(props.onPlayerStep) then
        props.onPlayerStep(agent, player);
      end

    end);



  end);

  Voxel.intersectGridAABB(State.grid, epbb, function(v, c)
        
    local vbb = {
      ll = {c[1] - 0.5, c[2] - 0.5, c[3] - 0.5},
      ur = {c[1] + 0.5, c[2] + 0.5, c[3] + 0.5}
    };
    
    local props = Voxel.getPropertyForType(v.type);
    
    if (props.onNearby) then
      props.onNearby(collisionData, v, npbb, vbb);
    end
    
    if (not Voxel.intersectAABBs(npbb, vbb)) then
      return;
    end
  
    if (props.onCollide) then
      props.onCollide(collisionData, v, npbb, vbb);
    end
    
    if (props.fluid) then
      return;
    end
    
    local bounce = props.bounciness or 0.0;
    
    collidePlayerAABB(player, opbb, npbb, vbb, newPos, c, bounce, function()
      collisionData.standing = true;
      standVoxelCount = standVoxelCount + 1;
      standingVoxels[standVoxelCount] = v;
    end);
   
      
    npbb = {
      ll = {newPos.x - PLAYER_SIZE.x, newPos.y - PLAYER_SIZE.y, newPos.z - PLAYER_SIZE.z},
      ur = {newPos.x + PLAYER_SIZE.x, newPos.y + PLAYER_SIZE.y, newPos.z + PLAYER_SIZE.z}
    };

  end);

  collisionData.standingVoxels = standingVoxels;
  collisionData.standingVoxelCount = standVoxelCount;
  player.position = newPos;

end

function Gameplay.updatePlayerOrientation(player, inputs, dt)

  player.rotationX = player.rotationX + inputs.look.x;
  player.rotationY = cpml.utils.clamp(player.rotationY + inputs.look.y, -math.pi * 0.45, math.pi * 0.45);

  player.lookDir:set(
    sin(player.rotationX) * cos(player.rotationY),
    sin(player.rotationY),
    cos(player.rotationX) * cos(player.rotationY)
  );
  
  player.forwardDir:set(
    sin(player.rotationX),
    0,
    cos(player.rotationX)
  );
  
  player.rightDir:set(
    sin(player.rotationX - math.pi * 0.5),
    0,
    cos(player.rotationX - math.pi * 0.5)
  );

end

function Gameplay.getPlayerDamping(player, collisionData, inputs, dt)

  local airDamp = 0.1 * dt;
  local groundDamp = 0.2 * dt;
  local speed = PLAYER_SPEED * dt;

  
  local onIce = true;

  if (collisionData.standingVoxelCount == 0) then
    onIce = false;
  end
  
  for _, v in pairs(collisionData.standingVoxels) do
    if (v.type ~= Voxel.BLOCK_INDEX_MAP["ice"]) then
      onIce = false;
    end
  end
  
  
  if (collisionData.standing) then
    if (vec3.len(inputs.move) < 0.01) then
      groundDamp = math.min(1.0, 15 * dt);
      if (onIce) then
        groundDamp = 0.2 * dt;
      end
    else -- Running then
      
      local runVelocity = (player.forwardDir * inputs.move.z * speed) + (player.rightDir * inputs.move.x * speed);
      
      local dampAngle = vec3.dot(vec3.normalize(player.velocity), vec3.normalize(runVelocity));
      dampAngle = 1.0-cpml.utils.clamp((dampAngle * 0.5 + 0.5), 0.0, 1.0);
      groundDamp = cpml.utils.lerp(0.2 * dt, 15 * dt, dampAngle);
    
    end
  end

  if (player.swimming) then
    airDamp = WATER_DAMPING * dt;
    groundDamp = WATER_DAMPING * dt;
  end
  
  if (player.flying) then
    airDamp = math.min(0.1, 10 * dt);
    groundDamp = math.min(0.1, 10 * dt);
  end
  
  return vec3(groundDamp, airDamp, groundDamp);
end

function Gameplay.updatePlayer(player, inputs, dt)
    
  dt = math.min(dt, 0.1); 

  Gameplay.updatePlayerOrientation(player, inputs, dt);
  
  local speed = PLAYER_SPEED * dt;
  
  --player.camera.position = player.camera.position + (inputs.move * (dt * 5));
  --newPos = player.camera.position + (player.lookDir * inputs.move.z * speed) + (player.rightDir * inputs.move.x * speed);  
  
  --Different Movement Circumstances

  player.flying = false;
  if (Editor.isActive and not Editor.gravity) then
    player.velocity = player.velocity + (player.lookDir * inputs.move.z * speed * 5) + (player.rightDir * inputs.move.x * speed * 5);
    player.flying = true;
  elseif (player.swimming) then
    player.velocity = player.velocity + (WATER_GRAVITY * dt);
    player.velocity = player.velocity + (player.lookDir * inputs.move.z * speed) + (player.rightDir * inputs.move.x * speed);
  else
    player.velocity = player.velocity + (GRAVITY * dt);
    player.velocity = player.velocity + (player.forwardDir * inputs.move.z * speed) + (player.rightDir * inputs.move.x * speed);
  end
  
  local velMag = vec3.len(player.velocity);
  Audio.step:setCooldown(cpml.utils.clamp(1.5 / (velMag + 0.1), 0.2, 1.0));
  local collisionData = {};
  
  --Collide player with voxels and agents
  Gameplay.collidePlayer(player, dt, collisionData);
 
 local ppos = player.position; 
  local vbelow = Voxel.get(State.grid, ppos.x, ppos.y - PLAYER_SIZE.y - 0.5, ppos.z);

  if (collisionData.standing and velMag > 2.0 and not collisionData.water) then
    if (vbelow and (vbelow.type == Voxel.BLOCK_INDEX_MAP["ice"]  or vbelow.type == Voxel.BLOCK_INDEX_MAP["rubber"])) then

    else
      Audio.step:play();
    end
  end

  if (inputs.jump == 1 and collisionData.standing) then
    player.velocity = player.velocity + (JUMP);
    Audio.jump:play();
    Audio.step:resetCooldown();
    --player.velocity.y = (JUMP * dt).y;
  end
  
  if (inputs.jump == 1 and player.swimming) then
    player.velocity.y = math.max(1.0, player.velocity.y);
  end

  local damping = Gameplay.getPlayerDamping(player, collisionData, inputs, dt);
  
  --Todo Make safe
  player.velocity = player.velocity - (player.velocity * damping);
  
  --Move Player
  player.camera.position = player.position + player.headOffset;
  player.camera.look_at = player.lookDir + player.camera.position;
  
  --Handle edge cases
  if (collisionData.fire) then
    PostProcess.playFireOverlay();
    Audio.scream:play();
    Audio.lava:play();
    Gameplay.teleportPlayerToStart(player);
  end
  
  if (collisionData.info) then
    PostProcess.playMessageOverlay(collisionData.info);
  end
  
  if (player.position.y < WORLD_Y_MIN) then
    PostProcess.playFallOverlay();
    Audio.scream:play();
    Gameplay.teleportPlayerToStart(player);
  end
  
  if (collisionData.finish) then
    if (Editor.isActive and Editor.selection and Editor.selection.voxel and Editor.selection.voxel.type == Voxel.BLOCK_INDEX_MAP["end"]) then
      return
    end
    
    State.levelFinished = true;
    PostProcess.playWinOverlay();
    if (collisionData.nextLevel and collisionData.nextLevel ~= "") then
      Audio.winwarp:play();
    end
    Level.loadLevelFromId(collisionData.nextLevel);
  end
  
  player.swimming = collisionData.water;

  if (collisionData.water and velMag > 1.0) then
    Audio.swim:play();
  end
  
end

local inputs = {
};

function Gameplay.getInputs(dt)
  
  inputs.move = vec3();
  inputs.look = vec2();
  inputs.jump = 0;

  if (love.keyboard.isDown("a")) then
    inputs.move.x = -1;
  end
  if (love.keyboard.isDown("d")) then
    inputs.move.x = 1;
  end
  if (love.keyboard.isDown("w")) then
    inputs.move.z = 1;
  end
  if (love.keyboard.isDown("s")) then
    inputs.move.z = -1;
  end
  
  if (love.keyboard.isDown("left")) then
    inputs.look.x = 2 * dt;
  end
  
  if (love.keyboard.isDown("right")) then
    inputs.look.x = -2 * dt;
  end
  
  if (love.keyboard.isDown("up")) then
    inputs.look.y = 2 * dt;
  end
  
  if (love.keyboard.isDown("down")) then
    inputs.look.y = -2 * dt;
  end
  
  if (love.keyboard.isDown("space")) then
    inputs.jump = 1;
  end
  
  --[[
  if (love.keyboard.isDown("escape")) then
    Gameplay.setMouseControlCamera(false);
  end
  ]]
  
  if (State.mouseCamera) then
    
    inputs.look.x = inputs.look.x - (State.mouseDeltaX  or 0) * 0.003;
    inputs.look.y = inputs.look.y - (State.mouseDeltaY  or 0) * 0.003;
  
    State.mouseDeltaX = 0;
    State.mouseDeltaY = 0;
  end
  
  return inputs;
  
end

local DPISave = -1;

local DTSave = 0;

function Gameplay.update(dt)
  
  if (not Editor.isActive and not State.levelFinished) then
    State.time = State.time + dt;
  end

  Agent.updateSystem(State.agentSystem, dt);  
  Gameplay.updatePlayer(Player1, Gameplay.getInputs(dt), dt);

end

function Gameplay.render()

  Gameplay.renderScene(Player1);
  
  love.graphics.draw(State.canvas3D.color, 0, 0,0, 1, 1);
  PostProcess.render();
  
 
  --Debug print framerates
  --love.graphics.setColor(1,0,0,1);
  --love.graphics.print(DTSave, 0, 0);
  
  love.graphics.setColor(1,1,1,1);
  if (Editor.isActive) then
    Editor.printTooltip();
  else
    love.graphics.printf(SecondsToClock(State.time)..[[ 
[Enter] - Edit Mode]], 5, 0, 400);
  end
end

function client.keypressed(key)

  if (Editor.isActive) then
    Editor.keypressed(key);
  else
    if (key == "return") then
      Editor.enterEditMode();
    end
  end

end

function client.update(dt)
  
  DTSave = (DTSave + dt) * 0.5;
  
  if (DPISave ~= love.window.getDPIScale()) then
    DPISave = love.window.getDPIScale();
    love.resize();
  end

  Gameplay.update(dt);

end

function client.mousemoved(x, y, dx, dy)
    
  if (State.mouseCamera) then
    State.mouseDeltaX = (State.mouseDeltaX or 0) + dx;
    State.mouseDeltaY = (State.mouseDeltaY or 0) + dy;
  end

end

function client.resize()
  local w, h = love.graphics.getDimensions();
  
  State.canvas3D = GFX.createCanvas3D(w, h, {
    dpiscale = love.window.getDPIScale() * 2
  });
  
end

function client.draw()

    Gameplay.render();

    
    if (Editor.isActive) then
      Editor.drawOverlay();
    else
      local w, h = love.graphics.getDimensions();

      love.graphics.setColor(1,1,1,0.4);
      love.graphics.rectangle("fill", w * 0.5 - 10, h * 0.5 - 1, 20,  2);
      love.graphics.rectangle("fill", w * 0.5 - 1, h * 0.5 - 10, 2,  20);
    end

  
    
end

function client.load()
  love.resize();

  local font = love.graphics.newImageFont("imagefont.png",
    " abcdefghijklmnopqrstuvwxyz" ..
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
    "123456789.,!?-+/():;%&`'*#=[]\"")

  love.graphics.setFont(font);

  State.grid = Voxel.newStarterGrid();
  State.agentSystem = Agent.newAgentSystem();
  Gameplay.teleportPlayerToStart(Player1);
  

  network.async(function()
    local levels = castle.storage.get("levels") or "";
    local levelsArray = PostProcess.split(levels, ";");
    Editor.userLevels = levelsArray;
  end);

  Editor.enterPlayMode();
  --loadLevelFromId("practice0");
end


function castle.postopened(post)
  
  local version = post.data.version;
  
  if (version < 3) then
    Level.loadLevel({grid = Voxel.newStarterGrid()});
  else
    Level.loadLevel(Level.deserialize(post.data));
  end
  
  Editor.isActive = false;
  State.mouseCameraPressed = true;
  
end


local asyncLevelLoading = -10;

function Level.loadLevelFromId(levelId)
  
  if (not levelId) then
    return
  end

  
  if (levelId == "blank") then
    Level.loadLevel({grid = Voxel.newBlankGrid()});
  else
    
    if (love.timer.getTime() - asyncLevelLoading < 5) then
      return;
    end
  
    asyncLevelLoading = love.timer.getTime();

    print("Loading", levelId);

    Level.loadFromUrl("levels/"..levelId..".lua", levelId);
    
    --[[
    local encodedLevel = require("levels/"..levelId..".lua");
    if (encodedLevel) then
      local data = cjson.decode(encodedLevel);
      if (data.grid) then
        loadLevel(data.grid);
      end
    end
    ]]
  
  end  
  
end

function Level.loadLevel(level)
  
  State.grid = level.grid;
  State.agentSystem = level.agentSystem or Agent.newAgentSystem();
  Voxel.reload(State.grid);
  Agent.resetSystem(State.agentSystem);
  Gameplay.teleportPlayerToStart(Player1);
  Editor.selection = nil;

end

function Level.deserialize(data)

  data.grid = Voxel.unpostify(data.grid);

  data.agentSystem = Agent.unpostify(data.agentSystem) or Agent.newAgentSystem();

  print(data.agentSystem.agentIndex);
end

function Level.serialize()

  local data = {};
  data.grid = Voxel.postify(State.grid);
  data.agentSystem = Agent.postify(State.agentSystem)
  data.version = PostVersion;
  data.blockTypes = Voxel.BLOCK_TYPES;

  return data;

end

function Level.saveLevelToDisk(filepath)

  local file = io.open(filepath, "w+");

  file:write("return [["..cjson.encode(Level.serialize()).."]]");

  io.close(file);
  
end

function Level.loadFromUrl(url, levelId)

    
  network.async(function()
      
    local encodedLevel = require(url);
    if (encodedLevel) then
      local data = cjson.decode(encodedLevel);
      if (data.grid) then
        Level.deserialize(data);
        Level.loadLevel(data);
      end
    end
  
    
  end);

end

function Level.loadFromUser(levelName)

  network.async(function()
    local level = castle.storage.get("LEVEL>"..levelName);
    local data = cjson.decode(level);
    data = Level.deserialize(data);
    Level.loadLevel(data);
  end)

end

function Level.saveToUser(levelName)

  network.async(function()
    castle.storage.set("LEVEL>"..levelName, cjson.encode(Level.serialize()));

    local levels = castle.storage.get("levels") or "";
    local levelsArray = PostProcess.split(levels, ";");
    
    local thereAlready = false;
    local numLevels = 0;

    for i, lvlName in pairs(levelsArray) do
      if lvlName == levelName then
        thereAlready = true;
      end

      numLevels = i;
    end

    if (not thereAlready) then
      levelsArray[numLevels + 1] = levelName;
      levels = levels..";"..levelName;
      castle.storage.set("levels", levels);
    end

    Editor.userLevels = levelsArray;

    
  end);

end

function Level.loadLevelFromDisk(filepath)

  --[[
  local file = io.open("C:/level.lua", "r");

  local dec = cjson.decode(file:read("*a"));

  io.close(file);

  Level.loadLevel(Level.deserialize(dec));]]

  Level.loadFromUrl("file://"..filepath);
end

function Level.postLevel()

  local data = Level.serialize();
  
  network.async(function()
    castle.post.create {
        message = 'Level 1',
        media = 'capture',
        data = data
    }
    end)

end


