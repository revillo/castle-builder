local DefaultVert = [[
      
  uniform mat4 mvp; 

  vec4 position(mat4 transform_projection, vec4 vertex_position)
  {
      vec4 p = mvp * vertex_position;
      p.y = -p.y;
      return p;
  }

]]

local Shaders = {
  
  Tiles = (function()
    
    local frag = [[
      
        vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
        {
          texture_coords.y = 1.0 - texture_coords.y;
          return Texel(texture, texture_coords / 8.0);
          //return vec4(texture_coords, 0.0, 1.0);
        } 
    
    ]]
    return love.graphics.newShader(DefaultVert, frag);

  
  
  end)()



}

return Shaders;