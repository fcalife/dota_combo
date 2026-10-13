ChatCommands = ChatCommands or class({})


function ChatCommands:Init()
	RegisterGameEventListener("player_chat", function(event)
		ChatCommands:OnPlayerChat(event)
	end)
end


function ChatCommands:OnPlayerChat(event)
	if not event.userid then return end
	if not event.playerid or not PlayerResource:IsValidPlayerID(event.playerid) then return end

	event.player = PlayerResource:GetPlayer(event.playerid)
	if not event.player then return end

	event.hero = event.player:GetAssignedHero()
	if not event.hero then return end

	event.player_id = event.playerid

	local command_source = string.trim(string.lower(event.text))
	if command_source:sub(0,1) ~= "-" then return end
	-- removing `-`
	command_source = command_source:sub(2)

	local arguments = string.split(command_source)
	local command_name = table.remove(arguments, 1)

	if ChatCommands[command_name] then
		ErrorTracking.Try(ChatCommands[command_name], ChatCommands, arguments, event)
	end

	ErrorTracking.Try(ChatCommands.GeneralProcessing, ChatCommands, command_name, arguments, event)
end


ChatCommands:Init()


-- Chat commands that rely on knowing command name go here
function ChatCommands:GeneralProcessing(command_name, arguments, event)
	if not command_name then return end
	if not GameMode:IsDeveloper(event.player_id) and not GameRules:IsCheatMode() then return end


end


function ChatCommands:position(arguments, event)
	print("[DEBUG] position:", event.hero:GetAbsOrigin())
end


function ChatCommands:rr(arguments, event)
	if not GameMode:IsDeveloper(event.player_id) and not GameRules:IsCheatMode() then return end

	SendToServerConsole('script_reload')
end


function ChatCommands:timescale(arguments, event)
	if not GameMode:IsDeveloper(event.player_id) and not GameRules:IsCheatMode() then return end
	if not arguments[1] then return end

	local value = tonumber(arguments[1])
	if value < 1 then value = 1 end -- if arg < 1 server freezes
	Convars:SetInt("host_timescale", value)
end


function ChatCommands:entindex(arguments, event)
	print(event.hero:entindex(), event.hero:GetPlayerOwnerID())
end


function ChatCommands:modifiers(arguments, event)
	if not GameMode:IsDeveloper(event.player_id) and not GameRules:IsCheatMode() then return end

	print(event.hero:GetUnitName(), "modifiers:")
	for i, modifier in ipairs(event.hero:FindAllModifiers()) do
		print("\t[" .. i .. "] " .. modifier:GetName())
	end
end


function ChatCommands:error(arguments, event)
	if not GameMode:IsDeveloper(event.player_id) then return end

	local index = nil
	print(arguments[index])
	print(1 + index)
end


function ChatCommands:list_errors(arguments, event)
	if not GameMode:IsDeveloper(event.player_id) then return end

	print("[Chat Commands] listing collected errors")
	DeepPrintTable(ErrorTracking.collected_errors)
end


function ChatCommands:toast(arguments, event)
	if not GameMode:IsDeveloper(event.player_id) then return end

	Toasts:NewForAll("mail_incoming", {
		topic = "#feedback_reply",
		source = "#dev_team",
	})

	Toasts:NewForAll("payment_success", {
		product_name = "subscription_tier_1",
	})

	Toasts:NewForAll("payment_success", {
		product_name = "currency_bundle_550",
	})

	Toasts:NewForAll("payment_fail", {
		product_name = "subscription_tier_2",
	})

	Toasts:NewForAll("player_tip", {
		source_player_id = event.player_id,
		target_player_id = event.player_id,
		currency = 5
	})
end


function ChatCommands:purchase_item(arguments, event)
	if not GameMode:IsDeveloper(event.player_id) then return end

	WebInventory:PurchaseItem(event.player_id, arguments[1], tonumber(arguments[2] or 0), arguments[3] or CURRENCY_TYPE.BASIC, tonumber(arguments[4] or 1))
end


function ChatCommands:equip(arguments, event)
	if not GameMode:IsDeveloper(event.player_id) then return end

	WebInventory:EquipEvent({
		PlayerID = event.player_id,
		item_name = arguments[1]
	})
end


function ChatCommands:unequip(arguments, event)
	if not GameMode:IsDeveloper(event.player_id) then return end

	WebInventory:UnequipEvent({
		PlayerID = event.player_id,
		item_name = arguments[1]

	})
end


function ChatCommands:use_item(arguments, event)
	if not GameMode:IsDeveloper(event.player_id) then return end

	WebInventory:ItemConsumeEvent({
		PlayerID = event.player_id,
		item_name = arguments[1],
		used_count = tonumber(arguments[2] or 1)
	})
end


function ChatCommands:redeem_gift_code(arguments, event)
	if not GameMode:IsDeveloper(event.player_id) then return end

	GiftCodes:RedeemGiftCode({
		PlayerID = event.player_id,
		gift_code = arguments[1]
	})
end


function ChatCommands:roll_test(arguments, event)
	if not GameMode:IsDeveloper(event.player_id) then return end

	local rolled = {}

	for i = 0, 1000 do
		local outcome = WebTreasure:RollTreasureItem(event.player_id, WebInventory.treasure_pools[arguments[1] or "sprays_treasure_1"])

		if not rolled[outcome] then
			rolled[outcome] = 1
		else
			rolled[outcome] = rolled[outcome] + 1
		end
	end

	print("1k rolls result: ")
	DeepPrintTable(rolled)
end


function ChatCommands:tip(arguments, event)
	if not GameMode:IsDeveloper(event.player_id) then return end

	Tips:Tip({
		PlayerID = 0,
		target_player_id = tonumber(arguments[1])
	})
end


function ChatCommands:tip_test(arguments, event)
	if not GameMode:IsDeveloper(event.player_id) then return end

	local _pairs = {
		{0, 1}, {1, 2}, {2, 0}, {4, 6}, {3, 0}, {7, 0}, {8, 2},
	}

	for i, pair in pairs(_pairs) do
		Timers:CreateTimer(1 + i, function()
			Toasts:NewForAll("player_tip", {
				source_player_id = pair[1],
				target_player_id = pair[2],
				currency = 5
			})
		end)
	end
end


function ChatCommands:aftermatch(arguments, event)
	if not GameMode:IsDeveloper(event.player_id) then return end

	WebApi:AfterMatchRequest(tonumber(arguments[1] or 2))
end


function ChatCommands:leaderboard(arguments, event)
	if not GameMode:IsDeveloper(event.player_id) then return end

	WebLeaderboards:SendLeaderboard({
		PlayerID = 0,
		map_name = arguments[1] or GetMapName()
	})
end


function ChatCommands:gpl(arguments, event)
	if not GameMode:IsDeveloper(event.player_id) then return end

	print("Punishment level:", WebPlayer:GetPunishmentLevel(event.player_id))
end


function ChatCommands:spl(arguments, event)
	if not GameMode:IsDeveloper(event.player_id) then return end

	WebPlayer:SetPunishmentLevel(event.player_id, tonumber(arguments[1] or 0), arguments[2] or "chat command", true)
end


function ChatCommands:time(arguments, event)
	print(GetSystemDate())
	print(GetSystemTime())
	print(GetSystemTimeMS())
end


function ChatCommands:dates(arguments, event)
	-- supposed to be true
	print(DateOlder(GetSystemDate(), "01/10/24"))
	print(DateOlder(GetSystemDate(), "02/09/24"))
	print(DateOlder(GetSystemDate(), "02/09/25"))
	-- supposed to be false
	print(DateOlder(GetSystemDate(), "01/09/24"))
	print(DateOlder(GetSystemDate(), "01/05/24"))
	print(DateOlder(GetSystemDate(), "01/10/23"))
	print(DateOlder(GetSystemDate(), "12/10/23"))
end



function ChatCommands:claim(arguments, event)
	WebPromoEvents:ClaimRewardEvent({
		PlayerID = event.player_id,
		promo_event_id = arguments[1],
		task_id = arguments[2],
	})
end
