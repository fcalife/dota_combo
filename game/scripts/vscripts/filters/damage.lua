function Filters:DamageFilter(event)
	local target = event.entindex_victim_const and EntIndexToHScript(event.entindex_victim_const) or nil
	local attacker = event.entindex_attacker_const and EntIndexToHScript(event.entindex_attacker_const) or nil
	local ability = event.entindex_inflictor_const and  EntIndexToHScript(event.entindex_inflictor_const) or nil

	return true
end
