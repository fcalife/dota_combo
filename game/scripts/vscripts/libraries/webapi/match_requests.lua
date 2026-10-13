-- status: in progress

local function retry_times(times)
	return function()
		times = times - 1
		return times > 0
	end
end


function WebApi:GetPlayersSteamIDs()
	local players = {}

	for player_id = 0, 23 do
		if PlayerResource:IsValidPlayerID(player_id) then
			table.insert(players, tostring(PlayerResource:GetSteamID(player_id)))
		end
	end

	return players
end


function WebApi:RequestBeforeMatch()
	local players = WebApi:GetPlayersSteamIDs()

	WebApi:Send(
		"api/lua/match/before",
		{
			players = players,
			match_id = WebApi.match_id,
		},
		function(data)
			WebApi:_HandleBeforeMatchResponse(data)
		end,
		function(error)
			print("[WebApi] error in before-match: ")
			DeepPrintTable(error)
		end,
		retry_times(2)
	)
end


function WebApi:_HandleBeforeMatchResponse(data)
	for steam_id, player_data in pairs(data.players or {}) do
		local player_id = WebApi:GetPlayerIdBySteamId(steam_id)

		WebPlayer:SetPlayerData(player_id, player_data)
		BattlePass:SetPlayerData(player_id, player_data.battle_pass)
		WebMail:SetPlayerMails(player_id, player_data.mails)
		WebInventory:SetPlayerItems(player_id, player_data.items)
		Equipment:AssignEquippedItems(player_id, player_data.equipped_items)
		Tips:SetTipsData(player_id, player_data.tips_used)
		WebPromoEvents:SetClaimsData(player_id, player_data.promo_event_claims or {})
	end
	-- TODO: process shared stuff for leaderboards etc.
	BattlePass:SetExtraData(data.battle_pass or {})
	WebApi.before_match_succeeded = true
end


function WebApi:GetRatingChange(player_id)
	return 0
end


function WebApi:AfterMatchRequest(winner_team)
	local players = {}

	for player_id = 0, DOTA_MAX_PLAYERS do
		if PlayerResource:IsValidPlayerID(player_id) and not PlayerResource:IsFakeClient(player_id) then
			local rating_change = WebApi:GetRatingChange(player_id)
			local bp_exp_new = BattlePass:GetNewExp(player_id)
			local bp_level_new = BattlePass:GetNewLevel(player_id)

			local steam_id = tostring(PlayerResource:GetSteamID(player_id))

			table.insert(players, {
				steam_id = steam_id,
				team_id = PlayerResource:GetTeam(player_id),

				hero_name = PlayerResource:GetSelectedHeroName(player_id),

				kills = PlayerResource:GetKills(player_id),
				deaths = PlayerResource:GetDeaths(player_id),
				assists = PlayerResource:GetAssists(player_id),

				networth = PlayerResource:GetNetWorth(player_id),
				damage_dealt = PlayerResource:GetRawPlayerDamage(player_id),
				damage_taken = PlayerResource:GetHeroDamageTaken(player_id, true),
				damage_reduced = 0, -- TODO: this should be calculated properly in-place
				healing = PlayerResource:GetHealing(player_id),
				stun_duration_total = PlayerResource:GetStuns(player_id),

				rating_change = rating_change,
				bp_exp_new = bp_exp_new,
				bp_level_new = bp_level_new,

				locale = WebLocale:GetPlayerLocale(player_id)
			})
		end
	end

	WebApi:Send(
		"api/lua/match/after",
		{
			-- map_name \
			-- match_id | - included in webapi Send automatically
			duration = GameRules:GetGameTime(),
			winner_team_id = winner_team,
			banned_heroes = GameRules:GetBannedHeroes(),
			players = players,
		},
		function(data)
			WebApi:_HandleAfterMatchResponse(data)
		end,
		function(error)
			print("[WebApi] error in after-match: ")
			DeepPrintTable(error)
		end
	)
end


function WebApi:_HandleAfterMatchResponse(data)
	print("[WebApi] after-match succeeded")
end
