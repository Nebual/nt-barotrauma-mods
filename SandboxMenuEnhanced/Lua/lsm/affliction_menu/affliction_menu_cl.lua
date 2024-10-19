
SandboxMenu.Afflictions = SandboxMenu.Afflictions or {}
SandboxMenu.Afflictions.AllAfflictions = AfflictionPrefab.Prefabs.Keys
SandboxMenu.Afflictions.TargetPlayer = "Not selected"
SandboxMenu.Afflictions.SelectedLimb = 1
SandboxMenu.Afflictions.Intensity = 50
SandboxMenu.Afflictions.SelectedAffliction = "burn"

-- Affliction name sort
local function sortObj(objA, objB)
    return AfflictionPrefab.Prefabs[tostring(objA)].Name < AfflictionPrefab.Prefabs[tostring(objB)].Name
end
table.sort(SandboxMenu.Afflictions.AllAfflictions, sortObj)


local afflictionsTab = GUI.Frame(GUI.RectTransform(Vector2(0.995, 0.935), SandboxMenu.menuContent.RectTransform, GUI.Anchor.TopCenter))
afflictionsTab.RectTransform.AbsoluteOffset = Point(0, 65)
afflictionsTab.Visible = false



local selectedPlayer = GUI.DropDown(GUI.RectTransform(Vector2(0.15, 0.05), afflictionsTab.RectTransform, GUI.Anchor.TopLeft), SandboxMenu.Afflictions.TargetPlayer, 6, nil, false)
selectedPlayer.RectTransform.AbsoluteOffset = Point(27, 15)

for k, v in ipairs(Character.CharacterList) do -- Adding all categories
    selectedPlayer.AddItem(v.DisplayName, v.DisplayName )
end 

selectedPlayer.OnSelected = function(s, obj)
    SandboxMenu.Afflictions.TargetPlayer = obj
    SandboxMenu.Afflictions.UpdateCharacterAfflictionsList()
end

local intensityText = GUI.TextBlock(GUI.RectTransform(Vector2(0.35, 0.1), afflictionsTab.RectTransform), "50", nil, nil, GUI.Alignment.Center)
intensityText.RectTransform.AbsoluteOffset = Point(250, 15)

local intensity = GUI.ScrollBar(GUI.RectTransform(Vector2(0.35, 0.1), afflictionsTab.RectTransform), 0.1, nil, "GUISlider")
intensity.RectTransform.AbsoluteOffset = Point(250, 15)
intensity.Range = Vector2(-100, 250)
intensity.BarScrollValue = 50
intensity.OnMoved = function ()
    SandboxMenu.Afflictions.Intensity = math.floor(intensity.BarScrollValue)
    intensityText.Text = tostring(SandboxMenu.Afflictions.Intensity)
end


local limbs = {
    [1] = "Whole Body",
    [LimbType.Head] = "Head",
    [LimbType.Torso] = "Torso",
    [LimbType.LeftArm] = "Left Arm",
    [LimbType.RightArm] = "Right Arm",
    [LimbType.LeftLeg] = "Left Leg",
    [LimbType.RightLeg] = "Right Leg",
}

local selectedLimb = GUI.DropDown(GUI.RectTransform(Vector2(0.15, 0.05), afflictionsTab.RectTransform, GUI.Anchor.TopLeft), limbs[SandboxMenu.Afflictions.SelectedLimb], 6, nil, false)
selectedLimb.RectTransform.AbsoluteOffset = Point(27, 45)

for k, v in pairs( limbs ) do -- Adding all categories
    selectedLimb.AddItem( v, k )
end 

selectedLimb.OnSelected = function(s, obj)
    SandboxMenu.Afflictions.SelectedLimb = obj
end 



local afflictionSelection = GUI.ListBox(GUI.RectTransform(Vector2(0.35, 0.97), afflictionsTab.RectTransform, GUI.Anchor.TopRight))
afflictionSelection.RectTransform.AbsoluteOffset = Point(50, 15)

for k, v in ipairs(SandboxMenu.Afflictions.AllAfflictions) do
    local prefab = AfflictionPrefab.Prefabs[tostring(v)]
    if prefab.Name ~= "" then
        local availableAffliction = GUI.Button(GUI.RectTransform(Vector2(1, 1), afflictionSelection.Content.RectTransform, GUI.Anchor.TopCenter), prefab.Name, GUI.Alignment.Center, "GUIButtonSmall")

        availableAffliction.OnClicked = function()
            SandboxMenu.Afflictions.SelectedAffliction = tostring(v)
            SandboxMenu.Afflictions.RequestAffliction()
        end
    end
end

local characterAfflictionSelection = GUI.ListBox(GUI.RectTransform(Vector2(0.35, 0.75), afflictionsTab.RectTransform, GUI.Anchor.TopLeft))
characterAfflictionSelection.RectTransform.AbsoluteOffset = Point(25, 90)

function SandboxMenu.Afflictions.UpdateCharacterAfflictionsList()
    characterAfflictionSelection.ClearChildren()

    local char = SandboxMenu.GetCharacterByName(SandboxMenu.Afflictions.TargetPlayer)
    if not char then
        return
    end

    local refreshButton = GUI.Button(GUI.RectTransform(Vector2(0.8, 1), characterAfflictionSelection.Content.RectTransform, GUI.Anchor.TopCenter), "[Refresh]", GUI.Alignment.Center, "GUIButtonSmall")
    refreshButton.OnClicked = function()
        SandboxMenu.Afflictions.UpdateCharacterAfflictionsList()
    end

    for value in char.CharacterHealth.GetAllAfflictions() do
        local prefab = value.Prefab
        if prefab.Name.Value ~= "" and prefab.Name ~= "Lualess" and value.Strength > 0.01 then
            local text = prefab.Name.Value .. " ("..tostring(math.floor(value.Strength*10)/10)..")"
            local limbtype
            if prefab.LimbSpecific then
                local limb = char.CharacterHealth.GetAfflictionLimb(value)
                if limb then
                    limbtype = SandboxMenu.NormalizeLimbType(limb.type)
                    text = text .. " - " .. limbs[limbtype]
                end
            end
            local availableAffliction = GUI.Button(GUI.RectTransform(Vector2(1, 1), characterAfflictionSelection.Content.RectTransform, GUI.Anchor.TopCenter), text, GUI.Alignment.Center, "GUIButtonSmall")

            availableAffliction.OnClicked = function()
                SandboxMenu.Afflictions.SelectedAffliction = prefab.Identifier.Value
                SandboxMenu.Afflictions.SelectedLimb = limbtype or 1
                SandboxMenu.Afflictions.RequestAffliction()
            end
        end
    end
end

function SandboxMenu.GetCharacterByName(name)
    for k, v in ipairs(Character.CharacterList) do
        if v.DisplayName == name then
            return v
        end
    end
end

-- converts thighs, feet, forearms and hands into legs and arms
function SandboxMenu.NormalizeLimbType(limbtype)
    if
        limbtype == LimbType.Head or
        limbtype == LimbType.Torso or
        limbtype == LimbType.RightArm or
        limbtype == LimbType.LeftArm or
        limbtype == LimbType.RightLeg or
        limbtype == LimbType.LeftLeg then
        return limbtype
    end

    if limbtype == LimbType.LeftForearm or limbtype==LimbType.LeftHand then return LimbType.LeftArm end
    if limbtype == LimbType.RightForearm or limbtype==LimbType.RightHand then return LimbType.RightArm end

    if limbtype == LimbType.LeftThigh or limbtype==LimbType.LeftFoot then return LimbType.LeftLeg end
    if limbtype == LimbType.RightThigh or limbtype==LimbType.RightFoot then return LimbType.RightLeg end

    if limbtype == LimbType.Waist then return LimbType.Torso end

    return limbtype
end

function SandboxMenu.Afflictions.RequestAffliction()
    -- If singleplayer
    if (Game.IsSingleplayer) then
        local char = SandboxMenu.GetCharacterByName(SandboxMenu.Afflictions.TargetPlayer)
        if not char then
            return
        end

        local limb = char.AnimController.GetLimb(SandboxMenu.Afflictions.SelectedLimb)
        local intensity = SandboxMenu.Afflictions.Intensity
        local prefab = AfflictionPrefab.Prefabs[SandboxMenu.Afflictions.SelectedAffliction]
        char.CharacterHealth.ApplyAffliction(limb, prefab.Instantiate(intensity))

        return
    end

    local netMsg = Networking.Start("SpawnMenuMod_RequestAffliction");
    netMsg.WriteString( SandboxMenu.Afflictions.SelectedAffliction )
    netMsg.WriteString(SandboxMenu.Afflictions.TargetPlayer)
    netMsg.WriteInt16(SandboxMenu.Afflictions.SelectedLimb)
    netMsg.WriteInt16(SandboxMenu.Afflictions.Intensity)

    Networking.Send(netMsg)

    Timer.Wait(SandboxMenu.Afflictions.UpdateCharacterAfflictionsList, 1000)
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