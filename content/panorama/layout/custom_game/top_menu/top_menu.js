const HUD = {
	CONTEXT: $.GetContextPanel(),
	LINES: $("#CTM_Lines"),
};

(() => {
	const menu = FindDotaHudElement("MenuButtons");

	for (const b of menu.Children()) b.visible = false;

	const ex_lines = menu.FindChildTraverse(HUD.LINES.id);
	if (ex_lines) ex_lines.DeleteAsync(0);

	HUD.LINES.SetParent(menu);
	menu.style.margin = "0px;";
})();
