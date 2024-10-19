SandboxMenu.MenuModules = {}

function SandboxMenu.TableFindKeyByValue(tbl, key)
    for k, v in pairs(tbl) do
        if v == key then
            return k
        end
    end

    return -1
end

function SandboxMenu.TableHasValue(tbl, value)

    for k, v in pairs(tbl) do
        if v == value then
            return true
        end
    end

    return false
end 


-- Main sandbox frame
SandboxMenu.frame = GUI.Frame(GUI.RectTransform(Vector2(1, 1)), nil)
SandboxMenu.frame.CanBeFocused = false

-- menu frame
local menu = GUI.Frame(GUI.RectTransform(Vector2(1.5, 1.35), SandboxMenu.frame.RectTransform, GUI.Anchor.Center), nil)
menu.CanBeFocused = false
menu.Visible = false 

SandboxMenu.menuContent = GUI.Frame(GUI.RectTransform(Vector2(0.4, 0.6), menu.RectTransform, GUI.Anchor.Center))

-- Кнопка открытия меню
local button = GUI.Button(GUI.RectTransform(Point(135, 10), SandboxMenu.frame.RectTransform, GUI.Anchor.BottomRight), "Sandbox menu", GUI.Alignment.Center, "GUIButtonSmall")
button.RectTransform.AbsoluteOffset = Point(25, 0)
button.OnClicked = function ()
    menu.Visible = not menu.Visible

    if playersLoaded then return end 

    playersLoaded = true
end


Hook.Patch("Barotrauma.GameScreen", "AddToGUIUpdateList", function()
    SandboxMenu.frame.AddToGUIUpdateList()
end)
    
Hook.Patch("Barotrauma.SubEditorScreen", "AddToGUIUpdateList", function()
    SandboxMenu.frame.AddToGUIUpdateList()
end)

function SandboxMenu.RegisterTab(tab)
    table.insert(SandboxMenu.MenuModules, tab)
end

function SandboxMenu.HideAllTabs()
    for k, v in ipairs(SandboxMenu.MenuModules) do
        v.Visible = false        
    end
end