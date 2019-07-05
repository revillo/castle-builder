local Voxel = {};
local vec3 = cpml.vec3;

local Matrix = {};
local Images = {
  tiles = love.graphics.newImage('tiles.png', {mipmaps = true});
}
Images.tiles:setFilter("nearest", "nearest");


function Matrix.insert(matrix, voxel, x, y, z)
  
  matrix[x] = matrix[x] or {};
  matrix[x][y] = matrix[x][y] or {};
  matrix[x][y][z] = voxel;
   
end

function Matrix.get(matrix, x, y, z) 
  
  if (not matrix[x]) then return nil end;
  if (not matrix[x][y]) then return nil end;
  return matrix[x][y][z];

end

local round = cpml.utils.round;


function Matrix.contains(matrix, x, y, z)
  
  local x, y, z = round(x), round(y), round(z);
  local vox = Matrix.get(matrix, x, y, z);
  return vox;
  
end

function Voxel.newGrid()
  
  local cubeList = {};
  local cubeListIndex = 0;

  for x = 1, 16 do for z = 1, 16 do
      cubeListIndex = cubeListIndex + 1;

      cubeList[cubeListIndex] = {
        center = {x - 8, 0, z - 8},
        type = 3
      };
      
  end end
  
  for x = 7, 10 do for z = 7, 10 do
    
    cubeListIndex = cubeListIndex + 1;

    cubeList[cubeListIndex] = {
      center = {x - 5, z - 6, z - 7},
      type = 2
    };
  
  end end
  
  local matrix = {};
  
  for i = 1, cubeListIndex do
  
    local center = cubeList[i].center;
    local x, y, z = center[1], center[2], center[3];
    Matrix.insert(matrix, cubeList[i], x, y, z);

  end

  return {
    matrix = matrix
  }
  
end

local min = math.min;
local sign = function (x) return x / math.abs(x) end;

local function dc(v, d)
  
  local t;
  if (d > 0.0) then
    t = (round(v) + 0.5 - v) / d;
  elseif (d < 0.0) then
    t = ((round(v) - 0.5) - v) / d;
  else 
    t = 100.0;
  end
  
  if (t == 0) then
    t = 100.0;
  end
  
  return t;
  
end

local t3pos = vec3();
local t3ds = vec3();
local t3nrm = vec3();

local function advanceRay(p, d)

  t3ds:set(dc(p.x, d.x), dc(p.y, d.y), dc(p.z, d.z));
  
  if (t3ds.x < t3ds.y and t3ds.x < t3ds.z) then
    t = t3ds.x;
    t3nrm:set(-sign(d.x), 0.0, 0.0);
  elseif (t3ds.y < t3ds.z) then
    t = t3ds.y;
    t3nrm:set(0.0, -sign(d.y), 0.0);
  else
    t = t3ds.z;
    t3nrm:set(0.0, 0.0, -sign(d.z));
  end
  
  local tStep = math.min(1.0, t) + 0.001;
  p.x = p.x + d.x * (tStep);
  p.y = p.y + d.y * (tStep);
  p.z = p.z + d.z * (tStep);
  
  return p, t3nrm;

end

function Voxel.traceRay(grid, ray)
  
  local o = ray.origin;
  local d = ray.direction;
  local t = 0.0;
  
  t3pos:set(o.x, o.y, o.z);
  
  for i = 1, 100 do
    
    local p, n = advanceRay(t3pos, d);
    local vox = Matrix.contains(grid.matrix, p.x, p.y, p.z);
    if (vox) then
      return vox, p, n;
    end
   
  end
 
  return nil, nil, nil;
  
end

function Voxel.get(grid, x, y, z)
  
  return Matrix.get(grid.matrix, x, y, z);
  
end

function Voxel.remove(grid, x, y, z)
  
  Matrix.insert(grid.matrix, nil, x, y, z);
  grid.meshDirty = true;

end

function Voxel.insert(grid, voxel, x, y, z)
  
  voxel.center = {x,y,z};
  
  Matrix.insert(grid.matrix, voxel, x, y, z);
  
  grid.meshDirty = true;

end

function Voxel.draw(grid)
  
  if (not grid.mesh or grid.meshDirty) then
    grid.mesh = Mesh.mergeChunk(grid.matrix);
    grid.mesh:setTexture(Images.tiles);
    grid.meshDirty = false;
  end
  
  GFX.drawMesh(grid.mesh);  

end

function Voxel.intersectAABBs(a, b) 
  
  if (a.ll[1] > b.ur[1] or a.ll[2] > b.ur[2] or a.ll[3] > b.ur[3] or
      a.ur[1] < b.ll[1] or a.ur[2] < b.ll[2] or a.ur[3] < b.ll[3]) then
        return false;
  end

  return true;
  
end

function Voxel.intersectGridAABB(grid, aabb, callback) 
  
  local x0, x1 = aabb.ll[1], aabb.ur[1];
  local y0, y1 = aabb.ll[2], aabb.ur[2];
  local z0, z1 = aabb.ll[3], aabb.ur[3];
  
  local matrix = grid.matrix;
  local get = Matrix.get;
  
  for vx = round(x0), round(x1) do
  for vy = round(y0), round(y1) do
  for vz = round(z0), round(z1) do
    
    local voxel = get(matrix, vx, vy, vz);
    if (voxel) then
      callback(voxel);
    end
  end end end

end


return Voxel;