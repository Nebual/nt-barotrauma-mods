
SandboxMenu.Afflictions = SandboxMenu.Afflictions or {}
SandboxMenu.Afflictions.AllAfflictions = AfflictionPrefab.Prefabs.Keys
SandboxMenu.Afflictions.Limbs = {
    [1] = "Main Limb",
    [2] = "Unknown",
    [3] = "Unknown",
    [4] = "Unknown",
    [5] = "Unknown",
    [6] = "Unknown",
}
SandboxMenu.Afflictions.TargetPlayer = "Not selected" 
SandboxMenu.Afflictions.SelectedLimb = 1
SandboxMenu.Afflictions.Intensity = 50
SandboxMenu.Afflictions.SelectedAffliction = "burn"


local afflictionsTab = GUI.Frame(GUI.RectTransform(Vector2(0.995, 0.9), SandboxMenu.menuContent.RectTransform, GUI.Anchor.Center))

afflictionsTab.RectTransform.AbsoluteOffset = Point(0, 10)
afflictionsTab.Visible = false



local selectedPlayer = GUI.DropDown(GUI.RectTransform(Vector2(0.15, 0.05), afflictionsTab.RectTransform, GUI.Anchor.TopLeft), SandboxMenu.Afflictions.TargetPlayer, 3, nil, false)
selectedPlayer.RectTransform.AbsoluteOffset = Point(27, 15)

for k, v in ipairs(Character.CharacterList) do -- Adding all categories
    selectedPlayer.AddItem(v.DisplayName, v.DisplayName )
end 

selectedPlayer.OnSelected = function(s, obj)
    SandboxMenu.Afflictions.TargetPlayer = obj
end

local intensityText = GUI.TextBlock(GUI.RectTransform(Vector2(0.35, 0.1), afflictionsTab.RectTransform), "50", nil, nil, GUI.Alignment.Center)
intensityText.RectTransform.AbsoluteOffset = Point(250, 15)

local intensity = GUI.ScrollBar(GUI.RectTransform(Vector2(0.35, 0.1), afflictionsTab.RectTransform), 0.1, nil, "GUISlider")
intensity.RectTransform.AbsoluteOffset = Point(250, 15)
intensity.Range = Vector2(-1, 250)
intensity.BarScrollValue = 50
intensity.OnMoved = function ()
    SandboxMenu.Afflictions.Intensity = math.floor(intensity.BarScrollValue)
    intensityText.Text = tostring(SandboxMenu.Afflictions.Intensity)
end


local limbs = {
    [1] = "Main Limb",
    [LimbType.Head] = "Head",
    [LimbType.Torso] = "Torso",
    [LimbType.LeftArm] = "Left Arm",
    [LimbType.RightArm] = "Right Arm",
    [LimbType.LeftLeg] = "Left Leg",
    [LimbType.RightLeg] = "Right Leg",
}

local selectedLimb = GUI.DropDown(GUI.RectTransform(Vector2(0.15, 0.05), afflictionsTab.RectTransform, GUI.Anchor.TopLeft), limbs[SandboxMenu.Afflictions.SelectedLimb], 3, nil, false)
selectedLimb.RectTransform.AbsoluteOffset = Point(27, 45)

for k, v in pairs( limbs ) do -- Adding all categories
    selectedLimb.AddItem( v, k )
end 

selectedLimb.OnSelected = function(s, obj)
    SandboxMenu.Afflictions.SelectedLimb = obj
end 


local afflictionSelection = GUI.ListBox(GUI.RectTransform(Vector2(0.35, 0.85), afflictionsTab.RectTransform, GUI.Anchor.TopRight)) 
afflictionSelection.RectTransform.AbsoluteOffset = Point(50, 15)

-- Item name sort
local function sortObj(objA, objB)
    return AfflictionPrefab.Prefabs[tostring(objA)].Name < AfflictionPrefab.Prefabs[tostring(objB)].Name
end

table.sort(SandboxMenu.Afflictions.AllAfflictions, sortObj)

for k, v in ipairs(SandboxMenu.Afflictions.AllAfflictions) do
    local prefab = AfflictionPrefab.Prefabs[tostring(v)]
    local availableAffliction = GUI.Button(GUI.RectTransform(Vector2(1, 1), afflictionSelection.Content.RectTransform, GUI.Anchor.TopCenter), prefab.Name, GUI.Alignment.Center, "GUIButtonSmall")

    availableAffliction.OnClicked = function()
        SandboxMenu.Afflictions.SelectedAffliction = tostring(v)

        -- If singleplayer
        if (Game.IsSingleplayer) then                
            local char

            for k, v in ipairs(Character.CharacterList) do
                if v.DisplayName == SandboxMenu.Afflictions.TargetPlayer then
                    char = v
                    break
                end
            end

            if not char then
                return
            end

            local limb = char.AnimController.GetLimb(SandboxMenu.Afflictions.SelectedLimb )
        
            local intensity = SandboxMenu.Afflictions.Intensity

            char.CharacterHealth.ApplyAffliction(limb, prefab.Instantiate(intensity))

            return  
        end

        local netMsg = Networking.Start("SpawnMenuMod_RequestAffliction");
        netMsg.WriteString( SandboxMenu.Afflictions.SelectedAffliction )
        netMsg.WriteString(SandboxMenu.Afflictions.TargetPlayer)
        netMsg.WriteInt16(SandboxMenu.Afflictions.SelectedLimb)
        netMsg.WriteInt16(SandboxMenu.Afflictions.Intensity)
        
        Networking.Send(netMsg)
    end
end

local afflictionsButton = GUI.Button(GUI.RectTransform(Vector2(0.1, 0.15), SandboxMenu.menuContent.RectTransform, GUI.Anchor.TopLeft), "Afflictions", GUI.Alignment.Center, "GUIButtonSmall")
afflictionsButton.RectTransform.AbsoluteOffset = Point(150, 25)
afflictionsButton.OnClicked = function()
    selectedPlayer.ClearChildren()
    for k, v in ipairs(Character.CharacterList) do -- Adding all categories
        selectedPlayer.AddItem(v.DisplayName, v.DisplayName )
    end 
    
    SandboxMenu.HideAllTabs()
    afflictionsTab.Visible = true
end

SandboxMenu.RegisterTab(afflictionsTab)