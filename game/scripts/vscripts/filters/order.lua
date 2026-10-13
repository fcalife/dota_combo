function Filters:ExecuteOrderFilter(event)
	local order_type = event.order_type
	local player_id = event.issuer_player_id_const
	local target = event.entindex_target ~= 0 and EntIndexToHScript(event.entindex_target) or nil
	local ability = event.entindex_ability ~= 0 and EntIndexToHScript(event.entindex_ability) or nil
	local order_position = Vector(event.position_x, event.position_y, 0)

	if ability and not ability.GetAbilityName then ability = nil end
	local ability_name = ability and ability:GetAbilityName() or nil

	local unit
	if event.units and event.units["0"] then
		unit = EntIndexToHScript(event.units["0"])
	end

	-- no orders allowed after winner is decided
	if GameMode.winner then return false end

	if DisableHelp.ExecuteOrderFilter(order_type, ability, target, unit, order_position) == false then
		return false
	end

	return true
end
