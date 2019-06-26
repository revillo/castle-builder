local Voxel = {};

function Voxel.insert(grid, voxel, x, y, z)
  
  grid[x] = grid[x] or {};
  grid[x][y] = grid[x][y] or {};
  grid[x][y][z] = voxel;
   
end

function Voxel.get(grid, x, y, z) 
  
  if (not grid[x]) then return nil end;
  if (not grid[x][y]) then return nil end;
  return grid[x][y][z];

end

function Voxel.newGrid()
  
  local cubeList = {};
  local cubeListIndex = 0;

  for x = 1, 10 do for z = 1, 10 do
      cubeListIndex = cubeListIndex + 1;

      cubeList[cubeListIndex] = {
        center = {x - 3, 0, z - 3},
      };
  end end
  
  local grid = {};
  
  for i = 1, cubeListIndex do
  
    local center = cubeList[i].center;
    local x, y, z = center[1], center[2], center[3];
    Voxel.insert(grid, cubeList[i], x, y, z);

  end

  return {
    
    list = cubeList,
    length = cubeListIndex,
    grid = grid
  
  }
  
end

local round = function(x) return math.floor(x + 0.5) end;

function Voxel.gridIntersectAABB(grid, aabb, callback) 
  
  local x0, x1 = aabb.ll[1], aabb.ur[1];
  local y0, y1 = aabb.ll[2], aabb.ur[2];
  local z0, z1 = aabb.ll[3], aabb.ur[3];
  
  for vx = round(x0), round(x1) do
  for vy = round(y0), round(y1) do
  for vz = round(z0), round(z1) do
    
    local voxel = Voxel.get(grid, vx, vy, vz);
    if (voxel) then
      callback(voxel);
    end
  end end end

end


return Voxel;