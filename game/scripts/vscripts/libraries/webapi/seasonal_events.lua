SeasonalEvents = SeasonalEvents or {}

function SeasonalEvents:Init()
	SeasonalEvents._halloween_dates = {
		["10/27/22"] = true, -- just in case of US timezone things
		["10/28/22"] = true,
		["10/29/22"] = true,
		["10/30/22"] = true,
	}

	SeasonalEvents._christmas_dates = {
		["12/23/22"] = true, -- Friday
		["12/24/22"] = true, -- Saturday
		["12/25/22"] = true, -- Sunday
		["12/26/22"] = true, -- Monday, for extended fun
	}

	EventStream:Listen("SeasonalEvents:get_events", SeasonalEvents.SendEvents, SeasonalEvents)
end


function SeasonalEvents:SendEvents(event)
	local player_id = event.PlayerID
	if not player_id or not PlayerResource:IsValidPlayerID(player_id) then return end

	local player = PlayerResource:GetPlayer(player_id)
	if not IsValidEntity(player) then return end

	CustomGameEventManager:Send_ServerToPlayer(player, "SeasonalEvents:update_events", {
		halloween = SeasonalEvents:IsHalloween(),
		christmas = SeasonalEvents:IsChristmas(),
	})
end

function SeasonalEvents:IsHalloween()
	-- return SeasonalEvents._halloween_dates[GetSystemDate()] or false
	return false
end

function SeasonalEvents:IsChristmas()
	-- return SeasonalEvents._christmas_dates[GetSystemDate()] or false
	return false
end

SeasonalEvents:Init()
