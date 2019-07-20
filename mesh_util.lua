local MeshUtil = {};

POSITION_ATTRIBUTE = {"VertexPosition", "float", 3};
UV_ATTRIBUTE = {"VertexTexCoord", "float", 2};
--COLOR_ATTRIBUTE = {"VertexColor", "float", 4};
FACE_INDEX_ATTRIBUTE = {"FaceIndex", "float", 1};

BASIC_ATTRIBUTES = {
  POSITION_ATTRIBUTE,
  UV_ATTRIBUTE,
  FACE_INDEX_ATTRIBUTE
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
  




MeshUtil.makeCubeFace = function(a, b, c, d, ou, ov, faceIndex)
  
  ou = ou or 0;
  ov = ov or 0;
  --clr = clr or {1,1,1,1};
  --[[
  return {
    {a[1], a[2], a[3], 0 + ou, 1 + ov, clr[1], clr[2], clr[3], clr[4]},
    {b[1], b[2], b[3], 1 + ou, 1 + ov, clr[1], clr[2], clr[3], clr[4]},
    {c[1], c[2], c[3], 1 + ou, 0 + ov, clr[1], clr[2], clr[3], clr[4]},
    
    {a[1], a[2], a[3], 0 + ou, 1 + ov, clr[1], clr[2], clr[3], clr[4]},
    {c[1], c[2], c[3], 1 + ou, 0 + ov, clr[1], clr[2], clr[3], clr[4]},
    {d[1], d[2], d[3], 0 + ou, 0 + ov, clr[1], clr[2], clr[3], clr[4]}
  };
  ]]
  
 return {
    {a[1], a[2], a[3], 0 + ou, 1 + ov, faceIndex},
    {b[1], b[2], b[3], 1 + ou, 1 + ov, faceIndex},
    {c[1], c[2], c[3], 1 + ou, 0 + ov, faceIndex},
    
    {a[1], a[2], a[3], 0 + ou, 1 + ov, faceIndex},
    {c[1], c[2], c[3], 1 + ou, 0 + ov, faceIndex},
    {d[1], d[2], d[3], 0 + ou, 0 + ov, faceIndex}
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


return MeshUtil;