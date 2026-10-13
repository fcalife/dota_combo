local PROMO_EVENTS = {}

PROMO_EVENTS["chc_test_event"] = {
	custom_game = "custom_hero_clash",
	active = true,
	started_at = "05/01/21", -- date for backend to fetch data from - stuff before won't be accounted
	ends_at = "05/31/24", -- month / day / year - most fucked up format that is default in dota

	tasks = {
		reach_round = {
			target = 60,
			rewards = {
				currency = 100,
			}
		},
		play_games = {
			target = 10,
			rewards = {
				currency = 250,
			}
		},
		win_games = {
			target = 5,
			rewards = {
				currency = 450,
			}
		},
	},
}

PROMO_EVENTS["ot3_test_event"] = {
	custom_game = "overthrow_3",
	active = true,
	started_at = "05/01/21", -- date for backend to fetch data from - stuff before won't be accounted
	ends_at = "05/31/24", -- month / day / year - most fucked up format that is default in dota

	tasks = {
		play_games = {
			target = 30,
			rewards = {
				currency = 100,
				items = {bp_reroll = 10,},
			}
		},
		win_games = {
			target = 10,
			rewards = {
				currency = 250,
				items = {bp_reroll = 10, bp_gg_token = 5},
			}
		},
		mvp = {
			target = 5,
			rewards = {
				currency = 350,
				items = {bp_reroll = 20, bp_legendary_lagresse = 3},
			}
		},
		ot3_upgrades = {
			target = 200,
			rewards = {
				currency = 350,
				items = {bp_reroll = 20, bp_gg_token = 5},
			}
		},
		kill_heroes = {
			target = 500,
			rewards = {
				currency = 500,
				items = {bp_reroll = 50, bp_gg_token = 5},
			}
		},
		ot3_hero_challenge = {
			target = 10,
			rewards = {
				currency = 1000,
				items = {bp_reroll = 50, bp_breathtaking_benefaction = 5}
			}
		}
	},
}

PROMO_EVENTS["12v12_test_event"] = {
	custom_game = "12v12",
	active = true,
	started_at = "05/01/21", -- date for backend to fetch data from - stuff before won't be accounted
	ends_at = "05/31/24", -- month / day / year - most fucked up format that is default in dota

	tasks = {
		play_games = {
			target = 30,
			rewards = {
				currency = 100,
				items = {bp_reroll = 10,},
			}
		},
		win_games = {
			target = 10,
			rewards = {
				currency = 250,
				items = {bp_reroll = 10, bp_gg_token = 5},
			}
		},
		mvp = {
			target = 5,
			rewards = {
				currency = 350,
				items = {bp_reroll = 20, bp_legendary_lagresse = 3},
			}
		},
		kill_heroes = {
			target = 500,
			rewards = {
				currency = 500,
				items = {bp_reroll = 50, bp_gg_token = 5},
			}
		},
	}
}

return PROMO_EVENTS
