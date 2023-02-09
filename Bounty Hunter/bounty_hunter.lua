--[[
- Script Name : Bounty Hunter
- Made By : PrivateDonut
- Version : 2.0
- Description : This script will allow you to set a bounty on a player. If the player is killed by another player, the bounty hunter will receive a reward.
]] --
-- General Settings
local bountyScript = true -- Enable/Disable entire script
local npcid = 100000 -- NPC Entry ID
local rewardGold = true --  Gold Reward Gossip Menu
local rewardItem = true -- Item Reward Gossip Menu
local rewardItemID = 20880 -- Item ID used to place bounties

-- Bounty Minimum & Maximum
-- Bounty is in gold
local minGoldBounty = 50 -- Min Gold Amount
local maxGoldBounty = 100000 -- Max Gold Amount
-- Bounty is in item count
local minItemBounty = 10 -- Min Item Amount
local maxItemBounty = 100 -- Max Item Amount

-- Bounty Hunter Checks
-- These settings will return false not claiming the bounty reward if any that are set to true are valid. For example, if checkIsGM is set to true and the player placing the bounty is a GM, the bounty will not be placed.
local checkIsGM = false -- Check if player is a GM
local checkIsInCombat = true -- Check if player is in combat
local checkIfSameIP = false -- Check if player is placing a bounty on someone with the same IP

-- Do not edit below this line unless you know what you're doing.
if bountyScript == true then
    -- Format current in-game example: 1000 = 1,000
    local function format_number(NUM)
        local s = string.format("%d", NUM)
        local formatted = s:gsub("(%d)(%d%d%d)$", "%1,%2")
        formatted = formatted:gsub("(%d)(%d%d%d)%.", "%1.%2.")
        return formatted
    end
    -- Convert copper to gold
    local function convertMoney(gold)
        local gold = gold * 10000
        return gold
    end

    local function OnGossipHello(event, player, creature)
        if rewardGold == true then
            player:GossipMenuAddItem(0, "Place Bounty With Gold", 0, 1, 1,
                "|cFFFF0000Bounty Hunter|r\n\n Place your bounty\n  Minimum Bounty: |cFF00FF00" ..
                    format_number(minGoldBounty) .. " gold|r\n Maximum Bounty: |cFF00FF00" ..
                    format_number(maxGoldBounty) .. " gold|r\n\n" .. "Accept and enter bounty amount", code)
        end
        if rewardItem == true then
            player:GossipMenuAddItem(0, "Place Bounty With " .. GetItemLink(rewardItemID) .. "", 0, 10, 1,
                "|cFFFF0000Bounty Hunter|r\n\n  Place your bounty\n  Minimum Bounty: |cffFF4809" ..
                    format_number(minItemBounty) .. " " .. GetItemLink(rewardItemID) ..
                    "|r\n Maximum Bounty: |cffFF4809" .. format_number(maxItemBounty) .. " " ..
                    GetItemLink(rewardItemID) .. "|r\n\n" .. "Accept and enter bounty amount", code)
        end
        player:GossipSendMenu(1, creature)
    end

    local function GoldBounty(event, player, creature, sender, intid, code, menuid)
        -- Get the gold amount and store it in the temp bounty table. 
        if (intid == 1) then
            if (tonumber(code)) then
                bountyAmount = tonumber(code)
                player:GossipMenuAddItem(0, "Enter Players Name", 0, 3, 1,
                    "|cFFFF0000[Bounty Hunter]|r\n\n Enter players name." .. "\n\n|cFF00FF00Bounty Amount: |r" ..
                        format_number(bountyAmount) .. " gold")
                player:GossipSendMenu(1, creature)
            else
                player:SendBroadcastMessage("|cFFFF0000[Bounty Hunter]|r You must enter a gold amount.")
            end
        end

        if (intid == 3) then
            if (tostring(code)) then
                local target = tostring(code)
                -- get target by name
                local targetName = GetPlayerByName(target)
                if targetName == nil then
                    player:SendBroadcastMessage("|cFFFF0000[Bounty Hunter]|r Player not found or may be offline.")
                    return
                end
                local targetGuid = targetName:GetGUIDLow() -- Get target GUID
                -- Get class colors for each class ID.
                local Classes = {
                    [1] = "|cffC79C6E", -- Warrior
                    [2] = "|cffF58CBA", -- Paladin
                    [3] = "|cffABD473", -- Hunter
                    [4] = "|cffFFF569", -- Rogue
                    [5] = "|cffFFFFFF", -- Priest
                    [6] = "|cffC41F3B", -- Death Knight
                    [7] = "|cff0070DE", -- Shaman
                    [8] = "|cff69CCF0", -- Mage
                    [9] = "|cff9482C9", -- Warlock
                    [11] = "|cff00FF96" -- Druid
                }
                local targetClass = Classes[targetName:GetClass()]
                local playerClass = Classes[player:GetClass()]

                if checkIsGM == true and player:IsGM() == true then -- Check if player is a GM
                    player:SendBroadcastMessage("|cFFFF0000[Bounty Hunter]|r You cannot place a bounty on a GM.")
                    return
                elseif checkIsInCombat == true and player:IsInCombat() == true then -- Check if player is in combat
                    player:SendBroadcastMessage("|cFFFF0000[Bounty Hunter]|r You cannot place a bounty while in combat.")
                    return
                elseif checkIfSameIP == true and player:GetPlayerIP() == target:GetPlayerIP() then -- Check if player is placing a bounty on someone with the same IP
                    player:SendBroadcastMessage(
                        "|cFFFF0000[Bounty Hunter]|r You cannot place a bounty on someone with the same IP.")
                    return
                elseif bountyAmount < minGoldBounty then -- Check if bounty amount is less than the minimum bounty amount
                    player:SendBroadcastMessage(
                        "|cFFFF0000[Bounty Hunter]|r You cannot place a bounty less than |cFF00FF00" ..
                            format_number(minGoldBounty) .. " gold|r.")
                    return
                elseif bountyAmount > maxGoldBounty then -- Check if bounty amount is greater than the maximum bounty amount
                    player:SendBroadcastMessage(
                        "|cFFFF0000[Bounty Hunter]|r You cannot place a bounty greater than |cFF00FF00" ..
                            format_number(maxGoldBounty) .. " gold|r.")
                    return
                elseif convertMoney(player:GetCoinage()) < convertMoney(bountyAmount) then -- Check if player has enough gold to place the bounty
                    player:SendBroadcastMessage(
                        "|cFFFF0000[Bounty Hunter]|r You do not have enough gold to place this bounty.")
                    return
                else
                    local query = CharDBQuery("SELECT * FROM bounties WHERE placedOn = '" .. targetGuid .. "'")
                    -- if query is not nil
                    if query then
                        player:SendBroadcastMessage("|cFFFF0000[Bounty Hunter]|r|cff00FFF6 " .. target ..
                                                        " already has a bounty on them.|r")
                        player:GossipComplete()
                    else -- else place bounty information inside database.

                        CharDBExecute("INSERT INTO bounties (placedBy, placedOn, goldAmount) VALUES ('" ..
                                          player:GetGUIDLow() .. "', '" .. targetGuid .. "', '" ..
                                          format_number(bountyAmount) .. "')")
                        SendWorldMessage("|cFFFF0000[Bounty Hunter]|r|cff00FFF6 " .. playerClass .. "" ..
                                             player:GetName() .. "|r has placed a bounty on " .. targetClass .. "" ..
                                             target .. "|r for " .. format_number(bountyAmount) ..
                                             "|r |cffFFFF00gold.|r")
                        player:SendBroadcastMessage("|cFFFF0000[Bounty Hunter]|r|cff00FFF6 " ..
                                                        format_number(bountyAmount) ..
                                                        " gold has been removed from you.|r")
                        player:ModifyMoney(-convertMoney(bountyAmount))
                        player:GossipComplete()
                    end
                end
            end
        end
    end

    local function ItemBounty(event, player, creature, sender, intid, code, menuid)
        -- Get the gold amount and store it in the temp bounty table. 
        if (intid == 10) then
            if (tonumber(code)) then
                bountyAmount = tonumber(code)
                player:GossipMenuAddItem(0, "Enter Players Name", 0, 11, 1,
                    "|cFFFF0000[Bounty Hunter]|r\n\n Enter players name." .. "\n\n|cFF00FF00Bounty Amount: |r" ..
                        format_number(bountyAmount) .. "" .. GetItemLink(rewardItemID) .. "")
                player:GossipSendMenu(1, creature)
            else
                player:SendBroadcastMessage("|cFFFF0000[Bounty Hunter]|r You must enter a gold amount.")
            end
        end

        if (intid == 11) then
            if (tostring(code)) then
                local target = tostring(code)
                -- get target by name
                local targetName = GetPlayerByName(target)
                if targetName == nil then
                    player:SendBroadcastMessage("|cFFFF0000[Bounty Hunter]|r Player not found or may be offline.")
                    return
                end
                local targetGuid = targetName:GetGUIDLow() -- Get target GUID
                -- Get class colors for each class ID.
                local Classes = {
                    [1] = "|cffC79C6E", -- Warrior
                    [2] = "|cffF58CBA", -- Paladin
                    [3] = "|cffABD473", -- Hunter
                    [4] = "|cffFFF569", -- Rogue
                    [5] = "|cffFFFFFF", -- Priest
                    [6] = "|cffC41F3B", -- Death Knight
                    [7] = "|cff0070DE", -- Shaman
                    [8] = "|cff69CCF0", -- Mage
                    [9] = "|cff9482C9", -- Warlock
                    [11] = "|cff00FF96" -- Druid
                }
                local targetClass = Classes[targetName:GetClass()]
                local playerClass = Classes[player:GetClass()]

                if checkIsGM == true and player:IsGM() == true then -- Check if player is a GM
                    player:SendBroadcastMessage("|cFFFF0000[Bounty Hunter]|r You cannot place a bounty on a GM.")
                    player:GossipComplete()
                    return
                elseif checkIsInCombat == true and player:IsInCombat() == true then -- Check if player is in combat
                    player:SendBroadcastMessage("|cFFFF0000[Bounty Hunter]|r You cannot place a bounty while in combat.")
                    player:GossipComplete()
                    return
                elseif checkIfSameIP == true and player:GetPlayerIP() == targetName:GetPlayerIP() then -- Check if player is placing a bounty on someone with the same IP
                    player:SendBroadcastMessage(
                        "|cFFFF0000[Bounty Hunter]|r You cannot place a bounty on someone with the same IP.")
                    player:GossipComplete()
                    return
                elseif bountyAmount < minItemBounty then -- Check if bounty amount is less than the minimum bounty amount
                    player:SendBroadcastMessage(
                        "|cFFFF0000[Bounty Hunter]|r You cannot place a bounty less than |cFF00FF00" ..
                            format_number(minItemBounty) .. " " .. GetItemLink(rewardItemID) .. "|r.")
                    return
                elseif bountyAmount > maxItemBounty then -- Check if bounty amount is greater than the maximum bounty amount
                    player:SendBroadcastMessage(
                        "|cFFFF0000[Bounty Hunter]|r You cannot place a bounty greater than |cFF00FF00" ..
                            format_number(maxItemBounty) .. " " .. GetItemLink(rewardItemID) .. "|r.")
                    return
                elseif player:GetItemCount(rewardItemID) < bountyAmount then -- Check if player has enough gold to place the bounty
                    player:SendBroadcastMessage("|cFFFF0000[Bounty Hunter]|r You do not have enough " ..
                                                    GetItemLink(rewardItemID) .. " to place this bounty.")
                    return
                else
                    local query = CharDBQuery("SELECT * FROM bounties WHERE placedOn = '" .. targetGuid .. "'")
                    -- if query is not nil
                    if query then
                        player:SendBroadcastMessage("|cFFFF0000[Bounty Hunter]|r|cff00FFF6 " .. target ..
                                                        " already has a bounty on them.|r")
                        player:GossipComplete()
                    else -- else place bounty information inside database.

                        CharDBExecute("INSERT INTO bounties (placedBy, placedOn, itemAmount) VALUES ('" ..
                                          player:GetGUIDLow() .. "', '" .. targetGuid .. "', '" ..
                                          format_number(bountyAmount) .. "')")
                        SendWorldMessage("|cFFFF0000[Bounty Hunter]|r|cff00FFF6 " .. playerClass .. "" ..
                                             player:GetName() .. "|r has placed a bounty on " .. targetClass .. "" ..
                                             target .. "|r for " .. format_number(bountyAmount) .. "|r |cffFFFF00" ..
                                             GetItemLink(rewardItemID) .. "|r.")
                        player:SendBroadcastMessage("|cFFFF0000[Bounty Hunter]|r|cff00FFF6 " ..
                                                        format_number(bountyAmount) .. " " .. GetItemLink(rewardItemID) ..
                                                        " has been removed from you.|r")
                        player:RemoveItem(rewardItemID, bountyAmount)
                        player:GossipComplete()
                    end
                end
            end
        end
    end

    local function OnPlayerKillPlayer(event, killer, killed)
        if rewardItem == true then
            if checkIsGM == true and killer:IsGM() == true then
                killer:SendBroadcastMessage("|cFFFF0000[Bounty Hunter]|r You cannot claim a bounty on a GM.")
                return
            elseif checkIfSameIP == true and killer:GetPlayerIP() == killed:GetPlayerIP() then
                killer:SendBroadcastMessage(
                    "|cFFFF0000[Bounty Hunter]|r You cannot claim a bounty on someone with the same IP.")
                return
            else
                local query = CharDBQuery("SELECT * FROM bounties WHERE placedOn = '" .. killed:GetGUIDLow() .. "'")
                if query then
                    local placedBy = query:GetUInt32(1)
                    local placedOn = query:GetUInt32(2)
                    local goldAmount = query:GetUInt32(3)
                    local itemAmount = query:GetUInt32(4)
                    local placedByName = GetPlayerByGUID(placedBy):GetName()
                    local placedOnName = GetPlayerByGUID(placedOn):GetName()
                    local placedByClass = GetPlayerByGUID(placedBy):GetClass()
                    local placedOnClass = GetPlayerByGUID(placedOn):GetClass()
                    local Classes = {
                        [1] = "|cffC79C6E", -- Warrior
                        [2] = "|cffF58CBA", -- Paladin
                        [3] = "|cffABD473", -- Hunter
                        [4] = "|cffFFF569", -- Rogue
                        [5] = "|cffFFFFFF", -- Priest
                        [6] = "|cffC41F3B", -- Death Knight
                        [7] = "|cff0070DE", -- Shaman
                        [8] = "|cff69CCF0", -- Mage
                        [9] = "|cff9482C9", -- Warlock
                        [11] = "|cff00FF96" -- Druid
                    }
                    local killerClass = Classes[killer:GetClass()]
                    local killedClass = Classes[killed:GetClass()]

                    if goldAmount == nil or goldAmount == 0 then
                        killer:AddItem(rewardItemID, itemAmount)
                        SendWorldMessage("|cFFFF0000[Bounty Hunter]|r|cff00FFF6 " .. killerClass .. "" ..
                                             killer:GetName() .. "|r has claimed the bounty on " .. killedClass .. "" ..
                                             killed:GetName() .. "|r for " .. itemAmount .. " " ..
                                             GetItemLink(rewardItemID) .. "|r.")

                        CharDBExecute("DELETE FROM bounties WHERE placedOn = '" .. killed:GetGUIDLow() .. "'")
                    end
                end
            end
        end

        if rewardGold == true then
            if checkIsGM == true and killer:IsGM() == true then
                killer:SendBroadcastMessage("|cFFFF0000[Bounty Hunter]|r You cannot claim a bounty on a GM.")
                return
            elseif checkIfSameIP == true and killer:GetPlayerIP() == killed:GetPlayerIP() then
                killer:SendBroadcastMessage(
                    "|cFFFF0000[Bounty Hunter]|r You cannot claim a bounty on someone with the same IP.")
                return
            else
                local query = CharDBQuery("SELECT * FROM bounties WHERE placedOn = '" .. killed:GetGUIDLow() .. "'")
                if query then
                    local placedBy = query:GetUInt32(1)
                    local placedOn = query:GetUInt32(2)
                    local goldAmount = query:GetUInt32(3)
                    local itemAmount = query:GetUInt32(4)
                    local placedByName = GetPlayerByGUID(placedBy):GetName()
                    local placedOnName = GetPlayerByGUID(placedOn):GetName()
                    local placedByClass = GetPlayerByGUID(placedBy):GetClass()
                    local placedOnClass = GetPlayerByGUID(placedOn):GetClass()
                    local Classes = {
                        [1] = "|cffC79C6E", -- Warrior
                        [2] = "|cffF58CBA", -- Paladin
                        [3] = "|cffABD473", -- Hunter
                        [4] = "|cffFFF569", -- Rogue
                        [5] = "|cffFFFFFF", -- Priest
                        [6] = "|cffC41F3B", -- Death Knight
                        [7] = "|cff0070DE", -- Shaman
                        [8] = "|cff69CCF0", -- Mage
                        [9] = "|cff9482C9", -- Warlock
                        [11] = "|cff00FF96" -- Druid
                    }
                    local killerClass = Classes[killer:GetClass()]
                    local killedClass = Classes[killed:GetClass()]

                    if itemAmount == nil or itemAmount == 0 then
                        killer:ModifyMoney(convertMoney(goldAmount))
                        SendWorldMessage("|cFFFF0000[Bounty Hunter]|r|cff00FFF6 " .. killerClass .. "" ..
                                             killer:GetName() .. "|r has claimed the bounty on " .. killedClass .. "" ..
                                             killed:GetName() .. "|r for " .. goldAmount .. " gold.")
                        CharDBExecute("DELETE FROM bounties WHERE placedOn = '" .. killed:GetGUIDLow() .. "'")
                    end
                end
            end
        end
    end

    RegisterCreatureGossipEvent(npcid, 1, OnGossipHello)
    RegisterCreatureGossipEvent(npcid, 2, GoldBounty)
    RegisterCreatureGossipEvent(npcid, 2, ItemBounty)
    RegisterPlayerEvent(6, OnPlayerKillPlayer)
end