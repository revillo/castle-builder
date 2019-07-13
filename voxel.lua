local Voxel = {};
local vec3 = cpml.vec3;

local Matrix = {};

local MATRIX_MAX_COUNT = 256;

Voxel.BLOCK_TYPES = {
  "start", "end", "wood", "brick", "ice", "rubber", "fire", "water", "grass"
}

Voxel.BLOCK_PROPERTIES = {
  
  start = {
    offset = {0,0}
  },
  
  ["end"] = {
    offset = {4, 0}
  },
  
  wood = {
    offset = {1, 0}
  },
  
  brick = {
    offset = {2, 0}
  },
  
  grass  = {
    offset = {3, 0}
  },
  
  rubber = {
    offset = {5, 0},
    bounciness = 10,
    jelly = true,
    color = {1, 0.3, 0.7, 0.9}
  },
  
  ice = {
    offset = {6, 0},
    friction = 0.1
  },
  
  fire = {
    offset = {7, 0}
  },
  
  water = {
    offset = {0, 1},
    color = {0, 1, 1, 0.7},
    jelly = true
  }

}

Voxel.BLOCK_INDEX_MAP = {}

for i, v in pairs(Voxel.BLOCK_TYPES) do
  Voxel.BLOCK_INDEX_MAP[v] = i;
end

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

function Voxel.newStarterGrid()
  
  local cubeList = {};
  local cubeListIndex = 0;
  
  local grassType = Voxel.BLOCK_INDEX_MAP["grass"];
 local startType = Voxel.BLOCK_INDEX_MAP["start"];
  local endType = Voxel.BLOCK_INDEX_MAP["end"];
  
  for x = 1, 16 do for z = 1, 16 do
      cubeListIndex = cubeListIndex + 1;

      cubeList[cubeListIndex] = {
        center = {x - 8, 0, z - 8},
        type = grassType
      };
      
  end end
  
  cubeListIndex = cubeListIndex + 1;
  
  cubeList[cubeListIndex] = {
    center = {0, 1, -5},
    type = startType
  };
  
  cubeListIndex = cubeListIndex + 1;
  cubeList[cubeListIndex] = {
    center = {3, 1, 5},
    type = endType;
  }
  
  
 local waterMatrix = {};
   

  
  local matrix = {};
  
  for i = 1, cubeListIndex do
  
    local center = cubeList[i].center;
    local x, y, z = center[1], center[2], center[3];
    Matrix.insert(matrix, cubeList[i], x, y, z);

  end
  
   return {
    matrices = {waterMatrix, matrix},
    startBlock = {0, 1, -5},
    endBlock = {3, 1, 5},
    matrixIndex = 2,
    matrixVoxelCount = cubeListIndex,
    dirtyMeshes = {[1] = false, [2] = true}
  }
end

function Voxel.newTestGrid()
  
  local cubeList = {};
  local cubeListIndex = 0;
  local grassType = Voxel.BLOCK_INDEX_MAP["grass"];
  local brickType = Voxel.BLOCK_INDEX_MAP["brick"];
  local startType = Voxel.BLOCK_INDEX_MAP["start"];
  local endType = Voxel.BLOCK_INDEX_MAP["end"];
  local waterType = Voxel.BLOCK_INDEX_MAP["water"];
  local rubberType = Voxel.BLOCK_INDEX_MAP["rubber"];
  
  for x = 1, 16 do for z = 1, 16 do
      cubeListIndex = cubeListIndex + 1;

      cubeList[cubeListIndex] = {
        center = {x - 8, 0, z - 8},
        type = grassType
      };
      
  end end
  
  for x = 7, 10 do for z = 7, 10 do
    
    cubeListIndex = cubeListIndex + 1;

    cubeList[cubeListIndex] = {
      center = {x - 5, z - 6, z - 7},
      type = brickType
    };
  
  end end
  
  cubeListIndex = cubeListIndex + 1;
  
  cubeList[cubeListIndex] = {
    center = {0, 1, -5},
    type = startType
  };
  
  cubeListIndex = cubeListIndex + 1;
  cubeList[cubeListIndex] = {
    center = {3, 1, 5},
    type = endType;
  }
  
  local waterMatrix = {};
  
  for x = 1, 5 do for y = 1, 5 do for z = 1, 5 do
    
    local cube = {
      center = {x - 8, y, z},
      type = waterType;
    }
    
    Matrix.insert(waterMatrix, cube, x - 8, y, z);
  
  end end end
  
  local matrix = {};
  
  for i = 1, cubeListIndex do
  
    local center = cubeList[i].center;
    local x, y, z = center[1], center[2], center[3];
    Matrix.insert(matrix, cubeList[i], x, y, z);

  end

  
  return {
    matrices = {waterMatrix, matrix},
    startBlock = {0, 1, -5},
    endBlock = {3, 1, 5},
    matrixIndex = 2,
    matrixVoxelCount = cubeListIndex,
    dirtyMeshes = {[1] = true, [2] = true}
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
    local vox = Voxel.get(grid, p.x, p.y, p.z);
    if (vox) then
      return vox, p, n;
    end
   
  end

 
  return nil, nil, nil;
  
  
end

function Voxel.isSolid(grid, x, y, z)

   local vox = Voxel.get(grid, x, y, z)
   
   return vox and Voxel.BLOCK_TYPES[vox.type] ~= "water" and Voxel.BLOCK_TYPES[vox.type] ~= "fire";
  
end

function Voxel.get(grid, x, y, z)
  
  local rx, ry, rz = round(x), round(y), round(z);
  
  for i = 1, grid.matrixIndex do
    local vox = Matrix.get(grid.matrices[i], rx, ry, rz);
    if (vox) then return vox; end;
  end
  
  return nil;
  
end

function Voxel.remove(grid, x, y, z)
  
  for i = 1, grid.matrixIndex do
    local vox = Matrix.get(grid.matrices[i], x, y, z);
    if (vox) then 
      Matrix.insert(grid.matrices[i], nil, x, y, z);
      grid.dirtyMeshes[i] = true
    end
  end
  
  return nil;
  
end

function Voxel.insert(grid, voxel, x, y, z)
  
  voxel.center = {x,y,z};
  
  if (voxel.type == Voxel.BLOCK_INDEX_MAP["start"]) then
    Voxel.remove(grid, grid.startBlock[1], grid.startBlock[2], grid.startBlock[3]);
    grid.startBlock = {x,y,z};
  end
  
  if (voxel.type == Voxel.BLOCK_INDEX_MAP["end"]) then
    Voxel.remove(grid, grid.endBlock[1], grid.endBlock[2], grid.endBlock[3]);
    grid.endBlock = {x, y, z};
  end
  
  if (voxel.type == Voxel.BLOCK_INDEX_MAP["water"] or voxel.type == Voxel.BLOCK_INDEX_MAP["rubber"]) then
    Matrix.insert(grid.matrices[1], voxel, x, y, z);
    grid.dirtyMeshes[1] = true;
    return;
  end
  
  
  if (grid.matrixVoxelCount > MATRIX_MAX_COUNT) then
    grid.matrixIndex = grid.matrixIndex + 1;
    grid.matrices[grid.matrixIndex] = {};
    grid.matrixVoxelCount = 0;
  end
  
  Matrix.insert(grid.matrices[grid.matrixIndex], voxel, x, y, z);
  grid.matrixVoxelCount = grid.matrixVoxelCount + 1;
  
  grid.dirtyMeshes[grid.matrixIndex] = true;

end


function Voxel.intersectAABBs(a, b) 
  
  if (a.ll[1] > b.ur[1] or a.ll[2] > b.ur[2] or a.ll[3] > b.ur[3] or
      a.ur[1] < b.ll[1] or a.ur[2] < b.ll[2] or a.ur[3] < b.ll[3]) then
        return false;
  end

  return true;
  
end

function Voxel.volumeAABB(aabb)
  
  return (aabb.ur[1] - aabb.ll[1]) * (aabb.ur[2] - aabb.ll[2]) * (aabb.ur[3] - aabb.ll[3]);

end

function Voxel.overlapAABBs(a, b)
  
  if (Voxel.intersectAABBs(a, b)) then
    
    local ll = {math.max(a.ll[1], b.ll[1]), math.max(a.ll[2], b.ll[2]), math.max(a.ll[3], b.ll[3])};
    local ur = {math.min(a.ur[1], b.ur[1]), math.min(a.ur[2], b.ur[2]), math.min(a.ur[3], b.ur[3])};
    
    return Voxel.volumeAABB({ll = ll, ur = ur});
  
  end
  
  return 0;

end

function Matrix.intersectGridAABB(matrix, aabb, callback) 
 
  local x0, x1 = aabb.ll[1], aabb.ur[1];
  local y0, y1 = aabb.ll[2], aabb.ur[2];
  local z0, z1 = aabb.ll[3], aabb.ur[3];
  
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

function Voxel.intersectGridAABB(grid, aabb, callback) 
  
  for i = 1, grid.matrixIndex do
    Matrix.intersectGridAABB(grid.matrices[i], aabb, callback);
  end

end

local WATER_TYPE = Voxel.BLOCK_INDEX_MAP["water"];
local waterPass = function(type)
  return type == WATER_TYPE;
end

local waterFail = function(type)
  return type ~= WATER_TYPE;
end

local allPass = function(type) return true end;

function Voxel.draw(grid)
  
  grid.meshes = grid.meshes or {};
  --grid.waterMeshes = grid.waterMeshes or {};
  
  for i = 1, grid.matrixIndex do
    
    if (grid.dirtyMeshes[i]) then
      grid.meshes[i] = Matrix.makeMesh(grid.matrices[i], allPass);
      if (grid.meshes[i]) then
        grid.meshes[i]:setTexture(Images.tiles);
      end
      
      grid.dirtyMeshes[i] = nil;
    end
  
  end
  
  
  for i = 2,grid.matrixIndex do
    GFX.drawMesh(grid.meshes[i]);  
  end

  
  local waterMesh = grid.meshes[1];
  
  GFX.setShader(Shaders.WaterTiles);

  love.graphics.setBlendMode("alpha");
  love.graphics.setMeshCullMode("front");
  GFX.setUniform("waterTile", true);
  GFX.drawMesh(waterMesh);  
  love.graphics.setMeshCullMode("back");
  GFX.drawMesh(waterMesh);  
  GFX.setUniform("waterTile", false);

end

function Voxel.reload(grid)
  
  for i = 1, grid.matrixIndex do
    grid.dirtyMeshes[i] = true;
  end

end

Matrix.makeMesh = function(matrix, typePass, faceMap)
  
  faceMap = faceMap or {};
  
  local checkMap = function(h, o)
    if (faceMap[h]) then
      faceMap[h] = nil;
    else
      faceMap[h] = o;
    end
  end
 
  
  for x in pairs(matrix) do
  for y in pairs(matrix[x]) do
  for z, cube in pairs(matrix[x][y]) do
    
    if (cube and typePass(cube.type)) then
      
      local properties = Voxel.BLOCK_PROPERTIES[Voxel.BLOCK_TYPES[cube.type]];

      local center = cube.center;
      local color = cube.color or properties.color or {1,1,1,1};
      local x, y, z = center[1], center[2], center[3];
      local halfSize = 0.5;
      
      local x0, x1 = halfSize + x, -halfSize + x;
      local y0, y1 = -halfSize + y, halfSize + y;
      local z0, z1 = -halfSize + z, halfSize + z;
         
      local a = {x0, y0, z0};
      local b = {x1, y0, z0};
      local c = {x1, y1, z0};
      local d = {x0, y1, z0};
      
      local e = {x0, y0, z1};
      local f = {x1, y0, z1};
      local g = {x1, y1, z1};
      local h = {x0, y1, z1};
      
      local ou, ov = properties.offset[1], properties.offset[2];
      
      checkMap(tostring(x).."+_"..y.."_"..z, {e, a, d, h, ou, ov, color});
      checkMap(tostring(x-1).."+_"..y.."_"..z, {b, f, g, c, ou, ov, color});
      
      checkMap(tostring(x).."_"..tostring(y-1).."+_"..z, {e, f, b, a, ou, ov, color});
      checkMap(tostring(x).."_"..tostring(y).."+_"..z, {d, c, g, h, ou, ov, color});
      
      checkMap(tostring(x).."_"..tostring(y).."_"..tostring(z-1).."+", {a, b, c, d, ou, ov, color});
      checkMap(tostring(x).."_"..tostring(y).."_"..tostring(z).."+", {f, e, h, g, ou, ov, color});
    end
  end end end
  
  local verts = {};
  local index = 1;
  local mcf = Mesh.makeCubeFace;
  
  for f, o in pairs(faceMap) do
    if (o) then
      local face = mcf(o[1], o[2], o[3], o[4], o[5], o[6], o[7]);
       for v = 1, 6 do
        verts[index] = face[v]; 
        index = index + 1;
      end     
    end
  end
  
  if (index == 1) then
    return nil;
  end
  
  return love.graphics.newMesh(
      BASIC_ATTRIBUTES, verts, "triangles", "static"
    ), faceMap;
end

return Voxel;