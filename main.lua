--castle://localhost:4000/main.lua

local client = love;
GFX = require("gfx3D");
cpml = GFX.cpml;
Mesh = require("mesh_util");
local Shaders = require("shaders");
local Voxel = require("voxel");
local mat4 = cpml.mat4;
local vec3 = cpml.vec3;
local vec2 = cpml.vec2;
local ui = castle.ui;

local cos = math.cos;
local sin = math.sin;

local UP = vec3(0.0, 1.0, 0.0);
local CAMERA_NEAR_CLIP = 0.1;
local CAMERA_FAR_CLIP = 100.0;
local GRAVITY = UP * -15;
local JUMP = UP * 600;

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
  headOffset = vec3(0.0, 0.75, 0.0);
}


local BLOCK_TYPES = {
  "start", "wood", "brick", "grass"
}

local BLOCK_INDEX_MAP = {}

for i, v in pairs(BLOCK_TYPES) do
  BLOCK_INDEX_MAP[v] = i-1;
end

local TOOLS = {
  "add", "select", "remove"
}

local Editor = {
  voxelType = "wood",
  voxelColor = {1,1,1},
  tool = "add"
};

function Editor.uiupdate()
    
    ui.section("Edit Voxels", {
      defaultOpen = true,
    }, function()
      
      Editor.voxelType = ui.dropdown("Voxel Type", Editor.voxelType, BLOCK_TYPES);
      
      Editor.voxelColor = {ui.colorPicker("Color", Editor.voxelColor[1], Editor.voxelColor[2], Editor.voxelColor[3], 1, {
          enableAlpha = false
        })};
        
      Editor.tool = ui.radioButtonGroup('Tool', Editor.tool, TOOLS, {
        onChange = function(tool)
          
          if (tool ~= "select") then
            Editor.selection = nil;
          end
        end      
      });
      
      if (Editor.selection) then
        
        local c = Editor.selection.center;
        ui.markdown("x="..c[1].." y="..c[2].." z="..c[3]);
        
      end
    
    end);
    
end

function Editor.selectVoxel(x, y, z)
  
   Editor.selection = {
      center = {x, y, z}
  };

end

function Editor.renderScene(player)
  
  return;
  
  --[[
  if (not Editor.selection) then
    return
  end
  
  GFX.setCanvas3D(state.canvas3D)
  love.graphics.setDepthMode( "lequal", true );
  --love.graphics.clear(0,0,0,0, true, true);
  
  love.graphics.setColor(1,1,1,1);
  local w, h = love.graphics.getDimensions();

  love.graphics.setMeshCullMode("back");
  
  GFX.setShader(GFX.Shader.Default);
  GFX.setCameraView(player.camera.position, player.camera.look_at, UP);
  GFX.setCameraPerspective(player.camera.fovy, w/h, CAMERA_NEAR_CLIP, CAMERA_FAR_CLIP);
  
  local c = Editor.selection.center;
  
  gt = mat4();
  gt[13], gt[14], gt[15] = c[1], c[2], c[3];
  gt[1], gt[6], gt[11] = 1.1, 1.1, 1.1;
  GFX.drawMesh(Mesh.Cube, gt);

  
  GFX.setShader();
  love.graphics.setCanvas();
]]

end

function Editor.mousepressed(x, y, button)

  local w, h = love.graphics.getDimensions();
  local mx, my = love.mouse.getPosition();
  local ray = GFX.pickRay(mx / w, my / h);
  local vox, pos, normal = Voxel.traceRay(state.grid, ray);
  local round = cpml.utils.round;
  
  if (vox) then
    local c = vox.center;

    if (Editor.tool == "select") then
      
      Editor.selectVoxel(c[1], c[2], c[3]);
      
      return;
    end
    
    if (button == 1) then
      local vx, vy, vz = round(c[1] + normal.x), round(c[2] + normal.y), round(c[3] + normal.z);
      Voxel.insert(state.grid, 
        {
          type = BLOCK_INDEX_MAP[Editor.voxelType],
          color = Editor.voxelColor
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


local vgrid = Voxel.newGrid();
state.grid = vgrid;

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
  
  local gt = mat4();
  gt[14] = -5;
  
  GFX.drawMesh(Mesh.PlaneY, gt);
  
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

local axisSize = {x = 0.3, y = 0.8, z = 0.3};
local Y_BIAS = 0.0;



function collidePlayer(player, dt)
    
  newPos =  player.position + (player.velocity * dt);
  local oldPos = player.position;
  
  local opbb = {
    ll = {oldPos.x - axisSize.x, oldPos.y - axisSize.y, oldPos.z - axisSize.z},
    ur = {oldPos.x + axisSize.x, oldPos.y + axisSize.y, oldPos.z + axisSize.z}
  };
  
  local npbb = {
    ll = {newPos.x - axisSize.x, newPos.y - axisSize.y, newPos.z - axisSize.z},
    ur = {newPos.x + axisSize.x, newPos.y + axisSize.y, newPos.z + axisSize.z}
  };
  
  local epbb = {
    ll = {newPos.x - axisSize.x * 2, newPos.y - axisSize.y * 2, newPos.z - axisSize.z * 2},
    ur = {newPos.x + axisSize.x * 2, newPos.y + axisSize.y * 2, newPos.z + axisSize.z * 2}
  };
  
  player.standing = false;
  
  Voxel.intersectGridAABB(vgrid, epbb, function(v)
    
    local c = v.center;
    
    local vbb = {
      ll = {c[1] - 0.5, c[2] - 0.5, c[3] - 0.5},
      ur = {c[1] + 0.5, c[2] + 0.5, c[3] + 0.5}
    };
    
    if (not Voxel.intersectAABBs(npbb, vbb)) then
      return;
    end
    
    local vup1, vup2      = Voxel.get(vgrid, c[1], c[2] + 1, c[3]), Voxel.get(vgrid, c[1], c[2] + 2, c[3]);
    local vdown1, vdown2  = Voxel.get(vgrid, c[1], c[2] - 1, c[3]), Voxel.get(vgrid, c[1], c[2] - 2, c[3]);
    local vforward, vback = Voxel.get(vgrid, c[1], c[2], c[3] + 1), Voxel.get(vgrid, c[1], c[2], c[3] - 1);
    local vleft, vright   = Voxel.get(vgrid, c[1] - 1, c[2], c[3]), Voxel.get(vgrid, c[1] + 1, c[2], c[3]);
    
    local epsi = 0.0001;
    
    --Y Negative
    if (opbb.ll[2] >= vbb.ur[2] and npbb.ll[2] < vbb.ur[2] and not vup1 and not vup2) then
      player.velocity.y = math.max(0, player.velocity.y);
      newPos.y = vbb.ur[2] + axisSize.y + epsi;
      player.standing = true;
    --Z Positive
    elseif (opbb.ur[3] <= vbb.ll[3] and npbb.ur[3] > vbb.ll[3] and not vback) then
      player.velocity.z = math.min(0, player.velocity.z);
      newPos.z = vbb.ll[3] - axisSize.z - epsi;  
    --X Positive
    elseif (opbb.ur[1] <= vbb.ll[1] and npbb.ur[1] > vbb.ll[1] and not vleft) then
      player.velocity.x = math.min(0, player.velocity.x);
      newPos.x = vbb.ll[1] - axisSize.x - epsi;  
    --Y Positive
    elseif (opbb.ur[2] <= vbb.ll[2] and npbb.ur[2] > vbb.ll[2] and not vdown1 and not vdown2) then
      player.velocity.y = math.min(0, player.velocity.y);
      newPos.y = vbb.ll[2] - axisSize.y - epsi;   
    -- Z Negative
    elseif (opbb.ll[3] >= vbb.ur[3] and npbb.ll[3] < vbb.ur[3] and not vforward) then
      player.velocity.z = math.max(0, player.velocity.z);
      newPos.z = vbb.ur[3] + axisSize.z + epsi;
    --X Negative
    elseif (opbb.ll[1] >= vbb.ur[1] and npbb.ll[1] < vbb.ur[1] and not vright) then
      player.velocity.x = math.max(0, player.velocity.x);
      newPos.x = vbb.ur[1] + axisSize.x + epsi;
    end  
      
    npbb = {
      ll = {newPos.x - axisSize.x, newPos.y - axisSize.y, newPos.z - axisSize.z},
      ur = {newPos.x + axisSize.x, newPos.y + axisSize.y, newPos.z + axisSize.z}
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
      player.position[whichAxis] = (voxPos - voxDelta * (axisSize[whichAxis] + 0.5))[whichAxis];
    end
    ]]
    
    
    
    --hits = true;

  end);

  
  player.position = newPos;

end

function updatePlayerInputs(player, inputs, dt)

  dt = math.min(dt, 0.1); 

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
  
  local speed = 8 * dt;
  
  --player.camera.position = player.camera.position + (inputs.move * (dt * 5));
  
  --newPos = player.camera.position + (player.lookDir * inputs.move.z * speed) + (player.rightDir * inputs.move.x * speed);
  
  player.velocity = player.velocity + (GRAVITY * dt);
  player.velocity = player.velocity + (player.forwardDir * inputs.move.z * speed) + (player.rightDir * inputs.move.x * speed);
  
  if (inputs.jump == 1 and player.standing) then
    player.velocity = player.velocity + (JUMP * dt);
  end
  
  --inputs.jump = math.max(0.0, inputs.jump - dt * 1.5);
  
  
  collidePlayer(player, dt);
 
  local groundDamp = 1.0 * dt;
  
  if (player.standing) then
    if (vec3.len(inputs.move) < 0.01) then
      groundDamp = math.min(1.0, 15 * dt);
    end
  end

  
  --Todo Make safe
  player.velocity = player.velocity - (player.velocity * vec3(groundDamp, 0.1 * dt, groundDamp));
  
  player.camera.position = player.position + player.headOffset;
  player.camera.look_at = player.lookDir + player.camera.position;

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
  
  return inputs;
  
end

local dpiSave = -1;

function client.update(dt)
  
  if (dpiSave ~= love.window.getDPIScale()) then
    dpiSave = love.window.getDPIScale();
    w,h = love.graphics.getDimensions();
    client.resize();
  end

  updatePlayerInputs(Player1, getInputs(), dt);

end

function love.resize()
  local w, h = love.graphics.getDimensions();
  state.canvas3D = GFX.createCanvas3D(w, h);
end

function client.draw()
  renderScene(Player1);
  Editor.renderScene(Player1);
  love.graphics.draw(state.canvas3D.color, 0, 0,0, 1, 1);
end

function client.load()
  love.resize();
end


