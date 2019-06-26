--castle://localhost:4000/main.lua

local client = love;
local GFX = require("gfx3D");
local Mesh = require("mesh_util");
local Shaders = require("shaders");
local Voxel = require("voxel");
local cpml = GFX.cpml;
local mat4 = cpml.mat4;
local vec3 = cpml.vec3;
local vec2 = cpml.vec2;
local ui = castle.ui;

local cos = math.cos;
local sin = math.sin;

local UP = vec3(0.0, 1.0, 0.0);
local CAMERA_NEAR_CLIP = 0.2;
local CAMERA_FAR_CLIP = 100.0;


local Player1 = {
  
  camera = {
    position = vec3(0.0, 2.0, -5.0),
    look_at = vec3(0.0, 2.0, 0.0),
    fovy = 70
  },
  
  rotationX = 0,
  rotationY = 0,
  lookDir = vec3(),
  forwardDir = vec3(),
  rightDir = vec3()

}

local Images = {
  tiles = love.graphics.newImage('tiles.png', {mipmaps = true});
}

Images.tiles:setFilter("linear", "nearest");

local Viewport = {
}

function createViewport()
  local w, h = love.graphics.getDimensions();
  
  local dpi = love.window.getDPIScale();
  Viewport.colorCanvas = love.graphics.newCanvas(w , h );
 -- Viewport.depthCanvas = love.graphics.newCanvas(w, h, {format="depth24"});
  Viewport.colorCanvas:setFilter("linear", "linear");
 
end



function love.resize()
  createViewport();
end

local state = {

}

local vgrid = Voxel.newGrid();

state.cubeMerge = Mesh.mergeCubes(vgrid.list, 1, 100);
state.cubeMerge:setTexture(Images.tiles);

function renderScene(player)
  
  love.graphics.setCanvas({
    {Viewport.colorCanvas},
    depth = true,
    stencil = true
--    depthstencil = Viewport.depthCanvas
  });
  
  love.graphics.setDepthMode( "lequal", true );
  love.graphics.clear(0,0,0,0, true, true);
  
  love.graphics.setColor(1,1,1,1);
  local w, h = love.graphics.getDimensions();
  local t = love.timer.getTime();
  love.graphics.setMeshCullMode("back");
  
  GFX.setShader(Shaders.Tiles);
  GFX.setCameraView(player.camera.position, player.camera.look_at, UP);
  GFX.setCameraPerspective(player.camera.fovy, w/h, CAMERA_NEAR_CLIP, CAMERA_FAR_CLIP);
  
  
  GFX.drawMesh(state.cubeMerge);  
  
  local gt = mat4();
  gt[14] = -5;
  
  GFX.drawMesh(Mesh.PlaneY, gt);
  
  love.graphics.setShader();
  love.graphics.setCanvas();
end

local newPos = vec3();
function updatePlayerInputs(player, inputs, dt)

  player.rotationX = player.rotationX + inputs.look.x * dt * 2;
  player.rotationY = player.rotationY + inputs.look.y * dt * 2;

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
  
  local speed = dt * 5;
  
  --player.camera.position = player.camera.position + (inputs.move * (dt * 5));
  newPos = player.camera.position + (player.lookDir * inputs.move.z * speed) + (player.rightDir * inputs.move.x * speed);

  local hits = false;
  
  local aabb = {
    ll = {newPos.x - 0.4, newPos.y - 0.4, newPos.z - 0.4},
    ur = {newPos.x + 0.4, newPos.y + 0.4, newPos.z + 0.4}
  };
  
  Voxel.gridIntersectAABB(vgrid.grid, aabb, function(v)
    hits = true;
  end);
  
  if (not hits) then
    player.camera.position = newPos;
  end
  
  player.camera.look_at = player.lookDir + player.camera.position;
end

function getInputs()
  
  local inputs = {};
  
  inputs.move = vec3();
  inputs.look = vec2();
  
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
  
  
  return inputs;
  
end

local dpiSave = -1;

function client.update(dt)
  
if (dpiSave ~= love.window.getDPIScale()) then
  dpiSave = love.window.getDPIScale();
  w,h = love.graphics.getDimensions();
  client.resize(w, h);
end

  updatePlayerInputs(Player1, getInputs(), dt);

end

function client.draw()
  
  local w, h = love.graphics.getDimensions();

  renderScene(Player1);
  
  
  love.graphics.draw(Viewport.colorCanvas, 0, 0,0, 1, 1);
  
end

function client.load()
  
  createViewport();
 
end


