Events = Events or {}

require("events/npc_spawned")


function Events:Init()
	ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(Events, "OnGameRulesStateChange"), Events)
	ListenToGameEvent("entity_killed", Dynamic_Wrap(Events, "OnEntityKilled"), Events)
	ListenToGameEvent("npc_spawned", Dynamic_Wrap(Events, "OnNPCSpawned"), Events)
	ListenToGameEvent("dota_player_pick_hero", Dynamic_Wrap(Events, "OnHeroPicked"), Events)
end


function Events:OnGameRulesStateChange(event)
	local new_state = GameRules:State_Get()

	EventDriver:Dispatch("Events:gamerules_state_changed", {
		state = new_state
	})
end


function Events:OnEntityKilled(event)
	local killed = event.entindex_killed and EntIndexToHScript(event.entindex_killed) or nil
	local killer = event.entindex_attacker and EntIndexToHScript(event.entindex_attacker) or nil
	local inflictor = event.entindex_inflictor and EntIndexToHScript(event.entindex_inflictor) or nil

	EventDriver:Dispatch("Events:entity_killed", {
		killed = killed,
		killer = killer,
		inflictor = inflictor
	})
end


function Events:OnHeroPicked(event)
	local hero = event.heroindex and EntIndexToHScript(event.heroindex) or nil

	if not hero then return end

	EventDriver:Dispatch("Events:hero_picked", {
		player_id = hero:GetPlayerOwnerID(),
		hero = hero,
	})
end
