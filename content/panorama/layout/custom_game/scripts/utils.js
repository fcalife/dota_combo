const LOCAL_PLAYER_ID = Game.GetLocalPlayerID();
const LOCAL_STEAM_ID = Game.GetLocalPlayerInfo() ? Game.GetLocalPlayerInfo().player_steamid : "0";
const MAP_NAME = Game.GetMapInfo().map_display_name;

Object.defineProperties(Array.prototype, {
	random: {
		value: function () {
			return this[Math.floor(Math.random() * this.length)];
		},
	},
	includes: {
		value: function (searchElement, fromIndex) {
			return this.indexOf(searchElement, fromIndex) !== -1;
		},
	},
});

Object.defineProperties(String.prototype, {
	format: {
		value: function () {
			var args = arguments;
			return this.replace(/{(\d+)}/g, function (match, number) {
				return typeof args[number] != "undefined" ? args[number] : match;
			});
		},
	},
	includes: {
		value: function (searchString, position) {
			return this.indexOf(searchString, position) !== -1;
		},
	},
});

function SetInterval(callback, interval) {
	interval = interval / 1000;
	$.Schedule(interval, function reschedule() {
		$.Schedule(interval, reschedule);
		callback();
	});
}

function SubscribeToNetTableKey(tableName, key, callback) {
	var immediateValue = CustomNetTables.GetTableValue(tableName, key) || {};
	if (immediateValue != null) callback(immediateValue);
	CustomNetTables.SubscribeNetTableListener(tableName, function (_tableName, currentKey, value) {
		if (currentKey === key && value != null) callback(value);
	});
}

const FindDotaHudElement = (id) => dotaHud.FindChildTraverse(id);
const dotaHud = (() => {
	let panel = $.GetContextPanel();
	while (panel) {
		if (panel.id === "DotaHud") return panel;
		panel = panel.GetParent();
	}
})();

var useChineseDateFormat = $.Language() === "schinese" || $.Language() === "tchinese";
/** @param {Date} date */
function formatDate(date) {
	return useChineseDateFormat
		? date.getFullYear() + "-" + date.getMonth() + "-" + date.getDate()
		: date.getMonth() + "/" + date.getDate() + "/" + date.getFullYear();
}

let boostGlow = false;
let glowSchelude;
const CENTER_SCREEN_MENUS = ["CollectionDotaU"];

function _GetVarFromUniquePortraitsData(player_id, hero_name, path) {
	const unique_portraits = CustomNetTables.GetTableValue("game_state", "portraits");
	if (unique_portraits && unique_portraits[player_id]) {
		return `${path}${unique_portraits[player_id]}.png`;
	} else {
		return `${path}${hero_name}.png`;
	}
}

function GetPortraitImage(player_id, hero_name) {
	return _GetVarFromUniquePortraitsData(player_id, hero_name, "file://{images}/heroes/");
}
function GetPortraitIcon(player_id, hero_name) {
	return _GetVarFromUniquePortraitsData(player_id, hero_name, "file://{images}/heroes/icons/");
}

let colors_exceptions = {
	[-1]: "#ffffffff",
};
function GetHEXPlayerColor(player_id) {
	let player_color = Players.GetPlayerColor(player_id).toString(16);
	if (colors_exceptions[player_id]) player_color = colors_exceptions[player_id];

	return player_color == null
		? "#000000"
		: "#" +
				player_color.substring(6, 8) +
				player_color.substring(4, 6) +
				player_color.substring(2, 4) +
				player_color.substring(0, 2);
}

function LocalizeWithValues(line, kv) {
	let result = $.Localize(line);
	Object.entries(kv).forEach(([k, v]) => {
		result = result.replace(`%%${k}%%`, v);
	});
	return result;
}

function Stacktrace(name) {
	$.Msg(new Error(name).stack);
}
function FormatBigNumber(x) {
	return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function GetModifierStackCount(unit_index, m_name) {
	for (var i = 0; i < Entities.GetNumBuffs(unit_index); i++) {
		var buff_name = Buffs.GetName(unit_index, Entities.GetBuff(unit_index, i));
		if (buff_name == m_name) {
			return Buffs.GetStackCount(unit_index, Entities.GetBuff(unit_index, i));
		}
	}
}

JSON.print = (object) => {
	let result_string;
	try {
		result_string = JSON.stringify(
			object,
			(key, value) => {
				return value;
			},
			"	",
		);
	} catch (e) {
		$.Msg(e);
	}
	let result_array = result_string.split("\n");
	while (result_array.length) {
		$.Msg(result_array.splice(0, 50).join("\n"));
	}
};
Math.clamp = function (num, min, max) {
	return this.min(this.max(num, min), max);
};

Math.float_interpolate = function (min, max, float) {
	return Math.round(min + (max - min) * float);
};

const _default_context_for_localization = $.GetContextPanel();
if (!$.LocalizeEngine) {
	$.LocalizeEngine = $.Localize;
	$.Localize = function (text, panel) {
		if (typeof text == "number") text = Math.round(text).toString();

		const token = text.startsWith("#") ? text : `#${text}`;
		const localized_text = $.LocalizeEngine(token, panel || _default_context_for_localization);
		return localized_text == token ? token.substring(1) : localized_text;
	};
}
function FormatSeconds(v, b_hours) {
	let hours = 0;
	if (b_hours) {
		hours = Math.floor(v / 3600);
		v = v - 3600 * hours;
	}
	const minutes = Math.floor(v / 60);
	v = v - 60 * minutes;
	return `${b_hours ? hours.toString() + ":" : ""}${minutes.toString().padStart(2, "0")}:${Math.floor(v)
		.toString()
		.padStart(2, "0")}`;
}

function IsSpectating() {
	return (
		(Game.GetLocalPlayerInfo() &&
			Game.GetLocalPlayerInfo().player_team_id &&
			Game.GetLocalPlayerInfo().player_team_id == 1) ||
		!Game.GetLocalPlayerInfo()
	);
}

function Distance2D(A, B) {
	const x_diff = A[0] - B[0];
	const y_diff = A[1] - B[1];
	return Math.sqrt(x_diff * x_diff + y_diff * y_diff);
}

Game.GetTeamScore = function (team) {
	const nt = CustomNetTables.GetTableValue("game_state", "team_score");

	if (!nt || !nt[team]) return 0;

	return nt[team];
};

function _Notify(listeners_array, data) {
	// filter invalid callbacks out
	listeners_array = listeners_array.filter((item) => {
		return typeof item == "function";
	});
	for (const callback of listeners_array) {
		try {
			callback(data);
		} catch (e) {
			$.Msg("Error in _Notify: ", e);
		}
	}
}
Object.fromEntries = (entries) => {
	let result_object = {};
	for (let [key, value] of entries) {
		result_object[key] = value;
	}
	return result_object;
};

function BuildTooltipParams(object) {
	let array = [];
	Object.entries(object).forEach(([k, v]) => {
		if (k && v) {
			v = typeof v == "object" ? JSON.stringify(v) : v.toString();
			array.push(`${k.toString()}=${v}`);
		}
	});
	return array.join("&");
}

function RandomInt(min, max) {
	let rand = min + Math.random() * (max + 1 - min);
	return Math.floor(rand);
}

function HasModifierByName(unit_ent_idx, name) {
	for (var i = 0; i < Entities.GetNumBuffs(unit_ent_idx); i++) {
		var buffName = Buffs.GetName(unit_ent_idx, Entities.GetBuff(unit_ent_idx, i));

		if (buffName == name) return true;
	}

	return false;
}

Entities.HasShard = function (unit) {
	return HasModifierByName(unit, "modifier_item_aghanims_shard");
};

function GetChildByPath(parent, ...child_path) {
	for (const id of child_path) {
		parent = parent.GetChild(id);
		if (!parent) return;
	}
	return parent;
}

Object.defineProperties(Object.prototype, {
	IsDOTAAbilityImage: {
		value: function () {
			return this.type === "DOTAAbilityImage";
		},
	},
	SetAbilityImage: {
		value: function (ability_entity_idx) {
			if (!this.IsDOTAAbilityImage()) return;

			const ability_name = Abilities.GetAbilityName(ability_entity_idx);
			if (ability_name) this.abilityname = ability_name;
			this.contextEntityIndex = ability_entity_idx;

			// const texture = Abilities.GetAbilityTextureName(ability_entity_idx || -1);
			// if (texture) {
			// 	this.SetImage("");
			// 	this.style.backgroundSize = "100%";
			// 	this.SetImage(`raw://resource/flash3/images/spellicons/${texture}.png`);
			//
			// 	let default_path = `url("s2r://panorama/images/spellicons/${texture}_png.vtex")`;
			//
			// 	this.style.backgroundImage = default_path;
			// }
		},
	},
	SetAbilityImageToPlayer: {
		value: function (player_id, ability_name) {
			if (!this.IsDOTAAbilityImage()) return;

			this.abilityname = ability_name;

			const player_info = Game.GetPlayerInfo(player_id);
			if (!player_info) return;

			const hero_ent_idx = player_info.player_selected_hero_entity_index;
			if (!hero_ent_idx) return;

			this.SetAbilityImage(Entities.GetAbilityByName(hero_ent_idx, ability_name));
		},
	},
	SetAbilityImageToLocalHero: {
		value: function (ability_name) {
			if (!this.IsDOTAAbilityImage()) return;

			this.SetAbilityImageToPlayer(LOCAL_PLAYER_ID, ability_name);
		},
	},
});

function EscapeHTML(string) {
	return string.replace(
		/[&<>'"]/g,
		(tag) =>
			({
				"&": "&amp;",
				"<": "&lt;",
				">": "&gt;",
				"'": "&#39;",
				'"': "&quot;",
			}[tag] || tag),
	);
}

const _context = $.GetContextPanel();
_context.custom_tickers_counter = 0;
_context.custom_tickers = _context.custom_tickers || {};
class CustomTicker {
	constructor(name, refresh_rate) {
		this.name = name;
		if (_context.custom_tickers[name]) _context.custom_tickers[name].RemoveSelf();
		_context.custom_tickers[name] = this;

		this.refresh_rate = refresh_rate;
		this.callbacks = {};
		this.pause = false;
		this.pause_delay_schedule = undefined;
		this.Update();
	}
	Update() {
		if (this.interrupt) return;

		if (!this.pause)
			Object.values(this.callbacks).forEach((_function) => {
				_function();
			});
		$.Schedule(this.refresh_rate, () => {
			this.Update();
		});
	}
	Add(callback, name = `Default${_context.custom_tickers_counter++}`) {
		this.callbacks[name] = callback;
	}
	Remove(name) {
		if (this.callbacks[name]) delete this.callbacks[name];
	}
	SetPause(state) {
		this.pause = state;
	}
	PauseIn(delay_for_pause) {
		if (this.pause_delay_schedule !== undefined) $.CancelScheduled(this.pause_delay_schedule);

		this.pause_delay_schedule = $.Schedule(delay_for_pause, () => {
			this.SetPause(true);
			this.pause_delay_schedule = undefined;
		});
	}
	SetRefreshRate(refresh_rate) {
		this.refresh_rate = refresh_rate;
	}
	RemoveSelf() {
		this.callbacks = {};
		this.interrupt = true;
		delete _context.custom_tickers[this.name];
	}
}

function DefaultChildrenSort(root, param_name, reverse) {
	for (const child of root.Children().sort((a, b) => {
		if (reverse) return (b[param_name] || 0) - (a[param_name] || 0);
		return (a[param_name] || 0) - (b[param_name] || 0);
	})) {
		root.MoveChildBefore(child, root.GetChild(0));
	}
}

Math.rd = (num, chars_after_dot = 0) => {
	const rd_n = Math.pow(10, chars_after_dot);
	return Math.round(num * rd_n) / rd_n;
};

function CSSLineToObjectCamelCase(style_string) {
	return style_string.split(";").reduce((obj, declaration) => {
		const [prop, val] = declaration.split(":").map((part) => part.trim());
		if (prop && val) obj[prop.replace(/-([a-z])/g, (_, l) => l.toUpperCase())] = val + ";";
		return obj;
	}, {});
}

function GenerateSublines(container, max_childs_per_line, margin_b_lines = 0, margin_b_childs = 0) {
	container.RemoveAndDeleteChildren();
	let line;
	let counter = 0;
	let line_counter = 0;
	container.style.flowChildren = "down";

	const check_line = () => {
		if (!line || counter >= max_childs_per_line) {
			line = $.CreatePanel("Panel", container, "");
			line.style.flowChildren = "right";
			line.style.horizontalAlign = "center";
			if (margin_b_lines > 0 && line_counter > 0) line.style.marginTop = `${margin_b_lines}px`;
			counter = 0;
			line_counter++;
		}
	};
	return {
		add: function (child) {
			check_line();
			counter++;
			child.SetParent(line);
			for (const [k, v] of Object.entries(CSSLineToObjectCamelCase(this.style()))) child.style[k] = v;
		},
		style: function () {
			const style = [margin_b_childs > 0 && counter > 1 ? `margin-left: ${margin_b_childs}px` : undefined].filter(
				(s) => s != undefined,
			);
			return style.length > 0 ? `${style.join(";")};` : "";
		},
		create: function (type, id = "", props = {}) {
			const line = this.line();
			props.style = (props.style || "") + this.style();
			return $.CreatePanel(type, line, id, props);
		},
		line: () => {
			check_line();
			counter++;
			return line;
		},
	};
}

// =========================================
// =========================================
// ========== ############# UTILS ==========
// =========================================
// =========================================
