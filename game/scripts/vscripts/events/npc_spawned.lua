function Events:OnNPCSpawned(event)
	local unit = event.entindex and EntIndexToHScript(event.entindex) or nil
	if not unit then return end

	-- wait for 1 frame for unit creation to finalize
	-- some fields aren't correct when accessed from here without delay
	Timers:CreateTimer(0, function()
		Events:_OnNpcInitFinished(event, unit)
	end)
end


function Events:_OnNpcInitFinished(event, unit)
	if not IsValidEntity(unit) then return end

	local owner_player_id = unit:GetPlayerOwnerID()
	local unit_name = unit:GetUnitName()

	EventDriver:Dispatch("Events:npc_spawned", {
		unit = unit,
		unit_name = unit_name,
		owner_player_id = owner_player_id,
	})
end
