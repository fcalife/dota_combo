WebApi = WebApi or {}
-- status: complete, untested

-- change this into provided dev key for testing in tools
local dev_key = ""

WebApi.custom_game = "ar_custom_game_template"
WebApi.match_id = IsInToolsMode() and RandomInt(-10000000, -1) or tonumber(tostring(GameRules:Script_GetMatchID()))
WebApi.server_url = IsInToolsMode() and "http://127.0.0.1:5000/" or "https://api.template.dota2unofficial.com/" --


local dedicated_key = IsInToolsMode() and dev_key or GetDedicatedServerKeyV2("1")
local dedicated_key_v3 = IsInToolsMode() and dev_key or GetDedicatedServerKeyV3("3")


function WebApi:Send(path, data, on_success_callback, on_error_callback, retry_while)
	local request = CreateHTTPRequestScriptVM("POST", WebApi.server_url .. path)

	request:SetHTTPRequestHeaderValue("Dedicated-Server-Key", dedicated_key)
	request:SetHTTPRequestHeaderValue("Dedicated-Server-Key-v3", dedicated_key_v3)

	if data then
		data.map_name = GetMapName()
		data.custom_game = WebApi.custom_game
		data.match_id = WebApi.match_id
		if IsInToolsMode() then
			print("[WebApi] requesting", path)
			DeepPrintTable(data)
		end
		request:SetHTTPRequestRawPostBody("application/json", json.encode(data))
	end

	request:Send(function(response)
		local status_code = response.StatusCode
		if status_code >= 200 and status_code <= 300 then
			print("[WebApi] finished request to", path, status_code)
			local response_data = json.decode(response.Body)
			if on_success_callback then
				on_success_callback(response_data)
			end
		else
			print("[WebApi] failed request, body:", response.Body)
			local error_data = response.Body and json.decode(response.Body) or {}

			if retry_while and retry_while() then
				WebApi:Send(path, data, on_success_callback, on_error_callback, retry_while)
			elseif on_error_callback then
				on_error_callback(error_data)
			end
		end
	end)
end


function WebApi:GetPlayerIdBySteamId(steam_id)
	return WebApi.steam_id_to_player_id[steam_id]
end


function WebApi:InitSteamIdTable()
	WebApi.steam_id_to_player_id = {}
	for player_id = 0, 24 do
		if PlayerResource:IsValidPlayerID(player_id) then
			local steam_id = tostring(PlayerResource:GetSteamID(player_id))
			if steam_id then
				WebApi.steam_id_to_player_id[steam_id] = player_id
			end
		end
	end
end


function WebApi:ProcessMetadata(player_id, metadata)
	if not metadata then return end
	-- match event carries current player state (i.e. current currency instead of additional)
	if metadata.currency then
		WebPlayer:SetCurrency(player_id, tonumber(metadata.currency))
	end

	if metadata.hard_currency then
		WebPlayer:SetHardCurrency(player_id, tonumber(metadata.hard_currency))
	end

	if metadata.items then
		for _, item in pairs(metadata.items) do
			WebInventory:AddItem(player_id, item)
		end
		WebInventory:UpdateClient(player_id)
	end

	if metadata.subscription then
		WebPlayer:SetSubscriptionStatus(player_id, metadata.subscription)
	end

	if metadata.bp_level then
		WebPlayer:SetLevel(player_id, metadata.bp_level)
	end

	if metadata.bp_exp then
		WebPlayer:SetCurrentExp(player_id, metadata.bp_exp)
	end

	if metadata.gift_codes then
		for _, code in pairs(metadata.gift_codes) do
			GiftCodes:AddGiftCode(player_id, code)
		end
		GiftCodes:UpdateClient(player_id)
	end

	WebPlayer:UpdateClient(player_id)
	BattlePass:UpdateClient(player_id)
end


RegisterGameEventListener("player_connect_full", function()
	if WebApi.before_match_sent then return end
	print("[WebApi] player loaded, requesting before-match")
	WebApi:InitSteamIdTable()
	WebApi.before_match_sent = true
	WebApi:RequestBeforeMatch()

	MatchEvents:ScheduleNextRequest()
end)
