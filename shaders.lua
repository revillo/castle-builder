local DefaultVert = [[
      
  uniform mat4 mvp; 
  uniform mat4 model;
  uniform mat4 view;
  uniform vec3 cameraPos;

  uniform bool waterTile;
  
  
  varying vec3 worldPos;
  varying vec3 normal;
  varying vec3 tanCameraPos;
  varying vec3 tanFragPos;
  
  attribute float FaceIndex;
  
    
  vec3 faceNormals[] = vec3[6](
    vec3(1.0, 0.0, 0.0),
    vec3(-1.0, 0.0, 0.0),
    vec3(0.0, -1.0, 0.0),
    vec3(0.0, 1.0, 0.0),
    vec3(0.0, 0.0, -1.0),
    vec3(0.0, 0.0, 1.0)
  );
  
  vec3 faceBitangents[] = vec3[6](
    vec3(0.0, 1.0, 0.0),
    vec3(0.0, 1.0, 0.0),
    vec3(0.0, 0.0, -1.0),
    vec3(0.0, 0.0, 1.0),
    vec3(0.0, 1.0, 0.0),
    vec3(0.0, 1.0, 0.0)
  );
  
  
  vec4 position(mat4 transform_projection, vec4 vertex_position)
  {
  
      vertex_position.a = 1.0;

      vec4 p = mvp * vertex_position;
      worldPos = (model * vertex_position).xyz;
      p.y = -p.y;      
      
      
      vec3 aNormal = faceNormals[int(FaceIndex)];
      vec3 aBitangent = faceBitangents[int(FaceIndex)];
      vec3 aTangent = normalize(cross(aBitangent, aNormal));
      
      vec3 T   = normalize(mat3(model) * aTangent);
      vec3 B   = normalize(mat3(model) * aBitangent);
      normal   = normalize(mat3(model) * aNormal);
      mat3 TBN = transpose(mat3(T, B, normal));

      tanCameraPos = TBN * cameraPos;
      tanFragPos = TBN * worldPos;
            
      if (waterTile) {
        p.z -= 0.0001;
      }
      
      return p;
  }

]]


local noise = [[
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
      //return snoise(p + vec3(time * 0.1)) * sin(time) + snoise(p * 2.0 - vec3(time * 0.2)) * 0.5 * cos(time);
      return snoise(p + vec3(time * 0.1)) + snoise(p * 2.0 - vec3(time * 0.2)) * 0.5;
    }

]];

local shading = [[ 
  
const float shadowHeight = 8.0;
        
float getPlayerShadow() {
  vec3 diff = cameraPos - worldPos;
  float height = diff.y - 1.3;
  float dist = max(abs(diff.x), abs(diff.z));
  if (dist < 0.3 && height > 0.0 && height < shadowHeight) {
    return 0.5 + (height/(shadowHeight*2.0));
  } else {
    return 1.0;
  }
}

void getLighting(float bump, out float diffuse, out float spec) {
  vec3 cameraRay = normalize(worldPos - cameraPos);
            
  vec3 wPos = worldPos + normal * bump * 0.05;
  vec3 normalBump = -normalize(cross(dFdx(wPos), dFdy(wPos)));
  vec3 r = reflect(cameraRay, -normalBump);

  vec3 sun = normalize(vec3(1.0, 1.0, 1.0));
  spec = pow(max(dot(r, sun), 0.0), 20.0);
  diffuse = max(spec, dot(normalBump, sun) * 0.2 + 0.8) * 0.7 + 0.3 *normal.y;
  
  float shadow = getPlayerShadow();
  diffuse *= shadow;
  spec *= shadow;
}

]];


local Shaders = {
  
  WaterTiles = (function()
    
    local frag = noise..[[
        varying vec3 worldPos;
        uniform vec3 cameraPos;
        
        vec4 getWaterColor(vec4 color) {
        
          vec3 wpos2 = worldPos;
          float noise = snoiseFract(wpos2) + 0.5;
          
          vec3 normal = -normalize(cross(dFdx(worldPos), dFdy(worldPos)));
          vec3 wPos = wpos2 + normal * noise * 0.1;
          vec3 normalNoise = -normalize(cross(dFdx(wPos), dFdy(wPos)));
          
          vec3 eyeRay = normalize(wpos2 - cameraPos);
          
          vec3 r = reflect(eyeRay, -normalNoise);
          
          vec3 sun = normalize(vec3(1.0, 1.0, 1.0));
          float spec = pow(max(dot(r, sun), 0.0), 10.0);
          float diff = max(spec, dot(normalNoise, sun) * 0.2 + 0.8) * (normal.y * 0.4 + 0.6);
          
          color = vec4(0.0, 0.7, 1.0, 0.6);
          
          float angle = abs(dot(eyeRay, normal)) / (1.0 + length(wpos2 - cameraPos) * 0.1);
          
          color.a = 1.0 - angle * 0.5;
          
          color = vec4(diff * color.rgb + vec3(spec * 0.5), color.a + spec * 0.3);
          
          return color;
        }
        
        vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
        {

           return getWaterColor(color);
         
        } 
    
    ]]
    return love.graphics.newShader(DefaultVert, frag);

  end)(),
  
  Tiles = (function()
    
    local frag = noise..[[
      
        varying vec3 worldPos;
        varying vec3 normal;
        varying vec3 tanCameraPos;
        varying vec3 tanFragPos;
        
        uniform vec3 cameraPos;
        //uniform float time;
        extern Image bumpTex;
        ]]..shading..[[
        
        vec2 parallax(vec2 texCoords, vec3 viewDir, Image tex)
        { 
            float height = length(Texel(tex, texCoords).rgb);    
            vec2 p = vec2(viewDir.x, viewDir.y) / viewDir.z * (height * 0.001);
            return texCoords - p;    
        } 
        
        float fireNoise(vec3 pos) {
          return snoise(pos * 2.0 + vec3(time * 0.1)) + snoise((pos + vec3(10.0)) * 4.0 - vec3(time * 0.15)) * 0.5;
        }
        
         
        vec4 getRubberColor(vec2 uv, vec4 color) {
          vec3 wpos2 = worldPos;
          uv = mod(uv, vec2(1.0));
          vec2 uvdiff = uv - vec2(0.5);
          float rectish = clamp((0.5 - max(abs(uvdiff.x), abs(uvdiff.y))) * 2.0, 0.0, 0.2);
          float bubblish = pow(length(vec3(uvdiff, 0.0) - vec3(0.0, 0.0, 0.5)), 0.5);
          float noise = (1.0 - bubblish);
                    
          vec3 normal = -normalize(cross(dFdx(worldPos), dFdy(worldPos)));
          vec3 wPos = wpos2 + normal * noise * 1;
          vec3 normalNoise = -normalize(cross(dFdx(wPos), dFdy(wPos)));
          
          vec3 eyeRay = normalize(wpos2 - cameraPos);
          
          vec3 r = reflect(eyeRay, -normalNoise);
          
          vec3 sun = normalize(vec3(1.0, 1.0, 1.0));
          float spec = pow(max(dot(r, sun), 0.0), 5.0);
          float diff = max(spec, dot(normalNoise, sun) * 0.2 + 0.8) * (normal.y * 0.4 + 0.6);
                    
          color = vec4(0.9, 0.2, 0.7, 0.6);
          
          float angle = abs(dot(eyeRay, normal)) / (1.0 + length(wpos2 - cameraPos) * 0.1);
          
          color.a = 1.0;
          
          color = vec4(diff * color.rgb + vec3(spec * 0.3), color.a + spec * 1.0);
          
          return color;
        
        }
        
        
        vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
        {
          
          if (texture_coords.y > 7.0) {
            return getRubberColor(texture_coords, color);
          }
          
          vec4 tex;
          tex.a = 1.0;
          vec2 tc;
          float bump = 0.0;
          bool fire = texture_coords.x > 7.0;
          
          if (!fire) {
            tc = texture_coords / 8.0;
            
            //tc = parallax(tc, normalize(tanCameraPos - tanFragPos), bumpTex);

            tex = Texel(texture, tc);
            bump = length(Texel(bumpTex, tc).rgb);
          } else {
          
            tc = vec2(mod(texture_coords.x + time, 1.0) + 7.0, texture_coords.y);  
            tc = tc / 8.0;

            bump = fireNoise(worldPos * 0.5) - 0.0;
            if (bump > 0.0) {
              bump = pow(bump, 0.5);
              tex.rgb = mix( vec3(1.0, 0.4, 0.1), vec3(0.4, 0.2, 0.1), bump ); 
            }

            if (bump < 0.0) {
              tex.rgb = mix( vec3(1.0, 0.3, 0.1), vec3(1.0, 0.95, 0.3), -bump ); 
              if (bump < -0.2) {
                tex.rgb += vec3(-(bump + 0.2));
              }
              bump *= 0.25;
            }
          }
          /*
            vec3 cameraRay = normalize(worldPos - cameraPos);
            
            vec3 wPos = worldPos + normal * bump * 0.05;
            vec3 normalBump = -normalize(cross(dFdx(wPos), dFdy(wPos)));
            vec3 r = reflect(cameraRay, -normalBump);

            vec3 sun = normalize(vec3(1.0, 1.0, 1.0));
            float spec = pow(max(dot(r, sun), 0.0), 20.0);
            float diffuse = max(spec, dot(normalBump, sun) * 0.2 + 0.8) * 0.7 + 0.3 *normal.y;
            
            float shadow = getPlayerShadow();
            diffuse *= shadow;
            spec *= shadow;
          */

            float diffuse, spec;

            getLighting(bump, diffuse, spec);
            
            
            if (fire) {
                spec = pow(spec, 40.0) * 0.5;
                diffuse = 1.0;
            }
            
            return vec4(tex.rgb * diffuse + vec3(spec * 0.3), 1.0);
           
          
          tex.a = color.a;
 	          
          return tex;
        } 
    
    ]]
    return love.graphics.newShader(DefaultVert, frag);
  
  end)(),

  Agents = (function()
    
    local frag = [[

      uniform vec3 cameraPos;

      varying vec3 worldPos;
      varying vec3 normal;
      varying vec3 tanCameraPos;
      varying vec3 tanFragPos;
      uniform mat4 model;

      extern Image bumpTex;

    ]]..shading..[[
      vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {        
        color = Texel(texture, texture_coords / 8.0);

        //Eye
        if (texture_coords.x < 1.0) {
          //vec3 cntr = floor(worldPos + vec3(0.5));
          vec3 cntr = model[3].xyz;

          vec3 toCamera = cameraPos - cntr;
          vec3 toMe = worldPos - cntr;
  
          vec3 n = normalize(toCamera);
          vec3 cylinderPerp = (toMe) - dot(toMe, n) * n; 
          float eyeRadius = length(cylinderPerp);
  
  
          if (eyeRadius < 0.02) {
            color.rgb = vec3(1.0);
          } else if (eyeRadius < 0.08) {
            color.rgb = vec3(0.0);
          } else if (eyeRadius < 0.15) {
            //color.rgb = mix(vec3(0.968, 0.698, 0.403), vec3(0.32, 0.57, 0.90), (eyeRadius - 0.1)/0.1);
            color.rgb = vec3(0.32, 0.57, 0.90);
          }
        }
      
        float bump = length(Texel(bumpTex, texture_coords / 8.0).rgb);

        color.rgb *= 0.7 + normal.y * 0.3;

        float diffuse, spec;
        getLighting(bump, diffuse, spec);

        return vec4(color.rgb * diffuse + vec3(spec * 0.3), 1.0);

      }

    ]];

    return love.graphics.newShader(DefaultVert, frag);

  end)()


}

return Shaders;