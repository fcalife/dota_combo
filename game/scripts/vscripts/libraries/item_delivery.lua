ItemDelivery = ItemDelivery or {}

--[[
Provides functionality to instantly transfer purchased items to players with subscription.

-- TODO: resolve case when item has more parts than hero has free slots
]]

function ItemDelivery:Init()
	ItemDelivery.fast_delivery_exclusions = {
		item_ward_observer = true,
		item_ward_sentry = true,
		item_smoke_of_deceit = true,
		item_clarity = true,
		item_flask = true,
		item_greater_mango = true,
		item_enchanted_mango = true,
		item_tango = true,
		item_faerie_fire = true,
		item_tpscroll = true,
		item_dust = true,
	}
end


function ItemDelivery:Refund(unit, item)
	unit:ModifyGold(item:GetCost(), false, 0)
	UTIL_Remove(item)
end


function ItemDelivery:ProcessPurchasedItem(unit, item)
	if not IsValidEntity(unit) or not IsValidEntity(item) then return end

	local purchaser = item:GetPurchaser()
	if not IsValidEntity(purchaser) then return end
	local item_name = item:GetName()
	local player_id = purchaser:GetPlayerID()
	print("[ItemDelivery] added item", item_name, item.__in_transfer)

	-- skip exclusions
	if ItemDelivery.fast_delivery_exclusions[item_name] then return FILTER_CONTINUE, true end
	-- skip illusions and items already in transfer
	if unit:IsIllusion() or item.__in_transfer then return FILTER_RETURN, true end
	-- skip purchases in shop and with insufficient sub tier
	if unit:IsInRangeOfShop(DOTA_SHOP_HOME, true) or WebPlayer:GetSubscriptionTier(player_id) <= 0 then
		return FILTER_CONTINUE, true
	end

	if not purchaser:HasAnyAvailableInventorySpace() then
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(purchaser:GetPlayerID()), "display_custom_error", {
			message = "#dota_hud_error_cant_purchase_inventory_full"
		})
		return FILTER_RETURN, false
	end

	item.__in_transfer = true

	-- wait until item
	Timers:CreateTimer(0, function()
		if not IsValidEntity(item) then return end

		local inventory_source = (unit.IsCourier and unit:IsCourier() and unit) or purchaser
		inventory_source:TakeItem(item)

		local container = item:GetContainer()
		if container then UTIL_Remove(container) end

		item:SetCombineLocked(true)

		Timers:CreateTimer(0, function()
			if not IsValidEntity(item) then return end

			unit:TakeItem(item)
			item:SetCombineLocked(false)
			purchaser:AddItem(item)

			-- item.__in_transfer = nil
		end)
	end)

	return FILTER_CONTINUE, true
end


ItemDelivery:Init()
