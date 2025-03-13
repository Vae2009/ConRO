ConRO.RaidBuffs = {};
ConRO.WarningFlags = {};

-- Global cooldown spell id
local _GlobalCooldown = 61304;

local INF = 2147483647;

function ConRO:SpecName()
	local currentSpec = GetSpecialization();
	local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or 'None';
	return currentSpecName;
end

function ConRO:HeroSpec(subTreeID)
	local heroSpecID = C_ClassTalents.GetActiveHeroTalentSpec()
	local currentSpec = false;
	if heroSpecID ~= nil then
		if heroSpecID == subTreeID then
			currentSpec = true;
		end
	end

	return currentSpec
end

function ConRO:CheckTalents()
	self.PlayerTalents = {}
	wipe(self.PlayerTalents)

	local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then return end

    local configInfo = C_Traits.GetConfigInfo(configID)
    local treeIDs = configInfo and configInfo.treeIDs
    if not treeIDs then return end

    for _, treeID in ipairs(treeIDs) do
        local nodes = C_Traits.GetTreeNodes(treeID)
        for _, nodeID in ipairs(nodes) do
            local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
            if nodeInfo and nodeInfo.currentRank and nodeInfo.currentRank > 0 then
                local entryID = nodeInfo.activeEntry and nodeInfo.activeEntry.entryID or 
                                nodeInfo.entryIDs and nodeInfo.entryIDs[1]
                if entryID then
                    local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
                    local definitionID = entryInfo and entryInfo.definitionID
                    if definitionID then
                        local definitionInfo = C_Traits.GetDefinitionInfo(definitionID)
                        if definitionInfo then
                            local spellId = definitionInfo.spellID or definitionInfo.overriddenSpellID
                            if spellId then
                                self.PlayerTalents[entryID] = {
                                    id = spellId,
                                    rank = nodeInfo.currentRank,
                                    isHeroTalent = nodeInfo.subTreeID ~= nil
                                }
                            end
                        end
                    end
                end
            end
        end
    end
end

function ConRO:CheckPvPTalents()
	self.PvPTalents = {};
	local talents = C_SpecializationInfo.GetAllSelectedPvpTalentIDs();
	for k,v in ipairs(talents) do
		local _, name, _, _, _, id = GetPvpTalentInfoByID(v or 0);
		self.PvPTalents[id] = name;
	end
end

function ConRO:TalentChosen(entryCheck, rankCheck)
	if rankCheck ~= nil then
		local talent = self.PlayerTalents[entryCheck];
		if talent then
			for _,i in pairs(talent) do
				for k,v in pairs(i) do
					if k == "rank" then
						if v >= rankCheck then
							return true;
						end
					end
				end
				return false;
			end
		end
	else
		return self.PlayerTalents[entryCheck];
	end
end

function ConRO:PvPTalentChosen(talent)
	return self.PvPTalents[talent];
end

function ConRO:BurstMode(_Spell_ID, timeShift)
	local _Burst = ConRO_BurstButton:IsVisible();
	timeShift = timeShift or ConRO:EndCast();
	local _Burst_Threshold = ConRO.db.profile._Burst_Threshold;
	local _Burst_Mode = false;

	if _Spell_ID == "item" then
		if _Burst then
			_Burst_Mode = true;
		end
	else
		local _, _, baseCooldown = ConRO:Cooldown(_Spell_ID, timeShift);

		if _Burst and baseCooldown >= _Burst_Threshold then
			_Burst_Mode = true;
		end
	end

	return _Burst_Mode;
end

function ConRO:FullMode(_Spell_ID, timeShift)
	local _Full = ConRO_FullButton:IsVisible();
	local _Burst = ConRO_BurstButton:IsVisible();
	timeShift = timeShift or ConRO:EndCast();
	local _Burst_Threshold = ConRO.db.profile._Burst_Threshold;
	local _Full_Mode = false;

	if _Spell_ID == "item" then
		if _Full then
			_Full_Mode = true;
		end
	else
		local _, _, baseCooldown = ConRO:Cooldown(_Spell_ID, timeShift);

		if _Burst and baseCooldown < _Burst_Threshold then
			_Full_Mode = true;
		elseif _Full then
			_Full_Mode = true;
		end
	end

	return _Full_Mode;
end

function ConRO:IsPvP()
	local _is_PvP = UnitIsPVP('player');
	local _is_Arena, _is_Registered = IsActiveBattlefieldArena();
	local _Flagged = false;
		if _is_PvP or _is_Arena then
			_Flagged = true;
		end
	return _Flagged;
end

function ConRO:Warnings(_Message, _Condition)
	if self.WarningFlags[_Message] == nil then
		self.WarningFlags[_Message] = 0;
	end
	if _Condition then
		self.WarningFlags[_Message] = self.WarningFlags[_Message] + 1;
		if self.WarningFlags[_Message] == 1 then
			UIErrorsFrame:AddMessage(_Message, 1.0, 1.0, 0.0, 1.0);
		elseif self.WarningFlags[_Message] == 15 then
			self.WarningFlags[_Message] = 0;
		end
	else
		self.WarningFlags[_Message] = 0;
	end
end

ConRO.ItemSlotList = {
	"HeadSlot",
	"NeckSlot",
	"ShoulderSlot",
	"BackSlot",
	"ChestSlot",
	"WristSlot",
	"HandsSlot",
	"WaistSlot",
	"LegsSlot",
	"FeetSlot",
	"Finger0Slot",
	"Finger1Slot",
	"Trinket0Slot",
	"Trinket1Slot",
	"MainHandSlot",
	"SecondaryHandSlot",
}

ConRO.TierSlotList = {
	"HeadSlot",
	"ShoulderSlot",
	"ChestSlot",
	"HandsSlot",
	"LegsSlot",
}

function ConRO:ItemEquipped(_item_string)
	local _match_item_NAME = false;
	local _, _item_LINK = GetItemInfo(_item_string);

	if _item_LINK ~= nil then
		local _item_NAME = GetItemInfo(_item_LINK);

		for i, v in ipairs(ConRO.ItemSlotList) do
			local _slot_LINK = GetInventoryItemLink("player", GetInventorySlotInfo(v));
			if _slot_LINK then
				local _slot_item_NAME = GetItemInfo(_slot_LINK);

				if _slot_item_NAME == _item_NAME then
					_match_item_NAME = true;
					break;
				end
			end
		end
	end
	return _match_item_NAME;
end

function ConRO:UsableTrinket()
	local t13_Usable, t13_RDY, t14_Usable, t14_RDY = false, false, false, false;

	local item13ID = GetInventoryItemID("player", 13)
	if item13ID then
		local _, duration13, enable13 = GetItemCooldown(item13ID)
		if enable13 == 1 then
			t13_Usable = true;
			if duration13 == 0 then
				t13_RDY = true;
			end
		end
	end

	local item14ID = GetInventoryItemID("player", 14)
	if item14ID then
		local _, duration14, enable14 = GetItemCooldown(item14ID)
		if enable14 then
			t14_Usable = true;
			if duration14 == 0 then
				t14_RDY = true;
			end
		end
	end

	return item13ID, t13_Usable, t13_RDY, item14ID, t14_Usable, t14_RDY
end

--[[function ConRO:CountTier()
    local _, _, classIndex = UnitClass("player");
    local count = 0;

	for _, v in pairs(ConRO.TierSlotList) do
		local match = nil
		local _slot_LINK = GetInventoryItemLink("player", GetInventorySlotInfo(v))
		local _slot_item_NAME;

		if _slot_LINK then
			_slot_item_NAME = GetItemInfo(_slot_LINK)
		else
			break
		end

		if _slot_item_NAME == nil then
			return;
		end

		-- Death Knight
		if classIndex == 6 then
			match = string.match(_slot_item_NAME,"of the Risen Nightmare")
		end
		-- Demon Hunter
		if classIndex == 12 then
			match = string.match(_slot_item_NAME,"Screaming Torchfiend's")
		end
		-- Druid
		if classIndex == 11 then
			match = string.match(_slot_item_NAME,"Benevolent Embersage's")
		end
		-- Evoker
		if classIndex == 13 then
			match = string.match(_slot_item_NAME,"Werynkeeper's Timeless")
		end
		-- Hunter
		if classIndex == 3 then
			match = string.match(_slot_item_NAME,"Blazing Dreamstalker's")
		end
		-- Mage
		if classIndex == 8 then
			match = string.match(_slot_item_NAME,"Wayward Chronomancer's")
		end
		-- Monk
		if classIndex == 10 then
			match = string.match(_slot_item_NAME,"Mystic Heron's")
		end
		-- Paladin
		if classIndex == 2 then
			match = string.match(_slot_item_NAME,"Zealous Pyreknight's")
		end
		-- Priest
		if classIndex == 5 then
			match = string.match(_slot_item_NAME,"of Lunar Communion")
		end
		-- Rogue
		if classIndex == 4 then
			match = string.match(_slot_item_NAME,"Lucid Shadewalker's")
		end
		-- Shaman
		if classIndex == 7 then
			match = string.match(_slot_item_NAME,"Greatwolf Outcast's")
		end
		-- Warlock
		if classIndex == 9 then
			match = string.match(_slot_item_NAME,"Devout Ashdevil's")
		end
		-- Warrior
		if classIndex == 1 then
			match = string.match(_slot_item_NAME,"Molten Vanguard's")
		end

		if match then count = count + 1 end
	end
    return count
end]]

function ConRO:PlayerSpeed()
	local speed  = (GetUnitSpeed("player") / 7) * 100;
	local moving = false;
		if speed > 0 then
			moving = true;
		else
			moving = false;
		end
	return moving;
end

ConRO.EnergyList = {
	[0]	= 'Mana',
	[1] = 'Rage',
	[2]	= 'Focus',
	[3] = 'Energy',
	[4]	= 'Combo',
	[6] = 'RunicPower',
	[7]	= 'SoulShards',
	[8] = 'LunarPower',
	[9] = 'HolyPower',
	[11] = 'Maelstrom',
	[12] = 'Chi',
	[13] = 'Insanity',
	[16] = 'ArcaneCharges',
	[17] = 'Fury',
	[19] = 'Essence',
}

function ConRO:PlayerPower(_EnergyType)
	local resource;

	for k, v in pairs(ConRO.EnergyList) do
		if v == _EnergyType then
			resource = k;
			break
		end
	end

	local _Resource = UnitPower('player', resource);
	local _Resource_Max	= UnitPowerMax('player', resource);
	local _Resource_Percent = math.max(0, _Resource) / math.max(1, _Resource_Max) * 100;

	return _Resource, _Resource_Max, _Resource_Percent;
end

	--[[local FriendItems  = {
    [5] = {
        37727, -- Ruby Acorn
    },
    [8] = {
        34368, -- Attuned Crystal Cores
        33278, -- Burning Torch
    },
    [10] = {
        32321, -- Sparrowhawk Net
    },
    [15] = {
        1251, -- Linen Bandage
        2581, -- Heavy Linen Bandage
        3530, -- Wool Bandage
        3531, -- Heavy Wool Bandage
        6450, -- Silk Bandage
        6451, -- Heavy Silk Bandage
        8544, -- Mageweave Bandage
        8545, -- Heavy Mageweave Bandage
        14529, -- Runecloth Bandage
        14530, -- Heavy Runecloth Bandage
        21990, -- Netherweave Bandage
        21991, -- Heavy Netherweave Bandage
        34721, -- Frostweave Bandage
        34722, -- Heavy Frostweave Bandage
--        38643, -- Thick Frostweave Bandage
--        38640, -- Dense Frostweave Bandage
    },
    [20] = {
        21519, -- Mistletoe
    },
    [25] = {
        31463, -- Zezzak's Shard
    },
    [30] = {
        1180, -- Scroll of Stamina
        1478, -- Scroll of Protection II
        3012, -- Scroll of Agility
        1712, -- Scroll of Spirit II
        2290, -- Scroll of Intellect II
        1711, -- Scroll of Stamina II
        34191, -- Handful of Snowflakes
    },
    [35] = {
        18904, -- Zorbin's Ultra-Shrinker
    },
    [40] = {
        34471, -- Vial of the Sunwell
    },
    [45] = {
        32698, -- Wrangling Rope
    },
    [60] = {
        32825, -- Soul Cannon
        37887, -- Seeds of Nature's Wrath
    },
    [80] = {
        35278, -- Reinforced Net
    },
}

local HarmItems = {
    [5] = {
        37727, -- Ruby Acorn
    },
    [8] = {
        34368, -- Attuned Crystal Cores
        33278, -- Burning Torch
    },
    [10] = {
        32321, -- Sparrowhawk Net
    },
    [15] = {
        33069, -- Sturdy Rope
    },
    [20] = {
        10645, -- Gnomish Death Ray
    },
    [25] = {
        24268, -- Netherweave Net
        41509, -- Frostweave Net
        31463, -- Zezzak's Shard
    },
    [30] = {
        835, -- Large Rope Net
        7734, -- Six Demon Bag
        34191, -- Handful of Snowflakes
    },
    [35] = {
        24269, -- Heavy Netherweave Net
        18904, -- Zorbin's Ultra-Shrinker
    },
    [40] = {
        28767, -- The Decapitator
    },
    [45] = {
        32698, -- Wrangling Rope
    },
    [60] = {
        32825, -- Soul Cannon
        37887, -- Seeds of Nature's Wrath
    },
    [80] = {
        35278, -- Reinforced Net
    },
}]]

local targetDummiesIds = {
    [31146] = true,  --raider's training dummie
	[225983] = true, --Dungeoneer's training dummy - Dornogal
	[225984] = true, --Normal dummy - Dornogal
	[225979] = true, --Healing Dummy - Dornogal
	[225982] = true, --Cleave Dummy - Dornogal
	[225977] = true, --Dungeoneer's Tanking dummy - Dornogal
	[225976] = true, --Normal Tanking dummy - Dornogal
}

function ConRO:GetNpcIdFromGuid(GUID)
	local npcId = select(6, strsplit("-", GUID ))
	if npcId then
		npcId = tonumber(npcId)
		return npcId or 0
	end
	return 0
end

function ConRO:Targets(spellID)
	local target_in_range = false;
	local number_in_range = 0;
	local minRange, maxRange = false, false;
		if spellID == "Melee" then
			if UnitReaction("player", "target") ~= nil then
				if UnitReaction("player", "target") <= 4 and UnitExists("target") then
					_, maxRange = ConRO.rc:getRange("target");
					if maxRange then
						if tonumber(maxRange) <= 5 then
							target_in_range = true;
						end
					end
				end
			end

			for i = 1, 15 do
				local serial = UnitGUID('nameplate' .. i);
				local _Is_Dummy = false;
				if serial then
					local npcId = ConRO:GetNpcIdFromGuid(serial)
					if npcId then
						if (targetDummiesIds[npcId]) then
							_Is_Dummy = true;
						end
					end
				end

				if UnitReaction("player", 'nameplate' .. i) ~= nil then
					if UnitReaction("player", 'nameplate' .. i) <= 4 and UnitExists('nameplate' .. i) and (UnitAffectingCombat('nameplate' .. i) or _Is_Dummy) then
						_, maxRange = ConRO.rc:getRange('nameplate' .. i);
						if maxRange then
							if tonumber(maxRange) <= 5 then
								number_in_range = number_in_range + 1
							end
						end
					end
				end
			end
		elseif spellID == "10" then
			if UnitReaction("player", "target") ~= nil then
				if UnitReaction("player", "target") <= 4 and UnitExists("target") then
					_, maxRange = ConRO.rc:getRange("target");
					if maxRange then
						if tonumber(maxRange) <= 10 then
							target_in_range = true;
						end
					end
				end
			end

			for i = 1, 15 do
				local serial = UnitGUID('nameplate' .. i);
				local _Is_Dummy = false;
				if serial then
					local npcId = ConRO:GetNpcIdFromGuid(serial)
					if npcId then
						if (targetDummiesIds[npcId]) then
							_Is_Dummy = true;
						end
					end
				end

				if UnitReaction("player", 'nameplate' .. i) ~= nil then
					if UnitReaction("player", 'nameplate' .. i) <= 4 and UnitExists('nameplate' .. i) and (UnitAffectingCombat('nameplate' .. i) or _Is_Dummy) then
						_, maxRange = ConRO.rc:getRange('nameplate' .. i);
						if maxRange then
							if tonumber(maxRange) <= 10 then
								number_in_range = number_in_range + 1
							end
						end
					end
				end
			end
		elseif spellID == "15" then
			if UnitReaction("player", "target") ~= nil then
				if UnitReaction("player", "target") <= 4 and UnitExists("target") then
					_, maxRange = ConRO.rc:getRange("target");
					if maxRange then
						if tonumber(maxRange) <= 15 then
							target_in_range = true;
						end
					end
				end
			end

			for i = 1, 15 do
				local serial = UnitGUID('nameplate' .. i);
				local _Is_Dummy = false;
				if serial then
					local npcId = ConRO:GetNpcIdFromGuid(serial)
					if npcId then
						if (targetDummiesIds[npcId]) then
							_Is_Dummy = true;
						end
					end
				end

				if UnitReaction("player", 'nameplate' .. i) ~= nil then
					if UnitReaction("player", 'nameplate' .. i) <= 4 and UnitExists('nameplate' .. i) and (UnitAffectingCombat('nameplate' .. i) or _Is_Dummy) then
						_, maxRange = ConRO.rc:getRange('nameplate' .. i);
						if maxRange then
							if tonumber(maxRange) <= 15 then
								number_in_range = number_in_range + 1
							end
						end
					end
				end
			end
		elseif spellID == "25" then
			if UnitReaction("player", "target") ~= nil then
				if UnitReaction("player", "target") <= 4 and UnitExists("target") then
					_, maxRange = ConRO.rc:getRange("target");
					if maxRange then
						if tonumber(maxRange) <= 25 then
							target_in_range = true;
						end
					end
				end
			end

			for i = 1, 15 do
				local serial = UnitGUID('nameplate' .. i);
				local _Is_Dummy = false;
				if serial then
					local npcId = ConRO:GetNpcIdFromGuid(serial)
					if npcId then
						if (targetDummiesIds[npcId]) then
							_Is_Dummy = true;
						end
					end
				end

				if UnitReaction("player", 'nameplate' .. i) ~= nil then
					if UnitReaction("player", 'nameplate' .. i) <= 4 and UnitExists('nameplate' .. i) and (UnitAffectingCombat('nameplate' .. i) or _Is_Dummy) then
						_, maxRange = ConRO.rc:getRange('nameplate' .. i);
						if maxRange then
							if tonumber(maxRange) <= 25 then
								number_in_range = number_in_range + 1
							end
						end
					end
				end
			end
		elseif spellID == "30" then
			if UnitReaction("player", "target") ~= nil then
				if UnitReaction("player", "target") <= 4 and UnitExists("target") then
					_, maxRange = ConRO.rc:getRange("target");
					if maxRange then
						if tonumber(maxRange) <= 30 then
							target_in_range = true;
						end
					end
				end
			end

			for i = 1, 15 do
				local serial = UnitGUID('nameplate' .. i);
				local _Is_Dummy = false;
				if serial then
					local npcId = ConRO:GetNpcIdFromGuid(serial)
					if npcId then
						if (targetDummiesIds[npcId]) then
							_Is_Dummy = true;
						end
					end
				end

				if UnitReaction("player", 'nameplate' .. i) ~= nil then
					if UnitReaction("player", 'nameplate' .. i) <= 4 and UnitExists('nameplate' .. i) and (UnitAffectingCombat('nameplate' .. i) or _Is_Dummy) then
						_, maxRange = ConRO.rc:getRange('nameplate' .. i);
						if maxRange then
							if tonumber(maxRange) <= 30 then
								number_in_range = number_in_range + 1
							end
						end
					end
				end
			end
		elseif spellID == "40" then
			if UnitReaction("player", "target") ~= nil then
				if UnitReaction("player", "target") <= 4 and UnitExists("target") then
					_, maxRange = ConRO.rc:getRange("target");
					if maxRange then
						if tonumber(maxRange) <= 40 then
							target_in_range = true;
						end
					end
				end
			end

			for i = 1, 15 do
				local serial = UnitGUID('nameplate' .. i);
				local _Is_Dummy = false;
				if serial then
					local npcId = ConRO:GetNpcIdFromGuid(serial)
					if npcId then
						if (targetDummiesIds[npcId]) then
							_Is_Dummy = true;
						end
					end
				end

				if UnitReaction("player", 'nameplate' .. i) ~= nil then
					if UnitReaction("player", 'nameplate' .. i) <= 4 and UnitExists('nameplate' .. i) and (UnitAffectingCombat('nameplate' .. i) or _Is_Dummy) then
						_, maxRange = ConRO.rc:getRange('nameplate' .. i);
						if maxRange then
							if tonumber(maxRange) <= 40 then
								number_in_range = number_in_range + 1
							end
						end
					end
				end
			end
		else
			if ConRO:IsSpellInRange(spellID, "target") then
				target_in_range = true;
			end

			for i = 1, 15 do
				if UnitExists('nameplate' .. i) and UnitAffectingCombat('nameplate' .. i) and ConRO:IsSpellInRange(spellID, 'nameplate' .. i) then
					number_in_range = number_in_range + 1
				end
			end
		end
	--print(number_in_range)
	return number_in_range, target_in_range;
end

function ConRO:UnitAura(spellID, timeShift, unit, filter, isWeapon)
	timeShift = timeShift or 0;

	-- Handling weapon enchants
	if isWeapon == "Weapon" then
		local hasMainHandEnchant, mainHandExpiration, _, mainBuffId, hasOffHandEnchant, offHandExpiration, _, offBuffId = GetWeaponEnchantInfo()
		if hasMainHandEnchant and mainBuffId == spellID then
			if mainHandExpiration and (mainHandExpiration / 1000) > timeShift then
				local dur = (mainHandExpiration / 1000) - timeShift;
				return true, 0, dur;  -- No count information for weapon enchants
			end
		elseif hasOffHandEnchant and offBuffId == spellID then
			if offHandExpiration and (offHandExpiration / 1000) > timeShift then
				local dur = (offHandExpiration / 1000) - timeShift;
				return true, 0, dur;  -- No count information for weapon enchants
			end
		end
	else
		-- Iterating through unit auras
		for i = 1, 40 do
			local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
			if not aura then
				break  -- No more auras to check
			end

			if aura.spellId == spellID then
				local expirationTime = aura.expirationTime
				if expirationTime and (expirationTime - GetTime()) > timeShift then
					local dur = expirationTime - GetTime() - timeShift
					return true, aura.applications or 1, dur
				end
			end
		end
	end
	return false, 0, 0;
end

function ConRO:Form(spellID)
	for i = 1, 40 do
		local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL");
		if aura and aura.spellId == spellID then
			return true, aura.applications or 1;
			end
	end
	return false, 0;
end

function ConRO:PersistentDebuff(spellID)
	for i = 1, 40 do
		local aura = C_UnitAuras.GetAuraDataByIndex("target", i, "PLAYER|HARMFUL");
		if aura and aura.spellId == spellID then
			return true, aura.applications or 1;
		end
	end
	return false, 0;
end

function ConRO:Aura(spellID, timeShift, filter)
	return self:UnitAura(spellID, timeShift, 'player', filter);
end

function ConRO:TargetAura(spellID, timeShift)
	return self:UnitAura(spellID, timeShift, 'target', 'PLAYER|HARMFUL');
end

function ConRO:AnyTargetAura(spellID)
	local haveBuff = false;
	local count = 0;

	-- Iterate over nameplates
	for i = 1, 15 do
		if UnitExists('nameplate' .. i) then
			-- Iterate over auras on the current nameplate
			for x = 1, 40 do
				local aura = C_UnitAuras.GetAuraDataByIndex('nameplate' .. i, x, 'PLAYER|HARMFUL')
				if not aura then
					break  -- No more auras to check
				end

				if aura.spellId == spellID then
					haveBuff = true;
					count = count + 1;
					break;  -- No need to check further auras on this nameplate
				end
			end
		end
	end

	return haveBuff, count;
end

function ConRO:Purgable()
	local purgable = false;
	for i = 1, 40 do
		local aura = C_UnitAuras.GetAuraDataByIndex("target", i, "HELPFUL");
		if aura and aura.isStealable then
			purgable = true;
			break;
		end
	end
	return purgable;
end

function ConRO:Heroism()
	local _Bloodlust = 2825;
	local _TimeWarp = 80353;
	local _Heroism = 32182;
	local _PrimalRage = 264667;
	local _AncientHysteria = 90355;
	local _Netherwinds = 160452;
	local _DrumsofFury = 120257;
	local _DrumsofFuryBuff = 178207;
	local _DrumsoftheMountain = 142406;
	local _DrumsoftheMountainBuff = 230935;
	local _FuryoftheAspects = 390386;

	local _Exhaustion = 57723;
	local _Sated = 57724;
	local _TemporalDisplacement = 80354;
	local _Insanity = 95809;
	local _Fatigued = 264689;
	local _Exhaustion2 = 390435;

	local buffed = false;
	local sated = false;

		-- Function to check for specific buffs
		local function HasBuff(buffID)
			return ConRO:Aura(buffID, timeShift) ~= nil
		end

		-- Function to check for specific debuffs using the new API
		local function HasDebuff(debuffID)
			local i = 1
			while true do
				local debuff = C_UnitAuras.GetDebuffDataByIndex("player", i)
				if not debuff then
					break
				end
				if debuff.spellId == debuffID then
					return true
				end
				i = i + 1
			end
			return false
		end

		-- Check for Heroism/Lust buffs
		local hasteBuff = {
			bl = HasBuff(_Bloodlust),
			tw = HasBuff(_TimeWarp),
			hero = HasBuff(_Heroism),
			pr = HasBuff(_PrimalRage),
			ah = HasBuff(_AncientHysteria),
			nw = HasBuff(_Netherwinds),
			dof = HasBuff(_DrumsofFuryBuff),
			dotm = HasBuff(_DrumsoftheMountainBuff),
			fota = HasBuff(_FuryoftheAspects)
		}

		-- Check for Sated debuffs using the new API
		local satedDebuff = {
			ex = HasDebuff(_Exhaustion),
			sated = HasDebuff(_Sated),
			td = HasDebuff(_TemporalDisplacement),
			ins = HasDebuff(_Insanity),
			fat = HasDebuff(_Fatigued),
			ex2 = HasDebuff(_Exhaustion2)
		}

		-- Count active haste buffs
		local hasteCount = 0;
			for _, v in pairs(hasteBuff) do
				if v then
					hasteCount = hasteCount + 1;
				end
			end

		if hasteCount > 0 then
			buffed = true;
		end

		local satedCount = 0;
		for _, v in pairs(satedDebuff) do
			if v then
				satedCount = satedCount + 1;
			end
		end

		if satedCount > 0 then
			sated = true;
		end

	return buffed, sated;
end

function ConRO:InRaid()
	local numGroupMembers = GetNumGroupMembers();
	if numGroupMembers >= 6 then
		return true;
	else
		return false;
	end
end

function ConRO:InParty()
	local numGroupMembers = GetNumGroupMembers();
	if numGroupMembers >= 2 and numGroupMembers <= 5 then
		return true;
	else
		return false;
	end
end

function ConRO:IsSolo()
	local numGroupMembers = GetNumGroupMembers();
	if numGroupMembers <= 1 then
		return true;
	else
		return false;
	end
end

function ConRO:RaidBuff(spellID)
	local selfhasBuff = false;
	local haveBuff = false;
	local buffedRaid = false;

	local numGroupMembers = GetNumGroupMembers();
		if numGroupMembers >= 6 then
			selfhasBuff = true;
			for i = 1, numGroupMembers do -- For each raid member
				local unit = "raid" .. i;
				if UnitExists(unit) then
					if not UnitIsDeadOrGhost(unit) and UnitInRange(unit) then
						for x = 1, 40 do
							local aura = C_UnitAuras.GetAuraDataByIndex(unit, x, 'HELPFUL');
							if not aura then break end  -- Exit if no more auras

							if aura.spellId == spellID then
								haveBuff = true;
								break;
							end
						end
						if not haveBuff then
							break;
						end
					else
						haveBuff = true;
					end
				end
			end
		elseif numGroupMembers >= 2 and numGroupMembers <= 5 then
			for i = 1, 4 do -- For each party member
				local unit = "party" .. i;
				if UnitExists(unit) then
					if not UnitIsDeadOrGhost(unit) and UnitInRange(unit) then
						for x = 1, 40 do
							local aura = C_UnitAuras.GetAuraDataByIndex(unit, x, 'HELPFUL');
							if not aura then break end  -- Exit if no more auras

							if aura.spellId == spellID then
								haveBuff = true;
								break;
							end
						end
						if not haveBuff then
							break;
						end
					else
						haveBuff = true;
					end
				end
			end
			for x = 1, 40 do
				local aura = C_UnitAuras.GetAuraDataByIndex('player', x, 'HELPFUL');
				if not aura then break end  -- Exit if no more auras

				if aura.spellId == spellID then
					selfhasBuff = true;
					break;
				end
			end
		elseif numGroupMembers <= 1 then
			for x = 1, 40 do
				local aura = C_UnitAuras.GetAuraDataByIndex('player', x, 'HELPFUL');
				if not aura then break end  -- Exit if no more auras

				if aura.spellId == spellID then
					selfhasBuff = true;
					haveBuff = true;
					break;
				end
			end
		end

		if selfhasBuff and haveBuff then
			buffedRaid = true;
		end

	return buffedRaid;
end

function ConRO:OneBuff(spellID)
	local selfhasBuff = false;
	local haveBuff = false;
	local someoneHas = false;

	local numGroupMembers = GetNumGroupMembers();

	-- For raid groups
	if numGroupMembers >= 6 then
		for i = 1, numGroupMembers do -- For each raid member
			local unit = "raid" .. i;
			if UnitExists(unit) then
				for x = 1, 40 do
					local aura = C_UnitAuras.GetAuraDataByIndex(unit, x, 'PLAYER|HELPFUL');
					if not aura then break end  -- Exit if no more auras

					if aura.spellId == spellID then
						haveBuff = true;
						break;
					end
				end
				if haveBuff then
					break;
				end
			end
		end

	-- For party groups
	elseif numGroupMembers >= 2 and numGroupMembers <= 5 then
		-- Check the player first
		for x = 1, 40 do
			local aura = C_UnitAuras.GetAuraDataByIndex('player', x, 'PLAYER|HELPFUL');
			if not aura then break end  -- Exit if no more auras

			if aura.spellId == spellID then
				selfhasBuff = true;
				break;
			end
		end

		-- If the player doesn't have the buff, check the party
		if not selfhasBuff then
			for i = 1, 4 do -- For each party member
				local unit = "party" .. i;
				if UnitExists(unit) then
					for x = 1, 40 do
						local aura = C_UnitAuras.GetAuraDataByIndex(unit, x, 'PLAYER|HELPFUL');
						if not aura then break end  -- Exit if no more auras

						if aura.spellId == spellID then
							haveBuff = true;
							break;
						end
					end
					if haveBuff then
						break;
					end
				end
			end
		end

	-- For solo players
	elseif numGroupMembers <= 1 then
		for x = 1, 40 do
			local aura = C_UnitAuras.GetAuraDataByIndex('player', x, 'PLAYER|HELPFUL');
			if not aura then break end  -- Exit if no more auras

			if aura.spellId == spellID then
				selfhasBuff = true;
				break;
			end
		end
	end

	if selfhasBuff or haveBuff then
		someoneHas = true;
	end

	return someoneHas;
end

function ConRO:GroupBuffCount(spellID)
	local buffCount = 0;
	local numGroupMembers = GetNumGroupMembers();

	if numGroupMembers >= 6 then
		-- For each raid member
		for i = 1, numGroupMembers do
			local unit = "raid" .. i;
			if UnitExists(unit) then
				for x = 1, 40 do
					local aura = C_UnitAuras.GetAuraDataByIndex(unit, x, 'PLAYER|HELPFUL');
					if not aura then break end  -- Exit if no more auras

					if aura.spellId == spellID then
						buffCount = buffCount + 1;
						break;  -- Exit loop after finding the buff
					end
				end
			end
		end

	elseif numGroupMembers >= 2 and numGroupMembers <= 5 then
		-- For each party member
		for i = 1, 4 do
			local unit = "party" .. i;
			if UnitExists(unit) then
				for x = 1, 40 do
					local aura = C_UnitAuras.GetAuraDataByIndex(unit, x, 'PLAYER|HELPFUL');
					if not aura then break end  -- Exit if no more auras

					if aura.spellId == spellID then
						buffCount = buffCount + 1;
						break;  -- Exit loop after finding the buff
					end
				end
			end
		end

		-- Check the player
		for x = 1, 40 do
			local aura = C_UnitAuras.GetAuraDataByIndex('player', x, 'PLAYER|HELPFUL');
			if not aura then break end  -- Exit if no more auras

			if aura.spellId == spellID then
				buffCount = buffCount + 1;
				break;  -- Exit loop after finding the buff
			end
		end

	elseif numGroupMembers <= 1 then
		-- Check solo player
		for x = 1, 40 do
			local aura = C_UnitAuras.GetAuraDataByIndex('player', x, 'PLAYER|HELPFUL');
			if not aura then break end  -- Exit if no more auras

			if aura.spellId == spellID then
				buffCount = buffCount + 1;
				break;  -- Exit loop after finding the buff
			end
		end
	end

	return buffCount;
end

function ConRO:EndCast(target)
	target = target or 'player';
	local t = GetTime();
	local c = t * 1000;
	local gcd = 0;
	local _, _, _, _, endTime, _, _, _, spellId = UnitCastingInfo(target or 'player');

	-- we can only check player global cooldown
	if target == 'player' then
		local gstart, gduration;
		local spellCooldownInfo = _GlobalCooldown and C_Spell.GetSpellCooldown(_GlobalCooldown)
			gstart = spellCooldownInfo and spellCooldownInfo.startTime
			gduration = spellCooldownInfo and spellCooldownInfo.duration
		gcd = gduration - (t - gstart);

		if gcd < 0 then
			gcd = 0;
		end;
	end

	if not endTime then
		return gcd, nil, gcd;
	end

	local timeShift = (endTime - c) / 1000;
	if gcd > timeShift then
		timeShift = gcd;
	end

	return timeShift, spellId, gcd;
end

function ConRO:EndChannel(target)
	target = target or 'player';
	local t = GetTime();
	local c = t * 1000;
	local gcd = 0;
	local _, _, _, _, endTime, _, _, spellId = UnitChannelInfo(target or 'player');

	-- we can only check player global cooldown
	if target == 'player' then
		local gstart, gduration;
			local gstart, gduration
			local spellCooldownInfo = _GlobalCooldown and C_Spell.GetSpellCooldown(_GlobalCooldown)
			gstart = spellCooldownInfo and spellCooldownInfo.startTime
			gduration = spellCooldownInfo and spellCooldownInfo.duration
		gcd = gduration - (t - gstart);

		if gcd < 0 then
			gcd = 0;
		end;
	end

	if not endTime then
		return gcd, nil, gcd;
	end

	local timeShift = (endTime - c) / 1000;
	if gcd > timeShift then
		timeShift = gcd;
	end

	return timeShift, spellId, gcd;
end

function ConRO:SameSpell(spell1, spell2)
	local spellName1 = C_Spell.GetSpellInfo(spell1).name;
	local spellName2 = C_Spell.GetSpellInfo(spell2).name;
	return spellName1 == spellName2;
end

function ConRO:IsOverride(spellID)
	local _OverriddenBy = C_Spell.GetOverrideSpell(spellID);
	return _OverriddenBy;
end

function ConRO:TarYou()
	local tarYou = false;

	local targettarget = UnitName('targettarget');
	local targetplayer = UnitName('player');
	if targettarget == targetplayer then
		tarYou = true;
	end
	return tarYou;
end

function ConRO:TarHostile()
	local isEnemy = UnitReaction("player","target");
	local isDead = UnitIsDead("target");
		if isEnemy ~= nil then
			if isEnemy <= 4 and not isDead then
				return true;
			else
				return false;
			end
		end
	return false;
end

function ConRO:PercentHealth(target_unit)
	local unit = target_unit or 'target';
	local health = UnitHealth(unit);
	local healthMax = UnitHealthMax(unit);
	if health <= 0 or healthMax <= 0 then
		return 101;
	end
	return (health/healthMax)*100;
end

ConRO.Spellbook = {};
function ConRO:FindSpellInSpellbook(spellID)
	local spellName = C_Spell.GetSpellInfo(spellID).name;
	if not spellName then
		return nil
	end

	if ConRO.Spellbook[spellName] then
		return ConRO.Spellbook[spellName];
	end

	-- Check the first skill line tab (index 2 in your original code)
	local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(2)
    if skillLineInfo then
        local offset = skillLineInfo.itemIndexOffset
        local numSpells = skillLineInfo.numSpellBookItems
        local booktype = Enum.SpellBookSpellBank.Player

		for index = offset + 1, numSpells + offset do
			local spellBookInfo = C_SpellBook.GetSpellBookItemInfo(index, booktype)
            if spellBookInfo and spellName == spellBookInfo.name then
                ConRO.Spellbook[spellName] = index
                return index
			end
		end
	end

	-- Check the second skill line tab (index 3 in your original code)
	skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(3)
    if skillLineInfo then
        local offset = skillLineInfo.itemIndexOffset
        local numSpells = skillLineInfo.numSpellBookItems
        local booktype = Enum.SpellBookSpellBank.Player

        for index = offset + 1, numSpells + offset do
            local spellBookInfo = C_SpellBook.GetSpellBookItemInfo(index, booktype)
            if spellBookInfo and spellName == spellBookInfo.name then
                ConRO.Spellbook[spellName] = index
                return index
            end
        end
    end

	return nil;
end

function ConRO:FindCurrentSpell(spellID)
	local spellInfo = C_Spell.GetSpellInfo(spellID)
    if not spellInfo then
        return false
    end

    local spellName = spellInfo.name
    local hasSpell = false

    -- Check the first skill line tab (index 2 in your original code)
    local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(2)
    if skillLineInfo then
        local offset = skillLineInfo.itemIndexOffset
        local numSpells = skillLineInfo.numSpellBookItems
        local booktype = Enum.SpellBookSpellBank.Player

		for index = offset + 1, numSpells + offset do
			local spellBookInfo = C_SpellBook.GetSpellBookItemInfo(index, booktype)
			if spellBookInfo and spellName == spellBookInfo.name then
				hasSpell = true
				break
			end
		end
	end

	-- Check the second skill line tab (index 3 in your original code)
	skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(3)
	if skillLineInfo then
		local offset = skillLineInfo.itemIndexOffset
		local numSpells = skillLineInfo.numSpellBookItems
		local booktype = Enum.SpellBookSpellBank.Player

		for index = offset + 1, numSpells + offset do
			local spellBookInfo = C_SpellBook.GetSpellBookItemInfo(index, booktype)
            if spellBookInfo and spellName == spellBookInfo.name then
                hasSpell = true
                break
            end
		end
	end

	return hasSpell;
end

function ConRO:IsSpellInRange(spellCheck, target_unit)
	local unit = target_unit or 'target';
	local range = false;
	local spellid = spellCheck.spellID;
	local talentID = spellCheck.talentID;
	local have = ConRO:TalentChosen(talentID);
	local known = IsPlayerSpell(spellid);

	if have then
		known = true;
	end

	if known and ConRO:TarHostile() then
		-- Use C_Spell.IsSpellInRange instead of IsSpellInRange
		local inRange = C_Spell.IsSpellInRange(spellid, unit);

		if inRange == nil then
			local myIndex = nil
            local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(2) -- Get skill line info for the second tab

            if skillLineInfo then
                local offset = skillLineInfo.itemIndexOffset
                local numSpells = skillLineInfo.numSpellBookItems
                local booktype = Enum.SpellBookSpellBank.Player

                if offset and numSpells then
					for index = offset + 1, numSpells + offset do
						local spellBookInfo = C_SpellBook.GetSpellBookItemInfo(index, booktype)
                        if spellBookInfo and spellid == spellBookInfo.spellID then
                            myIndex = index
                            break
						end
					end
				end
			else
                -- Handle case where skillLineInfo is nil
                print("Error: Unable to retrieve skill line information.")
            end

			local numPetSpells, _ = C_SpellBook.HasPetSpells()
            if not myIndex and numPetSpells then
                local booktype = Enum.SpellBookSpellBank.Pet
				for index = 1, numPetSpells do
					local spellBookInfo = C_SpellBook.GetSpellBookItemInfo(index, booktype)
                    if spellBookInfo and spellid == spellBookInfo.spellID then
                        myIndex = index
                        break
					end
				end
			end

			if myIndex then
				inRange = C_Spell.IsSpellInRange(myIndex, unit)
            end
		end

		if inRange == true then
            range = true
        end
    end

  return range;
end

function ConRO:AbilityReady(spellCheck, timeShift, spelltype)
	local spellid = spellCheck.spellID;
	local entryID = spellCheck.talentID;
	local _CD, _MaxCD = ConRO:Cooldown(spellid, timeShift);
	local have = ConRO:TalentChosen(entryID);

	local known = IsPlayerSpell(spellid);
	local usable, notEnough = C_Spell.IsSpellUsable(spellid);
	local castTimeMilli = C_Spell.GetSpellInfo(spellid).castTime;
	local castTime = 0;
	local rdy = false;
		if spelltype == 'pet' then
			have = IsSpellKnown(spellid, true);
		elseif spelltype == 'pvp' then
			have = ConRO:PvPTalentChosen(entryID);
		end
		if have then
			known = true;
		end
		if spelltype == 'known' then
			if known and _CD <= 0 then
				rdy = true;
			end
		else
			if known and usable and _CD <= 0 and not notEnough then
				rdy = true;
			end
		end
		if castTimeMilli ~= nil then
			castTime = castTimeMilli/1000;
		end
	return spellid, rdy, _CD, _MaxCD, castTime;
end

function ConRO:ItemReady(_Item_ID, timeShift)
	local _CD, _MaxCD = ConRO:ItemCooldown(_Item_ID, timeShift);
	local _Item_COUNT = GetItemCount(_Item_ID, false, true);
	local _RDY = false;
		if _CD <= 0 and _Item_COUNT >= 1 then
			_RDY = true;
		else
			_RDY = false;
		end
	return _Item_ID, _RDY, _CD, _MaxCD, _Item_COUNT;
end

function ConRO:SpellCharges(spellid)
	local currentCharges, maxCharges, cooldownStart, maxCooldown;
	local spellChargeInfo = C_Spell.GetSpellCharges(spellid);
			currentCharges = spellChargeInfo and spellChargeInfo.currentCharges
			maxCharges = spellChargeInfo and spellChargeInfo.maxCharges
			cooldownStart = spellChargeInfo and spellChargeInfo.cooldownStartTime
			maxCooldown = spellChargeInfo and spellChargeInfo.cooldownDuration
	local currentCooldown = 0;
		if currentCharges ~= nil and currentCharges < maxCharges then
			currentCooldown = (maxCooldown - (GetTime() - cooldownStart));
		end
		if currentCharges == nil then
			currentCharges = 0;
		end
	return currentCharges, maxCharges, currentCooldown, maxCooldown;
end

function ConRO:Raidmob()
	local tlvl = UnitLevel("target");
	local plvl = UnitLevel("player");
	local strong = false;
		if tlvl == -1 or tlvl > plvl then
			strong = true;
		end
	return strong;
end

function ConRO:ExtractTooltipDamage(_Spell_ID)
    _Spell_Description = GetSpellDescription(_Spell_ID);
    _Damage = _Spell_Description:match("%d+([%d%,]+)"); --Need to get correct digits here.
	if _Damage == nil then
		_Damage = _Spell_Description:match("(%d+)");
	end
	local _My_HP = tonumber("1560");
	local _Will_Kill = "false";
	local _Damage_Number = _Damage;

--	if _Damage_Number >= _My_HP then
--		_Will_Kill = "true";
--	end

	print(_Damage_Number .. " - " .. _My_HP .. " -- " .. _Will_Kill);
end

function ConRO:ExtractTooltip(spell, pattern)
	local _pattern = gsub(pattern, "%%s", "([%%d%.,]+)");

	if not TDSpellTooltip then
		CreateFrame('GameTooltip', 'TDSpellTooltip', UIParent, 'GameTooltipTemplate');
		TDSpellTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	end
	TDSpellTooltip:SetSpellByID(spell);

	for i = 2, 4 do
		local line = _G['TDSpellTooltipTextLeft' .. i];
		local text = line:GetText();

		if text then
			local cost = strmatch(text, _pattern);
			if cost then
				cost = cost and tonumber((gsub(cost, "%D", "")));
				return cost;
			end
		end
	end

	return 0;
end

function ConRO:GlobalCooldown()
	local _, duration, enabled = C_Spell.GetSpellCooldown(61304);
		return duration;
end

function ConRO:Cooldown(spellid, timeShift)
	local start, maxCooldown, enabled;
	local spellCooldownInfo = C_Spell.GetSpellCooldown(spellid);
		start = spellCooldownInfo and spellCooldownInfo.startTime;
		maxCooldown = spellCooldownInfo and spellCooldownInfo.duration;
		enabled = spellCooldownInfo and spellCooldownInfo.isEnabled;
	local baseCooldownMS, gcdMS = GetSpellBaseCooldown(spellid);
	local baseCooldown = 0;

	if baseCooldownMS ~= nil then
		baseCooldown = (baseCooldownMS/1000) + (timeShift or 0);
	end

	if enabled and maxCooldown == 0 and start == 0 then
		return 0, maxCooldown, baseCooldown;
	elseif enabled then
		return (maxCooldown - (GetTime() - start) - (timeShift or 0)), maxCooldown, baseCooldown;
	else
		return 100000, maxCooldown, baseCooldown;
	end;
end

function ConRO:ItemCooldown(itemid, timeShift)
	local start, maxCooldown, enabled = GetItemCooldown(itemid);
	local baseCooldownMS, gcdMS = GetSpellBaseCooldown(itemid);
	local baseCooldown = 0;

	if baseCooldownMS ~= nil then
		baseCooldown = baseCooldownMS/1000;
	end

	if enabled and maxCooldown == 0 and start == 0 then
		return 0, maxCooldown, baseCooldown;
	elseif enabled then
		return (maxCooldown - (GetTime() - start) - (timeShift or 0)), maxCooldown, baseCooldown;
	else
		return 100000, maxCooldown, baseCooldown;
	end;
end

function ConRO:Interrupt()
	if UnitCanAttack ('player', 'target') then
		local tarchan, _, _, _, _, _, cnotInterruptible = UnitChannelInfo("target");
		local tarcast, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target");

		if tarcast and not notInterruptible then
			return true;
		elseif tarchan and not cnotInterruptible then
			return true;
		else
			return false;
		end
	end
end

function ConRO:BossCast()
	if UnitCanAttack ('player', 'target') then
		local tarchan, _, _, _, _, _, cnotInterruptible = UnitChannelInfo("target");
		local tarcast, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target");

		if tarcast and notInterruptible then
			return true;
		elseif tarchan and cnotInterruptible then
			return true;
		else
			return false;
		end
	end
end

function ConRO:CallPet()
	local petout = IsPetActive();
	local incombat = UnitAffectingCombat('player');
	local mounted = IsMounted();
	local inVehicle = UnitHasVehicleUI("player");
	local summoned = true;
		if not petout and not mounted and not inVehicle and incombat then
			summoned = false;
		end
	return summoned;
end

function ConRO:PetAssist()
	local incombat = UnitAffectingCombat('player');
	local mounted = IsMounted();
	local inVehicle = UnitHasVehicleUI("player");
	local affectingCombat = IsPetAttackActive();
	local attackstate = true;
	local assist = false;
	local petspell = select(9, UnitCastingInfo("pet"))
		for i = 1, 24 do
			local name, _, _, isActive = GetPetActionInfo(i)
			if name == 'PET_MODE_ASSIST' and isActive then
				assist = true;
			end
		end
		if not (affectingCombat or assist) and incombat and not mounted and not inVehicle then
			attackstate = false;
		end
	return attackstate, petspell;
end

function ConRO:Totem(spellID)
	local spellInfo = C_Spell.GetSpellInfo(spellID)
    if not spellInfo then
        return false
    end

    local spellName = spellInfo.name
	for i=1,4 do
		local _, totemName, startTime, duration = GetTotemInfo(i);
		if spellName == totemName then
			local est_dur = startTime + duration - GetTime();
			return true, est_dur;
		end
	end
	return false, 0;
end

function ConRO:Dragonriding()
	local isGliding, canGlide, forwardSpeed = C_PlayerInfo.GetGlidingInfo()

	return canGlide;
end

function ConRO:FormatTime(left)
	local seconds = left >= 0        and math.floor((left % 60)    / 1   ) or 0;
	local minutes = left >= 60       and math.floor((left % 3600)  / 60  ) or 0;
	local hours   = left >= 3600     and math.floor((left % 86400) / 3600) or 0;
	local days    = left >= 86400    and math.floor((left % 31536000) / 86400) or 0;
	local years   = left >= 31536000 and math.floor( left / 31536000) or 0;

	if years > 0 then
		return string.format("%d [Y] %d [D] %d:%d:%d [H]", years, days, hours, minutes, seconds);
	elseif days > 0 then
		return string.format("%d [D] %d:%d:%d [H]", days, hours, minutes, seconds);
	elseif hours > 0 then
		return string.format("%d:%d:%d [H]", hours, minutes, seconds);
	elseif minutes > 0 then
		return string.format("%d:%d [M]", minutes, seconds);
	else
		return string.format("%d [S]", seconds);
	end
end

local GetTime = GetTime;
local UnitGUID = UnitGUID;
local UnitExists = UnitExists;
local TableInsert = tinsert;
local TableRemove = tremove;
local MathMin = math.min;
local wipe = wipe;

function ConRO:InitTTD(maxSamples, interval)
	interval = interval or 0.25;
	maxSamples = maxSamples or 50;

	if self.ttd and self.ttd.timer then
		self:CancelTimer(self.ttd.timer);
		self.ttd.timer = nil;
	end

	self.ttd = {
		interval   = interval,
		maxSamples = maxSamples,
		HPTable    = {},
	};

	self.ttd.timer = self:ScheduleRepeatingTimer('TimeToDie', interval);
end

function ConRO:DisableTTD()
	if self.ttd.timer then
		self:CancelTimer(self.ttd.timer);
	end
end

local HPTable = {};
local trackedGuid;
function ConRO:TimeToDie(trackedUnit)
	trackedUnit = trackedUnit or 'target';

	-- Query current time (throttle updating over time)
	local now = GetTime();

	-- Current data
	local ttd = self.ttd;
	local guid = UnitGUID(trackedUnit);

	if trackedGuid ~= guid then
		wipe(HPTable);
		trackedGuid = guid;
	end

	if guid and UnitExists(trackedUnit) then
		local hpPct = self:PercentHealth('target') * 100;
		TableInsert(HPTable, 1, { time = now, hp = hpPct});

		if #HPTable > ttd.maxSamples then
			TableRemove(HPTable);
		end
	else
		wipe(HPTable);
	end
end

function ConRO:GetTimeToDie()
	local seconds = 5*60;

	local n = #HPTable
	if n > 5 then
		local a, b = 0, 0;
		local Ex2, Ex, Exy, Ey = 0, 0, 0, 0;

		local hpPoint, x, y;
		for i = 1, n do
			hpPoint = HPTable[i]
			x, y = hpPoint.time, hpPoint.hp

			Ex2 = Ex2 + x * x
			Ex = Ex + x
			Exy = Exy + x * y
			Ey = Ey + y
		end

		-- Invariant to find matrix inverse
		local invariant = 1 / (Ex2 * n - Ex * Ex);

		-- Solve for a and b
		a = (-Ex * Exy * invariant) + (Ex2 * Ey * invariant);
		b = (n * Exy * invariant) - (Ex * Ey * invariant);

		if b ~= 0 then
			-- Use best fit line to calculate estimated time to reach target health
			seconds = (0 - a) / b;
			seconds = MathMin(5*60, seconds - (GetTime() - 0));

			if seconds < 0 then
				seconds = 5*60;
			end
		end
	end
	return seconds;
end