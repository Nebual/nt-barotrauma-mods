function CloneMod.FindClientFromCharacter(character)
    for client in Client.ClientList do
        if client.Character == character then return client end
    end
    return nil
end

function CloneMod.GiveAffliction(character, afflictionPrefab, strength, scaleByMaxVitality, limb)
    local affliction = AfflictionPrefab.Prefabs[afflictionPrefab]
    if scaleByMaxVitality then
        strength = strength * character.MaxVitality / 100
    end
    character.CharacterHealth.ApplyAffliction(limb, affliction.Instantiate(strength))
end