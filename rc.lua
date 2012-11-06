--This program is free software; you can redistribute it and/or
--modify it under the terms of the GNU General Public License
--as published by the Free Software Foundation; either version 2
--of the License, or (at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU General Public License for more details.
--
--You should have received a copy of the GNU General Public License
--along with this program; if not, write to the Free Software
--Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")

-- Load Debian menu entries
require("debian.menu")

require("vicious")
require("blingbling")


function run_once(prg, args)
  if not prg then
    do return nil end
  end
  if not args then
    args=""
  end
  awful.util.spawn_with_shell('pgrep -x -u $USER -x ' .. prg .. ' || (' .. prg .. ' ' .. args ..')')
end

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.add_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init("/usr/share/awesome/themes/elbereth/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "x-terminal-emulator"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

run_once("nm-applet")
run_once("mpd")
run_once("xscreensaver")
run_once("conky", '-c ~/.config/awesome/themes/elbereth/conky/modalconky')
awful.util.spawn_with_shell("sudo pglcmd stop")
awful.util.spawn_with_shell("touch ~/.config/awesome/conkystate")

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
-- Elven tengwar numerals
tags = {names  = { "", "", "", "", "", "", "", "", "" }}

for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag(tags.names, s, layouts[2])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "Debian", debian.menu.Debian_menu.Debian },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock({ align = "right" })

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
mywibox = {}
mywibox2 = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
						return awful.widget.tasklist.label.currenttags(c,s)
	
--                                              return awful.widget.tasklist.label.focused(c, s)
                                          end, mytasklist.buttons)
    --This is a hack to shrink the wibox
    awesome.font="Tengwar Formal CSUR 6"
     -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })
    mywibox2[s] = awful.wibox({ position = "bottom", screen = s })
    --Restore font (other half of hack)
    awesome.font="Tengwar Formal CSUR 11"

    -- Cpu Widget
    cpulabel= widget({ type = "textbox" })
    cpulabel.text="    Cpu: "

    cpu=blingbling.classical_graph.new()
    cpu:set_font_size(8)
    cpu:set_height(21)
    cpu:set_width(125)
    cpu:set_show_text(false)
    cpu:set_label("Load: $percent %")
    cpu:set_graph_color("#e7e444dd")
    cpu:set_graph_line_color(beautiful.fg_focus)
    cpu:set_filled(true)
    cpu:set_h_margin(1.5)
    cpu:set_v_margin(1.5)
    cpu:set_background_color("#cfd3ebdd")
    cpu:set_filled_color("#292b2bff")
    cpu:set_rounded_size(0.25)
    vicious.register(cpu, vicious.widgets.cpu, '$1',3)
 
    -- Mem Widget
    memlabel= widget({ type = "textbox" })
    memlabel.text="     Mem: "
  
    memwidget = blingbling.classical_graph.new()
    memwidget:set_font_size(8)
    memwidget:set_height(22)
    memwidget:set_h_margin(1.5)
    memwidget:set_v_margin(1.5)
    memwidget:set_width(125)
    memwidget:set_filled(true)
    memwidget:set_show_text(false)
    memwidget:set_filled_color("#292b2bff")
    memwidget:set_rounded_size(0.25)
    memwidget:set_graph_color("#e7e444dd")
    memwidget:set_background_color("#cfd3ebdd")
    memwidget:set_graph_line_color(beautiful.fg_focus)
    vicious.register(memwidget, vicious.widgets.mem, "$1", 5)

    -- Disk Free Widgets
    dflabel= widget({ type = "textbox" })
    dflabel.text="    /home: "
    df=blingbling.progress_graph.new()
    df:set_height(22)
    df:set_width(125)
    df:set_graph_color("#e7e444dd")
    df:set_graph_line_color(beautiful.fg_focus)
    df:set_horizontal(true)
    df:set_filled(true)
    df:set_h_margin(1.5)
    df:set_v_margin(1.5)
    df:set_filled_color("#292b2bff")
    df:set_rounded_size(0.25)
    df:set_background_color("#cfd3ebdd")

    df2label= widget({ type = "textbox" })
    df2label.text="    /: "

    df2=blingbling.progress_graph.new()
    df2:set_height(22)
    df2:set_width(125)
    df2:set_graph_color("#e7e444dd")
    df2:set_graph_line_color(beautiful.fg_focus)
    df2:set_horizontal(true)
    df2:set_filled(true)
    df2:set_h_margin(1.5)
    df2:set_v_margin(1.5)
    df2:set_filled_color("#292b2bff")
    df2:set_rounded_size(0.25)
    df2:set_background_color("#cfd3ebdd")

    vicious.register(df, vicious.widgets.fs, '${/home used_p}',121)
    vicious.register(df2, vicious.widgets.fs, '${/ used_p}',237)

    --If you couldn't guess, this says "Elbereth"
    elbereth_label=widget({type = "textbox"})
    elbereth_label.text="  "

    -- MPD
    mpd_volume_label=widget({ type = "textbox"})
    mpd_volume_label.text="  " --Elven for song

    my_mpd=blingbling.mpd_visualizer.new()
    my_mpd:set_height(20)
    my_mpd:set_width(340)
    my_mpd:update()
    my_mpd:set_line(true)
    my_mpd:set_h_margin(2)
    my_mpd:set_v_margin(3)
    my_mpd:set_mpc_commands()
    my_mpd:set_launch_mpd_client(terminal .. " -e ncmpcpp")
    my_mpd:set_show_text(true)
    my_mpd:set_font_size(12)
    my_mpd:set_background_text_color(beautiful.bg_normal)
    my_mpd:set_text_color(beautiful.fg_focus)
    my_mpd:set_error_text_color(beautiful.fg_normal)
    my_mpd:set_graph_color(beautiful.fg_focus)
    my_mpd:set_label("- $artist : $title -")

    mpd_volume=blingbling.volume.new()
    mpd_volume:set_height(20)
    mpd_volume:set_v_margin(3)
    mpd_volume:set_width(23)
    mpd_volume:update_mpd()
    mpd_volume:set_mpd_control()
    mpd_volume:set_background_graph_color("#00000099")
    mpd_volume:set_graph_color("#99aaffee")
    mpd_volume:set_bar(true)

    -- Volume Label
    volume_label = widget({ type = "textbox"})
    volume_label.text="   " --Elven for noise
    my_volume=blingbling.volume.new()
    my_volume:set_height(20)
    my_volume:set_v_margin(3)
    my_volume:set_width(23)
    my_volume:update_master()
    my_volume:set_master_control()
    my_volume:set_bar(true)
    my_volume:set_background_graph_color("#00000099")
    my_volume:set_graph_color("#99aaffee")
    
    -- Spacing
    gap =widget({ type = "textbox"})
    gap.text="    "
    biggap =widget({ type = "textbox"})
    biggap.text="                    "
    smallgap =widget({ type = "textbox"})
    smallgap.text=" "

    -- Add widgets to the wibox - order matters

    mywibox2[s].widgets = {
        {
            elbereth_label,
            layout=awful.widget.layout.horizontal.rightleft
        },
        mpd_volume_label,
        mpd_volume,
        smallgap,
        my_mpd,
        biggap,
        gap,
        cpulabel,
        cpu.widget,
        gap,
        gap,
        memlabel,
        memwidget.widget,
        gap,gap,
        df2label,
        df2,
        gap,gap,
        dflabel,
        df,
        layout = awful.widget.layout.horizontal.leftright
    }

    mywibox[s].widgets = {
        {
            mylauncher,
            mytaglist[s],
            smallgap,
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        mytextclock,smallgap,
        my_volume.widget,
        volume_label,
        s == 1 and mysystray or nil,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end)
    --Uncomment these two lines to enable scroll wheel annoyingness:
    --awful.button({ }, 4, awful.tag.viewnext),
    --awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(

--Shift-Mod-P suspends
    awful.key({ modkey,  "Shift"         }, "p",  function () 
awful.util.spawn_with_shell("sudo pm-suspend") end     ),

--Control-Mod-P hibernates
    awful.key({ modkey,  "Control"         }, "p",  function () 
awful.util.spawn_with_shell("sudo pm-hibernate") end     ),

--Mod-S opens ncmcpp
    awful.key({ modkey,           }, "s",  function () 
awful.util.spawn_with_shell(terminal .. " -e ncmpcpp") end     ),

--Launch firefox
    awful.key({ modkey,           }, "i",  function () 
awful.util.spawn("firefox") end     ),

--Control volume with Up/Down and control up/down (Shift up/down are reserved for not yet implemented conky stuff)
    awful.key({ modkey, "Control"          }, "Up",  function () 
awful.util.spawn_with_shell("mpc volume +5") end     ),
    awful.key({ modkey, "Control"          }, "Down",  function () 
awful.util.spawn_with_shell("mpc volume -5") end     ),
    awful.key({ modkey,           }, "Up",  function () 
awful.util.spawn_with_shell("amixer --quiet set Master 5%+") end     ),
    awful.key({ modkey,           }, "Down",  function () 
awful.util.spawn_with_shell("amixer --quiet set Master 5%-") end     ),

--Shift-Mod Left and Right toggle the conkystate
    awful.key({ modkey,  "Shift"         }, "Left",  function () 
awful.util.spawn_with_shell("echo 0 > ~/.config/awesome/conkystate") end     ),
    awful.key({ modkey,  "Shift"         }, "Right", function ()  awful.util.spawn_with_shell("echo 1 > ~/.config/awesome/conkystate") end  ),

    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    --This allows the printscreen button to take a screenshot
    awful.key({ }, "Print", function () awful.util.spawn("scrot -e 'mv $f ~/screenshots/ 2>/dev/null'") end),

    awful.key({ modkey,           }, "h",
        function ()
            awful.client.focus.bydirection( "left" )
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "l",
        function ()
           awful.client.focus.bydirection("right")
            if client.focus then client.focus:raise() end
         end),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.bydirection( "down" )
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
           awful.client.focus.bydirection("up")
            if client.focus then client.focus:raise() end
         end),

    awful.key({ modkey,           }, "w", function () mymainmenu:show({keygrabber=true}) end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.bydirection(  "down" )    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.bydirection(  "up" )    end),
    awful.key({ modkey, "Shift"   }, "h", function () awful.client.swap.bydirection(  "left" )    end),
    awful.key({ modkey, "Shift"   }, "l", function () awful.client.swap.bydirection(  "right" )    end),
    awful.key({ modkey, "Control" }, "h", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "l", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "=",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "-",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "=",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "-",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "=",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "-",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])

                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     size_hints_honor = false,
                     buttons = clientbuttons } },
    --{ rule = { }, properties = { }, callback = awful.client.setslave },

    { rule = { class = "MPlayer" },
      properties = { floating = true } },
      
      --When you watch a fullscreen firefox plugin, you need this or it can't fullscreen correctly.
    { rule = { class = "Plugin-container" },
      properties = { floating = true } },

    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    { rule = { class = "Gnome-terminal" },
      properties = { }, callback = awful.client.setslave },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
         -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
