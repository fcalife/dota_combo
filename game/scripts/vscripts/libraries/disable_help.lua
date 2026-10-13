DisableHelp = DisableHelp or {}

EventStream:Listen("set_disable_help", function(data)
	local to = data.to;
	if PlayerResource:IsValidPlayerID(to) then
		local player_id = data.PlayerID;

		if not player_id or not PlayerResource:IsValidPlayerID(player_id) then return end

		local is_help_disabled = data.disable == 1
		PlayerResource:SetUnitShareMaskForPlayer(player_id, to, 4, is_help_disabled)

		local disable_help_table = CustomNetTables:GetTableValue("disable_help", tostring(player_id)) or {}
		disable_help_table[tostring(to)] = is_help_disabled
		DeepPrintTable(disable_help_table)
		CustomNetTables:SetTableValue("disable_help", tostring(player_id), disable_help_table)
	end
end)

local disabled_modifiers = {
	modifier_tiny_toss = true,
}

local disabled_modifiers_for_nonparty = {
	modifier_tiny_toss = true,
}

function DisableHelp.ModifierGainedFilter(filterTable)
	if disabled_modifiers[filterTable.name_const] then
		local parent = EntIndexToHScript(filterTable.entindex_parent_const)
		local caster = EntIndexToHScript(filterTable.entindex_caster_const)
		local ability = EntIndexToHScript(filterTable.entindex_ability_const)

		if PlayerResource:IsDisableHelpSetForPlayerID(parent:GetPlayerOwnerID(), caster:GetPlayerOwnerID()) then
			ability:EndCooldown()
			ability:RefundManaCost()
			DisplayError(caster:GetPlayerOwnerID(), "dota_hud_error_target_has_disable_help")
			return false
		end
	end
	if disabled_modifiers_for_nonparty[filterTable.name_const] then
		local parent = EntIndexToHScript(filterTable.entindex_parent_const)
		local caster = EntIndexToHScript(filterTable.entindex_caster_const)
		local ability = EntIndexToHScript(filterTable.entindex_ability_const)

		if parent:IsRealHero()
		and (parent:GetTeam() == caster:GetTeam())
		and PlayerResource:GetPartyID(parent:GetPlayerOwnerID()) ~= PlayerResource:GetPartyID(caster:GetPlayerOwnerID())
		then
			ability:EndCooldown()
			ability:RefundManaCost()
			DisplayError(caster:GetPlayerOwnerID(), "dota_hud_error_target_has_disable_help")
			return false
		end
	end
end

local disabled_abilities = {
	--[[ HEROES ]]--
	bane_nightmare = true,
	earth_spirit_boulder_smash = true,
	earth_spirit_geomagnetic_grip = true,
	earth_spirit_petrify = true,
	enigma_demonic_conversion = true,
	furion_sprout = true,
	wisp_tether = true,
	kunkka_x_marks_the_spot = true,
	life_stealer_infest = true,
	lycan_wolf_bite = true,
	marci_grapple = true,
	morphling_replicate = true,
	necrolyte_death_seeker = true,
	oracle_fates_edict = true,
	oracle_purifying_flames = true,
	obsidian_destroyer_astral_imprisonment = true,
	phoenix_supernova = true,
	pudge_dismember = true,
	pugna_decrepify = true,
	rubick_telekinesis = true,
	rubick_spell_steal = true,
	shadow_demon_disruption = true,
	snapfire_firesnap_cookie = true,
	snapfire_gobble_up = true,
	terrorblade_sunder = true,
	tiny_toss = true,
	troll_warlord_battle_trance = true,
	vengefulspirit_nether_swap = true,
	weaver_time_lapse = true,
	winter_wyvern_cold_embrace = true,

	--[[ ITEMS ]]--
	item_shadow_amulet = true,
	item_force_staff = true,
	item_wind_waker = true,
	item_ethereal_blade = true,
	item_hurricane_pike = true,
	item_lotus_orb = true,

	--[[ NEUTRAL ITEMS ]]--
	item_wand_of_the_brine = true,
	item_book_of_shadows = true,
}

function DisableHelp.ExecuteOrderFilter(order_type, ability, target, unit, order_vector)
	if not unit or not ability then
		return
	end
	if not ability or ability:IsNull() then return end

	local caster_player_id = unit:GetPlayerOwnerID()
	local ability_name = ability:GetAbilityName()

	if ability_name == "furion_sprout" then
		if (
			order_type == DOTA_UNIT_ORDER_CAST_TARGET and
			target and
			target:IsRealHero() and
			target ~= unit and
			target:GetTeam() == unit:GetTeam()
		) then
			DisplayError(caster_player_id, "dota_hud_error_target_has_disable_help")
			return false
		else
			local enemies = FindUnitsInRadius(
				unit:GetTeam(),
				order_vector,
				nil,
				210,
				DOTA_UNIT_TARGET_TEAM_ENEMY,
				DOTA_UNIT_TARGET_HERO,
				DOTA_UNIT_TARGET_FLAG_NONE,
				FIND_ANY_ORDER,
				false
			)
			if #enemies == 0 then
				local allies = FindUnitsInRadius(
					unit:GetTeam(),
					order_vector,
					nil,
					160,
					DOTA_UNIT_TARGET_TEAM_FRIENDLY,
					DOTA_UNIT_TARGET_HERO,
					DOTA_UNIT_TARGET_FLAG_NONE,
					FIND_ANY_ORDER,
					false
				)
				for i, x in pairs(allies) do
					if x == unit then allies[i] = nil end
				end
 				if #allies > 0 then
					DisplayError(caster_player_id, "dota_hud_error_target_has_disable_help")
					return false
				end
			end
		end
	elseif order_type == DOTA_UNIT_ORDER_CAST_TARGET
	and target
	and disabled_abilities[ability_name]
	and target:GetTeam() == unit:GetTeam()
	and PlayerResource:IsDisableHelpSetForPlayerID(target:GetPlayerOwnerID(), unit:GetPlayerOwnerID())
	then
		DisplayError(unit:GetPlayerOwnerID(), "dota_hud_error_target_has_disable_help")
		return false
	end
end
