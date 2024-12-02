local PFInstalled
for package in ContentPackageManager.EnabledPackages.All do
    if tostring(package.UgcId) == tostring(2701251094) then
        PFInstalled = true
    end
end

if PFInstalled == true then
    Hook.Add("loaded", "no", function()
        Hook.Remove("characterCreated", "addToPriority")
    end)
end