SandboxMenu = SandboxMenu or {}

if SERVER then
    require("lsm.item_menu.give_items_sv")
    require("lsm.affliction_menu.affliction_menu_sv")
else
    require("lsm.base_cl")
    require("lsm.item_menu.item_menu_cl")
    require("lsm.affliction_menu.affliction_menu_cl")
end