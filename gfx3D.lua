local Shader = {

  
  Default = (function()
    
    local vert = [[
      
      uniform mat4 mvp; 
    
      vec4 position(mat4 transform_projection, vec4 vertex_position)
      {
          vec4 p = mvp * vertex_position;
          p.y = -p.y;
          return p;
      }
    
    ]]
    
    local frag = [[
      
        vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
        {
          return vec4(texture_coords, 0.0, 1.0);
        }
    
    ]]
    
    return love.graphics.newShader(vert, frag);
  end)()


}


local cpml = require("lib/cpml")
local mat4 = cpml.mat4;
local activeShader = Shader.Default;

local viewMatrixTemp = mat4();
local viewMatrix = mat4();
local projectionMatrix = mat4();

local mvp = mat4();
local mvpt = mat4();
local mv = mat4();
local mi = mat4();

function viewLook(out, eye, look_at, up)
	local z_axis = (eye - look_at):normalize()
	local x_axis = up:cross(z_axis):normalize()
	local y_axis = z_axis:cross(x_axis):normalize()
 
  out[1] = x_axis.x
	out[2] = x_axis.y
	out[3] = x_axis.z
	out[4] = 0
	out[5] = y_axis.x
	out[6] = y_axis.y
	out[7] = y_axis.z
	out[8] = 0
	out[9] = z_axis.x
	out[10] = z_axis.y
	out[11] = z_axis.z
	out[12] = 0
	out[13] = eye.x
	out[14] = eye.y
	out[15] = eye.z
	out[16] = 1

  return out
end

return {
  Shader = Shader, 

  cpml = cpml,
  
  setShader = function(shader) 
    love.graphics.setShader(shader);
    activeShader = shader;
  end,
  
  setCameraView = function(eye, look_at, up)

    viewLook(viewMatrixTemp, eye, look_at, up);
    
    viewMatrix:invert(viewMatrixTemp);
    
  end,
  
  setCameraPerspective = function(fovy, aspect, near, far)
      
      projectionMatrix = mat4.from_perspective(fovy, aspect, near, far);
  
  end,
  
  drawMesh = function(mesh, modelMatrix)
  
    modelMatrix = modelMatrix or mi;
    mv:mul(modelMatrix, viewMatrix);
    mvp:mul(mv, projectionMatrix);
    
    mat4.transpose(mvpt, mvp); 
    activeShader:send("mvp", mvpt);
  
    love.graphics.draw(mesh);
  end
};