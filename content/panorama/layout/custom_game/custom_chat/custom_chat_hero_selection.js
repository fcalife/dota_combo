(() => {
	let default_players_colors = {};
	for (let player_id = 0; player_id <= 24; player_id++)
		default_players_colors[player_id] = GetHEXPlayerColor(player_id);

	GameEvents.SendToServerEnsured("custom_chat:update_guild_tag_colors", { colors: default_players_colors });
})();
