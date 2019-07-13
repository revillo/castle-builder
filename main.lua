--castle://localhost:4000/main.lua

local client = love;
GFX = require("gfx3D");
cpml = GFX.cpml;
Mesh = require("mesh_util");
Shaders = require("shaders");
local Voxel = require("voxel");
local mat4 = cpml.mat4;
local vec3 = cpml.vec3;
local vec2 = cpml.vec2;
local ui = castle.ui;
local PLAYER_SIZE = {x = 0.3, y = 0.75, z = 0.3};
local PLAYER_SPEED = 8;
local WORLD_Y_MIN = -10;

local cos = math.cos;
local sin = math.sin;

local UP = vec3(0.0, 1.0, 0.0);
local CAMERA_NEAR_CLIP = 0.1;
local CAMERA_FAR_CLIP = 100.0;
local GRAVITY = UP * -15;
local WATER_GRAVITY = UP * -1;
local WATER_DAMPING = 3;
local JUMP = UP * 6.4;
local MAX_BOUNCE = 10;

local state = {

}

local Player1 = {
  
  camera = {
    position = vec3(0.0, 2.0, -3.0),
    look_at = vec3(0.0, 2.0, 0.0),
    fovy = 70
  },
  
  rotationX = 0,
  rotationY = 0,
  
  lookDir = vec3(),
  forwardDir = vec3(),
  rightDir = vec3(),
  
  velocity = vec3(0, 0, 0),
  position = vec3(0.0, 3.5, -3.0);
  headOffset = vec3(0.0, 0.73, 0.0);
}


local TOOLS = {
  "add", "select", "remove"
}

local Editor = {
  voxelType = "wood",
  voxelColor = {1,1,1},
  tool = "add",
  isActive = true,
  gravity = true
};

function teleportPlayer(player, x, y, z)
    player.position:set(x,y,z);
    player.velocity:set(0,0,0);
    player.camera.position = player.position + player.headOffset;
end

function teleportPlayerToStart(player)
    local startBlock = state.grid.startBlock;
    teleportPlayer(Player1, startBlock[1], startBlock[2] + 2, startBlock[3] );
end

function setMouseControlCamera(toggle)
  love.mouse.setRelativeMode(toggle);
  state.mouseCamera = toggle;
end


function Editor.uiupdate()
    
    if (not Editor.isActive) then
      
      local editLevel = ui.button("Edit Level");
      if (editLevel) then
        Editor.isActive = true;
        setMouseControlCamera(false);
      end
      return;
    end
    
    local playLevelBtn, postLevelBtn;
    
    playLevelBtn = ui.button("Play Level");
    postLevelBtn = ui.button("Post Level");
    
    if (postLevelBtn) then
      postLevel(state.grid);
    end
    
    if (playLevelBtn) then
      --setMouseControlCamera(true);
      state.playLevelPressed = true;
      teleportPlayerToStart(Player1);
      Editor.isActive = false;
    end
    
    if (postLevel) then
      
    end
    
    ui.section("Edit Voxels", {
      defaultOpen = true,
    }, function()
      
      Editor.tool = ui.radioButtonGroup('Tool', Editor.tool, TOOLS, {
        onChange = function(tool)
          
          if (tool ~= "select") then
            Editor.selection = nil;
          end
        end      
      });
      
      Editor.voxelType = ui.dropdown("Voxel Type", Editor.voxelType, Voxel.BLOCK_TYPES, {
        
        onChange = function(typeName)
        
          if (Editor.selection) then
            Editor.selection.voxel.type = Voxel.BLOCK_INDEX_MAP[typeName];
            local c = Editor.selection.center;
            Voxel.insert(state.grid, Editor.selection.voxel, c[1], c[2], c[3]); 
          end
          
        end
      
      });
      
      --[[
      Editor.voxelColor = {ui.colorPicker("Paint Color", Editor.voxelColor[1], Editor.voxelColor[2], Editor.voxelColor[3], 1, {
          enableAlpha = false,
          onChange = function(clr)
            
            if (Editor.selection) then
              Editor.selection.voxel.color = {clr.r, clr.g, clr.b};
              local c = Editor.selection.center;
              Voxel.insert(state.grid, Editor.selection.voxel, c[1], c[2], c[3]);
            end
         end
        })
      };]]
        
      
      if (Editor.selection) then
        
        local c = Editor.selection.center;
        ui.markdown("x="..c[1].." y="..c[2].." z="..c[3]);
        
      end
    
    end);
    
     ui.section("Editor Camera", {
      defaultOpen = true,
    }, function()
      
      Editor.gravity = ui.checkbox("Gravity", Editor.gravity);
      
      end);
    
end

function Editor.selectVoxel(voxel, x, y, z)
  
   Editor.selection = {
      center = {x, y, z},
      voxel = voxel
   };
   
   Editor.voxelType = Voxel.BLOCK_TYPES[voxel.type];
   Editor.voxelColor = voxel.color or {1,1,1};

end

function Editor.mousepressed(x, y, button)

  if (state.playLevelPressed) then
    state.playLevelPressed = false;
    setMouseControlCamera(true);
  end
  
  if (not Editor.isActive) then
    return;
  end

  local w, h = love.graphics.getDimensions();
  local mx, my = love.mouse.getPosition();
  local ray = GFX.pickRay(mx / w, my / h);
  local vox, pos, normal = Voxel.traceRay(state.grid, ray);
  local round = cpml.utils.round;
  
  if (vox) then
    local c = vox.center;

    if (Editor.tool == "select") then
      
      Editor.selectVoxel(vox, c[1], c[2], c[3]);
      
      return;
    end
    
    if (button == 1) then
      local vx, vy, vz = round(c[1] + normal.x), round(c[2] + normal.y), round(c[3] + normal.z);
      
      if (vy < 0) then return end;
      
      local oldPos = Player1.position;
  
      local pbb = {
        ll = {oldPos.x - PLAYER_SIZE.x, oldPos.y - PLAYER_SIZE.y, oldPos.z - PLAYER_SIZE.z},
        ur = {oldPos.x + PLAYER_SIZE.x, oldPos.y + PLAYER_SIZE.y, oldPos.z + PLAYER_SIZE.z}
      };
      
      local vbb = {
        ll = {vx - 0.5, vy - 0.5, vz - 0.5},
        ur = {vx + 0.5, vy + 0.5, vz + 0.5}
      };
      
      if (Voxel.intersectAABBs(pbb, vbb)) then
        return;
      end
      
      Voxel.insert(state.grid, 
        {
          type = Voxel.BLOCK_INDEX_MAP[Editor.voxelType],
          --color = Editor.voxelColor
        }, vx, vy, vz);
        
    elseif (button == 2) then
      local vx, vy, vz = c[1], c[2], c[3];
      Voxel.remove(state.grid, vx, vy, vz);  
    end
    
  end  

  
end

function love.mousepressed(...)
  
  Editor.mousepressed(...);

end

function castle.uiupdate()
  
  Editor.uiupdate();

end



function renderScene(player)

  GFX.setCanvas3D(state.canvas3D)
  love.graphics.setDepthMode( "lequal", true );
  love.graphics.clear(0,0,0,0, true, true);
  
  love.graphics.setColor(1,1,1,1);
  local w, h = love.graphics.getDimensions();
  local t = love.timer.getTime();
  love.graphics.setMeshCullMode("back");
  
  GFX.setShader(Shaders.Tiles);
  GFX.setCameraView(player.camera.position, player.camera.look_at, UP);
  GFX.setCameraPerspective(player.camera.fovy, w/h, CAMERA_NEAR_CLIP, CAMERA_FAR_CLIP);
  
  Voxel.draw(state.grid)
  
    
  GFX.setShader(GFX.Shader.Default);
  if (Editor.selection) then
    local c = Editor.selection.center;
  
    gt = mat4();
    gt[13], gt[14], gt[15] = c[1], c[2], c[3];
    gt[1], gt[6], gt[11] = 1.1, 1.1, 1.1;
    GFX.drawMesh(Mesh.Cube, gt);
  end
  
  love.graphics.setShader();
  love.graphics.setCanvas();
end

local newPos = vec3();
local voxPos = vec3();
local voxDelta = vec3();
local voxPosDelta = vec3();
local moveVelocity = vec3();

local Y_BIAS = 0.0;


local PostProcess = {
  effect = "none"
}

function PostProcess.render()
  local w, h = love.graphics.getDimensions();
  
  if (PostProcess.effect == "fadeIn") then
    
    local t = (love.timer.getTime() - PostProcess.startTime) / PostProcess.duration;
    --love.graphics.setColor(1, 0.75, 0.0, 1.0 - t); 
    
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
    
    if (t >= 1) then
      PostProcess.effect = "none";
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

end

function PostProcess.playWinOverlay()

  PostProcess.effect = "fadeIn";
  PostProcess.color = {1, 0.7, 0.5, 1.0};
  PostProcess.startTime = love.timer.getTime();
  PostProcess.duration = 4;
  PostProcess.startAlpha = 0.5;
  PostProcess.text = "Win";
  
end



function collidePlayer(player, dt, collisionData)
    
  newPos =  player.position + (player.velocity * dt);
  local oldPos = player.position;
  
  local opbb = {
    ll = {oldPos.x - PLAYER_SIZE.x, oldPos.y - PLAYER_SIZE.y, oldPos.z - PLAYER_SIZE.z},
    ur = {oldPos.x + PLAYER_SIZE.x, oldPos.y + PLAYER_SIZE.y, oldPos.z + PLAYER_SIZE.z}
  };
  
  local npbb = {
    ll = {newPos.x - PLAYER_SIZE.x, newPos.y - PLAYER_SIZE.y, newPos.z - PLAYER_SIZE.z},
    ur = {newPos.x + PLAYER_SIZE.x, newPos.y + PLAYER_SIZE.y, newPos.z + PLAYER_SIZE.z}
  };
  
  local epbb = {
    ll = {newPos.x - PLAYER_SIZE.x * 2, newPos.y - PLAYER_SIZE.y * 2, newPos.z - PLAYER_SIZE.z * 2},
    ur = {newPos.x + PLAYER_SIZE.x * 2, newPos.y + PLAYER_SIZE.y * 2, newPos.z + PLAYER_SIZE.z * 2}
  };
  
  player.standing = false;
  
  local standingVoxels = {
  }
  
  local vgrid = state.grid;
  
  local standVoxelCount = 0;
  
  local rubberType = Voxel.BLOCK_INDEX_MAP["rubber"];
  local fireType = Voxel.BLOCK_INDEX_MAP["fire"];
  local waterType = Voxel.BLOCK_INDEX_MAP["water"];
  local endType = Voxel.BLOCK_INDEX_MAP["end"];
  
  Voxel.intersectGridAABB(state.grid, epbb, function(v)
    
    local c = v.center;
    
    local vbb = {
      ll = {c[1] - 0.5, c[2] - 0.5, c[3] - 0.5},
      ur = {c[1] + 0.5, c[2] + 0.5, c[3] + 0.5}
    };
    
    if (not Voxel.intersectAABBs(npbb, vbb)) then
      return;
    end
    
    if (v.type == endType) then
      collisionData.finish = true;
    end
    
    if (v.type == waterType) then
      collisionData.water = true;
      return;
    end
    
    if (v.type == fireType) then
      if (Voxel.overlapAABBs(npbb, vbb) > 0.1) then
        collisionData.fire = true;
      end
      return;
    end
    
    local vup1, vup2      = Voxel.isSolid(vgrid, c[1], c[2] + 1, c[3]), Voxel.isSolid(vgrid, c[1], c[2] + 2, c[3]);
    local vdown1, vdown2  = Voxel.isSolid(vgrid, c[1], c[2] - 1, c[3]), Voxel.isSolid(vgrid, c[1], c[2] - 2, c[3]);
    local vforward, vback = Voxel.isSolid(vgrid, c[1], c[2], c[3] + 1), Voxel.isSolid(vgrid, c[1], c[2], c[3] - 1);
    local vleft, vright   = Voxel.isSolid(vgrid, c[1] - 1, c[2], c[3]), Voxel.isSolid(vgrid, c[1] + 1, c[2], c[3]);
    
    local epsi = 0.0001;
    
    local bounce = 0;
    if (v.type == rubberType) then
      bounce = 1.0;
    end
    

    
    --Y Negative
    if (opbb.ll[2] >= vbb.ur[2] and npbb.ll[2] < vbb.ur[2] and not vup1 and not vup2) then
      local bounceAmt =  math.min(-player.velocity.y * bounce, MAX_BOUNCE);
      player.velocity.y = math.max(bounceAmt, player.velocity.y);
      newPos.y = vbb.ur[2] + PLAYER_SIZE.y + epsi;
      player.standing = true;
      standVoxelCount = standVoxelCount + 1;
      standingVoxels[standVoxelCount] = v;
    --Z Positive
    elseif (opbb.ur[3] <= vbb.ll[3] and npbb.ur[3] > vbb.ll[3] and not vback) then
      local bounceAmt =  math.max(-player.velocity.z * bounce, -MAX_BOUNCE);
      player.velocity.z = math.min(bounceAmt, player.velocity.z);
      newPos.z = vbb.ll[3] - PLAYER_SIZE.z - epsi;  
    --X Positive
    elseif (opbb.ur[1] <= vbb.ll[1] and npbb.ur[1] > vbb.ll[1] and not vleft) then
      local bounceAmt =  math.max(-player.velocity.x * bounce, -MAX_BOUNCE);
      player.velocity.x = math.min(bounceAmt, player.velocity.x);
      newPos.x = vbb.ll[1] - PLAYER_SIZE.x - epsi;  
    --Y Positive
    elseif (opbb.ur[2] <= vbb.ll[2] and npbb.ur[2] > vbb.ll[2] and not vdown1 and not vdown2) then
      local bounceAmt =  math.max(-player.velocity.y * bounce, -MAX_BOUNCE);
      player.velocity.y = math.min(bounceAmt, player.velocity.y);
      newPos.y = vbb.ll[2] - PLAYER_SIZE.y - epsi;   
    -- Z Negative
    elseif (opbb.ll[3] >= vbb.ur[3] and npbb.ll[3] < vbb.ur[3] and not vforward) then
      local bounceAmt =  math.min(-player.velocity.z * bounce, MAX_BOUNCE);
      player.velocity.z = math.max(bounceAmt, player.velocity.z);
      newPos.z = vbb.ur[3] + PLAYER_SIZE.z + epsi;
    --X Negative
    elseif (opbb.ll[1] >= vbb.ur[1] and npbb.ll[1] < vbb.ur[1] and not vright) then
      local bounceAmt =  math.min(-player.velocity.x * bounce, MAX_BOUNCE);
      player.velocity.x = math.max(bounceAmt, player.velocity.x);
      newPos.x = vbb.ur[1] + PLAYER_SIZE.x + epsi;
    end  
      
    npbb = {
      ll = {newPos.x - PLAYER_SIZE.x, newPos.y - PLAYER_SIZE.y, newPos.z - PLAYER_SIZE.z},
      ur = {newPos.x + PLAYER_SIZE.x, newPos.y + PLAYER_SIZE.y, newPos.z + PLAYER_SIZE.z}
    };
    --[[
    voxPos:set(center[1], center[2] - Y_BIAS, center[3]);
    --newPos.y = newPos.y - 0.4;
    voxDelta = voxPos - newPos;
    
    local whichAxis = voxDelta:to_axis();  
    local pm = vec3.dot(voxDelta, player.velocity);

    if (pm > 0) then
      --Subtract velocity projected on voxel direction
      player.velocity = player.velocity - (voxDelta * pm);
      
      --Position player exactly along axis
      voxPos.y = voxPos.y + Y_BIAS;
      player.position[whichAxis] = (voxPos - voxDelta * (PLAYER_SIZE[whichAxis] + 0.5))[whichAxis];
    end
    ]]
    
    
    
    --hits = true;

  end);

  collisionData.standingVoxels = standingVoxels;
  player.position = newPos;

end

function updatePlayerOrientation(player, inputs, dt)

  player.rotationX = player.rotationX + inputs.look.x * dt * 2;
  player.rotationY = cpml.utils.clamp(player.rotationY + inputs.look.y * dt * 2, -math.pi * 0.45, math.pi * 0.45);

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

function getPlayerDamping(player, collisionData, inputs, dt)

  local airDamp = 0.1 * dt;
  local groundDamp = 0.2 * dt;
  local speed = PLAYER_SPEED * dt;

  
  local onIce = true;
  
  for i, v in pairs(collisionData.standingVoxels) do
    if (v.type ~= Voxel.BLOCK_INDEX_MAP["ice"]) then
      onIce = false;
    end
  end
  
  
  if (player.standing) then
    if (vec3.len(inputs.move) < 0.01) then
      groundDamp = math.min(1.0, 15 * dt);
      if (onIce) then
        groundDamp = 0.2 * dt;
      end
    else -- Running then
      
      local runVelocity = (player.forwardDir * inputs.move.z * speed) + (player.rightDir * inputs.move.x * speed);
      
      local dampAngle = vec3.dot(vec3.normalize(player.velocity), vec3.normalize(runVelocity));
      local dampAngle = 1.0-cpml.utils.clamp((dampAngle * 0.5 + 0.5), 0.0, 1.0);
      groundDamp = cpml.utils.lerp(0.2 * dt, 15 * dt, dampAngle);
    
    end
  end

  
  if (player.inWater) then
    airDamp = WATER_DAMPING * dt;
    groundDamp = WATER_DAMPING * dt;
  end
  
  if (player.flying) then
    airDamp = math.min(0.1, 10 * dt);
    groundDamp = math.min(0.1, 10 * dt);
  end
  
  return vec3(groundDamp, airDamp, groundDamp);
end

function updatePlayer(player, inputs, dt)

  dt = math.min(dt, 0.1); 

  updatePlayerOrientation(player, inputs, dt);
  
  local speed = PLAYER_SPEED * dt;
  
  --player.camera.position = player.camera.position + (inputs.move * (dt * 5));
  
  --newPos = player.camera.position + (player.lookDir * inputs.move.z * speed) + (player.rightDir * inputs.move.x * speed);
  
  
  --Different Movement Circumstances
  player.flying = false;
  if (Editor.isActive and not Editor.gravity) then
    player.velocity = player.velocity + (player.lookDir * inputs.move.z * speed * 5) + (player.rightDir * inputs.move.x * speed * 5);
    player.flying = true;
  elseif (player.inWater) then
    player.velocity = player.velocity + (WATER_GRAVITY * dt);
    player.velocity = player.velocity + (player.lookDir * inputs.move.z * speed) + (player.rightDir * inputs.move.x * speed);
  else
    player.velocity = player.velocity + (GRAVITY * dt);
    player.velocity = player.velocity + (player.forwardDir * inputs.move.z * speed) + (player.rightDir * inputs.move.x * speed);
  end
  
  if (inputs.jump == 1 and player.standing) then
    player.velocity = player.velocity + (JUMP);
    --player.velocity.y = (JUMP * dt).y;
  end
  
  if (inputs.jump == 1 and player.inWater) then
    player.velocity.y = math.max(1.0, player.velocity.y);
  end
    
  local collisionData = {};
  
  
  --Collide player with voxels
  collidePlayer(player, dt, collisionData);
 
  local damping = getPlayerDamping(player, collisionData, inputs, dt);
  
  --Todo Make safe
  player.velocity = player.velocity - (player.velocity * damping);
  
  --Move Player
  player.camera.position = player.position + player.headOffset;
  player.camera.look_at = player.lookDir + player.camera.position;
  
  --Handle edge cases
  if (collisionData.fire) then
    PostProcess.playFireOverlay();
    teleportPlayerToStart(player);
  end
  
  if (player.position.y < WORLD_Y_MIN) then
    PostProcess.playFallOverlay();
    teleportPlayerToStart(player);
  end
  
  if (collisionData.finish) then
    PostProcess.playWinOverlay();
  end
  
  player.inWater = collisionData.water;
  
end

local inputs = {
  jump = 0;
};
function getInputs()
    
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
    inputs.look.x = 1;
  end
  
  if (love.keyboard.isDown("right")) then
    inputs.look.x = -1;
  end
  
  if (love.keyboard.isDown("up")) then
    inputs.look.y = 1;
  end
  
  if (love.keyboard.isDown("down")) then
    inputs.look.y = -1;
  end
  
  if (love.keyboard.isDown("space")) then
    inputs.jump = 1;
  end
  
  if (love.keyboard.isDown("escape")) then
    setMouseControlCamera(false);
  end
  
  if (state.mouseCamera) then
    
    inputs.look.x = inputs.look.x - (state.mouseDeltaX  or 0) * 0.15;
    inputs.look.y = inputs.look.y - (state.mouseDeltaY  or 0) * 0.15;
  
    state.mouseDeltaX = 0;
    state.mouseDeltaY = 0;
  end
  
  return inputs;
  
end

local dpiSave = -1;

local DELTA_SAVE = 0;

function client.update(dt)
  
  DELTA_SAVE = (DELTA_SAVE + dt) * 0.5;
  
  if (dpiSave ~= love.window.getDPIScale()) then
    dpiSave = love.window.getDPIScale();
    w,h = love.graphics.getDimensions();
    client.resize();
  end

  updatePlayer(Player1, getInputs(), dt);

end

function love.mousemoved(x, y, dx, dy)
    
  if (state.mouseCamera) then
    state.mouseDeltaX = (state.mouseDeltaX or 0) + dx;
    state.mouseDeltaY = (state.mouseDeltaY or 0) + dy;
  end

end

function client.resize()
  local w, h = love.graphics.getDimensions();
  state.canvas3D = GFX.createCanvas3D(w, h);
end

function client.draw()
  renderScene(Player1);
  
  love.graphics.draw(state.canvas3D.color, 0, 0,0, 1, 1);
 
 
  --Debug print framerates
  --love.graphics.setColor(1,0,0,1);
  --love.graphics.print(DELTA_SAVE, 0, 0);
  
  PostProcess.render();
end

function client.load()
  love.resize();
  
  state.grid = Voxel.newStarterGrid();
  teleportPlayerToStart(Player1);
  
end


function castle.postopened(post)
  
    loadPost(post.data);

end

function loadPost(data)

  state.grid = data.grid;
  Voxel.reload(state.grid);

end

function postLevel()
  
  local safeGrid = {};
  
  for k, v in pairs(state.grid) do
    safeGrid[k] = v;
  end
  
  safeGrid.meshes = nil;
  
  data.grid = safeGrid;

  network.async(function()
    castle.post.create {
        message = 'Level 1',
        media = 'capture',
        data = data
    }
    end)

end


