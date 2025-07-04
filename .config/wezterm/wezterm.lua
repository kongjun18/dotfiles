local wezterm = require("wezterm")
local action = wezterm.action
local is_linux = string.find(wezterm.target_triple, "linux")
local is_darwin = string.find(wezterm.target_triple, "darwin")
local is_windows = string.find(wezterm.target_triple, "windows")
local font_size_offset = is_linux and 0 or is_darwin and 3 or 0
local config = {
	-- FIXME: term = "wezterm" causes wrong cursor shape
	-- term = "wezterm",
	use_fancy_tab_bar = false,
	tab_bar_at_bottom = true,
	adjust_window_size_when_changing_font_size = true,
	window_padding = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	},
	color_scheme = "nightfox",
	font = wezterm.font("JetBrains Mono"), -- Built in JetBrains Mono
	font_size = 14 + font_size_offset,
	use_ime = true, -- Use Chinese input method
	harfbuzz_features = { "zero" }, -- Distinguish 0 and o
	use_dead_keys = false, -- disable dead key for Vim
	hide_tab_bar_if_only_one_tab = true,
	disable_default_key_bindings = true,
	keys = {
		-- Clipboard
		{ key = "c", mods = "CTRL|SHIFT", action = action.CopyTo("Clipboard") },
		{ key = "v", mods = "CTRL|SHIFT", action = action.PasteFrom("Clipboard") },
		-- Window
		{ key = "m", mods = "CTRL|SHIFT", action = action.SpawnWindow },
		{ key = "n", mods = "CTRL|SHIFT", action = action.Hide },
		{ key = "Enter", mods = "ALT", action = action.ToggleFullScreen },
		{ key = "F11", action = action.ToggleFullScreen },
		-- Tab
		{ key = "t", mods = "CTRL|SHIFT", action = action.SpawnTab("CurrentPaneDomain") },
		{ key = "Tab", mods = "CTRL|SHIFT", action = action.ActivateTabRelative(-1) },
		{ key = "Tab", mods = "CTRL", action = action.ActivateTabRelative(1) },
		{ key = "1", mods = "ALT", action = action.ActivateTab(0) },
		{ key = "2", mods = "ALT", action = action.ActivateTab(1) },
		{ key = "3", mods = "ALT", action = action.ActivateTab(2) },
		{ key = "4", mods = "ALT", action = action.ActivateTab(3) },
		{ key = "5", mods = "ALT", action = action.ActivateTab(4) },
		{ key = "6", mods = "ALT", action = action.ActivateTab(5) },
		{ key = "7", mods = "ALT", action = action.ActivateTab(6) },
		{ key = "8", mods = "ALT", action = action.ActivateTab(7) },
		-- Pane
		{ key = "w", mods = "CTRL|SHIFT", action = action.CloseCurrentPane({ confirm = true }) },
		{
			key = "\\",
			mods = "ALT",
			action = action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
		},
		{
			key = "-",
			mods = "ALT",
			action = action.SplitVertical({ domain = "CurrentPaneDomain" }),
		},
		{ key = "z", mods = "ALT", action = action.TogglePaneZoomState },
		{ key = "h", mods = "ALT", action = action.ActivatePaneDirection("Left") },
		{ key = "l", mods = "ALT", action = action.ActivatePaneDirection("Right") },
		{ key = "k", mods = "ALT", action = action.ActivatePaneDirection("Up") },
		{ key = "j", mods = "ALT", action = action.ActivatePaneDirection("Down") },
		{ key = "w", mods = "ALT", action = action.CloseCurrentPane({ confirm = true }) },
		-- Configuration
		{ key = "r", mods = "CTRL|SHIFT", action = action.ReloadConfiguration },
		-- Mode
		{ key = "f", mods = "CTRL|SHIFT", action = action.Search({ CaseSensitiveString = "" }) },
		{ key = "Space", mods = "CTRL|SHIFT", action = action.QuickSelect },
		{ key = "y", mods = "CTRL|SHIFT", action = action.ActivateCopyMode },
		-- Scroll
		{ key = "PageUp", action = action.ScrollByPage(-1) },
		{ key = "PageDown", action = action.ScrollByPage(1) },
		-- Font
		{ key = "-", mods = "CTRL", action = action.DecreaseFontSize },
		{ key = "=", mods = "CTRL", action = action.IncreaseFontSize },
		{ key = "0", mods = "CTRL", action = action.ResetFontSize },
		-- Command Palette
		{ key = "P", mods = "CTRL", action = wezterm.action.ActivateCommandPalette },
	},
	key_tables = {
		-- Vim-like mappings
		copy_mode = {
			{ key = "Escape", mods = "NONE", action = action.CopyMode("Close") },
			{ key = "$", mods = "SHIFT", action = action.CopyMode("MoveToEndOfLineContent") },
			{ key = "0", mods = "NONE", action = action.CopyMode("MoveToStartOfLine") },
			{ key = "g", mods = "NONE", action = action.CopyMode("MoveToViewportTop") },
			{ key = "G", mods = "NONE", action = action.CopyMode("MoveToViewportBottom") },
			{ key = "V", mods = "NONE", action = action.CopyMode({ SetSelectionMode = "Line" }) },
			{ key = "^", mods = "SHIFT", action = action.CopyMode("MoveToStartOfLineContent") },
			{ key = "b", mods = "NONE", action = action.CopyMode("MoveBackwardWord") },
			{ key = "e", mods = "NONE", action = action.CopyMode("MoveForwardWordEnd") },
			{ key = "u", mods = "CTRL", action = action.CopyMode("PageUp") },
			{ key = "f", mods = "CTRL", action = action.CopyMode("PageDown") },
			{ key = "b", mods = "CTRL", action = action.CopyMode("PageUp") },
			{ key = "d", mods = "CTRL", action = action.CopyMode("PageDown") },
			{ key = "h", mods = "NONE", action = action.CopyMode("MoveLeft") },
			{ key = "j", mods = "NONE", action = action.CopyMode("MoveDown") },
			{ key = "k", mods = "NONE", action = action.CopyMode("MoveUp") },
			{ key = "l", mods = "NONE", action = action.CopyMode("MoveRight") },
			{ key = "q", mods = "NONE", action = action.CopyMode("Close") },
			{ key = "v", mods = "NONE", action = action.CopyMode({ SetSelectionMode = "Cell" }) },
			{ key = "v", mods = "CTRL", action = action.CopyMode({ SetSelectionMode = "Block" }) },
			{ key = "w", mods = "NONE", action = action.CopyMode("MoveForwardWord") },
			{
				key = "y",
				mods = "NONE",
				action = action.Multiple({ { CopyTo = "ClipboardAndPrimarySelection" }, { CopyMode = "Close" } }),
			},
			{ key = "PageUp", mods = "NONE", action = action.CopyMode("PageUp") },
			{ key = "PageDown", mods = "NONE", action = action.CopyMode("PageDown") },
		},
	},
	mouse_bindings = {
		-- Bind 'Up' event of SHIFT-Click to open hyperlinks
		{
			event = { Up = { streak = 1, button = "Left" } },
			mods = "SHIFT",
			action = action.OpenLinkAtMouseCursor,
		},
		-- Disable the 'Down' event of SHIFT-Click to avoid weird program behaviors
		{
			event = { Down = { streak = 1, button = "Left" } },
			mods = "SHIFT",
			action = action.Nop,
		},
	},
}

-- Use the defaults as a base
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- make username/project paths clickable. this implies paths like the following are for github.
-- ( "nvim-treesitter/nvim-treesitter" | wbthomason/packer.nvim | wez/wezterm | "wez/wezterm.git" )
table.insert(config.hyperlink_rules, {
	regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
	format = "https://www.github.com/$1/$3",
})

if is_darwin then
	table.insert(config.keys, { key = "c", mods = "CMD", action = action.CopyTo("Clipboard") })
	table.insert(config.keys, { key = "v", mods = "CMD", action = action.PasteFrom("Clipboard") })
end

if is_windows then
	local home = os.getenv("USERPROFILE")
	config.default_prog = { 'cmd.exe', '/c', string.format('%s/scoop/apps/msys2/current/msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell zsh', home)}
  -- Issue #1813: Error Failed to create window: The OpenGL implementation is
  -- too old to work on Windows 11 in VirtualBox.
	config.prefer_egl = true
end

return config

