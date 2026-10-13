const CONTEXT = $.GetContextPanel();
const ITEM_LIST = $("#CurrentItemsList");
const EQUIPPED_ITEMS_LIST = $("#EquippedItems");

let DEFINITIONS = {};
let PLAYER_ITEMS = {};
let EQUIPPED_ITEMS = {};

const SLOT_ID_TO_NAME = {
	["1"]: "#SPRAY",
	["2"]: "#AURA",
	["3"]: "#HERO_EFFECT",
	["4"]: "#KILL_EFFECT",
	["5"]: "#PET",
	["6"]: "#COSMETIC_SKILL",
	["7"]: "#HIGH_FIVE",
};

function SetDefinitions(definitions) {
	// $.Msg("set definitions ", definitions);
	ITEM_LIST.RemoveAndDeleteChildren();
	for (const [item_name, item_data] of Object.entries(definitions || {})) {
		const item_panel = $.CreatePanel("Label", ITEM_LIST, item_name);
		item_panel.text = $.Localize(`#${item_name}`);
		item_panel.item_name = item_name;
		item_panel.AddClass("ItemEntry");

		item_panel.SetPanelEvent("onactivate", () => {
			const is_equipped = item_panel.BHasClass("equipped");
			const event_name = is_equipped ? "WebInventory:unequip" : "WebInventory:equip";
			// item_panel.SetHasClass("equipped", !is_equipped);
			GameEvents.SendToServerEnsured(event_name, {
				item_name: item_name,
			});
		});
		item_data.panel = item_panel;
		DEFINITIONS[item_name] = item_data;
	}
	UpdateInventoryStatus();
	UpdateEquippedStatus();
}

function UpdateEquippedStatus() {
	// $.Msg("UpdateEquippedStatus");
	// $.Msg(DEFINITIONS);
	// $.Msg(EQUIPPED_ITEMS);
	for (const [item_name, item_data] of Object.entries(DEFINITIONS || {})) {
		const is_equipped = EQUIPPED_ITEMS[item_data.slot] == item_name;
		// $.Msg(item_name, " ", is_equipped, " ", EQUIPPED_ITEMS[item_data.slot]);
		item_data.panel.SetHasClass("equipped", is_equipped);
	}
}

function UpdateInventoryStatus() {
	for (const [item_name, data] of Object.entries(PLAYER_ITEMS || {})) {
		// $.Msg(item_name, " ", data);
		if (!DEFINITIONS[item_name]) continue;
		const item_definition = DEFINITIONS[item_name];
		item_definition.owned = true;
		item_definition.count = data.count || 1;
		item_definition.panel.SetHasClass("owned", true);
	}
	UpdateEquippedStatus();
}

function UpdateInventory(items) {
	// $.Msg("update inventory: ");
	// JSON.print(items);
	PLAYER_ITEMS = items;
	UpdateInventoryStatus();
}

function UpdateEquipped(equipped) {
	EQUIPPED_ITEMS = equipped || {};
	EQUIPPED_ITEMS_LIST.RemoveAndDeleteChildren();
	for (const [slot, item_name] of Object.entries(EQUIPPED_ITEMS)) {
		// $.Msg("equipment: ", slot, " ", item_name);
		const slot_name = SLOT_ID_TO_NAME[slot];
		let slot_panel = $.CreatePanel("Label", EQUIPPED_ITEMS_LIST, slot_name);
		slot_panel.AddClass("ItemSlot");
		slot_panel.text = `${$.Localize(slot_name)} : ${$.Localize("#" + item_name)}`;
	}
	UpdateEquippedStatus();
}

function UpdatePlayer(player_data) {
	$.Msg("Player data: ", player_data);

	CONTEXT.SetDialogVariableInt("currency", GameUI.Player.GetCurrency("currency"));
	CONTEXT.SetDialogVariableInt("hard_currency", GameUI.Player.GetCurrency("hard_currency"));
	CONTEXT.SetDialogVariable(
		"subscription_data",
		`Tier ${GameUI.Player.GetSubscriptionTier()} until
		${player_data.subscription.end_date} of type ${player_data.subscription.type}`,
	);
}

function UpdatePrices() {
	$("#currency_bundle_550").SetDialogVariable("price", GameUI.GetProductPrice("currency_bundle_550"));
	$("#subscription_tier_1").SetDialogVariable("price", GameUI.GetProductPrice("subscription_tier_1"));
	$("#subscription_tier_2").SetDialogVariable("price", GameUI.GetProductPrice("subscription_tier_2"));
}

(() => {
	UpdatePrices();

	GameUI.Inventory.RegisterForInventoryChanges(UpdateInventory);
	GameUI.Inventory.RegisterForDefinitionsChanges(SetDefinitions);
	GameUI.Inventory.RegisterForEquipmentChanges(UpdateEquipped);

	GameUI.Player.RegisterForPlayerDataChanges(UpdatePlayer);
})();
