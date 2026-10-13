Game.Events = {};
var contextPanel = $.GetContextPanel();

function GetCommandName(name) {
	return "custom_hotkey_" + name;
}

function RegisterKeyBindHandler(name) {
	Game.Events[name] = {};
	Game.AddCommand(
		GetCommandName(name),
		function () {
			for (var key in Game.Events[name]) {
				Game.Events[name][key]();
			}
		},
		"",
		0,
	);
}

function RegisterKeyBind(name, callback) {
	var key = Game.GetKeybindForCommand(name);
	if (key !== "") {
		Game.AddCommand(GetCommandName(name), callback, "", 0);
		Game.CreateCustomKeyBind(key, GetCommandName(name));
	}
}

GameUI.CustomUIConfig().RegisterKeyBind = RegisterKeyBind;
