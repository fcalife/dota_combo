Filters = Filters or {}

-- arbitrary number to signal that filter should return after calling function
FILTER_RETURN = 1000
FILTER_CONTINUE = 1001

require("filters/damage")
require("filters/modifier")
require("filters/order")
require("filters/item")
require("filters/experience")
require("filters/gold")

function Filters:Init()
	local game_mode_entity = GameRules:GetGameModeEntity()

	game_mode_entity:SetModifierGainedFilter(Dynamic_Wrap(Filters, "ModifierFilter"), Filters)
	game_mode_entity:SetDamageFilter(Dynamic_Wrap(Filters, "DamageFilter"), Filters)
	game_mode_entity:SetModifyGoldFilter(Dynamic_Wrap(Filters, "ModifyGoldFilter"), Filters)
	game_mode_entity:SetExecuteOrderFilter(Dynamic_Wrap(Filters, "ExecuteOrderFilter"), Filters)
	game_mode_entity:SetItemAddedToInventoryFilter(Dynamic_Wrap(Filters, "ItemAddedToInventoryFilter"), Filters)
	game_mode_entity:SetModifyExperienceFilter(Dynamic_Wrap(Filters, "FilterModifyExperience"), Filters)
end
