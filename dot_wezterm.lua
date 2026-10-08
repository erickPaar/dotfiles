local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

-- ==========================================================
-- Appearance
-- ==========================================================
config.color_scheme = "Tokyo Night"
config.window_background_opacity = 0.95
config.window_decorations = "TITLE | RESIZE"
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.initial_cols = 140
config.initial_rows = 35

-- Inactive pane dimming
config.inactive_pane_hsb = {
  saturation = 0.85,
  brightness = 0.65,
}

-- Background gradient (subtle, behind opacity)
config.background = {
  {
    source = { Gradient = {
      colors = { "#1a1b2e", "#16161e" },
      orientation = { Linear = { angle = -45.0 } },
    }},
    width = "100%",
    height = "100%",
    opacity = 0.95,
  },
}

-- ==========================================================
-- Font
-- ==========================================================
config.font = wezterm.font("FiraCode Nerd Font")
config.font_size = 11
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1" } -- ligatures on

-- ==========================================================
-- Cursor
-- ==========================================================
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500

-- ==========================================================
-- Scrollback
-- ==========================================================
config.scrollback_lines = 10000

-- ==========================================================
-- Tab bar
-- ==========================================================
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_max_width = 32

config.colors = {
  tab_bar = {
    background = "#16161e",
    active_tab = {
      bg_color = "#7aa2f7",
      fg_color = "#16161e",
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = "#1a1b26",
      fg_color = "#565f89",
    },
    inactive_tab_hover = {
      bg_color = "#24283b",
      fg_color = "#c0caf5",
    },
    new_tab = {
      bg_color = "#1a1b26",
      fg_color = "#565f89",
    },
    new_tab_hover = {
      bg_color = "#24283b",
      fg_color = "#c0caf5",
    },
  },
}

-- ==========================================================
-- Tab title: show process name (CWD lives in right-side status)
-- ==========================================================
local function tab_process(pane)
  return pane.foreground_process_name:match("([^/\\]+)$") or ""
end

-- Process icons for tab title
local process_icons = {
  bash = wezterm.nerdfonts.cod_terminal_bash,
  zsh = wezterm.nerdfonts.cod_terminal_bash,
  fish = wezterm.nerdfonts.cod_terminal_bash,
  git = wezterm.nerdfonts.dev_git,
  python = wezterm.nerdfonts.dev_python,
  python3 = wezterm.nerdfonts.dev_python,
  node = wezterm.nerdfonts.dev_nodejs_small,
  vim = wezterm.nerdfonts.custom_vim,
  nvim = wezterm.nerdfonts.custom_vim,
  cargo = wezterm.nerdfonts.dev_rust,
  go = wezterm.nerdfonts.seti_go,
  java = wezterm.nerdfonts.dev_java,
  kubectl = wezterm.nerdfonts.linux_docker,
  docker = wezterm.nerdfonts.linux_docker,
  ssh = wezterm.nerdfonts.md_server,
}

-- Read Claude state emoji from temp file
local function claude_state(pane_id)
  local f = io.open("/tmp/wezterm-claude-state-" .. tostring(pane_id), "r")
  if f then
    local state = f:read("*l")
    f:close()
    if state and #state > 0 then
      return state .. " "
    end
  end
  return ""
end

wezterm.on("format-tab-title", function(tab)
  local pane = tab.active_pane
  local state = claude_state(pane.pane_id)

  -- Respect manually-set tab title (via OSC 1 / tabtitle command)
  local user_title = tab.tab_title
  if user_title and #user_title > 0 then
    return { { Text = " " .. state .. user_title .. " " } }
  end

  -- Detect git worktree from CWD
  local cwd_uri = pane.current_working_dir
  if cwd_uri then
    local path = cwd_uri.file_path or ""
    local worktree = path:match("/%.claude/worktrees/([^/]+)")
    if worktree then
      return { { Text = state .. wezterm.nerdfonts.cod_git_branch .. "  " .. worktree .. " " } }
    end
  end

  local process = tab_process(pane)
  local icon = process_icons[process] or wezterm.nerdfonts.cod_terminal
  return { { Text = state .. icon .. " " .. process .. " " } }
end)

-- ==========================================================
-- Right-side status bar: workspace + CWD
-- ==========================================================
wezterm.on("update-right-status", function(window, pane)
  local workspace = window:active_workspace()
  local cwd_uri = pane:get_current_working_dir()
  local cwd = ""
  if cwd_uri then
    cwd = cwd_uri.file_path:match("([^/]+)/?$") or cwd_uri.file_path
  end

  local status = {}

  if workspace ~= "default" then
    table.insert(status, { Foreground = { Color = "#bb9af7" } })
    table.insert(status, { Text = wezterm.nerdfonts.cod_window .. " " .. workspace .. "  " })
  end

  if #cwd > 0 then
    table.insert(status, { Foreground = { Color = "#7aa2f7" } })
    table.insert(status, { Text = wezterm.nerdfonts.md_folder .. " " .. cwd .. "  " })
  end

  window:set_right_status(wezterm.format(status))
end)

-- ==========================================================
-- Bell notification
-- ==========================================================
config.audible_bell = "Disabled"
config.visual_bell = {
  fade_in_function = "EaseIn",
  fade_in_duration_ms = 80,
  fade_out_function = "EaseOut",
  fade_out_duration_ms = 80,
  target = "CursorColor",
}

-- ==========================================================
-- Hyperlink rules
-- ==========================================================
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- File paths (e.g., /home/user/file.txt:10)
table.insert(config.hyperlink_rules, {
  regex = "[/~][\\w./-]+(?::\\d+)?",
  format = "$0",
})

-- GitHub issues/PRs (e.g., #123)
table.insert(config.hyperlink_rules, {
  regex = "\\b([\\w-]+/[\\w.-]+)?#(\\d+)\\b",
  format = "https://github.com/$1/issues/$2",
})

-- ==========================================================
-- Launcher menu
-- ==========================================================
config.launch_menu = {
  { label = wezterm.nerdfonts.cod_terminal_bash .. "  Bash", args = { "bash", "-l" } },
  { label = wezterm.nerdfonts.md_server .. "  htop", args = { "htop" } },
  { label = wezterm.nerdfonts.dev_git .. "  Git Log", args = { "git", "log", "--oneline", "--graph", "--all" } },
  { label = wezterm.nerdfonts.md_docker .. "  Docker PS", args = { "docker", "ps" } },
}

-- ==========================================================
-- Workspaces
-- ==========================================================
-- Switch workspaces via launcher or keybind (see keys below)

-- ==========================================================
-- Quick select patterns
-- ==========================================================
config.quick_select_patterns = {
  -- Git hashes
  "[0-9a-f]{7,40}",
  -- IP addresses
  "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}",
  -- UUIDs
  "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
  -- File paths
  "(?:/[\\w.@-]+)+(?::\\d+)?",
}

-- ==========================================================
-- Mouse bindings
-- ==========================================================
config.mouse_bindings = {
  -- Right-click paste
  {
    event = { Down = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = act.PasteFrom("Clipboard"),
  },
  -- Ctrl+Click open hyperlink
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "CTRL",
    action = act.OpenLinkAtMouseCursor,
  },
}

-- ==========================================================
-- Keybindings
-- ==========================================================
config.keys = {
  -- Tab navigation. Ctrl+H/L freed for zellij + nvim window-direction.
  { key = "h", mods = "CTRL|ALT", action = act.ActivateTabRelative(-1) },
  { key = "l", mods = "CTRL|ALT", action = act.ActivateTabRelative(1) },

  -- Pane splits
  { key = "d", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "r", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = true }) },

  -- Pane navigation (vim-style)
  { key = "h", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Left") },
  { key = "l", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Right") },
  { key = "k", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Up") },
  { key = "j", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Down") },

  -- Pane rotate
  { key = "o", mods = "CTRL|SHIFT", action = act.RotatePanes("Clockwise") },

  -- Pane resize
  { key = "LeftArrow", mods = "CTRL|SHIFT|ALT", action = act.AdjustPaneSize({ "Left", 2 }) },
  { key = "RightArrow", mods = "CTRL|SHIFT|ALT", action = act.AdjustPaneSize({ "Right", 2 }) },
  { key = "UpArrow", mods = "CTRL|SHIFT|ALT", action = act.AdjustPaneSize({ "Up", 2 }) },
  { key = "DownArrow", mods = "CTRL|SHIFT|ALT", action = act.AdjustPaneSize({ "Down", 2 }) },

  -- Quick select (URLs, hashes, IPs, paths)
  { key = "s", mods = "CTRL|SHIFT", action = act.QuickSelect },

  -- Copy mode (vim-style selection)
  { key = "x", mods = "CTRL|SHIFT", action = act.ActivateCopyMode },

  -- Command palette
  { key = "p", mods = "CTRL|SHIFT", action = act.ActivateCommandPalette },

  -- Launcher menu
  { key = "Space", mods = "CTRL|SHIFT", action = act.ShowLauncherArgs({ flags = "FUZZY|LAUNCH_MENU_ITEMS|WORKSPACES|TABS" }) },

  -- Workspace management
  { key = "n", mods = "CTRL|SHIFT", action = act.SwitchToWorkspace },
  { key = "b", mods = "CTRL|SHIFT", action = act.SwitchWorkspaceRelative(-1) },
  { key = "f", mods = "CTRL|SHIFT", action = act.SwitchWorkspaceRelative(1) },

  -- Toggle ligatures
  {
    key = "=",
    mods = "CTRL|SHIFT",
    action = wezterm.action_callback(function(window, pane)
      local overrides = window:get_config_overrides() or {}
      if overrides.harfbuzz_features and overrides.harfbuzz_features[1] == "calt=0" then
        overrides.harfbuzz_features = { "calt=1", "clig=1", "liga=1" }
      else
        overrides.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
      end
      window:set_config_overrides(overrides)
    end),
  },

  -- Font size quick reset
  { key = "0", mods = "CTRL", action = act.ResetFontSize },
}

return config
