GameLoop = GameLoop or {}


function GameLoop:Init()
	local current_layout = MAP_LAYOUTS[GetMapName()]
	if not current_layout then return end
	GameLoop.current_layout = current_layout

	for _, team in pairs(current_layout.teamlist) do
		GameRules:SetCustomGameTeamMaxPlayers(team, current_layout.player_count)

		local color = TEAM_COLORS[team]
		if color then
			SetTeamCustomHealthbarColor(team, color[1], color[2], color[3])
		end
	end

	GameRules:SetCustomGameBansPerTeam(current_layout.player_count)

	EventDriver:Listen("Events:state_changed", GameLoop.OnStateChanged, GameLoop)
end


function GameLoop:OnStateChanged(event)
	print("[Game Loop] state changed: ", event.state)
end
