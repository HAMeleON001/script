script_name('admintools')
script_authors('ars','kakoi-to-chel-s-bh')
script_version('0.0.2')

--загрузка модулей
require 'libstd.deps' {
   'fyp:mimgui',
   'fyp:fa-icons-4',
   'donhomka:mimgui-addons'
}

--[[ function autoupdate(json_url, prefix, url)
   local dlstatus = require('moonloader').download_status
   local json = getWorkingDirectory() .. '\\'..thisScript().name..'-version.json'
   if doesFileExist(json) then os.remove(json) end
   downloadUrlToFile(json_url, json,
     function(id, status, p1, p2)
       if status == dlstatus.STATUSEX_ENDDOWNLOAD then
         if doesFileExist(json) then
           local f = io.open(json, 'r')
           if f then
             local info = decodeJson(f:read('*a'))
             updatelink = info.updateurl
             updateversion = info.latest
             f:close()
             os.remove(json)
             if updateversion ~= thisScript().version then
               lua_thread.create(function(prefix)
                 local dlstatus = require('moonloader').download_status
                 local color = -1
                 sampAddChatMessage((prefix..'Обнаружено обновление. Пытаюсь обновиться c '..thisScript().version..' на '..updateversion), color)
                 wait(250)
                 downloadUrlToFile(updatelink, thisScript().path,
                   function(id3, status1, p13, p23)
                     if status1 == dlstatus.STATUS_DOWNLOADINGDATA then
                       print(string.format('Загружено %d из %d.', p13, p23))
                     elseif status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
                       print('Загрузка обновления завершена.')
                       sampAddChatMessage((prefix..'Обновление завершено!'), color)
                       goupdatestatus = true
                       lua_thread.create(function() wait(500) thisScript():reload() end)
                     end
                     if status1 == dlstatus.STATUSEX_ENDDOWNLOAD then
                       if goupdatestatus == nil then
                         sampAddChatMessage((prefix..'Обновление прошло неудачно. Запускаю устаревшую версию..'), color)
                         update = false
                       end
                     end
                   end
                 )
                 end, prefix
               )
             else
               update = false
               print('v'..thisScript().version..': Обновление не требуется.')
             end
           end
         else
           print('v'..thisScript().version..': Не могу проверить обновление. Смиритесь или проверьте самостоятельно на '..url)
           update = false
         end
       end
     end
   )
   while update ~= false do wait(100) end
end
autoupdate("https://www.dropbox.com/s/gk8hevefv4v4qex/dodmin tools.lua?dl=1", '['..string.upper(thisScript().name)..']: ', "https://www.dropbox.com/s/gk8hevefv4v4qex/dodmin tools.lua?dl=1")
 ]]
-- подключение модулей
local imgui = require 'mimgui'
local memory = require 'memory'
local new = imgui.new
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local sampev = require 'lib.samp.events'
local mimgui_addons = require 'mimgui_addons'
local faicons = require 'fa-icons'

--окна Imgui
local bWindow = new.bool()

--цвета
a_color = {imgui.ImVec4(0.0, 0.52, 0.74, 1.0) --[[ Синий ]],
imgui.ImVec4(0.0, 0.55, 0.0, 1.0) --[[ Зеленый ]],
imgui.ImVec4(0.33, 0.0, 0.74, 1.0) --[[ Фиолетовый ]],
imgui.ImVec4(0.75, 0.70, 0.4, 1.0) --[[ Кукурузный ]],
imgui.ImVec4(0.92, 0.27, 0.92, 1.0)--[[ Розовый ]],
imgui.ImVec4(0.27, 0.63, 0.62, 1.0) --[[ Бирюзовый ]]}
local mainc = a_color[4]

local BulletSync = {lastId = 0, maxLines = 15}
for i = 1, BulletSync.maxLines do
	BulletSync[i] = {enable = false, o = {x, y, z}, t = {x, y, z}, time = 0, tType = 0}
end

--Search: main
function main()
   while true do
      wait(0)
      if wasKeyPressed(0x30--[[0]]) and wasKeyPressed(0x50--[[P]]) then
         bWindow[0] = not bWindow[0]
      end
      local oTime = os.time()
      if ckTraicers[0] and not isPauseMenuActive() then
         for i = 1, BulletSync.maxLines do
            if BulletSync[i].enable == true and oTime <= BulletSync[i].time then
               local o, t = BulletSync[i].o, BulletSync[i].t
               if isPointOnScreen(o.x, o.y, o.z) and
                  isPointOnScreen(t.x, t.y, t.z) then
                  local sx, sy = convert3DCoordsToScreen(o.x, o.y, o.z)
                  local fx, fy = convert3DCoordsToScreen(t.x, t.y, t.z)
                  renderDrawLine(sx, sy, fx, fy, 1, BulletSync[i].tType == 0 and 0xFFFFFFFF or 0xFFFFC700)
                  renderDrawPolygon(fx, fy-1, 3, 3, 4.0, 10, BulletSync[i].tType == 0 and 0xFFFFFFFF or 0xFFFFC700)
               end
            end
         end
      end
   end
end
--mimgui_param
setting_style = {
   styles = {u8"Синий", u8"Зеленый", u8"Фиолетовый", u8"Кукурузный", u8"Розовый", u8"Бирюзовый"},
   SArray = {},
   SSelected = new.int(1)
}
setting_style.SArray = new['const char*'][#setting_style.styles](setting_style.styles)

ckWallhack = new.bool()--wh
ckTraicers = new.bool()--bullet

-- imgui.OnInitialize() вызывается всего раз, перед первым показом рендера
imgui.OnInitialize(function()

	local defGlyph = imgui.GetIO().Fonts.ConfigData.Data[0].GlyphRanges
	imgui.GetIO().Fonts:Clear() -- очистим шрифты
	local font_config = imgui.ImFontConfig() -- у каждого шрифта есть свой конфиг
	font_config.SizePixels = 14.0;
   font_config.GlyphExtraSpacing.x = 0.1
   -- основной шрифт
	local def = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\arialbd.ttf', font_config.SizePixels, font_config, defGlyph)
   
   local config = imgui.ImFontConfig()
   config.MergeMode = true
   config.PixelSnapH = true
   config.FontDataOwnedByAtlas = false
   config.GlyphOffset.y = 1.0 -- смещение на 1 пиксеот вниз
   local fa_glyph_ranges = new.ImWchar[3]({ faicons.min_range, faicons.max_range, 0 })
   -- иконки
   local faicon = imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85(), font_config.SizePixels, config, fa_glyph_ranges)

   imgui.GetIO().ConfigWindowsMoveFromTitleBarOnly = true
	
end)


imgui.OnFrame(function () return bWindow[0] end,
function ()
   apply_custom_style()
   local style = imgui.GetStyle()
   local colors = style.Colors
   local clr = imgui.Col
   local color = colors[clr.ButtonHovered]
   local colorLog = colors[clr.WindowBg]
   local w, h = getScreenResolution()
   imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0.5))
   imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
   imgui.SetNextWindowSize(imgui.ImVec2(601, 500), imgui.Cond.FirstUseEver)
   imgui.Begin(u8"AdminTools", bWindow, imgui.WindowFlags_None)
   imgui.PopStyleColor()
   if imgui.BeginTabBar('##1') then
		if imgui.BeginTabItem(u8'Общие настройки') then
         imgui.SetWindowFontScale(1.0)
         imgui.AlignTextToFramePadding()
         imgui.Text(u8"Стиль интерфейса:")
         imgui.SameLine()
         imgui.PushItemWidth(130)
         if imgui.Combo('##style', setting_style.SSelected, setting_style.SArray, #setting_style.styles) then
            mainc = a_color[setting_style.SSelected[0] + 1]
         end
         if imgui.Checkbox("Wall Hack", ckWallhack) then
            nameTag(ckWallhack[0])
         end
         imgui.Checkbox(u8"Трейсеры пуль при слежке", ckTraicers)
			imgui.EndTabItem()
      end
	    imgui.EndTabBar()
    end
   imgui.End()
end)

function sampev.onBulletSync(playerid, data)
	if ckTraicers[0] then
		if data.target.x == -1 or data.target.y == -1 or data.target.z == -1 then
			return true
		end
		BulletSync.lastId = BulletSync.lastId + 1
		if BulletSync.lastId < 1 or BulletSync.lastId > BulletSync.maxLines then
			BulletSync.lastId = 1
		end
		local id = BulletSync.lastId
		BulletSync[id].enable = true
		BulletSync[id].tType = data.targetType
		BulletSync[id].time = os.time() + 15
		BulletSync[id].o.x, BulletSync[id].o.y, BulletSync[id].o.z = data.origin.x, data.origin.y, data.origin.z
		BulletSync[id].t.x, BulletSync[id].t.y, BulletSync[id].t.z = data.target.x, data.target.y, data.target.z
	end
end

function apply_custom_style()
   local style = imgui.GetStyle()
   local colors = style.Colors
   local clr = imgui.Col
   local ImVec4 = imgui.ImVec4
   style.WindowRounding = 1.5
   style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
   style.FrameRounding = 1.0
   style.ItemSpacing = imgui.ImVec2(4.0, 4.0)
   style.ScrollbarSize = 13.0
   style.ScrollbarRounding = 0
   style.GrabMinSize = 8.0
   style.GrabRounding = 1.0
   style.WindowBorderSize = 0.0
   style.WindowPadding = imgui.ImVec2(4.0, 4.0)
   style.FramePadding = imgui.ImVec2(2.5, 3.5)
   style.ButtonTextAlign = imgui.ImVec2(0.5, 0.35)
   style.WindowMinSize = imgui.ImVec2(650, 320)
 
 
   colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
   colors[clr.TextDisabled]           = ImVec4(0.7, 0.7, 0.7, 1.0)
   colors[clr.WindowBg]               = ImVec4(0.07, 0.07, 0.07, 1.0)
   colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
   colors[clr.Border]                 = ImVec4(mainc.x, mainc.y, mainc.z, 0.4)
   colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
   colors[clr.FrameBg]                = ImVec4(mainc.x, mainc.y, mainc.z, 0.7)
   colors[clr.FrameBgHovered]         = ImVec4(mainc.x, mainc.y, mainc.z, 0.4)
   colors[clr.FrameBgActive]          = ImVec4(mainc.x, mainc.y, mainc.z, 0.9)
   colors[clr.TitleBg]                = ImVec4(mainc.x, mainc.y, mainc.z, 1.0)
   colors[clr.TitleBgActive]          = ImVec4(mainc.x, mainc.y, mainc.z, 1.0)
   colors[clr.TitleBgCollapsed]       = ImVec4(mainc.x, mainc.y, mainc.z, 0.79)
   colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
   colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
   colors[clr.ScrollbarGrab]          = ImVec4(mainc.x, mainc.y, mainc.z, 0.8)
   colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
   colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
   colors[clr.CheckMark]              = ImVec4(mainc.x + 0.13, mainc.y + 0.13, mainc.z + 0.13, 1.00)
   colors[clr.SliderGrab]             = ImVec4(0.28, 0.28, 0.28, 1.00)
   colors[clr.SliderGrabActive]       = ImVec4(0.35, 0.35, 0.35, 1.00)
   colors[clr.Button]                 = ImVec4(mainc.x, mainc.y, mainc.z, 0.8)
   colors[clr.ButtonHovered]          = ImVec4(mainc.x, mainc.y, mainc.z, 0.63)
   colors[clr.ButtonActive]           = ImVec4(mainc.x, mainc.y, mainc.z, 1.0)
   colors[clr.Header]                 = ImVec4(mainc.x, mainc.y, mainc.z, 0.6)
   colors[clr.HeaderHovered]          = ImVec4(mainc.x, mainc.y, mainc.z, 0.43)
   colors[clr.HeaderActive]           = ImVec4(mainc.x, mainc.y, mainc.z, 0.8)
   colors[clr.Separator]              = colors[clr.Border]
   colors[clr.SeparatorHovered]       = ImVec4(0.26, 0.59, 0.98, 0.78)
   colors[clr.SeparatorActive]        = ImVec4(0.26, 0.59, 0.98, 1.00)
   colors[clr.ResizeGrip]             = ImVec4(mainc.x, mainc.y, mainc.z, 0.8)
   colors[clr.ResizeGripHovered]      = ImVec4(mainc.x, mainc.y, mainc.z, 0.63)
   colors[clr.ResizeGripActive]       = ImVec4(mainc.x, mainc.y, mainc.z, 1.0)
   colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
   colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
   colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
   colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
   colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
end

--Search:wallhack
function nameTag(arg)
   local pStSet = sampGetServerSettingsPtr()
   if arg then
      memory.setfloat(pStSet + 39, 1488.0)
      memory.setint8(pStSet + 47, 0)
      memory.setint8(pStSet + 56, 1)
   else
      memory.setfloat(pStSet + 39, 50.0)
      memory.setint8(pStSet + 47, 0)
      memory.setint8(pStSet + 56, 1)
   end
end