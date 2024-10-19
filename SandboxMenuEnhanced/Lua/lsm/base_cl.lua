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

local GameMain = LuaUserData.CreateStatic('Barotrauma.GameMain')
local extraUIWidth = GUI.UIWidth < GameMain.GraphicsWidth and (GameMain.GraphicsWidth - GUI.UIWidth) or 0 -- ultrawide's have a smaller UIWidth than the actual screen width

-- Main sandbox frame
SandboxMenu.frame = GUI.Frame(GUI.RectTransform(Vector2(1, 1)), nil)
SandboxMenu.frame.CanBeFocused = false

-- menu frame
local menu = GUI.Frame(GUI.RectTransform(Vector2(1 + 0.2/GUI.xScale, 1 + 0.3), SandboxMenu.frame.RectTransform, GUI.Anchor.Center), nil)
menu.CanBeFocused = false
menu.Visible = false 

SandboxMenu.menuContent = GUI.Frame(GUI.RectTransform(Vector2(0.4, 0.6), menu.RectTransform, GUI.Anchor.Center))

-- make draggable
local frameHandle = GUI.DragHandle(GUI.RectTransform(Vector2(1,1), SandboxMenu.menuContent.RectTransform, GUI.Anchor.Center), SandboxMenu.menuContent.RectTransform, nil)

-- Menu open button
local button = GUI.Button(GUI.RectTransform(Point(135*GUI.xScale, 10), SandboxMenu.frame.RectTransform, GUI.Anchor.BottomRight), "Sandbox menu", GUI.Alignment.Center, "GUIButtonSmall")
button.RectTransform.AbsoluteOffset = Point(24*GUI.xScale - extraUIWidth, 0)
button.OnClicked = function ()
    menu.Visible = not menu.Visible
end


Hook.Patch("Barotrauma.GameScreen", "AddToGUIUpdateList", function()
    SandboxMenu.frame.AddToGUIUpdateList()
end)
    
Hook.Patch("Barotrauma.SubEditorScreen", "AddToGUIUpdateList", function()
    SandboxMenu.frame.AddToGUIUpdateList()
end)
Hook.Patch("Barotrauma.GUI", "TogglePauseMenu", {}, function(instance, ptable)
    if not GUI.PauseMenuOpen and menu.Visible then
        menu.Visible = false
        ptable.PreventExecution = true
    end
end, Hook.HookMethodType.Before)

function SandboxMenu.RegisterTab(tab)
    table.insert(SandboxMenu.MenuModules, tab)
end

function SandboxMenu.HideAllTabs()
    for k, v in ipairs(SandboxMenu.MenuModules) do
        v.Visible = false        
    end
end