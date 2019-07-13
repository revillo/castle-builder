local DefaultVert = [[
      
  uniform mat4 mvp; 
  uniform mat4 model;
  uniform mat4 view;
  
  varying vec3 worldPos;
  uniform bool waterTile;
  
  vec4 position(mat4 transform_projection, vec4 vertex_position)
  {
  
      vec4 p = mvp * vertex_position;
      worldPos = (model * vertex_position).xyz;
      p.y = -p.y;      
      
      if (waterTile) {
        p.z -= 0.0001;
      }
      
      return p;
  }

]]

local Shaders = {
  
  WaterTiles = (function()
    
    local frag = [[
      vec3 random3(vec3 c) {
      float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
      vec3 r;
      r.z = fract(512.0*j);
      j *= .125;
      r.x = fract(512.0*j);
      j *= .125;
      r.y = fract(512.0*j);
      return r-0.5;
    }

    const float F3 =  0.3333333;
    const float G3 =  0.1666667;
    float snoise(vec3 p) {

      vec3 s = floor(p + dot(p, vec3(F3)));
      vec3 x = p - s + dot(s, vec3(G3));
       
      vec3 e = step(vec3(0.0), x - x.yzx);
      vec3 i1 = e*(1.0 - e.zxy);
      vec3 i2 = 1.0 - e.zxy*(1.0 - e);
        
      vec3 x1 = x - i1 + G3;
      vec3 x2 = x - i2 + 2.0*G3;
      vec3 x3 = x - 1.0 + 3.0*G3;
       
      vec4 w, d;
       
      w.x = dot(x, x);
      w.y = dot(x1, x1);
      w.z = dot(x2, x2);
      w.w = dot(x3, x3);
       
      w = max(0.6 - w, 0.0);
       
      d.x = dot(random3(s), x);
      d.y = dot(random3(s + i1), x1);
      d.z = dot(random3(s + i2), x2);
      d.w = dot(random3(s + 1.0), x3);
       
      w *= w;
      w *= w;
      d *= w;
       
      return dot(d, vec4(52.0));
    }
  
    uniform float time;

    
    float snoiseFract(vec3 p) {      
      return snoise(p) * sin(time) + snoise(p * 2.0) * 0.5 * cos(time);
    }
    

        varying vec3 worldPos;
        uniform vec3 cameraPos;

        vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
        {
          
          vec3 wpos2 = worldPos;
          float noise = snoiseFract(wpos2) + 0.5;
          
          //vec4 clr =  mix(vec4(0.0, 0.5, 0.9, 0.6), vec4(0.3, 0.6, 1.0, 0.8), noise);
          //vec2 tc = texture_coords / 8.0;          
          //vec4 tex = Texel(texture, tc);
          //tex.a = 0.65;
          
          vec4 clr = mix(vec4(vec3(0.9), 0.5), vec4(vec3(1.0), 0.7), noise) * vec4(1.0, 0.0, 1.0, 1.0);
          
          vec3 normal = -normalize(cross(dFdx(worldPos), dFdy(worldPos)));
          vec3 wPos = wpos2 + normal * noise * 0.4;
          vec3 normalNoise = -normalize(cross(dFdx(wPos), dFdy(wPos)));
          
          vec3 eyeRay = normalize(wpos2 - cameraPos);
          
          vec3 r = reflect(eyeRay, -normalNoise);
          
          vec3 sun = normalize(vec3(1.0, 1.0, 1.0));
          float spec = pow(max(dot(r, sun), 0.0), 10.0);
          float diff = max(spec, dot(normalNoise, sun) * 0.2 + 0.8) * (normal.y * 0.4 + 0.6);
          

          
          //return vec4(diff * vec3(1.0, 0.0, 1.0) + vec3(spec * 0.5), 0.95 + spec);
          return vec4(diff * color.rgb + vec3(spec * 0.5), color.a + spec);
          //return vec4(vec3(pixels), 1.0);
          
          
          //return clr;
        } 
    
    ]]
    return love.graphics.newShader(DefaultVert, frag);

  end)(),
  
  Tiles = (function()
    
    local frag = [[
      
        varying vec3 worldPos;
        varying vec3 eyePos;
        uniform vec3 cameraPos;

        vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
        {
          
          vec3 normal = -normalize(cross(dFdx(worldPos), dFdy(worldPos)));
          
          vec2 tc = texture_coords / 8.0;          
          vec4 tex = Texel(texture, tc);
          tex.rgb *= color.rgb;
          
          tex.rgb *= 0.6 + normal.y * 0.4;
          
          tex.a = color.a;
          
          /*
          float texMag = length(tex);
          vec3 wPos = worldPos - normal * texMag * 0.04;
          vec3 normalNoise = -normalize(cross(dFdx(wPos), dFdy(wPos)));
          vec3 eyeRay = normalize(worldPos - cameraPos);
          vec3 r = reflect(eyeRay, -normalNoise);

          vec3 sun = normalize(vec3(1.0, 1.0, 1.0));
          float spec = pow(max(dot(r, sun), 0.0), 20.0);
          float diff = max(spec, dot(normalNoise, sun) * 0.2 + 0.8);
          return vec4(tex.rgb * diff + vec3(spec * 0.2), 1.0);
          */
          
          return tex;
        } 
    
    ]]
    return love.graphics.newShader(DefaultVert, frag);

  
  
  end)()



}

return Shaders;