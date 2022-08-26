local wezterm = require("wezterm")
local action = wezterm.action

return {
	use_fancy_tab_bar = false,
	tab_bar_at_bottom = true,
	adjust_window_size_when_changing_font_size = true,
	window_padding = {
		left = 5,
		right = 5,
		top = 5,
		bottom = 5,
	},
	ssh_domains = {
		{
			name = "megvii",
			remote_address = "megvii",
			username = "kongjun",
		},
	},
	color_scheme = "dayfox", -- Dayfox color scheme
	font = wezterm.font("JetBrains Mono"), -- Built in JetBrains Mono
	font_size = 13,
	use_ime = true, -- Use Chinese input method
	harfbuzz_features = { "zero" }, -- Distinguish 0 and o
	use_dead_keys = false, -- disable dead key for Vim
	hide_tab_bar_if_only_one_tab = true,
	hyperlink_rules = {
		-- Linkify things that look like URLs and the host has a TLD name.
		-- Compiled-in default. Used if you don't specify any hyperlink_rules.
		{
			regex = "\\b\\w+://[\\w.-]+\\.[a-z]{2,15}\\S*\\b",
			format = "$0",
		},

		-- linkify email addresses
		-- Compiled-in default. Used if you don't specify any hyperlink_rules.
		{
			regex = [[\b\w+@[\w-]+(\.[\w-]+)+\b]],
			format = "mailto:$0",
		},

		-- file:// URI
		-- Compiled-in default. Used if you don't specify any hyperlink_rules.
		{
			regex = [[\bfile://\S*\b]],
			format = "$0",
		},

		-- Linkify things that look like URLs with numeric addresses as hosts.
		-- E.g. http://127.0.0.1:8000 for a local development server,
		-- or http://192.168.1.1 for the web interface of many routers.
		{
			regex = [[\b\w+://(?:[\d]{1,3}\.){3}[\d]{1,3}\S*\b]],
			format = "$0",
		},

		-- Make task numbers clickable
		-- The first matched regex group is captured in $1.
		{
			regex = [[\b[tT](\d+)\b]],
			format = "https://example.com/tasks/?t=$1",
		},

		-- Make username/project paths clickable. This implies paths like the following are for GitHub.
		-- ( "nvim-treesitter/nvim-treesitter" | wbthomason/packer.nvim | wez/wezterm | "wez/wezterm.git" )
		-- As long as a full URL hyperlink regex exists above this it should not match a full URL to
		-- GitHub or GitLab / BitBucket (i.e. https://gitlab.com/user/project.git is still a whole clickable URL)
		{
			regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
			format = "https://www.github.com/$1/$3",
		},
	},
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
	},
}
