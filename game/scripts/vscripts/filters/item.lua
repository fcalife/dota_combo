function Filters:ItemAddedToInventoryFilter(event)
	-- processing goes here
	if not event.item_entindex_const or not event.inventory_parent_entindex_const then return true end

	local inventory_owner = EntIndexToHScript(event.inventory_parent_entindex_const)
	local item = EntIndexToHScript(event.item_entindex_const)

	local signal, status = ItemDelivery:ProcessPurchasedItem(inventory_owner, item)
	if signal == FILTER_RETURN then
		return status
	end

	return true
end
