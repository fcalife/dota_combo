_G.GameMode = GameMode or {}

require("declarations")

require("extensions/init")
require("libraries/init")
require("events/init")
require("filters/init")
require("game/game_loop")

require("precache")


function Activate()
	GameMode:Init()
end


function Precache(context)
	print("[GameMode] Precache started")
	PrecacheManager:Run(context)
	print("[GameMode] Precache finished")
end


function GameMode:Init()
	Filters:Init()
	CustomChat:Init()
	Events:Init()
	GameLoop:Init()

	-- generic gamemode setup
	local game_mode_entity = GameRules:GetGameModeEntity()
	game_mode_entity:SetFreeCourierModeEnabled(true)

	GameRules:SetUseUniversalShopMode(true)
	GameRules:SetTimeOfDay(0.251)
	game_mode_entity:SetDaynightCycleDisabled( true )

	if IsInToolsMode() then
		game_mode_entity:SetFixedRespawnTime(1)
		game_mode_entity:SetDraftingBanningTimeOverride(0)
		GameRules:SetCustomGameSetupAutoLaunchDelay(3)
	end

	EventDriver:Dispatch("GameMode:init_finished", {})
end


function GameMode:IsDeveloper(player_id)
	local steam_id = tostring(PlayerResource:GetSteamID(player_id))

	return DEVELOPERS[steam_id] == true
end
