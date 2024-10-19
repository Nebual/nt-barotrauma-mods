-- Спавн предметов
SandboxMenu.ItemSpawn = SandboxMenu.ItemSpawn or {}
SandboxMenu.ItemSpawn.ItemList = {}
SandboxMenu.ItemSpawn.SelectedCategory = -1
SandboxMenu.ItemSpawn.SelectedQuality = 0
SandboxMenu.ItemSpawn.SelectedCount = 1
SandboxMenu.ItemSpawn.ItemCount = 1
SandboxMenu.ItemSpawn.SelectedMod = -1 
SandboxMenu.ItemSpawn.ItemName = ""
SandboxMenu.ItemSpawn.SearchID = 0

SandboxMenu.ItemSpawn.CachedSprites = {}

SandboxMenu.ItemSpawn.ModList = {
    [-1] = "All Mods"
}
SandboxMenu.ItemSpawn.AllItems = ItemPrefab.Prefabs.Keys

SandboxMenu.ItemSpawn.itemCategoryEnums = { -- All categories
    [-1] = "All Items",
    "Structure",
    "Decorative",
    "Machine",
    "Medical",
    "Weapon",
    "Diving",
    "Equipment",
    "Fuel",
    "Electrical",
    "Material",
    "Alien",
    "Wrecked",
    "ItemAssembly",
    "Legacy",
    "Misc",
}


local function AllItemsWithCorrectName()
    local tbl = {}
    
    for k, v in pairs(SandboxMenu.ItemSpawn.ItemList) do
        if string.find( string.lower(v.name), string.lower(SandboxMenu.ItemSpawn.ItemName)) then
            table.insert(tbl, v)
        end
    end

    return tbl
end

-- FILTRATION FUNCTIONS
local function AllItemsWithCorrectCategory(unfiltredTable)
    local tbl = {}
    
    for k, v in pairs(unfiltredTable) do
        if v.category == SandboxMenu.ItemSpawn.SelectedCategory then    
            table.insert(tbl, v)
        end
    end

    return tbl
end

local function AllItemsWithSelectedMod(unfiltredTable)
    local tbl = {}
    
    for k, v in pairs(unfiltredTable) do
        if SandboxMenu.TableFindKeyByValue(SandboxMenu.ItemSpawn.ModList, v.mod) == SandboxMenu.ItemSpawn.SelectedMod then
            table.insert(tbl, v)
        end
    end

    return tbl
end

local function SortTableAlphabetically(unfiltredTable)

    local function sortObj(objA, objB)
        return objA.name < objB.name
    end

    table.sort(unfiltredTable, sortObj)

end

function SandboxMenu.ItemSpawn.EnumItemCategoryToInteger(category) -- Convert enumerator id to int id
    if (category == 1) then
        return 1
    end
    return math.floor(math.log(category, 2) + 1)
end

local itemTab = GUI.Frame(GUI.RectTransform(Vector2(0.995, 0.935), SandboxMenu.menuContent.RectTransform, GUI.Anchor.TopCenter))
itemTab.RectTransform.AbsoluteOffset = Point(0, 65)
itemTab.Visible = false


-- Item List
local itemSelectMenu = GUI.ListBox(GUI.RectTransform(Vector2(0.95, 0.9), itemTab.RectTransform, GUI.Anchor.BottomCenter)) 
itemSelectMenu.RectTransform.AbsoluteOffset = Point(0, 25)

local maxItemsInRow = 12

function SandboxMenu.ItemSpawn.DrawItems()

    local processedItemsList = AllItemsWithCorrectName() -- Seeking by name 

    if SandboxMenu.ItemSpawn.SelectedCategory ~= -1 then -- if selected not All items
        processedItemsList = AllItemsWithCorrectCategory(processedItemsList) -- Seeking by category
    end
    if SandboxMenu.ItemSpawn.SelectedMod ~= -1 then -- if selected not All Mods
        processedItemsList = AllItemsWithSelectedMod(processedItemsList) -- Seeking by category
    end

    SortTableAlphabetically(processedItemsList)

    local itemCount = math.ceil(#processedItemsList / maxItemsInRow)

    itemSelectMenu.ClearChildren() 

    local itemsLines = {}

    for i = 1, itemCount do
        itemsLines[i] = GUI.ListBox(GUI.RectTransform(Vector2(1, 0.1), itemSelectMenu.Content.RectTransform, GUI.Anchor.TopLeft), true)
    end


    local function DrawNextItem(k, id)
        if (id ~= SandboxMenu.ItemSpawn.SearchID) then return end

        local v = processedItemsList[k]
        if (not v) then return end

        local currentItemLine = math.floor(k / maxItemsInRow)
        if (k % maxItemsInRow ~= 0) then
            currentItemLine = currentItemLine + 1
        end

        local imageItemFrame = GUI.Button(GUI.RectTransform(Point(65*GUI.xScale, 65*GUI.yScale), itemsLines[currentItemLine].Content.RectTransform))

        imageItemFrame.Color = Color(0,0,0,0)
        imageItemFrame.HoverColor = Color(0,0,0,0)
        imageItemFrame.PressedColor = Color(0,0,0,0)
        imageItemFrame.SelectedColor = Color(0,0,0,0)

        imageItemFrame.OnClicked = function()

            -- If singleplayer
            if (Game.IsSingleplayer) then
                for _, character in pairs(Character.CharacterList) do
                    if character.IsLocalPlayer then
                        for i = 1, SandboxMenu.ItemSpawn.SelectedCount do
                            Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab(v.id.ToString()), character.Inventory, nil, SandboxMenu.ItemSpawn.SelectedQuality, nil)
                        end
                    end
                end

                return
            end 

            -- If multiplayer
            local netMsg = Networking.Start("SpawnMenuMod_RequestSpawn");
            netMsg.WriteString(v.id.ToString())
            netMsg.WriteInt16(SandboxMenu.ItemSpawn.SelectedQuality)
            netMsg.WriteInt16(SandboxMenu.ItemSpawn.SelectedCount)
            Networking.Send(netMsg)

        end

        imageItemFrame.RectTransform.MinSize = Point(0, 65*GUI.yScale)
        local sprite = v.inventoryIcon
        local image = GUI.Image(GUI.RectTransform(Vector2(0.95, 0.95), imageItemFrame.RectTransform, GUI.Anchor.Center), sprite)
        image.ToolTip = RichString.Rich(ItemPrefab.GetItemPrefab(v.id.ToString()).GetTooltip().ToString() .. "\n‖color:gui.white‖(identifier: " .. v.id.ToString() ..")‖end‖" );
        
        Timer.NextFrame(function()
            DrawNextItem(k+1, id) 
        end)
   
    end

    SandboxMenu.ItemSpawn.SearchID = SandboxMenu.ItemSpawn.SearchID + 1
    DrawNextItem(1, SandboxMenu.ItemSpawn.SearchID)
end


-- Item categories drop menu
local itemCategory = GUI.DropDown(GUI.RectTransform(Vector2(0.15, 0.05), itemTab.RectTransform, GUI.Anchor.TopLeft), "All Items", 6, nil, false)
itemCategory.RectTransform.AbsoluteOffset = Point(25 * GUI.xScale, 15)

for k, v in pairs(SandboxMenu.ItemSpawn.itemCategoryEnums) do -- Adding all categories
    itemCategory.AddItem(v, k)
end

itemCategory.OnSelected = function (guiComponent, object) -- Selection Function
    SandboxMenu.ItemSpawn.SelectedCategory = object
    SandboxMenu.ItemSpawn.DrawItems()
end

-- Mods drop menu
local modSelection = GUI.DropDown(GUI.RectTransform(Vector2(0.15, 0.05), itemTab.RectTransform, GUI.Anchor.TopLeft), "All Mods", 6, nil, false)
modSelection.RectTransform.AbsoluteOffset = Point(160 * GUI.xScale, 15)

for k, v in pairs(SandboxMenu.ItemSpawn.ModList) do -- Adding all categories
    modSelection.AddItem(v, k)
end

modSelection.OnSelected = function (guiComponent, object) -- Selection Function
    SandboxMenu.ItemSpawn.SelectedMod = object
    SandboxMenu.ItemSpawn.DrawItems()
end

local itemQuality = GUI.DropDown(GUI.RectTransform(Vector2(0.15, 0.05), itemTab.RectTransform, GUI.Anchor.TopLeft), "Normal Quality", 4, nil, false)
itemQuality.RectTransform.AbsoluteOffset = Point(293 * GUI.xScale, 15)
itemQuality.AddItem("Normal Quality", 0)
itemQuality.AddItem("Good Quality", 1)
itemQuality.AddItem("Excellent Quality", 2)
itemQuality.AddItem("Masterwork Quality", 3)

itemQuality.OnSelected = function (s, object)
    SandboxMenu.ItemSpawn.SelectedQuality = object
end

local countText = GUI.TextBlock(GUI.RectTransform(Vector2(0.35, 0.1), itemTab.RectTransform), "1", nil, nil, GUI.Alignment.Center)
countText.RectTransform.AbsoluteOffset = Point(380 * GUI.xScale, 10)

local selectedCount = GUI.ScrollBar(GUI.RectTransform(Vector2(0.22, 0.1), itemTab.RectTransform), 0.1, nil, "GUISlider")
selectedCount.RectTransform.AbsoluteOffset = Point(440 * GUI.xScale, 15)
selectedCount.Range = Vector2(1, 62)
selectedCount.BarScrollValue = 1
selectedCount.OnMoved = function ()
    SandboxMenu.ItemSpawn.SelectedCount = math.floor(selectedCount.BarScrollValue)
    countText.Text = tostring(SandboxMenu.ItemSpawn.SelectedCount)
end

-- Item name textbox
local findItemByNameTextBox = GUI.TextBox(GUI.RectTransform(Vector2(0.25, 0.2), itemTab.RectTransform, GUI.Anchor.TopRight), SandboxMenu.ItemSpawn.ItemName) -- Find item by name
findItemByNameTextBox.RectTransform.AbsoluteOffset = Point(25 * GUI.xScale, 15)

findItemByNameTextBox.OnTextChangedDelegate = function(textBox)
    SandboxMenu.ItemSpawn.ItemName = textBox.Text
    SandboxMenu.ItemSpawn.DrawItems()
end

-- Все предметы в добавляем в список
for k, v in ipairs(SandboxMenu.ItemSpawn.AllItems) do
    if (ItemPrefab.GetItemPrefab(v)) then
        
        local itemPrefab = ItemPrefab.GetItemPrefab(v)  

        table.insert(SandboxMenu.ItemSpawn.ItemList, {
            id = v,
            name = itemPrefab.ToString(),
            description = itemPrefab.Description.ToString(),
            inventoryIcon = itemPrefab.InventoryIcon or itemPrefab.Sprite,
            category = SandboxMenu.ItemSpawn.EnumItemCategoryToInteger(itemPrefab.category),
            mod = itemPrefab.ContentPackage.Name,
        } )

        
        if not SandboxMenu.TableHasValue(SandboxMenu.ItemSpawn.ModList, itemPrefab.ContentPackage.Name) then -- Adding mod in modlist if we didn't added it befor
            table.insert(SandboxMenu.ItemSpawn.ModList, itemPrefab.ContentPackage.Name)
        end
    
    end

end


-- Creating button
local itemButton = GUI.Button(GUI.RectTransform(Vector2(0.1, 0.15), SandboxMenu.menuContent.RectTransform, GUI.Anchor.TopLeft), "Items", GUI.Alignment.Center, "GUIButtonSmall")
itemButton.RectTransform.AbsoluteOffset = Point(25, 25)
itemButton.OnClicked = function ()
    SandboxMenu.HideAllTabs()
    itemTab.Visible = true
    SandboxMenu.ItemSpawn.DrawItems()
end

SandboxMenu.RegisterTab(itemTab)