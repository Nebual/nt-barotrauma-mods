CloneMod = {}

local function clone(character, startWeakness, cloneAfflictions, position, cloner, retainOldBody)
    if SERVER or (CLIENT and Game.IsSingleplayer == true) then
    -- All first conditionals here
    if character.IsHumanoid == false then return false end
    if character.IsDead == false then return false end
    --

    -- conditions to explode the body upon cloning

    if Entity.Spawner.IsInRemoveQueue(character) then
        return false;
    end
    local client = CloneMod.FindClientFromCharacter(character)
    character.Enabled = false
    Entity.Spawner.AddEntityToRemoveQueue(character)

    local uncloneable = character.CharacterHealth.GetAfflictionStrengthByIdentifier("cloneweakness") >= 99.9
    or (character.IsHusk and CloneMod.cloneHusks == false)

    local headMissing = true
    for limb in character.AnimController.Limbs do
        if limb.IsSevered == true then startWeakness = startWeakness + 3 end
        if limb.type == LimbType.Head and limb.IsSevered == false then
            headMissing = false
        end
    end
        -- to reinvent the wheel

        local info = character.Info
        local newHuman = Character.Create("Human", position, ToolBox.RandomSeed(8), info, 0, false, true)

        newHuman.TeamID = CharacterTeamType.Team1

        newHuman.Revive()

        local retainedBody
        if retainOldBody ~= true then goto noretain end

        retainedBody = Character.Create("Human", position, ToolBox.RandomSeed(8), nil, 0, false, true)
        retainedBody.TeamID = CharacterTeamType.Team1
        retainedBody.Kill(CauseOfDeathType.Unknown)

        retainedBody.Info.Name = "Old body of: " .. tostring(newHuman.Name)

        ::noretain::

        if character.Inventory ~= nil and newHuman.Inventory ~= nil then
            for i = 0, math.min(character.Inventory.Capacity, newHuman.Inventory.Capacity), 1 do
                local list = character.Inventory.GetItemsAt(i)
                for item in list do
                    if item == nil then goto continue end
                    if retainOldBody then
                        retainedBody.Inventory.TryPutItem(item, i, true, false, nil)
                    else
                        newHuman.Inventory.TryPutItem(item, i, true, false, nil)
                    end
                    ::continue::
                end
            end
        end

        if client ~= nil and SERVER then
            client.SetClientCharacter(newHuman)
        end

        local weakness = 0
        if Level.Loaded ~= nil then
            for k, v in pairs(CloneMod.DifficultyThresholds) do
                if Level.Loaded.Difficulty >= v and cloner == "speedcloner" then weakness = CloneMod.SpeedClonerWeakness[k] end
                if Level.Loaded.Difficulty >= v and cloner ~= "speedcloner" then weakness = CloneMod.ClonePodWeakness[k] end
            end
        end


        if character.IsHusk then
            -- i'm sure there's a better way to do this
            newHuman.Info.SetSkillLevel("mechanical", 5)
            newHuman.Info.SetSkillLevel("medical", 5)
            newHuman.Info.SetSkillLevel("weapons", 5)
            newHuman.Info.SetSkillLevel("electrical", 5)
            newHuman.Info.SetSkillLevel("helm", 5)
            weakness = math.max(weakness * 2, 80)
        end

        CloneMod.GiveAffliction(newHuman, "cloneweakness", weakness + startWeakness, true)
        if cloner == "speedcloner" then
            CloneMod.GiveAffliction(newHuman, "cloning", 50, true)
        else
            CloneMod.GiveAffliction(newHuman, "cloning", 0.1, true)
        end
        -- explode uncloneable bodies
       if uncloneable then
            newHuman.Kill(CauseOfDeathType.Unknown)
            for limb in newHuman.AnimController.Limbs do
                newHuman.TrySeverLimbJoints(limb, 100, 100000, true, true, newHuman)
            end

        end


        -- special death afflictions
        CloneMod.GiveAffliction(newHuman, "clonefatigue", 9999)

        if character.CharacterHealth.GetAfflictionStrengthByIdentifier("pressure") > 0 then
            CloneMod.GiveAffliction(newHuman, "postmortembarotrauma", 9999)
        end

        if headMissing == true then
            CloneMod.GiveAffliction(newHuman, "alienhead", 9999)
            newHuman.Info.SetSkillLevel("mechanical", 5)
            newHuman.Info.SetSkillLevel("medical", 5)
            newHuman.Info.SetSkillLevel("weapons", 5)
            newHuman.Info.SetSkillLevel("electrical", 5)
            newHuman.Info.SetSkillLevel("helm", 5)
        end
        
        if newHuman.CharacterHealth.GetAfflictionStrengthByIdentifier("cloneweakness") >= 100 then CloneMod.GiveAffliction(newHuman, "cellularbreakdown", 9999) end
        --

        -- roll for random afflictions (above threshold)
            if newHuman.CharacterHealth.GetAfflictionStrengthByIdentifier("cloneweakness") > CloneMod.randomAfflictionThreshold
            and math.random(1,100) < CloneMod.randomAfflictionChance then
                local RandomCloneAffliction = CloneMod.RandomCloneAffliction
                for k, aff in pairs(RandomCloneAffliction) do
                    if newHuman.CharacterHealth.GetAfflictionStrengthByIdentifier(aff) > 0 then table.remove(RandomCloneAffliction, k) end
                end
                CloneMod.GiveAffliction(newHuman, RandomCloneAffliction[math.random(1, #RandomCloneAffliction)], 9999)
            end
        --
        
       -- re-add clone injuries from previous body
       for a in cloneAfflictions do
            CloneMod.GiveAffliction(newHuman, a.Prefab.Identifier, 9999)
       end
       
       if SERVER then
            local string = ""
            if character.IsHusk then string = " Your skills have been reset since you were cloned after huskification!"
            elseif headMissing then string = " Your skills have been reset since you were decapitated and cloned!" end
            Game.SendDirectChatMessage(ChatMessage.Create("You are being cloned!",
            "Every time you are cloned, you suffer more debilitating debuffs. You will wake up when the cloning process is complete." .. string,
            ChatMessageType.Default, nil, nil, nil, Color(255, 0, 25, 255) ), client)
       end

       return true
    end
end

Hook.Add("inventoryPutItem", "checkPodForID", function(inv, item, character, index, removeItemBool)
    if inv.Owner.Prefab.Identifier ~= "clonepod" and inv.Owner.Prefab.Identifier ~= "speedcloner" then return end
    if inv.Owner.GetComponentString("Powered").Voltage <= 0.5 then return end
    if inv.Owner.GetComponentString("Powered").IsOn == false then return end
    if item.Name == "ID Card" then
        for c in item.Components do
            if c.Name == "IdCard" then
                for char in Character.CharacterList do
                    if char.Name == c.OwnerName then
                        if Vector2.Distance(char.SimPosition, item.SimPosition) > 2.5 then return end
                        local currWeakness = char.CharacterHealth.GetAfflictionStrengthByIdentifier("cloneweakness")

                        local currCloneInjuries = {}
                        for a in char.CharacterHealth.GetAllAfflictions() do
                            if a.Prefab.AfflictionType == "cloneinjury" or a.Prefab.AfflictionType == "randomcloneinjury" then table.insert(currCloneInjuries, a) end
                        end
                        local cloned = clone(char, currWeakness, currCloneInjuries, item.WorldPosition, inv.Owner.Prefab.Identifier, CloneMod.RetainOldBody)
                        if cloned == true then
                            -- activate the self destruct mechanism
                            inv.Owner.GetComponentString("LightComponent").range = 451
                            
                            if SERVER then
                                local property = inv.Owner.GetComponentString("LightComponent").SerializableProperties[Identifier("range")]
                                Networking.CreateEntityEvent(inv.Owner, Item.ChangePropertyEventData(property, inv.Owner.GetComponentString("LightComponent")))
                            end

                            inv.Owner.GetComponentString("Powered").IsOn = false
                            if SERVER then
                                local property = inv.Owner.GetComponentString("Powered").SerializableProperties[Identifier("IsOn")]
                                Networking.CreateEntityEvent(inv.Owner, Item.ChangePropertyEventData(property, inv.Owner.GetComponentString("Powered")))
                            end
                        end
                    end
                end
            end
        end
    end

end)

Hook.Add("SRrevive", function(effect, deltaTime, item, targets, worldPosition, element)

for target in targets do
    local currWeakness = target.CharacterHealth.GetAfflictionStrengthByIdentifier("cloneweakness")

    local currCloneInjuries = {}
    for a in target.CharacterHealth.GetAllAfflictions() do
        if a.Prefab.AfflictionType == "cloneinjury" or a.Prefab.AfflictionType == "randomcloneinjury" then table.insert(currCloneInjuries, a) end
    end

    clone(target, currWeakness, currCloneInjuries, target.WorldPosition, "clonepod", false)

end

end)


--[[ Hook.Add("character.death", "dropDeathCard", function(character)
    local client = CloneMod.FindClientFromCharacter(character)
    if client == nil then return end
    if character.Inventory ~= nil then
        Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("deathcard"), character.Inventory, nil, 0, function(item)
            item.GetComponentString("IdCard").OwnerName = character.Name
        end, true, false)
    end
end) 

maybe later
]]