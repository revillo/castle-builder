local MeshUtil = {};

POSITION_ATTRIBUTE = {"VertexPosition", "float", 3};
UV_ATTRIBUTE = {"VertexTexCoord", "float", 2};

BASIC_ATTRIBUTES = {
  POSITION_ATTRIBUTE,
  UV_ATTRIBUTE
}


MeshUtil.makePlaneY = function(w, h)
  
  return love.graphics.newMesh(
    BASIC_ATTRIBUTES,
  {
    {
      w/2, 0, -h/2,
      1, 0
    },
    {
      -w/2, 0, -h/2,
      0, 0
    },
    {
      w/2, 0, h/2,
      1, 1
    },
    {
      -w/2, 0, h/2,
      0, 1
    }
    
  }, "strip", "static");


end

MeshUtil.PlaneY = MeshUtil.makePlaneY(10, 10);

MeshUtil.PlaneZ = (function(w, h)
    
  return love.graphics.newMesh(
    BASIC_ATTRIBUTES,
  {
    {
      -w/2, -h/2, 0,
      0, 0
    },
    {
      w/2, -h/2, 0,
      1, 0
    },
    {
      w/2, h/2, 0,
      1, 1
    },
    {
      -w/2, h/2, 0,
      0, 1
    }
    
  }, "fan", "static");

end)(1,1);
  




MeshUtil.makeCubeFace = function(a, b, c, d)
  
  return {
    {a[1], a[2], a[3], 0, 0},
    {b[1], b[2], b[3], 1, 0},
    {c[1], c[2], c[3], 1, 1},
    
    {a[1], a[2], a[3], 0, 0},
    {c[1], c[2], c[3], 1, 1},
    {d[1], d[2], d[3], 0, 1}
  };

end

MeshUtil.Cube = (function()
  local x0, x1 = 0.5, -0.5;
  local y0, y1 = -0.5, 0.5;
  local z0, z1 = -0.5, 0.5;
  
  local a = {x0, y0, z0};
  local b = {x1, y0, z0};
  local c = {x1, y1, z0};
  local d = {x0, y1, z0};
  
  local e = {x0, y0, z1};
  local f = {x1, y0, z1};
  local g = {x1, y1, z1};
  local h = {x0, y1, z1};
  
  local faces = {
    MeshUtil.makeCubeFace(a, b, c, d),
    MeshUtil.makeCubeFace(b, f, g, c),
    MeshUtil.makeCubeFace(d, c, g, h),  
    MeshUtil.makeCubeFace(e, a, d, h),
    MeshUtil.makeCubeFace(f, e, h, g),
    MeshUtil.makeCubeFace(a, e, f, b)
  };
  
  
  local verts = {};
  local index = 1;
  
  for f = 1, 6 do
      for v = 1, 6 do
        verts[index] = faces[f][v]; 
        index = index + 1;
      end    
  end
  
   return love.graphics.newMesh(
      BASIC_ATTRIBUTES, verts, "triangles", "static"
    );
      
end)()

MeshUtil.mergeCubes = function(cubeList, first, last)
  
  local faceMap = {};
  
  local checkMap = function(h, o)
    
    if (faceMap[h]) then
      faceMap[h] = nil;
    else
      faceMap[h] = o;
    end
  end
 
  
  for i = first, last do
    
    local cube = cubeList[i];
    local center = cube.center;
    local x, y, z = center[1], center[2], center[3];
    
    local x0, x1 = 0.5 + x, -0.5 + x;
    local y0, y1 = -0.5 + y, 0.5 + y;
    local z0, z1 = -0.5 + z, 0.5 + z;
       
    local a = {x0, y0, z0};
    local b = {x1, y0, z0};
    local c = {x1, y1, z0};
    local d = {x0, y1, z0};
    
    local e = {x0, y0, z1};
    local f = {x1, y0, z1};
    local g = {x1, y1, z1};
    local h = {x0, y1, z1};
      
    checkMap(tostring(x).."+_"..y.."_"..z, {e, a, d, h});
    checkMap(tostring(x-1).."+_"..y.."_"..z, {b, f, g, c});
    
    checkMap(tostring(x).."_"..tostring(y-1).."+_"..z, {e, f, b, a});
    checkMap(tostring(x).."_"..tostring(y).."+_"..z, {d, c, g, h});
    
    checkMap(tostring(x).."_"..tostring(y).."_"..tostring(z-1).."+", {a, b, c, d});
    checkMap(tostring(x).."_"..tostring(y).."_"..tostring(z).."+", {f, e, h, g});
  
  end
  
  local verts = {};
  local index = 1;
  local mcf = MeshUtil.makeCubeFace;
  
  for f, o in pairs(faceMap) do
    if (o) then
      local face = mcf(o[1], o[2], o[3], o[4]);
       for v = 1, 6 do
        verts[index] = face[v]; 
        index = index + 1;
      end     
    end
  end
  
  return love.graphics.newMesh(
      BASIC_ATTRIBUTES, verts, "triangles", "static"
    );
end

return MeshUtil;