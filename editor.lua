
local Editor = {
    TOOLS = {
        "Add", "Remove", "Select"
    },
    
    SCENE_TYPES = {
        "Block", "Agent"
    },

    sceneType = "Block", 
    voxelType = "wood",
    voxelColor = {1,1,1},
    tool = "Add",
    isActive = true,
    gravity = true,
    mouseCamera = false,
    loadLevelName = Voxel.LEVELS[2],
    toolCount = 1
}

function Editor.uiupdate(State)
    
    if (not Editor.isActive) then
      
      local editLevel = ui.button("Edit Level");
      if (editLevel) then
        Editor.isActive = true;
        Gameplay.setMouseControlCamera(false);
      end
      return;
    end
    
    local playLevelBtn, postLevelBtn;
    
    playLevelBtn = ui.button("Play Level");
    postLevelBtn = ui.button("Post Level");
    
    if (DEVELOPER_MODE) then
      local saveLevelBtn = ui.button("Save Level To File");
      local loadLevelBtn = ui.button("Load Level From File");
    
      if (saveLevelBtn) then
        Level.saveLevel("levels/last.lua");
      end
    
      if (loadLevelBtn) then
        Level.loadLevelFromId("last");
      end
    end
    
    if (postLevelBtn) then
      Level.postLevel();
    end
    
    if (playLevelBtn) then
      --setMouseControlCamera(true);
      State.mouseCameraPressed = true;
      Gameplay.teleportPlayerToStart(State.player1);
      Editor.isActive = false;
    end
  
    ui.section("Change Level", {
      defaultOpen = false,
    }, function()
      
      Editor.loadLevelName = ui.dropdown("Select Level", Editor.loadLevelName, Voxel.LEVELS, {
        
        onChange = function(level)
          Level.loadLevelFromId(level);
        end
      
      });
    
    end);
    
    
    ui.section("Edit Scene", {
      defaultOpen = true,
    }, function()
      
        Editor.sceneType = ui.dropdown("Type", Editor.sceneType, Editor.SCENE_TYPES);

        if (Editor.sceneType == "Block") then
            Editor.voxelType = ui.dropdown("Block Type", Editor.voxelType, Voxel.BLOCK_TYPES, {
            
            onChange = function(typeName)
            
                if (Editor.selection) then
                    Editor.selection.voxel.type = Voxel.BLOCK_INDEX_MAP[typeName];
                    local c = Editor.selection.center;
                    Voxel.insert(State.grid, Editor.selection.voxel, c[1], c[2], c[3]); 
                end
                
            end
            
            });
        elseif (Editor.sceneType == "Agent") then
            Editor.agentType = ui.dropdown("Agent Type", Editor.agentType or "SpringHead", Agent.TYPES, {
                
            });
        end

      Editor.tool = ui.radioButtonGroup('Tool', Editor.tool, Editor.TOOLS, {
        onChange = function(tool)
          
          if (tool ~= "select") then
            Editor.selection = nil;
          end

        end      
      });
      
      if (Editor.tool == "Add" and Editor.sceneType == "Block") then
        Editor.toolCount = ui.slider("Block Multiplier", Editor.toolCount, 1, 10);        
      end

      
      --[[
      Editor.voxelColor = {ui.colorPicker("Paint Color", Editor.voxelColor[1], Editor.voxelColor[2], Editor.voxelColor[3], 1, {
          enableAlpha = false,
          onChange = function(clr)
            
            if (Editor.selection) then
              Editor.selection.voxel.color = {clr.r, clr.g, clr.b};
              local c = Editor.selection.center;
              Voxel.insert(State.grid, Editor.selection.voxel, c[1], c[2], c[3]);
            end
         end
        })
      };]]
        
      
      if (Editor.selection) then
        local c = Editor.selection.center;
        ui.markdown("x="..c[1].." y="..c[2].." z="..c[3]);
        
        local voxel = Editor.selection.voxel;
        local props = Voxel.getPropertyForType(voxel.type);
        if (props.uiupdate) then
          props.uiupdate(voxel);
        end
      end
    
    end);
    
     ui.section("Editor Camera", {
      defaultOpen = true,
    }, function()
      
      Editor.gravity = ui.checkbox("Gravity", Editor.gravity);
      Editor.mouseCamera = ui.checkbox("Mouse", Editor.mouseCamera, {
        onChange = function(toggle)
        
          if (toggle) then
            State.mouseCameraPressed = true;
          else
            Gameplay.setMouseControlCamera(false);
          end
        
        end
      });
      
      end);
    
end

function Editor.selectVoxel(voxel, x, y, z)
  
   Editor.selection = {
      center = {x, y, z},
      voxel = voxel
   };
   
   Editor.voxelType = Voxel.BLOCK_TYPES[voxel.type];
   Editor.voxelColor = voxel.color or {1,1,1};

end

function Editor.insertAgent(prevCenter, normal)

    local c = prevCenter;
   
    if (normal.y < 0.5) then return end;

   local round = cpml.utils.round;
   local vx, vy, vz = round(c[1] + normal.x), round(c[2] + normal.y), round(c[3] + normal.z);
   
    if (vy < 0) then return end;

    Agent.addAgent(State.agentSystem, Editor.agentType, vx, vy, vz);

end

function Editor.insertVoxel(prevCenter, normal)

  local c = prevCenter;
  local round = cpml.utils.round;

  local vx, vy, vz = round(c[1] + normal.x), round(c[2] + normal.y), round(c[3] + normal.z);
      
    if (vy < 0) then return end;
    
    local oldPos = State.player1.position;

    local playerSize = State.player1.size;

    local pbb = {
      ll = {oldPos.x - playerSize.x, oldPos.y - playerSize.y, oldPos.z - playerSize.z},
      ur = {oldPos.x + playerSize.x, oldPos.y + playerSize.y, oldPos.z + playerSize.z}
    };
    
    local vbb = {
      ll = {vx - 0.5, vy - 0.5, vz - 0.5},
      ur = {vx + 0.5, vy + 0.5, vz + 0.5}
    };
    
    if (Voxel.intersectAABBs(pbb, vbb)) then
      return nil;
    end
    
    Voxel.insert(State.grid, 
      {
        type = Voxel.BLOCK_INDEX_MAP[Editor.voxelType],
        --color = Editor.voxelColor
      }, vx, vy, vz);
  return {vx, vy, vz};
end

function Editor.mousereleased(x, y, button)
  
  if (Editor.isActive and button == 3) then
    Gameplay.setMouseControlCamera(false);
  end

end


function Editor.mousepressed(x, y, button)

  if (State.mouseCameraPressed) then
    State.mouseCameraPressed = false;
    Gameplay.setMouseControlCamera(true);
  end
  
  if (not Editor.isActive) then
    return;
  end

 
  if (button == 3) then
    Gameplay.setMouseControlCamera(true);
  else
    local w, h = love.graphics.getDimensions();
    local mx, my = love.mouse.getPosition();
    local ray = GFX.pickRay(mx / w, my / h);
    local vox, c, tVoxel, normal = Voxel.traceRay(State.grid, ray);
    local agent, tAgent = Agent.traceRay(State.agentSystem, ray);

    local round = cpml.utils.round;

    if not vox then
        return
    end
  
    if (Editor.sceneType == "Agent") then

        if (Editor.tool == "Select") then
            if (tAgent < tVoxel) then
                --todo select agent
            end
        elseif (Editor.tool == "Add") then
            Editor.insertAgent(c, normal);
        elseif (Editor.tool == "Remove") then
            if (tAgent < tVoxel) then
                --todo remove agent
            end
        end

    end


    if (Editor.tool == "Select") then
      Editor.selectVoxel(vox, c[1], c[2], c[3]);      
    elseif (Editor.tool == "Add" and button == 1) then
      
      for _ = 1, Editor.toolCount do
        
        c = Editor.insertVoxel(c, normal);
        if (not c) then
          return;
        end
        
      end
        
    elseif (Editor.tool == "Remove" or (Editor.tool == "Add" and button == 2)) then
      local vx, vy, vz = c[1], c[2], c[3];
      Voxel.remove(State.grid, vx, vy, vz);  
    end
    
  end  
end



return Editor;