local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()
local home = wezterm.home_dir

-- =========================================================
-- UTSEENDE: ALLT ÄR SVART (HIGH CONTRAST)
-- =========================================================

-- Vi tar bort färdigt tema för att kunna köra dina skarpa färger
-- config.color_scheme = 'Dracula'

config.font_size = 12.0
config.window_decorations = "RESIZE"

-- Din padding (lyfter texten från botten)
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 27,
}

-- =========================================================
-- FÄRGER (Matchar din nya VS Code-setup)
-- =========================================================
config.colors = {
  -- 1. Huvudfönstret (Svart)
  background = '#000000',
  foreground = '#ffffff', -- Kritvit text

  -- Markör (Giftgrön för att synas bra)
  cursor_bg = '#00ff00',
  cursor_fg = '#000000',
  cursor_border = '#00ff00',

  selection_fg = '#ffffff',
  selection_bg = '#44475a', -- Mörkgrå markering

  -- 2. ANSI COLORS (Här är dina skarpa färger)
  ansi = {
    '#444444', -- Black
    '#ff0000', -- Red (REN RÖD)
    '#50fa7b', -- Green (DRACULA GRÖN - mjuk och matt)
    '#ffff00', -- Yellow (REN GUL)
    '#bd93f9', -- Blue (DRACULA LILA - För mappar!)
    '#ff00ff', -- Magenta (REN ROSA)
    '#00ffff', -- Cyan (REN CYAN)
    '#ffffff', -- White
  },

  brights = {
    '#777777', -- Bright Black
    '#ff3333', -- Bright Red
    '#5aff8f', -- Bright Green (ljusare Dracula-grön)
    '#ffff33', -- Bright Yellow
    '#d6acff', -- Bright Blue (LJUSLILA TEXT)
    '#ff33ff', -- Bright Magenta
    '#33ffff', -- Bright Cyan
    '#ffffff', -- Bright White
  },

  -- 3. Flik-raden (Din gamla setup)
  tab_bar = {
    background = '#000000',

    active_tab = {
      bg_color = '#000000',
      fg_color = '#f8f8f2',
      intensity = 'Bold',
    },

    inactive_tab = {
      bg_color = '#000000',
      fg_color = '#6272a4',
    },

    new_tab = {
      bg_color = '#000000',
      fg_color = '#f8f8f2',
    },
  },
}

-- =========================================================
-- FUNKTIONER (Hyperlinks, scroll, mouse)
-- =========================================================
-- 3. Klickbara länkar (Ctrl+Click på URLs)
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- 4. Scroll history (10000 rader)
config.scrollback_lines = 10000

-- Quick Select-mönster (CTRL+SHIFT+Space) — DevOps-specifik text
-- Läggs till WezTerms inbyggda mönster (URL:er, sökvägar, hashar) — inget tappas.
config.quick_select_patterns = {
  -- IPv4-adresser (t.ex. 192.168.1.10)
  '[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}',

  -- Kubernetes Pod-namn (t.ex. frontend-app-8594b9588d-x9q2z)
  '[a-z0-9-]+-[a-z0-9]{8,10}-[a-z0-9]{5}',

  -- UUIDs (vanligt i transaktions-/systemloggar)
  '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',

  -- MAC-adresser
  '[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}',
}

-- 5. Mouse bindings (triple-click = markera rad)
config.mouse_bindings = {
  {
    event = { Down = { streak = 3, button = 'Left' } },
    action = act.SelectTextAtMouseCursor 'Line',
  },
}

-- Auto-reload av config
config.automatically_reload_config = true

-- =========================================================
-- KNAPPAR (Mina egna inställningar)
-- =========================================================
config.keys = {
  -- Splitta fönster (vim-riktning: h/j/i/l = vänster/ner/upp/höger)
  { key = 'h', mods = 'ALT', action = act.SplitPane { direction = 'Left' } },
  { key = 'j', mods = 'ALT', action = act.SplitPane { direction = 'Down' } },
  { key = 'i', mods = 'ALT', action = act.SplitPane { direction = 'Up' } },
  { key = 'l', mods = 'ALT', action = act.SplitPane { direction = 'Right' } },
  -- Stäng pane: CTRL+w (obs: skuggar shellens radera-ord — använd ALT+Backspace där)
  { key = 'w', mods = 'CTRL', action = act.CloseCurrentPane { confirm = true } },
  { key = 'q', mods = 'ALT', action = act.CloseCurrentPane { confirm = true } },

  -- Navigera
  { key = 'LeftArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'DownArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Down' },

  -- Flikar (obs: CTRL+pilar skuggar ord-hopp på kommandoraden — använd ALT+b/f där)
  { key = 't', mods = 'CTRL', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'RightArrow', mods = 'CTRL', action = act.ActivateTabRelative(1) },
  { key = 'LeftArrow', mods = 'CTRL', action = act.ActivateTabRelative(-1) },
  { key = 'Tab', mods = 'CTRL', action = act.ActivateTabRelative(1) },
  { key = 'Tab', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },

  -- 6. Resize panes (CTRL+SHIFT+Arrows - intuitivt!)
  { key = 'LeftArrow', mods = 'CTRL|SHIFT', action = act.AdjustPaneSize { 'Left', 5 } },
  { key = 'RightArrow', mods = 'CTRL|SHIFT', action = act.AdjustPaneSize { 'Right', 5 } },
  { key = 'UpArrow', mods = 'CTRL|SHIFT', action = act.AdjustPaneSize { 'Up', 5 } },
  { key = 'DownArrow', mods = 'CTRL|SHIFT', action = act.AdjustPaneSize { 'Down', 5 } },

  -- 7. Zoom toggle (fullscreen en pane)
  { key = 'z', mods = 'ALT', action = act.TogglePaneZoomState },

  -- 8. Copy/Paste (explicit)
  { key = 'c', mods = 'CTRL|SHIFT', action = act.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },

  -- Rensa skärm + historik (guld innan en ny playbook-körning)
  { key = 'k', mods = 'CTRL|SHIFT', action = act.ClearScrollback 'ScrollbackAndViewport' },

  -- Öppna sök (snabbt hitta ERROR/Exception i loggar)
  { key = 'f', mods = 'CTRL|SHIFT', action = act.Search { CaseInSensitiveString = '' } },

  -- 9. TUI-genvägar i ny tab
  { key = 'g', mods = 'ALT', action = act.SpawnCommandInNewTab { args = { 'lazygit' } } },
  { key = 'k', mods = 'ALT', action = act.SpawnCommandInNewTab { args = { home .. '/.local/bin/k9s' } } },
  { key = 's', mods = 'ALT', action = act.SpawnCommandInNewTab { args = { home .. '/.local/bin/lazysql' } } },
  { key = 'd', mods = 'ALT', action = act.SpawnCommandInNewTab { args = { home .. '/.local/bin/lazydocker' } } },
}

-- =========================================================
-- SMARTA TAB-TITLAR (med emojis baserat på vad som körs)
-- =========================================================
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local pane = tab.active_pane
  local title = pane.title

  -- Om det är en SSH session
  if title:match("^(%w+@[%w%.]+):") then
    return '🌐 ' .. title
  end

  -- Om lazygit körs
  if title:match("lazygit") then
    return '🔀 ' .. tab.tab_index + 1 .. ': lazygit'
  end

  -- Om vim/nvim körs
  if title:match("n?vim") then
    return '📝 ' .. tab.tab_index + 1 .. ': ' .. title
  end

  -- Om kubectl körs
  if title:match("kubectl") then
    return '☸️  ' .. tab.tab_index + 1 .. ': k8s'
  end

  -- Om Ansible körs
  if title:match("ansible") then
    return '🤖 ' .. tab.tab_index + 1 .. ': ansible'
  end

  -- Om du läser loggar (tail, journalctl)
  if title:match("tail") or title:match("journalctl") then
    return '📄 ' .. tab.tab_index + 1 .. ': loggar'
  end

  -- Default: visa tab nummer och process
  return string.format('%d: %s', tab.tab_index + 1, title)
end)

return config

