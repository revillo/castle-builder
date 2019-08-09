local Shader = {

  Default = (function()
    
    local vert = [[
      
      uniform mat4 mvp; 
      uniform mat4 model;
      
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
          if (mod(screen_coords.x + screen_coords.y, 30.0) < 20.0) {
            discard;
            return vec4(0.0, 0.0, 0.0, 0.0);
          }
          return vec4(color);
        }
    
    ]]
    
    return love.graphics.newShader(vert, frag);
  end)()


}


local cpml = require("lib/cpml")
local mat4 = cpml.mat4;
local vec3 = cpml.vec3;
local activeShader = Shader.Default;

local cameraMatrix = mat4();
local viewMatrix = mat4();
local projectionMatrix = mat4();

local mvp = mat4();
local mvpt = mat4();
local mv = mat4();
local mi = mat4();
local vp = mat4();
local pickMatrix = mat4();
local tanX, tanY = 0;


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
local startTime = love.timer.getTime();

function setUniform(name, ...)
  if (activeShader:hasUniform(name)) then
    activeShader:send(name,  ...);
  end
end

local matrixTranspose = mat4();

function setUniformMat4(name, matrix4)

  mat4.transpose(matrixTranspose, matrix4);
  setUniform(name, matrixTranspose);

end
  
return {
  Shader = Shader, 

  cpml = cpml,
  
  createCanvas3D = function(...)
        
    local colorCanvas = love.graphics.newCanvas(...);

    colorCanvas:setFilter("linear", "linear");
  
    return {
      color = colorCanvas;
    }
  
  end,
  
  setCanvas3D = function(canvas3D)
    
   love.graphics.setCanvas({
      {canvas3D.color},
      depth = true,
      stencil = true
    });
  
  end,
  
  setShader = function(shader) 
    love.graphics.setShader(shader);
    activeShader = shader;
  end,
  
  setUniform = setUniform,
  
  setCameraView = function(eye, look_at, up)

    viewLook(cameraMatrix, eye, look_at, up);
    
    viewMatrix:invert(cameraMatrix);
    
  end,
  
  getCameraPosition = function()
  
    return {cameraMatrix[13], cameraMatrix[14], cameraMatrix[15]};
    
  end,
  
  setCameraPerspective = function(fovy, aspect, near, far)
      
    projectionMatrix = mat4.from_perspective(fovy, aspect, near, far);
    
    tanY = math.tan(math.rad(fovy) * 0.5);
    tanX = tanY * aspect; 
    
  end,
  
  pickRay = function(x, y)
  
    x, y = x * 2 - 1, y * -2 + 1;
        
    local d = {x * tanX, y * tanY, -1.0, 0.0};
    mat4.mul_vec4(d, cameraMatrix, d);
    
    local direction = vec3(d[1], d[2], d[3]);
    direction = vec3.normalize(direction);
    
    return {
      origin = vec3(cameraMatrix[13], cameraMatrix[14], cameraMatrix[15]),
      direction = direction
    };
    
  end,
  
  drawMesh = function(mesh, modelMatrix)
  
    if (not mesh) then
      return
    end

    modelMatrix = modelMatrix or mi;
    
    setUniformMat4("model", modelMatrix);
    setUniformMat4("view", viewMatrix);

    setUniform("time", love.timer.getTime() - startTime);
    setUniform("cameraPos", {cameraMatrix[13], cameraMatrix[14], cameraMatrix[15]});
    
    mv:mul(modelMatrix, viewMatrix);
    mvp:mul(mv, projectionMatrix);
    
    setUniformMat4("mvp", mvp);
  
    love.graphics.draw(mesh);
  end
};