CDFrames 'player'

local last_used

function private.BAG_UPDATE_COOLDOWN()
	for bag=0,4 do
		if GetBagName(bag) then
			for slot = 1, GetContainerNumSlots(bag) do
				local started, duration, enabled = GetContainerItemCooldown(bag, slot)
				if enabled == 1 then
					local name = link_name(GetContainerItemLink(bag, slot))
					if duration > 3 and duration <= 1800 and GetItemInfo(6948) ~= name then
						start_cd(
							name,
							GetContainerItemInfo(bag, slot),
							started,
							duration
						)
					elseif duration == 0 then
						stop_cd(started)
					end
				end
			end
		end
	end
	for slot=0,19 do
		local started, duration, enabled = GetInventoryItemCooldown('player', slot)
		if enabled == 1 then
			local name = link_name(GetInventoryItemLink('player', slot))
			if duration > 3 and duration <= 1800 then
				start_cd(
					name,
					GetInventoryItemTexture('player', slot),
					started,
					duration
				)
			elseif duration == 0 then
				stop_cd(started)
			end
		end
	end
end

function private.SPELL_UPDATE_COOLDOWN()
	local _, _, offset, spellCount = GetSpellTabInfo(GetNumSpellTabs())
	local totalSpells = offset + spellCount
	for id = 1, totalSpells do
		local started, duration, enabled = GetSpellCooldown(id, BOOKTYPE_SPELL)
		local name = GetSpellName(id, BOOKTYPE_SPELL)
		if enabled == 1 and duration > 2.5 then
			start_cd(
				name,
				GetSpellTexture(id, BOOKTYPE_SPELL),
				started,
				duration
			)
		elseif duration == 0 then
			stop_cd(name)
		end
	end
end

function public.setup()
	CDFrames_Settings.PLAYER = CDFrames_Settings.PLAYER or t
	public.frame = CDFrames.frame.new('Player Cooldowns', A(.2, .8, .2), CDFrames_Settings.PLAYER)
	do
		local frame = CreateFrame('Frame')
		frame:SetScript('OnEvent', function() _E[event]() end)
		frame:RegisterEvent('BAG_UPDATE_COOLDOWN')
		frame:RegisterEvent('SPELL_UPDATE_COOLDOWN')
	end
	BAG_UPDATE_COOLDOWN()
	SPELL_UPDATE_COOLDOWN()
end

do
	local cooldowns = t
	function private.start_cd(name, texture, started, duration)
		if CDFrames_Settings.used and name ~= last_used then return end
		if cooldowns[name] then frame:CancelCD(cooldowns[name]) end
		cooldowns[name] = frame:StartCD(name, '', texture, started, duration)
	end
	function private.stop_cd(name)
		if cooldowns[name] then frame:CancelCD(cooldowns[name]) end
	end
end

function private.link_name(link)
	for name in string.gfind(link, '|Hitem:%d+:%d+:%d+:%d+|h[[]([^]]+)[]]|h') do return name end
end

do
	local orig = UseContainerItem
	_G.UseContainerItem = function(...)
		last_used = link_name(GetContainerItemLink(unpack(arg)))
		return orig(unpack(arg))
	end
end

do
	local orig = UseInventoryItem
	_G.UseInventoryItem = function(...)
		last_used = link_name(GetInventoryItemLink('player', arg[1]))
		return orig(unpack(arg))
	end
end

do
	local orig = CastSpellByName
	_G.CastSpellByName = function(...)
		last_used = arg[1]
		return orig(unpack(arg))
	end
end

do
	local orig = CastSpell
	_G.CastSpell = function(...)
		last_used = GetSpellName(unpack(arg))
		return orig(unpack(arg))
	end
end

do
	local orig = UseAction
	_G.UseAction = function(...)
		CDFrames_Tooltip:SetOwner(UIParent, 'ANCHOR_NONE')
		CDFrames_Tooltip:SetAction(arg[1])
		last_used = CDFrames_TooltipTextLeft1:GetText()
		return orig(unpack(arg))
	end
end