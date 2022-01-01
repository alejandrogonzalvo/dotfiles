-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")

-- Theme handling library
local beautiful = require("beautiful")

-- Notification library and config
local naughty = require("naughty")
naughty.config.padding = 16
naughty.config.spacing = 16
naughty.config.defaults.margin = 16
naughty.config.defaults.timeout = 3
naughty.config.defaults.icon_size = 48

-- Enable hotkeys help widget for VIM and other apps
local hotkeys_popup = require("awful.hotkeys_popup")

-- bool variables for high-level management
local v_muted= false
local p_hidden = false

-- keyboard layout variable
local k_layout = "us"
local k_changed = "false"

-- exterior margin
v_margin = 0
h_margin = 0

-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "There were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init(gears.filesystem.get_configuration_dir() .. "forest.lua")

-- This is used later as the default terminal and editor to run.
terminal = "alacritty"
editor = "nvim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.floating,
}

-- }}}

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)
    end)

awful.screen.connect_for_each_screen(function(s)
    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4"}, s, awful.layout.layouts[1])

end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({ }, 4, awful.tag.viewprev),
    awful.button({ }, 5, awful.tag.viewnext)
))
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
    -- Change client
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),

    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
    {description = "view next", group = "tag"}),

    -- Modify margins
    awful.key({ modkey, "Shift"   }, "[", function ()
        h_margin = h_margin - 5
        awful.screen.connect_for_each_screen(function(s)
            s.padding = {
                left = h_margin,
                right = h_margin,
                top = v_margin,
                bottom = v_margin
          }
        end)
    end,
    {description = "decrease h_margin", group = "tag"}),

    awful.key({ modkey, "Shift"   }, "]", function ()
        v_margin = v_margin - 5
        awful.screen.connect_for_each_screen(function(s)
            s.padding = {
                left = h_margin,
                right = h_margin,
                top = v_margin,
                bottom = v_margin
          }
        end)
    end,
    {description = "decrease v_margin", group = "tag"}),

    awful.key({ modkey,           }, "[", function () 
        h_margin = h_margin + 5
        awful.screen.connect_for_each_screen(function(s)
            s.padding = {
                left = h_margin,
                right = h_margin,
                top = v_margin,
                bottom = v_margin
          }
        end)
    end,
    {description = "increment h_margin", group = "tag"}),

    awful.key({ modkey,           }, "]", function () 
        v_margin = v_margin + 5
        awful.screen.connect_for_each_screen(function(s)
            s.padding = {
                left = h_margin,
                right = h_margin,
                top = v_margin,
                bottom = v_margin
          }
        end)
    end,
    {description = "increment v_margin", group = "tag"}),

    awful.key({ modkey, "Control" }, "]", function () 
      local t = awful.screen.focused().selected_tag
      t.gap = t.gap + 5
      awful.layout.arrange(awful.screen.focused())
    end,
    {description = "increment useless gaps", group = "tag"}),

    awful.key({ modkey, "Control" }, "[", function ()
      local t = awful.screen.focused().selected_tag
      t.gap = t.gap - 5
      awful.layout.arrange(awful.screen.focused())
    end,
    {description = "decrease useless gaps", group = "tag"}),

    -- Volume configuration
    awful.key({ modkey,           }, "o", function () awful.spawn("amixer set 'Master' 5%-")   end,
              {description = "lower volume", group= "launcher"}),
    awful.key({ modkey,           }, "p", function () awful.spawn("amixer set 'Master' 5%+")   end,
              {description = "lower volume", group= "launcher"}),
    awful.key({ modkey,           }, "m",
      function ()
        if v_muted then
          awful.spawn("pactl set-sink-mute 0 0")
          v_muted = false
        else
          awful.spawn("pactl set-sink-mute 0 1")
          v_muted = true
        end
      end,
    {description = "mute volume", group= "launcher"}),

    -- Client moving
    awful.key({ modkey, "Shift" }, "Left",
      function ()
        -- get current tag
        local t = client.focus and client.focus.first_tag or nil
        if t == nil then
            return
        end
        local pt = t.screen.tags[t.index-1]
        if pt == nil then
          pt = t.screen.tags[4]
        end
        awful.client.movetotag(pt)
        awful.tag.viewprev()
      end,
    {description = "move client to previous tag and switch to it", group = "tag"}),

    awful.key({ modkey, "Shift" }, "Right",
      function ()
        -- get current tag
        local t = client.focus and client.focus.first_tag or nil
        if t == nil then
            return
        end
        local nt = client.focus.screen.tags[t.index+1]
        if nt == nil then
          nt = t.screen.tags[1]
        end
        awful.client.movetotag(nt)
        awful.tag.viewnext()
      end,
    {description = "move client to next tag and switch to it", group = "tag"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),

    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),

    awful.key({ modkey,  }, "j",
 	  function ()
      local c = awful.client.next(1)
      client.focus = c
  	end,
    {description = "focus the before client", group = "screen"}),

    awful.key({ modkey,  }, "k",
   	function ()
	    local c = awful.client.next(-1)
	    client.focus = c
   	end,
    {description = "focus the next client", group = "screen"}),

    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    awful.key({ modkey,		  }, "-",
    	function()
	        awful.spawn("spectacle")
    	end,
      {description = "hide polybar", group = "client"}),

    -- Show and hide polybar
    awful.key({ modkey,		  }, "s",
    	function()
	    if p_hidden then
	        awful.spawn("polybar-msg cmd show")
	        p_hidden = false
          awful.screen.connect_for_each_screen(function(s)
              s.padding = {
                  left = h_margin,
                  right = h_margin,
                  top = v_margin + 20,
                  bottom = v_margin 
              }
          end)
	    else
	    	awful.spawn("polybar-msg cmd hide")
		    p_hidden = true
	      awful.screen.connect_for_each_screen(function(s)
          s.padding = {
            left = h_margin,
            right = h_margin,
            top = v_margin,
            bottom = v_margin
          }
        end)
end

    	end,
      {description = "hide polybar", group = "client"}),

    -- Spotify manipulation
    awful.key({ modkey,           }, "8",
      function ()
        awful.spawn("spotifyctl -q previous")
      end,
      {description = "previous song", group = "client"}),
    awful.key({ modkey,           }, "9",
      function ()
        awful.spawn("spotifyctl -q playpause")
      end,
      {description = "previous song", group = "client"}),
    awful.key({ modkey,           }, "0",
      function ()
        awful.spawn("spotifyctl -q next")
      end,
      {description = "previous song", group = "client"}),
    awful.key({ modkey,           }, "/",
      function ()
        if eww then
          awful.spawn(ewwclose)
          eww = false
        else
          awful.spawn(centerlaunch)
          eww = true
        end
      end,
    {description = "toggle eww", group= "launcher"}),

	awful.key({ modkey,		  }, "a",
	function ()
	  awful.layout.inc(1)
      end,
	{description = "switch layout", group = "layout"}),


    -- Keyboard layout manipulation
    awful.key({modkey,            }, "1",
      function ()
        if k_layout == "us" and not k_changed then 
                awful.spawn("setxkbmap es")
                k_layout = "es"
                k_changed = true
        end
        if k_layout == "es" and not k_changed then
                awful.spawn("setxkbmap gr")
                k_layout = "gr"
                k_changed = true
        end
        if k_layout == "gr" and not k_changed then
                awful.spawn("setxkbmap us")
                k_layout = "us"
                k_changed = true
        end
        k_changed = false
      end,
      {description = "change keyboard layout", group = "layout"}),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Shift"   }, "Return", function () awful.spawn("kitty") end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),
	  awful.key({ modkey,		}, "d", function () awful.spawn("/home/alejandro/.config/rofi/launchers/text/./launcher.sh") end,
              {description = "show the menubar", group = "launcher"}),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "o",     function () awful.layout.inc(1, awful.screen.focused()) end,
        {description = "select next", group = "layout"}),
    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                    c:emit_signal(
                        "request::activate", "key.unminimize", {raise = true}
                    )
                  end
              end,
              {description = "restore minimized", group = "client"})

	   )
clientkeys = gears.table.join(


   awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey,    }, "q",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"})
        )
clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.centered,
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "copyq",  -- Includes session name in class.
          "pinentry",
        },
        class = {
          "Arandr",
          "Blueman-manager",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
          "Wpa_gui",
          "veromix",
          "xtightvncviewer"},

        -- Note that the name property shown in xprop might be set slightly after creation of the client
        -- and the name shown there might not match defined rules here.
        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "ConfigManager",  -- Thunderbird's about:config.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Remove titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = false }
    },
  
    -- Solves Firefox buggy behaviour
    { rule = { class = "firefox" },
      properties = { opacity = 1, maximized = false, floating = false } },
      
    -- Solves Nautilus buggy behaviour
    { rule = { class = "Nautilus" },
      properties = { opacity = 1, maximized = false, floating = false } },

    { rule = { class = "mpv" },
      properties = {border_width = 0 }},

}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end
    c.shape = function(cr, w, h)
      gears.shape.rounded_rect(cr, w, h, 4)
    end
    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}


-- Autostart
awful.spawn.with_shell("picom --experimental-backends")
awful.spawn.with_shell("/home/alejandro/.config/polybar/forest/launch.sh")
