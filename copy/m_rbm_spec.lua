rbmSpecSpellLists = {
	abjuration = {},
	conjuration = {},
	divination = {},
	enchantment = {},
	illusion = {},
	invocation = {},
	necromancy = {},
	alteration = {},
	abjuration_alteration = {},
	conjuration_invocation = {},
	divination_alteration = {},
	conjuration_necromancy = {},
	invocation_alteration = {},
}

rbmSpecKitNameStrref = {}

rbmSpecKitSchools = {
	[22] = { "abjuration", "abjuration_alteration" },
	[23] = { "conjuration", "conjuration_invocation", "conjuration_necromancy" },
	[24] = { "divination", "divination_alteration" },
	[25] = { "enchantment" },
	[26] = { "illusion" },
	[27] = { "invocation", "conjuration_invocation", "invocation_alteration" },
	[28] = { "necromancy", "conjuration_necromancy" },
	[29] = { "alteration", "abjuration_alteration", "divination_alteration", "invocation_alteration" },
}

rbmSpecKitMasks = {
	[64] = 22,
	[128] = 23,
	[256] = 24,
	[512] = 25,
	[1024] = 26,
	[2048] = 27,
	[4096] = 28,
	[8192] = 29,
}

function rbmSpecialistKitId()
	if currentChargenKit and chargen and chargen.kit and chargen.kit[currentChargenKit] then
		local kit = chargen.kit[currentChargenKit].id
		if rbmSpecKitSchools[kit] then
			return kit
		end
		if rbmSpecKitMasks[kit] then
			return rbmSpecKitMasks[kit]
		end
		return nil
	end

	local character = characters and characters[id]
	local className = character and character.class
	if not className then
		return nil
	end
	className = string.lower(className)

	for kit, strref in pairs(rbmSpecKitNameStrref) do
		local kitName = Infinity_FetchString(strref)
		if kitName and kitName ~= "" and string.find(className, string.lower(kitName), 1, true) then
			return kit
		end
	end

	return nil
end

function rbmIsSpecialistSpell(spellResref, kit)
	local schools = rbmSpecKitSchools[kit]
	if not spellResref or not schools then
		return false
	end

	for _, school in ipairs(schools) do
		if rbmSpecSpellLists[school][spellResref] then
			return true
		end
	end

	return false
end

local function rbmHasSpecialistSpellAtLevel(kit, level)
	for _, school in ipairs(rbmSpecKitSchools[kit] or {}) do
		for _, spellLevel in pairs(rbmSpecSpellLists[school]) do
			if spellLevel == level then
				return true
			end
		end
	end

	return false
end

local function rbmCountSpecialistSpells(spells, kit)
	local count = 0
	for _, spell in pairs(spells or {}) do
		if rbmIsSpecialistSpell(spell.resref, kit) then
			count = count + (spell.count or 1)
		end
	end
	return count
end

function rbmSpecialistRequirementsSatisfied(spells)
	local kit = rbmSpecialistKitId()
	local level = chargen and chargen.currentSpellLevelChoice
	if not kit or not level or not rbmHasSpecialistSpellAtLevel(kit, level) then
		return true
	end

	local chosen = 0
	for _, choice in pairs(chargen.choose_spell or {}) do
		local spell = spells and spells[level] and spells[level][choice.key]
		if spell and rbmIsSpecialistSpell(spell.resref, kit) then
			if choice.count then
				chosen = chosen + choice.count
			elseif choice.enabled then
				chosen = chosen + 1
			end
		end
	end

	return chosen >= 1
end

function rbmSpecialistCanMemorize(spell)
	local kit = rbmSpecialistKitId()
	if not kit or not bottomSpells or not characters or not characters[id] then
		return true
	end

	local level = currentSpellLevel
	local mageDetails = characters[id].mageDetails
	local details = mageDetails and mageDetails[level]
	if not details or not details.maxMemorized then
		return true
	end

	if #bottomSpells + 1 < details.maxMemorized then
		return true
	end
	if rbmCountSpecialistSpells(bottomSpells, kit) >= 1 then
		return true
	end
	if not rbmHasSpecialistSpellAtLevel(kit, level) then
		return true
	end

	local resref = type(spell) == "table" and spell.resref or spell
	return rbmIsSpecialistSpell(resref, kit)
end
