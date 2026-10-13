ITEM_DEFINITIONS["treasure_1"] = {
	slot = INVENTORY_SLOTS.TREASURES,
	type = ITEM_TYPES.CONSUMABLE,
	rarity = ITEM_RARITIES.RARE,

	unlocked_with = {
		currency = 200,
		currency_type = CURRENCY_TYPE.HARD
	},

	on_consume = Resolve("OnTreasureUsed", "WebTreasure"),
}
ITEM_DEFINITIONS["treasure_2"] = {
	slot = INVENTORY_SLOTS.TREASURES,
	type = ITEM_TYPES.CONSUMABLE,
	rarity = ITEM_RARITIES.MYTHICAL,

	unlocked_with = {
		currency = 200
	},

	on_consume = Resolve("OnTreasureUsed", "WebTreasure"),
}

ITEM_DEFINITIONS["treasure_3"] = {
	slot = INVENTORY_SLOTS.TREASURES,
	type = ITEM_TYPES.CONSUMABLE,
	rarity = ITEM_RARITIES.IMMORTAL,

	unlocked_with = {
		currency = 200
	},

	on_consume = Resolve("OnTreasureUsed", "WebTreasure"),
}
