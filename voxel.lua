local Voxel = {};
local vec3 = cpml.vec3;

local Matrix = {};

local MATRIX_MAX_COUNT = 256;

Voxel.BLOCK_TYPES = {
  "start", "end", "wood", "brick", "ice", "rubber", "lava", "water", "tile", "info", "leaves", "stone"
}

Voxel.LEVELS = {
  "blank", "practice0", "practice1", "practice2"
}

Voxel.BLOCK_PROPERTIES = {
  
  start = {
    offset = {0,0}
  },
  
  ["end"] = {
    offset = {4, 0},
    collide = function(collisionData, voxel) 
      collisionData.finish = true;
      collisionData.nextLevel = voxel.nextLevel;
    end,
    
    uiupdate = function(voxel)
      voxel.nextLevel = ui.textInput("Next Level", voxel.nextLevel or "");
    end
  },
  
  wood = {
    offset = {1, 1}
  },
  
  brick = {
    offset = {2, 0}
  },
  
  tile = {
    offset = {3, 1}
  },
  
  rubber = {
    offset = {0, 8},
    bounciness = 1,
  },
  
  ice = {
    offset = {5, 1},
    friction = 0.1
  },
  
  lava = {
    offset = {7, 0},
    collide = function(collisionData, voxel, pbb, vbb)
      if (Voxel.overlapAABBs(pbb, vbb) > 0.1) then
        collisionData.fire = true;
      end
    end,
    fluid = true
  },
  
  water = {
    offset = {0, 1},
    color = {0, 1, 1, 0.7},
    collide = function(collisionData) 
      collisionData.water = true;
    end,
    transparent = true,
    fluid = true
  },
  
  leaves = {
    
    offset = {2,2}
  
  },
  
  
  stone = {
    
    offset = {4,2}
  
  },
  
  info = {
    offset = {0, 2},
    nearby = function(collisionData, voxel, pbb, vbb)
        
      if (Voxel.intersectAABBs(pbb, Voxel.expandAABB(vbb, {0.1, 0.1, 0.1}))) then
        collisionData.info = voxel.msg or "...";
      end
      
    end,
    
    uiupdate = function(voxel)
    
      voxel.msg = ui.textArea("Message", voxel.msg or "...", {
        rows = 4
      })

    end
  },

}

function Voxel.getPropertyForType(typeIndex)
  return Voxel.BLOCK_PROPERTIES[Voxel.BLOCK_TYPES[typeIndex]];
end



Voxel.BLOCK_INDEX_MAP = {}

for i, v in pairs(Voxel.BLOCK_TYPES) do
  Voxel.BLOCK_INDEX_MAP[v] = i;
end

local Images = {
  tiles = love.graphics.newImage('tiles2.png'),
  tilesBump = love.graphics.newImage('tiles2.png', {mipmaps = false})
}

Images.tilesBump:setFilter("nearest", "linear");
--Images.tilesBump:setMipmapFilter("linear");

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

function Voxel.newBlankGrid()
  
  local waterMatrix = {};
  local matrix = {};
   local startType = Voxel.BLOCK_INDEX_MAP["start"];
  local woodType = Voxel.BLOCK_INDEX_MAP["wood"];
  local endType = Voxel.BLOCK_INDEX_MAP["end"];
 
  
  
  Matrix.insert(matrix, {type = startType}, 0, 21, 0);
  Matrix.insert(matrix, {type = endType}, 0, 21, 2);
  Matrix.insert(matrix, {type = woodType}, 0, 20, 0);
  Matrix.insert(matrix, {type = woodType}, 0, 20, 1);
  Matrix.insert(matrix, {type = woodType}, 0, 20, 2);
  
  return {
    matrices = {waterMatrix, matrix},
    startBlock = {0, 21, 0},
    endBlock = {0, 21, 2},
    matrixIndex = 2,
    matrixVoxelCount = 5,
    dirtyMeshes = {[1] = false, [2] = true}
  }

end

function Voxel.newStarterGrid()
  
  local cubeList = {};
  local cubeListIndex = 0;
  
  local tileType = Voxel.BLOCK_INDEX_MAP["tile"];
  local waterType = Voxel.BLOCK_INDEX_MAP["water"];
  local lavaType = Voxel.BLOCK_INDEX_MAP["lava"];
 local startType = Voxel.BLOCK_INDEX_MAP["start"];
  local infoType = Voxel.BLOCK_INDEX_MAP["info"];
  local endType = Voxel.BLOCK_INDEX_MAP["end"];
  
  for x = 1, 16 do for z = 1, 16 do
      cubeListIndex = cubeListIndex + 1;

      cubeList[cubeListIndex] = {
        center = {x - 8, 10, z - 8},
        type = tileType
      };
      
  end end
  
  cubeListIndex = cubeListIndex + 1;
  
  cubeList[cubeListIndex] = {
    center = {0, 11, -5},
    type = startType
  };
  
  cubeListIndex = cubeListIndex + 1;
  cubeList[cubeListIndex] = {
    center = {3, 11, 5},
    type = endType,
    nextLevel = "practice1"
  }
  
  cubeListIndex = cubeListIndex + 1;
  cubeList[cubeListIndex] = {
    type = infoType,
    msg = [[Welcome to <1.0,0.6,0.3>Verticube<1,1,1>! 

Use <1.0,0.6,0.3>WASD<1,1,1> to move. 

Use the <1.0,0.6,0.3>MOUSE<1,1,1> or <1.0,0.6,0.3>ARROW KEYS<1,1,1> to look around.

Press <1.0,0.6,0.3>SPACE<1,1,1> to jump.]],

    center = {0, 11, -4};
  }
  
  cubeListIndex = cubeListIndex + 1;
  cubeList[cubeListIndex] = {
    type = infoType,
    msg = [[The goal is to get from the <1,1,0>START<1,1,1> block to the <1,0,0>END<1,1,1> block without dying.
    
Different block types have effects that can hinder or aid your journey, like rubber, ice, water, lava, etc...]],

    center = {0, 11, -2};
  }
  
   cubeListIndex = cubeListIndex + 1;
   cubeList[cubeListIndex] = {
    type = infoType,
    msg = [[In <1.0,0.6,0.3>EDIT MODE<1,1,1>, you can add, remove and modify blocks in the scene using the buttons on the right.

You can create your own levels and post them to <0.5,0.5,0.5>Castle<1,1,1> for others to play!]],

    center = {0, 11, 0};
  }
  
   cubeListIndex = cubeListIndex + 1;
   cubeList[cubeListIndex] = {
    type = infoType,
    msg = [[Touch the <1,0,0>END BLOCK<1,1,1> to advance to the next practice level. 
    
Each of these levels can be completed without needing to modify the blocks. (But don't let that stop you!)]],

    center = {0, 11, 2};
  }
  
    cubeListIndex = cubeListIndex + 1;
   cubeList[cubeListIndex] = {
    type = infoType,
    msg = [[Good Luck!]],

    center = {0, 11, 4};
  }
  
 local waterMatrix = {};
   

  
  local matrix = {};
  
  for i = 1, cubeListIndex do
  
    local center = cubeList[i].center;
    local x, y, z = center[1], center[2], center[3];
    cubeList[i].center = nil;
    Matrix.insert(matrix, cubeList[i], x, y, z);

  end
  
  --[[
  for i = 1, cubeListIndex do
  
    local center = cubeList[i].center;
    local x, y, z = center[1], center[2] + 1, center[3] + 10;
    Matrix.insert(waterMatrix, {
      type = waterType
    }, x, y, z);

  end
  ]]
  
   return {
    matrices = {waterMatrix, matrix},
    startBlock = {0, 11, -5},
    endBlock = {3, 11, 5},
    matrixIndex = 2,
    matrixVoxelCount = cubeListIndex,
    dirtyMeshes = {[1] = false, [2] = true}
  }
end

function Voxel.newPracticeGrid()
  
  local matrix = {};
  local waterMatrix = {};
  local vcount = 0;
  
  local startPos = {2, 20, 0};
  --lava bridge
  --startPos = {2, 23, 16};
  --ice bounce
  --startPos = {2, 28, 30};
  
  local endPos = {2, 28, -18};
  
  local waterType = Voxel.BLOCK_INDEX_MAP["water"];
  local iceType = Voxel.BLOCK_INDEX_MAP["ice"];
  local rubberType = Voxel.BLOCK_INDEX_MAP["rubber"];
  local tileType = Voxel.BLOCK_INDEX_MAP["tile"];
  local woodType = Voxel.BLOCK_INDEX_MAP["wood"];
  local brickType = Voxel.BLOCK_INDEX_MAP["brick"];
  local startType = Voxel.BLOCK_INDEX_MAP["start"];
  local endType = Voxel.BLOCK_INDEX_MAP["end"];
  local lavaType = Voxel.BLOCK_INDEX_MAP["lava"];
  local infoType = Voxel.BLOCK_INDEX_MAP["info"];
 
  function addCube(x, y, z, type, voxel)
    voxel = voxel or {type = type};
    voxel.type = type;
    
    if (type == waterType) then
      Matrix.insert(waterMatrix, voxel, x, y, z);
    else
      Matrix.insert(matrix, voxel, x, y, z);
      vcount = vcount + 1;
    end
  end
  
  function addBox(ll, ur, type)
    for x = ll[1], ur[1] do
    for y = ll[2], ur[2] do
    for z = ll[3], ur[3] do
      addCube(x, y, z, type);
    end end end
  end
  
  
  addBox({-2, 19, -1}, {6, 19, 20}, tileType);
  
  --Brick Stairs
  addCube(2, 20, 3, brickType);
  addBox({2, 20, 4}, {2, 21, 4}, brickType);
  addBox({2, 20, 5}, {2, 22, 5}, brickType);
  addBox({2, 20, 7}, {2, 22, 8}, brickType);
  addBox({2, 20, 11}, {2, 22, 11}, brickType);
  addBox({2, 20, 15}, {2, 22, 15}, brickType);
  
  
  --Lava bridge
  addBox({0, 21, 21}, {4, 21, 29}, lavaType);
  --addBox({2, 22, 16}, {2, 22, 30}, brickType);
  addBox({2, 22, 19}, {2, 22, 20},  brickType);
  addCube(3, 22, 20, infoType, {
  msg = [[If you fall into <1.0,0.4,0>lava BLOCKS<1,1,1> you'll have to start over!]]
  });
  addCube(0, 22, 23, brickType);
  addCube(4, 22, 26, brickType);

  --ceiling
  addBox({-1, 26, 20}, {5, 26, 30}, brickType);
  
  --Steps
  addBox({-1, 21, 20}, {-1, 25, 36}, brickType);
  addBox({5, 21, 20}, {5, 25, 36}, brickType);
  
  addBox({0, 21, 20}, {4, 21, 20}, brickType);

  --Water cave
  addBox({0, 22, 31}, {4, 30, 35}, waterType);
  --Water floor
  addBox({0, 21, 30}, {4, 21, 36}, brickType);
  --Back wall
  addBox({0, 22, 36}, {4, 30, 36}, brickType);
  
  addBox({-1, 26, 31}, {-1, 30, 36}, brickType);
  addBox({5, 26, 31}, {5, 30, 36}, brickType);
  
  --Ice Bounce
  addBox({-1, 27, 20}, {5, 27, 30}, iceType);
  --rubber walls
  addBox({-1, 28, 20}, {-1, 30, 30}, rubberType);
  addBox({5, 28, 20}, {5, 30, 30}, rubberType);

  addBox({0, 27, 10}, {4, 27, 14}, rubberType);
  addBox({-1, 27, -20}, {5, 27, -16}, brickType);
  addBox({-1, 27, -21}, {5, 29, -21}, brickType);
  
  --Bounce back
  --addBox({0, 17, -8}, {4, 17, -4}, rubberType);
  
  addCube(4, 28, 28, infoType, {
    msg = [[<0.8, 0.8, 1>ICE BLOCKS<1,1,1> are slippery! Slide across them to build up speed.

Hold <1,0.6,0.3>SPACE<1,1,1> when falling on a <1,0,0.7>RUBBER BLOCK<1,1,1> to bounce extra high!

Try to reach the <1,0,0>END BLOCK<1,1,1>!]]
  });
  addCube(startPos[1], startPos[2], startPos[3], startType);
  addCube(endPos[1], endPos[2], endPos[3], endType);
  
  return {
    matrices = {waterMatrix, matrix},
    startBlock = startPos,
    endBlock = endPos,
    matrixIndex = 2,
    matrixVoxelCount = vcount,
    dirtyMeshes = {[1] = true, [2] = true}
  } 
  
end

function Voxel.newPracticeGridDEP()
  
  local cubeList = {};
  local cubeListIndex = 0;
  local tileType = Voxel.BLOCK_INDEX_MAP["tile"];
  local brickType = Voxel.BLOCK_INDEX_MAP["brick"];
  local startType = Voxel.BLOCK_INDEX_MAP["start"];
  local endType = Voxel.BLOCK_INDEX_MAP["end"];
  local waterType = Voxel.BLOCK_INDEX_MAP["water"];
  local rubberType = Voxel.BLOCK_INDEX_MAP["rubber"];
  
  for x = 1, 16 do for z = 1, 16 do
      cubeListIndex = cubeListIndex + 1;

      cubeList[cubeListIndex] = {
        center = {x - 8, 0, z - 8},
        type = tileType
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
      return vox, {round(p.x), round(p.y), round(p.z)},  p, n;
    end
   
  end

 
  return nil, nil, nil;
  
  
end

function Voxel.isSolid(grid, x, y, z)

   local vox = Voxel.get(grid, x, y, z)
   
   return vox and Voxel.BLOCK_TYPES[vox.type] ~= "water" and Voxel.BLOCK_TYPES[vox.type] ~= "lava";
  
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
  
  voxel.center = nil;
  
  local props = Voxel.BLOCK_PROPERTIES[Voxel.BLOCK_TYPES[voxel.type]];
  
  if (voxel.type == Voxel.BLOCK_INDEX_MAP["start"]) then
    Voxel.remove(grid, grid.startBlock[1], grid.startBlock[2], grid.startBlock[3]);
    grid.startBlock = {x,y,z};
  end
  
  if (voxel.type == Voxel.BLOCK_INDEX_MAP["end"]) then
    Voxel.remove(grid, grid.endBlock[1], grid.endBlock[2], grid.endBlock[3]);
    grid.endBlock = {x, y, z};
  end
  
  if (props.transparent) then
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
      callback(voxel, {vx, vy, vz});
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



function Voxel.sortWater(grid)
  
  if (not grid.waterMeshData or grid.waterMeshData.numCenters == 0) then
    return;
  end
  
  local pos = GFX.getCameraPosition();
  local centers = grid.waterMeshData.centers;
  local temp = {0,0,0};
  

  for i = 1, grid.waterMeshData.numCenters do
    local center = centers[i].center;
    temp[1], temp[2], temp[3] = center[1] - pos[1], center[2] - pos[2], center[3] - pos[3];
    centers[i].distance = temp[1] * temp[1] + temp[2] * temp[2] + temp[3] * temp[3];  
  end
  
  function faceSorter(a, b)
    return a.distance > b.distance;
  end
  
  table.sort(centers, faceSorter);
  
  local waterMesh = grid.meshes[1];
  
  local newVerts = grid.waterMeshData.newVerts;
  local oldVerts = grid.waterMeshData.verts;
  
  for i = 1, grid.waterMeshData.numCenters do
    local vertIndex = centers[i].vertIndex;
    
    for v = 1, 6 do
        newVerts[(i-1) * 6 + v] = oldVerts[vertIndex + v - 1];
    end
    
  end
  
  waterMesh:setVertices(newVerts, 1);

end

local lastSortTime = -100;

function Voxel.draw(grid)
  
  grid.meshes = grid.meshes or {};
  --grid.waterMeshes = grid.waterMeshes or {};
  
  for i = 1, grid.matrixIndex do
    
    if (grid.dirtyMeshes[i]) then
       if (i == 1) then
          
        local verts, centers, numCenters;
        grid.meshes[i], verts, centers, numCenters = Matrix.makeMesh(grid.matrices[i], allPass, "static");  
        
        if (grid.meshes[i]) then
          grid.waterMeshData = {
            centers = centers,
            numCenters = numCenters,
            verts = verts,
            newVerts = {}
          }
          
          Voxel.sortWater(grid);
       end
                
       else
          
          grid.meshes[i] = Matrix.makeMesh(grid.matrices[i], allPass);  
    
          if (grid.meshes[i]) then
            grid.meshes[i]:setTexture(Images.tiles); 
          end
          
       end
       
      grid.dirtyMeshes[i] = nil;
    end
  
  end
  
  
  for i = 2,grid.matrixIndex do
    GFX.setUniform("bumpTex", Images.tilesBump);
    GFX.drawMesh(grid.meshes[i]);  
  end

  local now = love.timer.getTime();
  
  if (now - lastSortTime > 1.0) then
    Voxel.sortWater(grid);
    --print("sorting water");
    lastSortTime = now;
  end
  
  --local endt = love.timer.getTime();
  
  --print(1000 * (endt - now));
  
  local waterMesh = grid.meshes[1];
  GFX.setShader(Shaders.WaterTiles);
  love.graphics.setBlendMode("alpha");
  love.graphics.setMeshCullMode("none");
  GFX.setUniform("waterTile", true);
  GFX.drawMesh(waterMesh);  

  
end

function Matrix.unpostify(safeMatrix)
  
  local matrix = {};

  for x in pairs(safeMatrix) do
  for y in pairs(safeMatrix[x]) do
  for z, cube in pairs(safeMatrix[x][y]) do
    
    if (type(cube) == "number") then
      Matrix.insert(matrix, {type=cube}, tonumber(x), tonumber(y), tonumber(z));
    else   
      Matrix.insert(matrix, cube, tonumber(x), tonumber(y), tonumber(z));
    end
  end end end
  
  return matrix;
end

function Voxel.unpostify(grid)
  
  for i, matrix in pairs(grid.matrices) do
    
    grid.matrices[i] = Matrix.unpostify(matrix);
  
  end

  return grid;
  
end

function Matrix.postify(matrix)
  
  local safeMatrix = {};
  for x in pairs(matrix) do
    local xs = tostring(x);
    safeMatrix[xs] = {};
  for y in pairs(matrix[x]) do
    local ys = tostring(y);
    safeMatrix[xs][ys] = {};
  for z, cube in pairs(matrix[x][y]) do
  
    local keycount = 0;
    for k,v in pairs(cube) do
      keycount = keycount + 1;
    end
    
    if (keycount == 1) then
     safeMatrix[xs][ys][tostring(z)] = cube.type;
    else
     safeMatrix[xs][ys][tostring(z)] = cube;
    end 
  end end end
  
  return safeMatrix;

end

function Voxel.postify(grid)
  
 local safeGrid = {};
  
  for k, v in pairs(grid) do
    safeGrid[k] = v;
  end
  
  safeGrid.meshes = nil;
  safeGrid.matrices = {};
  
  for i, matrix in pairs(grid.matrices) do
    safeGrid.matrices[i] = Matrix.postify(matrix);
  end
  
  safeGrid.waterMeshData = nil;
  
  return safeGrid;

end

function Voxel.expandAABB(aabb, amounts)
  
  return {
    ll = {aabb.ll[1] - amounts[1], aabb.ll[2] - amounts[2], aabb.ll[3] - amounts[3]},
    ur = {aabb.ur[1] + amounts[1], aabb.ur[2] + amounts[2], aabb.ur[3] + amounts[3]}
  };

end

function Voxel.makeAABB(center, extents)
  
  return {
    ll = {center[1] - extents[1], center[2] - extents[2], center[3] - extents[3]},
    ur = {center[1] + extents[1], center[2] + extents[2], center[3] + extents[3]}
  }
  
end

function Voxel.reload(grid)
  
  for i = 1, grid.matrixIndex do
    grid.dirtyMeshes[i] = true;
  end

end

Matrix.makeMesh = function(matrix, typePass, batchMode)
  
  local faceMap =  {};
  
  local checkMap = function(h, o)
    if (faceMap[h]) then
      faceMap[h] = nil;
    else
      faceMap[h] = o
    end
  end
 
  
  for x in pairs(matrix) do
  for y in pairs(matrix[x]) do
  for z, cube in pairs(matrix[x][y]) do
    
    if (cube and typePass(cube.type)) then
      
      local properties = Voxel.getPropertyForType(cube.type);

      local center = {x, y, z};
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
      
      checkMap(tostring(x).."+_"..y.."_"..z, {e, a, d, h, ou, ov, 0});
      checkMap(tostring(x-1).."+_"..y.."_"..z, {b, f, g, c, ou, ov, 1});
      
      checkMap(tostring(x).."_"..tostring(y-1).."+_"..z, {e, f, b, a, ou, ov, 2});
      checkMap(tostring(x).."_"..tostring(y).."+_"..z, {d, c, g, h, ou, ov, 3});
      
      checkMap(tostring(x).."_"..tostring(y).."_"..tostring(z-1).."+", {a, b, c, d, ou, ov, 4});
      checkMap(tostring(x).."_"..tostring(y).."_"..tostring(z).."+", {f, e, h, g, ou, ov, 5});
    end
  end end end
  
  local verts = {};
  local centerMap = {};
  local index = 1;
  local centerIndex = 1;
  local mcf = Mesh.makeCubeFace;
  
  for hash, o in pairs(faceMap) do
    if (o) then
      local face = mcf(o[1], o[2], o[3], o[4], o[5], o[6], o[7]);
      
      local a, b = o[1], o[3];
      
      centerMap[centerIndex] = {
        center = {(a[1] + b[1]) * 0.5, (a[2] + b[2]) * 0.5, (a[3] + b[3]) * 0.5},
        vertIndex = index
      }      
      
      centerIndex = centerIndex + 1;
      
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
      BASIC_ATTRIBUTES, verts, "triangles", batchMode or "static"
    ), verts, centerMap, centerIndex-1;
end

return Voxel;