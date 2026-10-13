const CONTEXT = $.GetContextPanel();
const SETTINGS_CONTAINER = $("#SettingsContainer");
let SETTINGS_STORE = {};
let DEBOUNCE_SCHEDULES = {};

let SETTING_TYPES = {
	CHECKBOX: 1,
	SLIDER: 2,
};

let SETTING_SNIPPETS = {
	[SETTING_TYPES.CHECKBOX]: "settings_checkbox",
	[SETTING_TYPES.SLIDER]: "settings_slider",
};

function ToggleSettings() {
	CONTEXT.ToggleClass("SettingsOpen");
}

class SettingProto {
	constructor(setting_panel, setting_name, config) {
		this.setting_name = setting_name;
		this.setting_panel = setting_panel;
		this.config = config;

		// bind tooltips to show (if defined for settings - some are obvious enough to skip that)
		setting_panel.SetPanelEvent("onmouseover", () => {
			const token = `settings_entry_tooltip_${this.setting_name}`;
			const localized = $.Localize(token);
			if (token != localized) {
				$.DispatchEvent("DOTAShowTextTooltip", this.setting_panel, localized);
			}
		});

		setting_panel.SetPanelEvent("onmouseout", () => {
			$.DispatchEvent("DOTAHideTextTooltip", this.setting_panel);
		});
	}

	UpdateState(new_value, skip_submission) {}
}

class Checkbox extends SettingProto {
	constructor(setting_panel, setting_name, config) {
		super(setting_panel, setting_name, config);
		this.toggle_button = setting_panel.GetChild(0);
		const default_state = config.default == 1; // booleans are networked as 0 / 1

		setting_panel.SetPanelEvent("onactivate", () => {
			const new_state = !this.toggle_button.selected;
			this.UpdateState(new_state);
		});

		this.UpdateState(default_state, true);
	}

	UpdateState(new_value, skip_submission) {
		this.toggle_button.selected = new_value;
		this.toggle_button.SetSelected(new_value);

		if (!skip_submission) {
			GameUI.Player.SetSettingValue(this.setting_name, new_value);
		}
	}
}

class Slider extends SettingProto {
	constructor(setting_panel, setting_name, config) {
		super(setting_panel, setting_name, config);

		this.slider = setting_panel.FindChild("SettingsSlider");
		this.slider.min = config.min || 0;
		this.slider.max = config.max || 100;
		this.slider.default = config.default || config.min;

		this.slider.SetPanelEvent("onvaluechanged", () => {
			setting_panel.SetDialogVariableInt("value", this.slider.value);
			SubmitDeboucedChange(this.setting_name, this.slider.value);
		});

		this.UpdateState(config.default || config.min, true);
	}

	UpdateState(new_value, skip_submission) {
		this.slider.value = new_value;

		if (!skip_submission) {
			SubmitDeboucedChange(this.setting_name, new_value);
		}
	}
}

const SETTING_CLASSES = {
	[SETTING_TYPES.CHECKBOX]: Checkbox,
	[SETTING_TYPES.SLIDER]: Slider,
};

function UpdateSettings(player_data) {
	let settings = {};
	if (player_data) settings = player_data.settings;
	else settings = GameUI.Player.GetSettings();

	for (const [setting_name, value] of Object.entries(settings || {})) {
		const setting_obj = SETTINGS_STORE[setting_name];

		if (setting_obj) {
			setting_obj.UpdateState(value, true);
		}
	}
}

function SubmitDeboucedChange(setting_name, new_value) {
	// debounce setting change submission, otherwise it would spam lua
	// useful for setting types such as Slider and it's sub-types (i.e. SlottedSlider)
	if (DEBOUNCE_SCHEDULES[setting_name]) {
		$.CancelScheduled(DEBOUNCE_SCHEDULES[setting_name]);
	}
	DEBOUNCE_SCHEDULES[setting_name] = $.Schedule(1, () => {
		GameUI.Player.SetSettingValue(setting_name, new_value);
		DEBOUNCE_SCHEDULES[setting_name] = undefined;
	});
}

function UpdateManifest(event) {
	if (!event || !event.manifest) return;

	SETTINGS_CONTAINER.RemoveAndDeleteChildren();
	SETTINGS_STORE = {};

	for (const [category, settings] of Object.entries(event.manifest)) {
		const category_panel_id = `settings_category_${category}`;
		let category_panel = SETTINGS_CONTAINER.FindChild(category_panel_id);
		if (!category_panel) {
			category_panel = $.CreatePanel("Panel", SETTINGS_CONTAINER, category_panel_id);
			category_panel.BLoadLayoutSnippet("settings_category");
		}
		category_panel.SetDialogVariableLocString("category_name", `#settings_category_${category}`);

		for (const [setting_name, config] of Object.entries(settings || {})) {
			if (!SETTING_SNIPPETS[config.type]) {
				continue;
			}
			let setting_panel = $.CreatePanel("Panel", category_panel, `setting_entry_${setting_name}`);
			setting_panel.BLoadLayoutSnippet(SETTING_SNIPPETS[config.type]);

			setting_panel.SetDialogVariableLocString("setting_name", `#settings_entry_${setting_name}`);

			const class_type = SETTING_CLASSES[config.type];
			if (!class_type) {
				return;
			}

			SETTINGS_STORE[setting_name] = new class_type(setting_panel, setting_name, config);
		}
	}

	UpdateSettings();
}

(() => {
	GameUI.Player.RegisterForPlayerDataChanges(UpdateSettings);

	const frame = GameEvents.NewProtectedFrame($.GetContextPanel());
	frame.SubscribeProtected("WebSettings:update_manifest", UpdateManifest);

	GameEvents.SendToServerEnsured("WebSettings:fetch_manifest", {});

	GameUI.ToggleSettings = ToggleSettings;
})();
