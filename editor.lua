
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
    agentsPaused = false,
    gravity = true,
    mouseCamera = false,
    toolCount = 1
}

local function printBool(value, on, off)
  if (value) then return on else return off end;
end

function Editor.printTooltip()
  love.graphics.setColor(1,1,1,1);

  love.graphics.printf([[Edit Mode
[G] - ]]..printBool(Editor.gravity, "Gravity On", "Gravity Off")..[[ 
[P] - ]]..printBool(Editor.agentsPaused, "Sim Paused", "Sim Running")..[[ 
[Enter] - Play Mode]], 5, 0, 400);

end

function Editor.keypressed(key)

  if (key == "g") then
    Editor.gravity = not Editor.gravity;
  elseif (key == "p") then
    Editor.agentsPaused = not Editor.agentsPaused;
  elseif  (key == "return") then
    Editor.enterPlayMode();
    Gameplay.setMouseControlCamera(true);
  end

end

function Editor.enterPlayMode()
  
  --Gameplay.setMouseControlCamera(true);
  State.mouseCameraPressed = true;
  --Gameplay.teleportPlayerToStart(State.player1);
  Editor.isActive = false;
end

function Editor.enterEditMode()

  Editor.isActive = true;
  Gameplay.setMouseControlCamera(false);
  State.mouseCameraPressed = false;

end

function Editor.uiupdate()
    
    if (not Editor.isActive) then
      return;
    end
    
    ui.tabs('main tabs', function()
    
      ui.tab("Edit", function()

    
                Editor.sceneType = ui.dropdown("Type", Editor.sceneType, Editor.SCENE_TYPES, {
                  onChange = function()
                    Editor.selection = nil;
                  end
                });

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

                            
                  --Block Attributes
                  if (Editor.selection) then
                    local c = Editor.selection.center;
                    ui.markdown("x="..c[1].." y="..c[2].." z="..c[3]);
                    
                    local voxel = Editor.selection.voxel;
                    local props = Voxel.getPropertyForType(voxel.type);
                    if (props.uiupdate) then
                      props.uiupdate(voxel);
                    end
                  end

                elseif (Editor.sceneType == "Agent") then
                    Editor.agentType = ui.dropdown("Agent Type", Editor.agentType or "SpringHead", Agent.TYPES, {
                        onChange = function()
                          Editor.agentAttributes = {};
                        end
                    });

                    local props = Agent.TYPE_PROPERTIES[Editor.agentType];

                    --Agent Attributes
                    if (props.attributes) then
                      Editor.agentAttributes = Editor.agentAttributes or {};
                      
                      for name, params in pairs(props.attributes) do

                        local UIUpdateAgentAttribute = {
                          onChange = function(newValue)
                            if (Editor.selection and Editor.selection.agent) then
                              Editor.selection.agent[name] = newValue;
                            end
                          end
                        };
                        
                        local value = Editor.agentAttributes[name];
                        if (value == nil) then
                          value = params.default;
                        end

                        if (params.type == "bool") then
                          Editor.agentAttributes[name] = ui.checkbox(name, value, UIUpdateAgentAttribute);
                        elseif (params.type == "option") then
                          Editor.agentAttributes[name] = ui.radioButtonGroup(name, value, params.options, UIUpdateAgentAttribute);
                        end

                      end

                    end
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
            
              --[[
            ui.section("Editor Camera", {
              defaultOpen = true,
            }, function()
              
              Editor.gravity = ui.checkbox("Gravity", Editor.gravity);
              Editor.mouseCamera = ui.checkbox("Lock Cursor", Editor.mouseCamera, {
                onChange = function(toggle)
                
                  if (toggle) then
                    State.mouseCameraPressed = true;
                  else
                    Gameplay.setMouseControlCamera(false);
                  end
                
                end
              });
              
              end);]]
        
    end)

    ui.tab("File", function()
       local postLevelBtn, newLevelBtn;

        ui.image("castle.png")
        postLevelBtn = ui.button("Post Level!");
        newLevelBtn = ui.button("New Level");
      
        ui.section("Cloud Storage", function()
          
          Editor.levelName = ui.textInput("Level Name", Editor.levelName or "My Level");
          local saveUserBtn = ui.button("Save");
  
          if (saveUserBtn) then
            Level.saveToUser(Editor.levelName);
          end

          if (Editor.userLevels) then
            ui.dropdown("My Levels", nil, Editor.userLevels, {
              onChange = function(levelName)
                Editor.levelName = levelName;
                Level.loadFromUser(levelName);
              end
            });
          end
          
        end);



        --File IO
        if (DEVELOPER_MODE) then

          ui.section("File System", function()
          
            Editor.filepath = ui.textInput("Filepath", Editor.filepath or "C:/castle-builder/levels/newLevel.lua")
    
            local saveLevelBtn = ui.button("Save Level To File");
            local loadLevelBtn = ui.button("Load Level From File");
          
            if (saveLevelBtn) then
              Level.saveLevelToDisk(Editor.filepath);
            end
          
            if (loadLevelBtn) then
              Level.loadLevelFromDisk(Editor.filepath);
            end
          
          end);
          
         
        end

        if (postLevelBtn) then
          Level.postLevel();
        end
           
        if (newLevelBtn) then
          Level.loadLevelFromId("blank");
        end

        ui.dropdown("Prebuilt Levels", nil, Voxel.LEVELS, {
            
          onChange = function(level)
            Level.loadLevelFromId(level);
          end
        
        });
    
    end);

    
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

function Editor.insertAgent(prevCenter, normal, topOnly)

    local c = prevCenter;
  
    if (topOnly and normal.y < 0.5) then return end;

   local round = cpml.utils.round;
   local vx, vy, vz = round(c[1] + normal.x), round(c[2] + normal.y), round(c[3] + normal.z);
   
    if (vy < 0) then return end;

    local ag = Agent.addAgent(State.agentSystem, Editor.agentType, vx, vy, vz);
    
    for name, value in pairs(Editor.agentAttributes) do
      ag[name] = value;
    end

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
            if (agent and ((tAgent and not tVoxel) or (tAgent < tVoxel))) then
                Editor.selection = {
                  agent = agent,
                  center = agent.center,
                  voxel = nil
                }

                Editor.agentAttributes = {};
                local props = Agent.getProperties(agent);
                Editor.agentType = agent.typeName;

                for name in pairs(props.attributes or {}) do
                  Editor.agentAttributes[name] = agent[name];
                end
            end
        elseif (Editor.tool == "Add" and button == 1) then
            Editor.insertAgent(c, normal, Editor.agentType == "SpringHead");
        elseif (Editor.tool == "Remove" or (Editor.tool == "Add" and button == 2)) then
          if (agent and ((tAgent and not tVoxel) or (tAgent < tVoxel))) then
            Agent.removeAgent(State.agentSystem, agent);
            end
        end
        
      return;
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

function Editor.drawOverlay()

  local w, h = love.graphics.getDimensions();


  local mx, my = love.mouse.getPosition();
  if (State.mouseCamera) then
    mx, my = w * 0.5, h * 0.5;
  end

  if (Editor.tool == "Add") then
    love.graphics.setColor(1,1,1,0.4);
    love.graphics.rectangle("fill", mx - 10, my - 1, 20,  2);
    love.graphics.rectangle("fill", mx - 1,  my - 10, 2,  20);
  elseif (Editor.tool == "Remove") then
    love.graphics.setColor(1,1,1,0.4);
    love.graphics.rectangle("fill", mx - 10, my - 1, 20,  2);
  end

end

return Editor;