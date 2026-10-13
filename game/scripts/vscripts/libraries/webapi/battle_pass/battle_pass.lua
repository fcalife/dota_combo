BattlePass = BattlePass or {}


require("libraries/webapi/battle_pass/rewards")


function BattlePass:Init()
	EventStream:Listen("BattlePass:get_rewards_data", BattlePass.SendRewardsData, BattlePass)
	EventStream:Listen("BattlePass:get_player_data", BattlePass.SendPlayerData, BattlePass)
	EventStream:Listen("BattlePass:redeem", BattlePass.RedeemRewardsEvent, BattlePass)

	BattlePass.rewards_data = {}
	BattlePass.players_data = {}

	BattlePass._redeem_in_progress = {}

	BattlePass:ProcessRewardsData()
end


function BattlePass:SetExtraData(data)
	if not data then return end

	BattlePass.start_date = data.start_date
	BattlePass.end_date = data.end_date
	BattlePass.end_date_redeem_only = data.end_date_redeem_only
	BattlePass.current_level_from_date = data.current_level_from_date
end


function BattlePass:ProcessRewardsData()
	-- remap rewards with extra details from item definitions and such

	for tier, rewards in pairs(BATTLE_PASS_REWARDS or {}) do
		BattlePass.rewards_data[tier] = {}

		for level, reward_data in pairs(rewards or {}) do
			BattlePass.rewards_data[tier][level] = {}

			if reward_data.item_name then
				local definition = WebInventory:GetItemDefinition(reward_data.item_name)
				if definition then
					BattlePass.rewards_data[tier][level] = {
						item_name = reward_data.item_name,
						count = reward_data.count,
						-- HINT: client might want extra data from definition for item
						--slot = definition.slot,
						--type = definition.type,
						--rarity = definition.rarity,
						-- for particles / models preview, this will go here
					}
				end
			end
			if reward_data.currency then
				BattlePass.rewards_data[tier][level].currency = reward_data.currency
			end
			if reward_data.items then
				BattlePass.rewards_data[tier][level].items = reward_data.items
			end
		end
	end
end


function BattlePass:SetPlayerData(player_id, data)
	BattlePass.players_data[player_id] = data

	BattlePass:UpdateClient(player_id)
end


function BattlePass:GetNewExp(player_id)
	-- IMPLEMENTATION SKIPPED
	-- SHOULD BE DONE IN INHERITED CUSTOM GAMES PER NEED
	return 0
end


function BattlePass:GetNewLevel(player_id)
	-- IMPLEMENTATION SKIPPED
	-- SHOULD BE DONE IN INHERITED CUSTOM GAMES PER NEED
	return 1
end


function BattlePass:SendRewardsData(event)
	local player_id = event.PlayerID
	if not player_id or not PlayerResource:IsValidPlayerID(player_id) then return end

	local player = PlayerResource:GetPlayer(player_id)
	if not player or player:IsNull() then return end

	CustomGameEventManager:Send_ServerToPlayer(player, "BattlePass:set_rewards_data", {
		bp_rewards_data = BattlePass.rewards_data or {},
	})
end


function BattlePass:SendPlayerData(event)
	local player_id = event.PlayerID
	if not player_id or not PlayerResource:IsValidPlayerID(player_id) then return end

	BattlePass:UpdateClient(player_id)
end


function BattlePass:RedeemRewardsEvent(event)
	local player_id = event.PlayerID
	if not player_id or not PlayerResource:IsValidPlayerID(player_id) then return end

	if BattlePass._redeem_in_progress[player_id] then
		DisplayError(player_id, "#dota_hud_error_webapi_request_in_progress")
		return
	end

	local steam_id = tostring(PlayerResource:GetSteamID(player_id))

	local currency = 0
	local hard_currency = 0
	local redeemed_levels = {}
	local _temp_stacked_items = {}
	local has_redeemed_data = false
	local tiers_checks = {
		["0"] = true,
		["1"] = WebInventory:HasItem(player_id, "battle_pass_tier_2"),
	}

	local old_redeemed_levels = WebPlayer:GetBattlepassData(player_id) and WebPlayer:GetBattlepassData(player_id).redeemed_levels

	for tier, levels_data in pairs(event.redeemed_levels or {}) do
		if tiers_checks[tier] then
			redeemed_levels[tier] = {}
			for _, level in pairs(levels_data or {}) do
				local b_level_already_owned = old_redeemed_levels and old_redeemed_levels[tier] and old_redeemed_levels[tier][level]

				if tiers_checks[tier] and not b_level_already_owned and level <= BattlePass:GetLevelFromDate() then
					has_redeemed_data = true
					table.insert(redeemed_levels[tier], level)
					local reward = BATTLE_PASS_REWARDS[tier] and BATTLE_PASS_REWARDS[tier][level]

					if reward.currency then
						currency = currency + reward.currency
					end

					if reward.hard_currency then
						hard_currency = hard_currency + reward.hard_currency
					end

					if reward and reward.item_name then
						_temp_stacked_items[reward.item_name] = (_temp_stacked_items[reward.item_name] or 0) + (reward.count or 1)
					end
					if reward.items then
						for _, _item_data in pairs(reward.items) do
							if _item_data.item_name then
								_temp_stacked_items[_item_data.item_name] = (_temp_stacked_items[_item_data.item_name] or 0) + (_item_data.count or 1)
							end
						end
					end
				end
			end
		end
	end
	if not has_redeemed_data then return end

	local items = {}
	for item_name, count in pairs(_temp_stacked_items) do
		table.insert(items, {
			name = item_name,
			count = count,
		})
	end

	BattlePass._redeem_in_progress[player_id] = true

	WebApi:Send(
		"api/lua/battle_pass/redeem",
		{
			steam_id = steam_id,
			redeemed_levels = redeemed_levels,
			currency = currency,
			hard_currency = hard_currency,
			items = items,
		},
		function(response)
			BattlePass._redeem_in_progress[player_id] = nil
			BattlePass.players_data[player_id].redeemed_levels = response.redeemed_levels
			BattlePass:UpdateClient(player_id)

			print("[Battle Pass] successfully redeemed levels", player_id)
			DeepPrintTable(response)

			if response.currency then
				WebPlayer:SetCurrency(player_id, response.currency)
			end

			if response.hard_currency then
				WebPlayer:SetHardCurrency(player_id, response.hard_currency)
			end

			WebPlayer:UpdateClient(player_id)

			if response.new_items then
				for _, item in pairs(response.new_items) do
					WebInventory:AddItem(player_id, item)
				end
				WebInventory:UpdateClient(player_id)
			end
		end,
		function(err)
			BattlePass._redeem_in_progress[player_id] = nil
			print("[Battle Pass] failed to redeem levels", player_id)
		end
	)
end


function BattlePass:OnSubTierConsumableUsed(player_id, item_name, item_data, definition)
	local current_sub_tier = WebPlayer:GetSubscriptionTier(player_id)

	if current_sub_tier and current_sub_tier > 0 then
		-- add currency compensation if player already has active subscription
		WebPlayer:AddBackendCurrency(player_id, definition.compensation_value)
		return
	end

	local steam_id = tostring(PlayerResource:GetSteamID(player_id))
	WebApi:Send(
		"api/lua/battle_pass/create_trial_subscription",
		{
			steam_id = steam_id,
		},
		function(response)
			print("[Battle Pass] successfully created trial subscription", player_id)

			WebPlayer:SetSubscriptionStatus(player_id, response.subscription)
			WebPlayer:UpdateClient(player_id)
		end,
		function(err)
			print("[Battle Pass] failed to create trial subscription", player_id)
		end
	)
end


function BattlePass:GetLevelFromDate()
	return BattlePass.current_level_from_date or 0
end


function BattlePass:UpdateClient(player_id)
	local player = PlayerResource:GetPlayer(player_id)
	if not player or player:IsNull() then return end

	CustomGameEventManager:Send_ServerToPlayer(player, "BattlePass:update", {
		bp_player_data = BattlePass.players_data[player_id] or {},
		b_unlocked_extra_items = WebInventory:HasItem(player_id, "battle_pass_tier_2"),

		start_date = BattlePass.start_date,
		end_date = BattlePass.end_date,
		end_date_redeem_only = BattlePass.end_date_redeem_only,
		current_level_from_date = BattlePass:GetLevelFromDate(),
	})
end


BattlePass:Init()
