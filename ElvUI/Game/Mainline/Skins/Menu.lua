local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule('Skins')

local _G = _G
local next = next
local strsub = strsub
local unpack = unpack
local hooksecurefunc = hooksecurefunc

local professionsRankBarMenuTag = 'MENU_PROFESSIONS_RANK_BAR'

local function GetProfessionsMenuFontObject()
	-- Same conversion as FontTemplate. Compositor font strings disallow SetFont.
	local fontStyle = E.db.general.fontStyle or P.general.fontStyle
	local fontSize = E.db.general.fontSize or P.general.fontSize
	if fontStyle == 'NONE' then fontStyle = '' end -- none isnt a real style

	local slug = E:CanFlagSlug(fontStyle)
	if slug then fontStyle = fontStyle..'SLUG' end -- handle before shadow

	local shadow = strsub(fontStyle, 0, 6) == 'SHADOW'
	if shadow then fontStyle = strsub(fontStyle, 7) end -- shadow isnt a real style

	local menuFontObject = E:GenerateFontObject('ElvUIMenuFont', E.media.normFont, fontSize, fontStyle)
	E:SetFontObjectShadow(menuFontObject, fontStyle, shadow)

	return menuFontObject
end

local function SkinProfessionsMenuFrameFonts(frame, menuFontObject)
	for _, region in next, { frame:GetRegions() } do
		if region:IsObjectType('FontString') then
			local fontObject = region:GetFontObject()
			if fontObject == _G.GameFontNormal or fontObject == _G.GameFontHighlightOutline then
				local textColorRed, textColorGreen, textColorBlue, textColorAlpha = region:GetTextColor()
				region:SetFontObject(menuFontObject)
				region:SetTextColor(textColorRed, textColorGreen, textColorBlue, textColorAlpha)
			end
		end
	end

	for _, child in next, { frame:GetChildren() } do
		SkinProfessionsMenuFrameFonts(child, menuFontObject)
	end
end

local function SkinProfessionsMenuFonts(menu)
	SkinProfessionsMenuFrameFonts(menu, GetProfessionsMenuFontObject())
end

local function SkinProfessionsRankBarMenu(menu)
	local menuDescription = menu.menuDescription
	if not menuDescription then return end

	local descriptionProxy = menuDescription:ToProxy()
	if descriptionProxy:GetTag() ~= professionsRankBarMenuTag then return end

	SkinProfessionsMenuFonts(menu:ToProxy())
end

local backdrops = {}
local function SkinFrame(frame)
	frame:StripTextures()

	if backdrops[frame] then
		frame.backdrop = backdrops[frame] -- relink it back
	else
		frame:CreateBackdrop('Transparent') -- :SetTemplate errors out
		frame.backdrop:SetInside(nil, 1, 5)

		backdrops[frame] = frame.backdrop -- keep below CreateBackdrop

		S:HandleTrimScrollBar(frame.ScrollBar)
	end

	frame.backdrop:OffsetFrameLevel(nil, frame)
end

local widgets = {}
local function SkinFrameAttachments(frame)
	if not frame.attachments then return end

	local r, g, b = unpack(E.media.rgbvaluecolor)
	for _, widget in next, frame.attachments do
		if widget:IsObjectType('Texture') then
			if widget:GetTexture() == 130940 then
				widget:SetTexture(E.Media.Textures.ArrowUp)
				widget:SetRotation(S.ArrowRotation.right)
				widget:SetVertexColor(r, g, b)
				widget:Size(12)

				widgets[widget] = true
			elseif widgets[widget] then
				widget:SetRotation(S.ArrowRotation.up)
				widgets[widget] = nil
			end
		end
	end
end

function S:SkinMenu(manager, ownerRegion, menuDescription, anchor)
	local menu = manager:GetOpenMenu()
	if not menu then return end

	SkinFrame(menu) -- Initial context menu
	menuDescription:AddMenuAcquiredCallback(SkinFrame) -- SubMenus

	if menuDescription:GetTag() == professionsRankBarMenuTag then
		SkinProfessionsMenuFonts(menu)
	end
end

function S:OpenMenu(ownerRegion, menuDescription, anchor)
	S:SkinMenu(self, ownerRegion, menuDescription, anchor) -- self is manager (Menu.GetManager)
end

function S:OpenContextMenu(ownerRegion, menuDescription)
	S:SkinMenu(self, ownerRegion, menuDescription) -- self is manager (Menu.GetManager)
end

function S:Blizzard_Menu()
	if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.misc) then return end

	local manager = _G.Menu.GetManager()
	hooksecurefunc(manager, 'OpenMenu', S.OpenMenu)
	hooksecurefunc(manager, 'OpenContextMenu', S.OpenContextMenu)
	hooksecurefunc(_G.CompositorMixin, 'AttachTexture', SkinFrameAttachments)
	hooksecurefunc(_G.MenuMixin, 'ReinitializeAll', SkinProfessionsRankBarMenu)
end

S:AddCallbackForAddon('Blizzard_Menu')
