function Filters:ModifierFilter(event)
	-- processing goes here
	local caster
	local parent
	local ability

	local modifier_name = event.name_const

	if event.entindex_caster_const then
		caster = EntIndexToHScript(event.entindex_caster_const)
	end

	if event.entindex_parent_const then
		parent = EntIndexToHScript(event.entindex_parent_const)
	end

	if event.entindex_ability_const then
		ability = EntIndexToHScript(event.entindex_ability_const)
	end


	if DisableHelp.ModifierGainedFilter(event) == false then
		return false
	end

	return true
end
