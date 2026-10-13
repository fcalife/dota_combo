WebPayments = WebPayments or {}
-- status: complete, untested

SOURCE_XSOLLA = "xsolla"
SOURCE_STRIPE = "stripe"

PAYMENT_MODES = {
	PAYMENT = "payment",
	SUBSCRIPTION = "subscription"
}


function WebPayments:Init()
	WebPayments.pending_requests = {}
	WebPayments.known_customer_portal_links = {}

	EventStream:Listen("WebPayments:get_customer_portal_url", WebPayments.RequestCustomerPortalUrl, WebPayments)
	EventStream:Listen("WebPayments:get_subscription_upgrade_url", WebPayments.RequestSubscriptionUpgradeUrl, WebPayments)
	EventStream:Listen("WebPayments:get_payment_url", WebPayments.RequestPaymentUrl, WebPayments)
	EventStream:Listen("WebPayments:cancel_subscription", WebPayments.CancelSubscription, WebPayments)

	-- validate combinations of source and method
	WebPayments.valid_payment_methods = {
		xsolla = {
			card = true,
		},
		stripe = {
			card = true,
			wechat_pay = true,
			alipay = true
		}
	}

	-- validate combinations of modes and methods
	WebPayments.valid_modes = {
		-- can only buy subs with card (xsolla counts as card purchase)
		subscription = {
			card = true,
		},
		payment = {
			card = true,
			wechat_pay = true,
			alipay = true
		}
	}
end


function WebPayments:RequestCustomerPortalUrl(event)
	local player_id = event.PlayerID
	if not player_id or not PlayerResource:IsValidPlayerID(player_id) then return end

	local player = PlayerResource:GetPlayer(player_id)
	if not player or player:IsNull() then return end

	local known_link = WebPayments.known_customer_portal_links[player_id]
	if known_link then
		CustomGameEventManager:Send_ServerToPlayer(player, "WebPayments:open_in_external_browser", {
			url = known_link
		})
		return
	end

	local steam_id = tostring(PlayerResource:GetSteamID(player_id))

	local source = WebPlayer:GetSubscriptionSource(player_id)
	if not source or source ~= SOURCE_STRIPE then
		print("[WebPayments] declined request for customer portal from player without Stripe subscription")
		return
	end

	WebApi:Send(
		"api/lua/payments/create_customer_portal_url",
		{
			steam_id = steam_id,
			subscription_source = source,
		},
		function(data)
			if not player or player:IsNull() then return end

			print("[WebPayments] created customer portal with URL: ", data.url)
			WebPayments.known_customer_portal_links[player_id] = data.url

			CustomGameEventManager:Send_ServerToPlayer(player, "WebPayments:open_in_external_browser", {
				url = data.url
			})
		end
	)
end


function WebPayments:RequestSubscriptionUpgradeUrl(event)
	local player_id = event.PlayerID
	if not player_id or not PlayerResource:IsValidPlayerID(player_id) then return end

	local steam_id = tostring(PlayerResource:GetSteamID(player_id))

	local source = WebPlayer:GetSubscriptionSource(player_id)

	-- Xsolla subscription update is performed via default payment flow
	-- with tier change handled on backend
	if source == SOURCE_XSOLLA then
		WebPayments:RequestPaymentUrl({
			PlayerID = player_id,
			payment_mode = PAYMENT_MODES.SUBSCRIPTION,
			payment_method = "card",
			payment_system = "xsolla",
			product_name = event.product_name,
			quantity = 1,
			as_gift_code = false
		})
		return
	end


	WebApi:Send(
		"api/lua/payments/create_upgrade_url",
		{
			steam_id = steam_id,
			subscription_source = source,
		},
		function(data)
			local player = PlayerResource:GetPlayer(player_id)
			if not player or player:IsNull() then return end

			print("[WebPayments] created customer portal for subscription upgrade with URL: ", data.url)

			CustomGameEventManager:Send_ServerToPlayer(player, "WebPayments:open_in_external_browser", {
				url = data.url
			})
		end
	)
end


function WebPayments:SetPaymentStatus(player_id, status)
	if status then
		MatchEvents:SetActivePolling(true)
		-- mark player as waiting for payment to complete, with timeout
		WebPayments.pending_requests[player_id] = Timers:CreateTimer(
			120,
			function()
				WebPayments.pending_requests[player_id] = nil
				if not next(WebPayments.pending_requests) then
					MatchEvents:SetActivePolling(false)
				end
			end
		)
	else
		if WebPayments.pending_requests[player_id] then
			Timers:RemoveTimer(WebPayments.pending_requests[player_id])
			WebPayments.pending_requests[player_id] = nil
		end

		-- disable active polling if no other players wait for their purchases in a meantime
		if not next(WebPayments.pending_requests) then
			MatchEvents:SetActivePolling(false)
		end
	end
end


function WebPayments:ValidatePaymentRequest(event)
	if not WebPayments.valid_payment_methods[event.payment_system] then return false end
	if not WebPayments.valid_payment_methods[event.payment_system][event.payment_method] then return false end

	if not WebPayments.valid_modes[event.payment_mode] then return false end
	if not WebPayments.valid_modes[event.payment_mode][event.payment_method] then return false end

	return true
end


function WebPayments:RequestPaymentUrl(event)
	local player_id = event.PlayerID
	if not IsValidPlayerID(player_id) then return end

	local steam_id = tostring(PlayerResource:GetSteamID(player_id))

	if not WebPayments:ValidatePaymentRequest(event) then
		DisplayError(player_id, "#dota_hud_error_incorrect_payment_configuration")
		return
	end

	WebApi:Send(
		"api/lua/payments/get_payment_url",
		{
			steam_id = steam_id,
			match_id = WebApi.match_id,
			payment_mode = event.payment_mode,
			payment_method = event.payment_method,
			payment_system = event.payment_system,
			product_name = event.product_name,
			quantity = event.quantity or 1,
			as_gift_code = event.as_gift_code or false,
		},
		function(data)
			local player = PlayerResource:GetPlayer(player_id)
			if not player or player:IsNull() then return end

			print("[WebPayments] created payment session with URL: ", data.url)
			DeepPrintTable(data)

			WebPayments:SetPaymentStatus(player_id, true)

			CustomGameEventManager:Send_ServerToPlayer(player, "WebPayments:open_in_external_browser", {
				method = data.method,
				system = data.system,
				url = data.url
			})
		end
	)
end


function WebPayments:CancelSubscription(event)
	local player_id = event.PlayerID
	if not IsValidPlayerID(player_id) then return end

	local current_subscription_type = WebPlayer:GetSubscriptionType(player_id)
	if not current_subscription_type or current_subscription_type == "payment" then
		DisplayError(player_id, "#dota_hud_error_cant_cancel_this_subscription_type")
		return
	end

	local steam_id = tostring(PlayerResource:GetSteamID(player_id))

	WebApi:Send(
		"api/lua/payments/cancel_subscription",
		{
			steam_id = steam_id,
			subscription_source = WebPlayer:GetSubscriptionSource(player_id)
		},
		function()
			print("[WebPayments] cancelled subscription for player", player_id)
			local data = WebPlayer:GetSubscriptionData(player_id)
			data.metadata.source = nil
			data.type = "payment"

			WebPlayer:UpdateClient(player_id)
		end,
		function(error)
			print("[WebPayments] failed to cancel subscription for player", player_id)
		end
	)
end


MatchEvents.event_handlers.payment_success = function(data)
	print("[WebPayments] payment complete!")
	DeepPrintTable(data)

	local player_id = WebApi:GetPlayerIdBySteamId(data.steam_id)
	if not player_id or not PlayerResource:IsValidPlayerID(player_id) then return end

	WebApi:ProcessMetadata(player_id, data)

	WebPayments:SetPaymentStatus(player_id, false)

	Toasts:NewForPlayer(player_id, "payment_success", data)
end


MatchEvents.event_handlers.payment_fail = function(data)
	print("[WebPayments] payment failed!")
	DeepPrintTable(data)

	local player_id = WebApi:GetPlayerIdBySteamId(data.steam_id)
	if not player_id or not PlayerResource:IsValidPlayerID(player_id) then return end

	WebApi:ProcessMetadata(player_id, data)

	Toasts:NewForPlayer(player_id, "payment_fail", data)
end


WebPayments:Init()
