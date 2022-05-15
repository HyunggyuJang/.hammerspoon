require("hs.ipc")
hs.hints.style = "vimperator"
hs.hints.showTitleThresh = 4
function switchToAppAndPasteFromClipboard(id)
  hs.window.get(id):focus()
  hs.timer.doAfter(0.001, function () hs.eventtap.keyStroke({"cmd"}, "v") end)
end

-- TODO: Port emacs.fnl's edit-with-emacs
-- function editWithEmacs()
--   local

-- Helper function (lua is not python)
local function intersect(m,n)
 local r={}
 for i,v1 in ipairs(m) do
  for k,v2 in pairs(n) do
   if (v1==v2) then
    return true
   end
  end
 end
 return false
end

-- Helper function (lua is not python)
local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

-- Helper function (lua is not python)
local function tableHasKey(table,key)
    return table[key] ~= nil
end

local pressed = {}
local events = {}

local function normal_mode(self, event, char)
    table.insert(events, event)

    if event:getType() == hs.eventtap.event.keyDown and char then
        table.insert(pressed, char)
        return
    end

    handled = false
    if #pressed > 1 then
        paste_style(self,pressed)
        handled = true
    elseif #pressed == 1 then
        -- handled = handle_single_key(self,pressed[1])
    end

    if not handled then
        replay(self)
    end

    events = {}
    pressed = {}
    collectgarbage()
end

function replay(self)
    inkscape = hs.application.get("Inkscape")
    for _, e in ipairs(events) do
        e:post(inkscape)
    end
end

local function handle_single_key(self, ev)
    if ev == 't' then
        open_emacs(self,false)
    elseif ev == 'T' then
        open_emacs(self,true)
    elseif ev == 'a' then
        self.mode = object_mode
    elseif ev == 'A' then
        save_object_mode(self)
    elseif ev == 's' then
        self.mode = style_mode
    elseif ev == 'S' then
        save_style_mode(self)
    else
        return false
    end
    return true
end

local function create_svg_and_paste(self, keys)

    -- print(hs.inspect.inspect(keys))
    -- Stolen from TikZ
    pt = 1.327 -- pixels
    w = 0.4 * pt
    thick_width = 0.8 * pt
    very_thick_width = 1.2 * pt

    style = {}
    style["stroke-opacity"] = 1

    if intersect({"s", "a", "d", "g", "h", "x", "e"}, keys)
    then
        style["stroke"] = "black"
        style["stroke-width"] = w
        style["marker-end"] = "none"
        style["marker-start"] = "none"
        style["stroke-dasharray"] = "none"
    else
        style["stroke"] = "none"
    end

    if has_value(keys, "g")
    then
        w = thick_width
        style["stroke-width"] = w
    end

    if has_value(keys, "h")
    then
        w = very_thick_width
        style["stroke-width"] = w
    end

    if has_value(keys, "a")
    then
        style['marker-end'] = 'url(#marker-arrow-' .. tostring(w) .. ')'
    end

    if has_value(keys, "x")
    then
        style['marker-start'] = 'url(#marker-arrow-' .. tostring(w) .. ')'
        style['marker-end'] = 'url(#marker-arrow-' .. tostring(w) .. ')'
    end

    if has_value(keys, "d")
    then
        style['stroke-dasharray'] = tostring(w) .. ',' .. tostring(2*pt)
    end

    if has_value(keys, "e")
    then
        style['stroke-dasharray'] = tostring(3*pt) .. ',' .. tostring(3*pt)
    end

    if has_value(keys, "f")
    then
        style['fill'] = 'black'
        style['fill-opacity'] = 0.12
    end

    if has_value(keys, "b")
    then
        style['fill'] = 'black'
        style['fill-opacity'] = 1
    end

    if has_value(keys, "w")
    then
        style['fill'] = 'white'
        style['fill-opacity'] = 1
    end

    if intersect(keys, {"f", "b", "w"})
    then
        style['marker-end'] = 'none'
        style['marker-start'] = 'none'
    end

    if not intersect(keys, {"f", "b", "w"})
    then
        style['fill'] = 'none'
        style['fill-opacity'] = 1
    end

    if style['fill'] == 'none' and style['stroke'] == 'none' then
        return
    end

    svg = [[
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg>
]]

    -- print(hs.inspect.inspect(style)) -- ENABLE ONLY FOR DEBUGGING

    if (tableHasKey(style, 'marker-end') and style['marker-end'] ~= 'none') or
       (tableHasKey(style, 'marker-start') and style['marker-start'] ~= 'none')
    then
        svgtemp = [[
<defs id="marker-defs">
<marker
]]
        svgtemp = svgtemp .. 'id="marker-arrow-' .. tostring(w) .. "\"\n"
        svgtemp = svgtemp .. 'orient="auto-start-reverse"' .. "\n"
        svgtemp = svgtemp .. 'refY="0" refX="0"' .. "\n"
        svgtemp = svgtemp .. 'markerHeight="3" markerWidth="2">' .. "\n"

        svgtemp = svgtemp .. '    <g transform="scale('.. tostring((2.40 * w + 3.87)/(4.5*w)) .. ')">' .. "\n"
        svg = svg .. svgtemp
        svgtemp = [[
    <path
       d="M -1.55415,2.0722 C -1.42464,1.29512 0,0.1295 0.38852,0 0,-0.1295 -1.42464,-1.29512 -1.55415,-2.0722"
       style="fill:none;stroke:#000000;stroke-width:{0.6};stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:10;stroke-dasharray:none;stroke-opacity:1�
       inkscape:connector-curvature="0" />
   </g>
</marker>
</defs>
]]
        svg = svg .. svgtemp
    end

    style_string = ''
    for key, value in pairs(style) do
        style_string = style_string .. key .. ":" .. " " .. value .. ";"
    end

    svg = svg .. '<inkscape:clipboard style="' .. style_string .. '" />' .. "\n</svg>"

    -- print(svg) -- ENABLE ONLY FOR DEBUGGING

    hs.pasteboard.writeDataForUTI("dyn.ah62d4rv4gu80w5pbq7ww88brrf1g065dqf2gnppxs3xu", svg)
    -- get UTI via https://github.com/sindresorhus/Pasteboard-Viewer
    hs.eventtap.keyStroke({"shift", "cmd"}, "v")
end

-- Initialize an inkscape window filter
-- https://stackoverflow.com/q/63795560
local InkscapeWF = hs.window.filter.new("Inkscape")

-- Or use watcher if filter doesn't work reliably
-- https://www.hammerspoon.org/docs/hs.application.watcher.html
-- local InkscapeWatcher = hs.application.get("Inkscape").watcher.new(catcher)

inkscape_shortcut_manager = {}
inkscape_shortcut_manager.mode = normal_mode

function catcher(event)
    if event:getFlags()['cmd'] then
        return false
    end
    char = event:getCharacters(true)
    print(hs.inspect.inspect(char))
    return true, inkscape_shortcut_manager.mode(self, event, char)
end
local tapper=hs.eventtap.new({hs.eventtap.event.types.keyUp,hs.eventtap.event.types.keyDown}, catcher)

-- Subscribe to when your Inkscape window is focused and unfocused
InkscapeWF
    :subscribe(hs.window.filter.windowFocused, function()
        print("starting keychords")
        tapper:start()
    end)
    :subscribe(hs.window.filter.windowUnfocused, function()
            print("stopping keychords")
            tapper:stop()
    end)
