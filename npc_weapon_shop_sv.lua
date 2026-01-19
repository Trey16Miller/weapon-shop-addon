AddCSLuaFile()
AddCSLuaFile("npc_weapon_shop/sh_config.lua")
AddCSLuaFile("autorun/client/npc_weapon_shop_cl.lua")

include("npc_weapon_shop/sh_config.lua")

util.AddNetworkString("NPCShop_Open")
util.AddNetworkString("NPCShop_Buy")
util.AddNetworkString("NPCShop_Notify")

local function GetMoney(ply)
    return ply:GetNWInt("NPCShop_Money", 0)
end

local function SetMoney(ply, amt)
    amt = math.max(0, math.floor(tonumber(amt) or 0))
    ply:SetNWInt("NPCShop_Money", amt)
end

hook.Add("PlayerInitialSpawn", "NPCShop_LoadMoney", function(ply)
    timer.Simple(1, function()
        if not IsValid(ply) then return end
        SetMoney(ply, tonumber(ply:GetPData("npcshop_money", "0")) or 0)
    end)
end)

hook.Add("PlayerDisconnected", "NPCShop_SaveMoney", function(ply)
    if not IsValid(ply) then return end
    ply:SetPData("npcshop_money", tostring(GetMoney(ply)))
end)

hook.Add("OnNPCKilled", "NPCShop_GiveMoneyScaled", function(npc, attacker)
    if not IsValid(npc) or not IsValid(attacker) then return end

    if attacker:IsVehicle() and IsValid(attacker:GetDriver()) then
        attacker = attacker:GetDriver()
    end
    if not IsValid(attacker) or not attacker:IsPlayer() then return end

    local maxHealth = npc:GetMaxHealth()
    if not maxHealth or maxHealth <= 0 then
        maxHealth = npc:Health()
    end
    if not maxHealth or maxHealth <= 0 then
        maxHealth = 100
    end

    local reward = math.Clamp(math.floor(maxHealth * 0.5), 10, 2000)
    SetMoney(attacker, GetMoney(attacker) + reward)
end)

local function Notify(ply, msg)
    net.Start("NPCShop_Notify")
        net.WriteString(msg or "")
    net.Send(ply)
end

concommand.Add("npcshop_open", function(ply)
    if not IsValid(ply) then return end

    net.Start("NPCShop_Open")
        net.WriteUInt(#NPCSHOP.Weapons, 8)
        for _, w in ipairs(NPCSHOP.Weapons) do
            net.WriteString(w.name)
            net.WriteString(w.class)
            net.WriteUInt(w.cost, 16)
        end
    net.Send(ply)
end)

net.Receive("NPCShop_Buy", function(_, ply)
    if not IsValid(ply) then return end

    local class = net.ReadString()
    if not isstring(class) or class == "" then return end

    local weapon
    for _, w in ipairs(NPCSHOP.Weapons) do
        if w.class == class then
            weapon = w
            break
        end
    end

    if not weapon then
        Notify(ply, "That weapon is not for sale.")
        return
    end

    local money = GetMoney(ply)
    if money < weapon.cost then
        Notify(ply, "Not enough money.")
        return
    end

    if ply:HasWeapon(class) then
        Notify(ply, "You already have that weapon.")
        return
    end

    SetMoney(ply, money - weapon.cost)
    ply:Give(class)
    ply:SelectWeapon(class)

    Notify(ply, "Purchased " .. weapon.name)
end)
