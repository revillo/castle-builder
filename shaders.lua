local DefaultVert = [[
      
  uniform mat4 mvp; 
  uniform mat4 model;
  
  varying vec3 worldPos;
  
  vec4 position(mat4 transform_projection, vec4 vertex_position)
  {
      vec4 p = mvp * vertex_position;
      worldPos = (model * vertex_position).xyz;
      p.y = -p.y;
      return p;
  }

]]

local Shaders = {
  
  Tiles = (function()
    
    local frag = [[
      
        varying vec3 worldPos;
        
        vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
        {
          texture_coords.y = 1.0 - texture_coords.y;
          
          vec3 normal = -normalize(cross(dFdx(worldPos), dFdy(worldPos)));
          
          
          
          vec4 tex = Texel(texture, texture_coords / 8.0);
          tex.rgb *= color.rgb;
          
          tex.rgb *= 0.6 + normal.y * 0.4;
          
          return tex;
          //return vec4(texture_coords, 0.0, 1.0);
        } 
    
    ]]
    return love.graphics.newShader(DefaultVert, frag);

  
  
  end)()



}

return Shaders;