const MAPS = ["dota"];

const CURRENT_MAP = Game.GetMapInfo().map_display_name;

const LEADERBOARD_STATES = {
	NONE: 0,
	FETCHED: 1,
	LOADED: 2,
};

// from - to - glory - new rating - items list
const REWARDS_BY_MMR = {
	dota: [
		[0, 1000, 0, 1000, {}],
		[1000, 2000, 750, 1500, {}],
		[2000, 3000, 2000, 2000, {}],
		[3000, 4000, 3000, 2500, {}],
		[4000, 999999, 5000, 3000, {}],
	],
};

const REWARDS_BY_TOP_PLACES = [
	[1, 3, { dragon_champion: 1, kill_effect_sword_smash: 1 }],
	[4, 10, { season_6_golden_wings: 1, spectral_kill_gold: 1 }],
	[11, 25, { season_6_silver_wings: 1, spectral_kill_blue: 1 }],
	[26, 100, { dragon_aura: 1 }],
];

function GetRewardsByRating(map_name, rating) {
	const rewards = REWARDS_BY_MMR[map_name];
	if (!rewards) return;

	let result = {
		end: rewards[0][0],
		start: 1,
		rank: -1,
	};

	for (let i = 0; i < rewards.length; i++) {
		const [start, end, currency, new_rating, items] = rewards[i];
		if (rating >= start && rating < end)
			result = {
				rewards: { currency: currency, items: items },
				start: start,
				end: end,
				rank: i,
				reset_new_rating: new_rating,
			};
	}

	return result;
}
function GetRewardsByTopPlace(rank) {
	let result = {};

	for (const [start, end, items] of REWARDS_BY_TOP_PLACES) if (rank >= start) result = items;

	return result;
}

function GetClassNameByTopPlace(place) {
	for (const [start, end, items] of REWARDS_BY_TOP_PLACES) if (place >= start && place <= end) return `Top${end}`;
}
