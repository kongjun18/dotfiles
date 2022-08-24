local wezterm = require("wezterm")

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
		{ key = "c", mods = "CTRL|SHIFT", action = wezterm.action({ CopyTo = "Clipboard" }) },
		{ key = "v", mods = "CTRL|SHIFT", action = wezterm.action({ PasteFrom = "Clipboard" }) },
		{ key = "m", mods = "CTRL|SHIFT", action = wezterm.action.SpawnWindow },
		{ key = "n", mods = "CTRL|SHIFT", action = wezterm.action.Hide },
		{ key = "t", mods = "CTRL|SHIFT", action = wezterm.action({ SpawnTab = "CurrentPaneDomain" }) },
		{ key = "w", mods = "CTRL|SHIFT", action = wezterm.action({ CloseCurrentTab = { confirm = true } }) },
		{ key = "r", mods = "CTRL|SHIFT", action = wezterm.action.ReloadConfiguration },
		{ key = "f", mods = "CTRL|SHIFT", action = wezterm.action({ Search = { CaseSensitiveString = "" } }) },
		{ key = "LeftArrow", mods = "CTRL|SHIFT", action = wezterm.action({ ActivatePaneDirection = "Left" }) },
		{ key = "RightArrow", mods = "CTRL|SHIFT", action = wezterm.action({ ActivatePaneDirection = "Right" }) },
		{ key = "UpArrow", mods = "CTRL|SHIFT", action = wezterm.action({ ActivatePaneDirection = "Up" }) },
		{ key = "DownArrow", mods = "CTRL|SHIFT", action = wezterm.action({ ActivatePaneDirection = "Down" }) },
		{ key = "z", mods = "CTRL|SHIFT", action = wezterm.action.TogglePaneZoomState },
		{ key = "Tab", mods = "CTRL|SHIFT", action = wezterm.action({ ActivateTabRelative = -1 }) },
		{ key = "Tab", mods = "CTRL", action = wezterm.action({ ActivateTabRelative = 1 }) },
		{ key = "PageUp", action = wezterm.action({ ScrollByPage = -1 }) },
		{ key = "PageDown", action = wezterm.action({ ScrollByPage = 1 }) },
		{ key = "-", mods = "CTRL", action = wezterm.action.DecreaseFontSize },
		{ key = "=", mods = "CTRL", action = wezterm.action.IncreaseFontSize },
		{ key = "0", mods = "CTRL", action = wezterm.action.ResetFontSize },
		{ key = "F11", action = wezterm.action.ToggleFullScreen },
		{ key = "1", mods = "ALT", action = wezterm.action({ ActivateTab = 0 }) },
		{ key = "2", mods = "ALT", action = wezterm.action({ ActivateTab = 1 }) },
		{ key = "3", mods = "ALT", action = wezterm.action({ ActivateTab = 2 }) },
		{ key = "4", mods = "ALT", action = wezterm.action({ ActivateTab = 3 }) },
		{ key = "5", mods = "ALT", action = wezterm.action({ ActivateTab = 4 }) },
		{ key = "6", mods = "ALT", action = wezterm.action({ ActivateTab = 5 }) },
		{ key = "7", mods = "ALT", action = wezterm.action({ ActivateTab = 6 }) },
		{ key = "8", mods = "ALT", action = wezterm.action({ ActivateTab = 7 }) },
	},
}
