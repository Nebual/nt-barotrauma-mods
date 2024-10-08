print("Loading SoftCrushDepth")

local function Lerp(a, b, t)
	return a + (b - a) * t
end

local function Clamp(num, min, max)
    if(num<min) then
        num = min
    elseif(num>max) then
        num = max
    end
    return num
end

local function randRange(min, max)
    return min + math.random() * (max - min)
end

LuaUserData.MakeFieldAccessible(Descriptors['Barotrauma.SubmarineBody'], "damageSoundTimer")
LuaUserData.MakeFieldAccessible(Descriptors['Barotrauma.SubmarineBody'], "depthDamageTimer")


-- this function is mostly reimplementing the vanilla version from SubmarineBody.cs, with these changes:
-- variable value tweask
-- Note: vanilla does not appear to ever actually call this clientside (in multiplayer), so the sound and camera shake don't actually work?
Hook.Patch('SoftCrushDepth.UpdateDepthDamage', 'Barotrauma.SubmarineBody', 'UpdateDepthDamage', function (instance, ptable)
    ptable.PreventExecution = true
	local deltaTime = ptable['deltaTime']
    local Submarine = instance.Submarine

	if CLIENT then
		if Game.GameSession ~= nil and string.find(LuaUserData.TypeOf(Game.GameSession.GameMode), "TestGameMode") then return end
	end
    if Level.Loaded == nil then return end
    local difficultyRatio = Level.Loaded.Difficulty / 100.0

    -- camera shake and sounds start playing 250 meters before crush depth
    local CosmeticEffectThreshold = -250.0 -- vanilla: -500
    -- breaches max out at 1000 meters below crush depth
    local MaxEffectThreshold = 1000.0 -- vanilla: 500
    local MinWallDamageProbability = 0.02 -- vanilla: 0.1
    local MaxWallDamageProbability = 0.4 + 0.4*difficultyRatio -- vanilla: 1.0
    local MinWallDamage = 50.0 -- vanilla: 50
    local MaxWallDamage = 250.0 * (1 + difficultyRatio) -- vanilla: 500
    local MinCameraShake = 5.0
    local MaxCameraShake = 50.0
    local MinDamageDelay = 8.0 - 3.0*difficultyRatio -- vanilla: 5
    local MaxDamageDelay = 13.0 -- vanilla: 10
    -- delay at the start of the round during which you take no depth damage
    -- (gives you a bit of time to react and return if you start the round in a level that's too deep)
    local MinRoundDuration = 60.0

    if Submarine.RealWorldDepth < Level.Loaded.RealWorldCrushDepth + CosmeticEffectThreshold or Submarine.RealWorldDepth < Submarine.RealWorldCrushDepth + CosmeticEffectThreshold then
        return
    end

    if CLIENT then
        instance.damageSoundTimer = instance.damageSoundTimer - deltaTime
        if instance.damageSoundTimer <= 0.0 then
            print("SoftCrushDepth: Playing crush depth damage sound")
            SoundPlayer.PlayDamageSound("pressure", randRange(0.0, 100.0), Submarine.WorldPosition + Rand.Vector(math.random() * math.min(Submarine.Borders.Width, Submarine.Borders.Height)), 20000.0)

            instance.damageSoundTimer = randRange(5.0, 10.0)
        end
    end

    instance.depthDamageTimer = instance.depthDamageTimer - deltaTime
    if instance.depthDamageTimer <= 0.0 and (Game.GameSession == nil or Game.GameSession.RoundDuration > MinRoundDuration) then
        for _, wall in pairs(Structure.WallList) do
            local wallCrushDepth, pastCrushDepth, pastCrushDepthRatio, damage -- goto requires pre-defining locals
            if wall.Submarine ~= Submarine then goto continue end

            wallCrushDepth = wall.CrushDepth
            pastCrushDepth = Submarine.RealWorldDepth - wallCrushDepth
            pastCrushDepthRatio = Clamp(pastCrushDepth / MaxEffectThreshold, 0.0, 1.0)

            if math.random() > Lerp(MinWallDamageProbability, MaxWallDamageProbability, pastCrushDepthRatio) then goto continue end

            damage = Lerp(MinWallDamage, MaxWallDamage, pastCrushDepthRatio)
            if pastCrushDepth > 0 then
                print("SoftCrushDepth: Dealing " .. tostring(damage) .. " damage to wall at " .. tostring(wall.WorldPosition) .. " (crush depth: " .. tostring(wallCrushDepth) .. ", past crush depth: " .. tostring(pastCrushDepth) .. ")")
                Explosion.RangedStructureDamage(wall.WorldPosition, 100.0, damage, 0.0)
                if CLIENT then
                    SoundPlayer.PlayDamageSound("StructureBlunt", randRange(0, 100), wall.WorldPosition, 2000.0)
                end
            end
            if Character.Controlled ~= nil and Character.Controlled.Submarine == Submarine then
                print("SoftCrushDepth: Shaking camera")
                Game.GameScreen.Cam.Shake = math.max(Game.GameScreen.Cam.Shake, Lerp(MinCameraShake, MaxCameraShake, pastCrushDepthRatio))
            end
            ::continue::
        end
        instance.depthDamageTimer = randRange(MinDamageDelay, MaxDamageDelay)
    end
end, Hook.HookMethodType.Before)
