include("npc_weapon_shop/sh_config.lua")

local shopFrame
local weapons = {}

local function OpenShop()
    if IsValid(shopFrame) then shopFrame:Remove() end

    shopFrame = vgui.Create("DFrame")
    shopFrame:SetTitle("Weapon Shop")
    shopFrame:SetSize(520, 360)
    shopFrame:Center()
    shopFrame:MakePopup()

    local money = vgui.Create("DLabel", shopFrame)
    money:SetPos(14, 34)
    money:SetSize(492, 20)
    money:SetFont("Trebuchet18")

    local list = vgui.Create("DListView", shopFrame)
    list:SetPos(14, 60)
    list:SetSize(492, 240)
    list:AddColumn("Weapon")
    list:AddColumn("Cost")

    for _, w in ipairs(weapons) do
        list:AddLine(w.name, "$" .. w.cost)
    end

    local buy = vgui.Create("DButton", shopFrame)
    buy:SetPos(14, 310)
    buy:SetSize(492, 34)
    buy:SetText("Buy")

    buy.DoClick = function()
        local id = list:GetSelectedLine()
        if not id then return end
        net.Start("NPCShop_Buy")
            net.WriteString(weapons[id].class)
        net.SendToServer()
    end

    shopFrame.Think = function()
        money:SetText("Money: $" .. LocalPlayer():GetNWInt("NPCShop_Money", 0))
    end
end

net.Receive("NPCShop_Open", function()
    weapons = {}
    local count = net.ReadUInt(8)
    for i = 1, count do
        weapons[i] = {
            name = net.ReadString(),
            class = net.ReadString(),
            cost = net.ReadUInt(16)
        }
    end
    OpenShop()
end)

net.Receive("NPCShop_Notify", function()
    chat.AddText(Color(255,220,120), "[Shop] ", color_white, net.ReadString())
end)

local nextOpen = 0
hook.Add("PlayerButtonDown", "NPCShop_KeyOpen", function(ply, key)
    if ply ~= LocalPlayer() then return end
    if CurTime() < nextOpen then return end
    if key == KEY_M then
        nextOpen = CurTime() + 0.3
        RunConsoleCommand("npcshop_open")
    end
end)

hook.Add("HUDPaint", "NPCShop_HUD", function()
    local money = LocalPlayer():GetNWInt("NPCShop_Money", 0)
    draw.RoundedBox(8, 20, 20, 220, 56, Color(0,0,0,170))
    draw.SimpleText("Money: $" .. money, "Trebuchet24", 30, 26, color_white)
    draw.SimpleText("Press M for Shop", "Trebuchet18", 30, 48, Color(200,200,200))
end)

hook.Add("Think", "NPCShop_HUDButton", function()
    if IsValid(NPCShop_Button) then return end
    NPCShop_Button = vgui.Create("DButton")
    NPCShop_Button:SetPos(20, 20)
    NPCShop_Button:SetSize(220, 56)
    NPCShop_Button:SetText("")
    NPCShop_Button:SetAlpha(0)
    NPCShop_Button.DoClick = function()
        RunConsoleCommand("npcshop_open")
    end
end)
