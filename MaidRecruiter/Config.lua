-- Button lists, destinations, and the reminder interval.
local _, NS = ...

local CHANNELS = {
	{ id = "YELL", label = "Yell" },
	{ id = "SAY", label = "Say" },
	{ id = "GUILD", label = "Guild chat" },
	{ id = "CHANNEL", label = "Channel" },
}

local function ChannelChoiceLabel(channel)
	for index = 1, #CHANNELS do
		if CHANNELS[index].id == channel then
			return CHANNELS[index].label
		end
	end
	return "Yell"
end

local function ChannelHint(channel)
	if channel == "SAY" then
		return "Posts with /say."
	end
	if channel == "GUILD" then
		return "Posts in guild chat."
	end
	if channel == "CHANNEL" then
		return "Joined channel name or number."
	end
	return "Posts with /yell."
end

local function PaintCounter(counter, text)
	local count = #(text or "")
	if count > 255 then
		counter:SetText(count .. "  splits")
		counter:SetTextColor(NS.COLOR.danger[1], NS.COLOR.danger[2], NS.COLOR.danger[3])
	else
		counter:SetText(count .. " / 255")
		counter:SetTextColor(NS.COLOR.muted[1], NS.COLOR.muted[2], NS.COLOR.muted[3])
	end
end

local function ItemForRow(row)
	if row.kind == "reply" then
		return MaidRecruiterDB.quickReplies[row.index]
	end
	return MaidRecruiterDB.broadcasts[row.index]
end

local function CreateField(parent, maxLetters)
	local edit = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
	edit:SetAutoFocus(false)
	edit:SetFontObject(GameFontHighlightSmall)
	edit:SetTextInsets(6, 6, 0, 0)
	edit:SetMaxLetters(maxLetters)
	edit:SetHeight(24)
	NS:ApplyBackdrop(edit, NS.COLOR.field, NS.COLOR.panelEdge)
	edit:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	edit:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	if NS.ui and NS.ui.settingsScroll then
		NS:PassWheel(edit, NS.ui.settingsScroll)
	end
	return edit
end

local function StyleRowFields(row, kind)
	row.kind = kind
	row.labelEdit = CreateField(row, 40)
	row.textEdit = CreateField(row, NS.MAX_INPUT)
	row.counter = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	row.counter:SetJustifyH("RIGHT")
	row.delete = NS:CreatePushButton(row, "x", 24, 24)
	row.delete.tipTitle = "Remove"
	row.labelEdit.row = row
	row.textEdit.row = row
	row.delete.row = row

	row.labelEdit:SetScript("OnTextChanged", function(edit)
		if NS._fillingSettings then
			return
		end
		local item = ItemForRow(edit.row)
		if item then
			item.label = edit:GetText() or ""
		end
	end)
	row.textEdit:SetScript("OnTextChanged", function(edit)
		local text = edit:GetText() or ""
		PaintCounter(edit.row.counter, text)
		if NS._fillingSettings then
			return
		end
		local item = ItemForRow(edit.row)
		if item then
			item.text = text
		end
	end)
	row.delete:SetScript("OnClick", function(button)
		local owner = button.row
		if owner.kind == "reply" then
			table.remove(MaidRecruiterDB.quickReplies, owner.index)
		else
			table.remove(MaidRecruiterDB.broadcasts, owner.index)
		end
		NS:RebuildSettings("keep")
	end)

	if kind == "broadcast" then
		row.channelButton = NS:CreatePushButton(row, "Yell", 110, 22)
		row.channelButton.row = row
		row.channelName = CreateField(row, 32)
		row.channelName.row = row
		row.channelHint = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		row.channelHint:SetJustifyH("LEFT")
		row.channelButton:SetScript("OnClick", function(button)
			NS:ToggleChannelMenu(button)
		end)
		row.channelName:SetScript("OnTextChanged", function(edit)
			if NS._fillingSettings then
				return
			end
			local item = ItemForRow(edit.row)
			if item then
				item.channelName = edit:GetText() or ""
			end
		end)
	end
end

local function PlaceRow(row, width)
	row:SetWidth(width)
	row.labelEdit:ClearAllPoints()
	row.textEdit:ClearAllPoints()
	row.counter:ClearAllPoints()
	row.delete:ClearAllPoints()
	row.delete:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
	row.counter:SetPoint("RIGHT", row.delete, "LEFT", -6, 0)
	row.counter:SetWidth(72)
	row.labelEdit:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
	row.labelEdit:SetSize(120, 24)
	row.textEdit:SetPoint("TOPLEFT", row.labelEdit, "TOPRIGHT", 6, 0)
	row.textEdit:SetPoint("RIGHT", row.counter, "LEFT", -6, 0)
	row.textEdit:SetHeight(24)
	if row.kind == "broadcast" then
		row.channelButton:ClearAllPoints()
		row.channelName:ClearAllPoints()
		row.channelHint:ClearAllPoints()
		row.channelButton:SetPoint("TOPLEFT", row.labelEdit, "BOTTOMLEFT", 0, -4)
		row.channelName:SetPoint("LEFT", row.channelButton, "RIGHT", 6, 0)
		row.channelName:SetPoint("RIGHT", row, "RIGHT", 0, 0)
		row.channelName:SetHeight(22)
		row.channelHint:SetPoint("LEFT", row.channelButton, "RIGHT", 8, 0)
		row.channelHint:SetPoint("RIGHT", row, "RIGHT", -4, 0)
	end
end

function NS:CloseChannelMenu()
	local menu = self.ui and self.ui.channelMenu
	if not menu then
		return
	end
	menu:Hide()
	if menu.catcher then
		menu.catcher:Hide()
	end
end

function NS:ToggleChannelMenu(anchor)
	local menu = self.ui and self.ui.channelMenu
	if not menu then
		return
	end
	if menu:IsShown() and menu.anchor == anchor then
		self:CloseChannelMenu()
		return
	end
	menu.anchor = anchor
	menu:ClearAllPoints()
	menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
	menu:SetFrameStrata("FULLSCREEN_DIALOG")
	if menu.catcher then
		menu.catcher:SetFrameStrata("FULLSCREEN")
		menu.catcher:Show()
	end
	menu:Show()
end

function NS:PickChannel(channel)
	local menu = self.ui.channelMenu
	local anchor = menu and menu.anchor
	local row = anchor and anchor.row
	if not row then
		self:CloseChannelMenu()
		return
	end
	local item = ItemForRow(row)
	if item then
		item.channel = channel
	end
	row.channelButton.label:SetText(ChannelChoiceLabel(channel))
	row.channelName:SetShown(channel == "CHANNEL")
	row.channelHint:SetShown(channel ~= "CHANNEL")
	row.channelHint:SetText(ChannelHint(channel))
	self:CloseChannelMenu()
end

function NS:RebuildSettings(scrollMode)
	local ui = self.ui
	if not ui or not ui.settingsScroll then
		return
	end
	local scroller = ui.settingsScroll
	local child = scroller.child
	local keep = scroller.bar:GetValue() or 0
	local width = scroller.scroll:GetWidth()
	if not width or width < 80 then
		width = (ui.frame:GetWidth() or 680) - 48
	end
	if width < 280 then
		width = 280
	end
	child:SetWidth(width)

	local y = 4
	local function Header(text)
		local header = ui.settingHeaders[text]
		if not header then
			header = child:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			header:SetText(text)
			header:SetTextColor(NS.COLOR.accent[1], NS.COLOR.accent[2], NS.COLOR.accent[3])
			header:SetJustifyH("LEFT")
			ui.settingHeaders[text] = header
		end
		header:ClearAllPoints()
		header:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
		header:SetWidth(width)
		header:Show()
		y = y + 22
	end

	Header("Whisper buttons")
	local replyRows = ui.replyRows
	for index = 1, #MaidRecruiterDB.quickReplies do
		local item = MaidRecruiterDB.quickReplies[index]
		local row = replyRows[index]
		if not row then
			row = CreateFrame("Frame", nil, child)
			StyleRowFields(row, "reply")
			replyRows[index] = row
		end
		row.index = index
		row:Show()
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
		PlaceRow(row, width)
		row:SetHeight(28)
		NS._fillingSettings = true
		row.labelEdit:SetText(item.label or "")
		row.textEdit:SetText(item.text or "")
		NS._fillingSettings = false
		PaintCounter(row.counter, item.text or "")
		y = y + 34
	end
	for index = #MaidRecruiterDB.quickReplies + 1, #replyRows do
		replyRows[index]:Hide()
	end

	ui.addReply:ClearAllPoints()
	ui.addReply:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
	ui.addReply:Show()
	y = y + 32

	Header("Broadcast buttons")
	local castRows = ui.broadcastRows
	for index = 1, #MaidRecruiterDB.broadcasts do
		local item = MaidRecruiterDB.broadcasts[index]
		local row = castRows[index]
		if not row then
			row = CreateFrame("Frame", nil, child)
			StyleRowFields(row, "broadcast")
			castRows[index] = row
		end
		row.index = index
		row:Show()
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
		PlaceRow(row, width)
		row:SetHeight(54)
		local channel = item.channel or "YELL"
		NS._fillingSettings = true
		row.labelEdit:SetText(item.label or "")
		row.textEdit:SetText(item.text or "")
		row.channelName:SetText(item.channelName or "")
		NS._fillingSettings = false
		PaintCounter(row.counter, item.text or "")
		row.channelButton.label:SetText(ChannelChoiceLabel(channel))
		row.channelName:SetShown(channel == "CHANNEL")
		row.channelHint:SetShown(channel ~= "CHANNEL")
		row.channelHint:SetText(ChannelHint(channel))
		y = y + 60
	end
	for index = #MaidRecruiterDB.broadcasts + 1, #castRows do
		castRows[index]:Hide()
	end

	ui.addBroadcast:ClearAllPoints()
	ui.addBroadcast:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
	ui.addBroadcast:Show()
	y = y + 36

	Header("Reminder")
	ui.reminderCheck:ClearAllPoints()
	ui.reminderCheck:SetPoint("TOPLEFT", child, "TOPLEFT", -4, -y)
	ui.reminderCheck.label:ClearAllPoints()
	ui.reminderCheck.label:SetPoint("LEFT", ui.reminderCheck, "RIGHT", 2, 0)
	NS._fillingSettings = true
	ui.reminderCheck:SetChecked(MaidRecruiterDB.reminder.enabled)
	ui.reminderCheck.mark:SetShown(MaidRecruiterDB.reminder.enabled and true or false)
	NS._fillingSettings = false
	y = y + 28

	ui.minutesLabel:ClearAllPoints()
	ui.minutesLabel:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
	ui.minutesEdit:ClearAllPoints()
	ui.minutesEdit:SetPoint("LEFT", ui.minutesLabel, "RIGHT", 6, 0)
	ui.minutesSuffix:ClearAllPoints()
	ui.minutesSuffix:SetPoint("LEFT", ui.minutesEdit, "RIGHT", 6, 0)
	NS._fillingSettings = true
	ui.minutesEdit:SetText(tostring(MaidRecruiterDB.reminder.minutes or 15))
	NS._fillingSettings = false
	y = y + 28

	ui.reminderNote:ClearAllPoints()
	ui.reminderNote:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
	ui.reminderNote:SetWidth(width)
	local noteHeight = ui.reminderNote:GetStringHeight() or 0
	if noteHeight < 1 then
		noteHeight = 28
	end
	y = y + noteHeight + 10

	ui.openCheck:ClearAllPoints()
	ui.openCheck:SetPoint("TOPLEFT", child, "TOPLEFT", -4, -y)
	ui.openCheck.label:ClearAllPoints()
	ui.openCheck.label:SetPoint("LEFT", ui.openCheck, "RIGHT", 2, 0)
	NS._fillingSettings = true
	ui.openCheck:SetChecked(MaidRecruiterDB.openOnWhisper)
	ui.openCheck.mark:SetShown(MaidRecruiterDB.openOnWhisper and true or false)
	NS._fillingSettings = false
	y = y + 28

	ui.soundCheck:ClearAllPoints()
	ui.soundCheck:SetPoint("TOPLEFT", child, "TOPLEFT", -4, -y)
	ui.soundCheck.label:ClearAllPoints()
	ui.soundCheck.label:SetPoint("LEFT", ui.soundCheck, "RIGHT", 2, 0)
	NS._fillingSettings = true
	ui.soundCheck:SetChecked(MaidRecruiterDB.soundOnWhisper)
	ui.soundCheck.mark:SetShown(MaidRecruiterDB.soundOnWhisper and true or false)
	NS._fillingSettings = false
	y = y + 32

	ui.keybindNote:ClearAllPoints()
	ui.keybindNote:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
	ui.keybindNote:SetWidth(width)
	local keyHeight = ui.keybindNote:GetStringHeight() or 0
	if keyHeight < 1 then
		keyHeight = 32
	end
	y = y + keyHeight + 12

	scroller:SetContentHeight(y)
	if scrollMode == "bottom" then
		scroller:ScrollToBottom()
	elseif scrollMode == "keep" then
		local _, maxValue = scroller.bar:GetMinMaxValues()
		if keep > (maxValue or 0) then
			keep = maxValue or 0
		end
		scroller.bar:SetValue(keep)
	else
		scroller.bar:SetValue(0)
	end
end

function NS:BuildSettings(parent)
	local ui = self.ui
	self:ApplyBackdrop(parent, self.COLOR.bg, self.COLOR.edge)

	ui.settingHeaders = {}
	ui.replyRows = {}
	ui.broadcastRows = {}

	local back = self:CreatePushButton(parent, "Back", 64, 22)
	back:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8)
	back.tipTitle = "Return to the tabs"
	back:SetScript("OnClick", function()
		NS:SetSettingsOpen(false)
	end)
	local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("LEFT", back, "RIGHT", 10, 0)
	title:SetText("Settings")
	title:SetTextColor(self.COLOR.text[1], self.COLOR.text[2], self.COLOR.text[3])

	local scroller = self:CreateScroller(parent)
	scroller:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -36)
	scroller:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -6, 8)
	ui.settingsScroll = scroller

	ui.addReply = self:CreatePushButton(scroller.child, "Add whisper button", 160, 22)
	ui.addReply:SetScript("OnClick", function()
		table.insert(MaidRecruiterDB.quickReplies, { label = "New button", text = "" })
		NS:RebuildSettings("bottom")
	end)
	ui.addBroadcast = self:CreatePushButton(scroller.child, "Add broadcast button", 170, 22)
	ui.addBroadcast:SetScript("OnClick", function()
		table.insert(MaidRecruiterDB.broadcasts, { label = "New broadcast", text = "", channel = "YELL", channelName = "" })
		NS:RebuildSettings("bottom")
	end)

	local function MakeCheck(label, onClick)
		local check = CreateFrame("CheckButton", nil, scroller.child, "BackdropTemplate")
		check:SetSize(18, 18)
		NS:ApplyBackdrop(check, NS.COLOR.field, NS.COLOR.panelEdge)
		check.mark = check:CreateTexture(nil, "OVERLAY")
		check.mark:SetPoint("TOPLEFT", 3, -3)
		check.mark:SetPoint("BOTTOMRIGHT", -3, 3)
		if check.mark.SetColorTexture then
			check.mark:SetColorTexture(NS.COLOR.accent[1], NS.COLOR.accent[2], NS.COLOR.accent[3], 1)
		else
			check.mark:SetTexture("Interface/Buttons/WHITE8x8")
			check.mark:SetVertexColor(NS.COLOR.accent[1], NS.COLOR.accent[2], NS.COLOR.accent[3], 1)
		end
		check.mark:Hide()
		check:SetHitRectInsets(0, -360, 0, 0)
		check.label = scroller.child:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		check.label:SetText(label)
		check.label:SetTextColor(NS.COLOR.text[1], NS.COLOR.text[2], NS.COLOR.text[3])
		check:SetScript("OnClick", function(selfCheck)
			local on = selfCheck:GetChecked() and true or false
			selfCheck.mark:SetShown(on)
			if NS._fillingSettings then
				return
			end
			onClick(on)
		end)
		NS:PassWheel(check, scroller)
		return check
	end

	ui.reminderCheck = MakeCheck("Remind me to recruit", function(enabled)
		NS:SetReminderEnabled(enabled)
	end)
	ui.minutesLabel = scroller.child:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	ui.minutesLabel:SetText("Every")
	ui.minutesEdit = CreateField(scroller.child, 3)
	ui.minutesEdit:SetSize(40, 22)
	ui.minutesEdit:SetScript("OnTextChanged", function(edit)
		local text = edit:GetText() or ""
		local filtered = text:gsub("[^%d]", "")
		if filtered ~= text then
			edit:SetText(filtered)
			return
		end
		if NS._fillingSettings or filtered == "" then
			return
		end
		NS:SetReminderMinutes(filtered)
	end)
	ui.minutesSuffix = scroller.child:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	ui.minutesSuffix:SetText("minutes")
	ui.reminderNote = scroller.child:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	ui.reminderNote:SetJustifyH("LEFT")
	ui.reminderNote:SetWordWrap(true)
	ui.reminderNote:SetText("The strip and a sound tell you when it is time. Changing the minutes starts that wait over. Nothing is posted for you.")

	ui.openCheck = MakeCheck("Open this window when a whisper arrives", function(enabled)
		MaidRecruiterDB.openOnWhisper = enabled and true or false
	end)
	ui.soundCheck = MakeCheck("Play an extra sound on a new whisper", function(enabled)
		MaidRecruiterDB.soundOnWhisper = enabled and true or false
	end)
	ui.keybindNote = scroller.child:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	ui.keybindNote:SetJustifyH("LEFT")
	ui.keybindNote:SetWordWrap(true)
	ui.keybindNote:SetText("Keybinds: Escape, Options, Key Bindings, AddOns, Maid Recruiter. The first eight whisper buttons and the first six broadcast buttons can each take a key. The game only accepts yell and channel posts from a click or a key press.")

	local catcher = CreateFrame("Button", nil, UIParent)
	catcher:SetAllPoints(UIParent)
	catcher:SetFrameStrata("FULLSCREEN")
	catcher:EnableMouse(true)
	catcher:Hide()
	catcher:SetScript("OnClick", function()
		NS:CloseChannelMenu()
	end)

	local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	menu:SetSize(140, 104)
	menu:Hide()
	menu.catcher = catcher
	self:ApplyBackdrop(menu, self.COLOR.bg, self.COLOR.accent)
	menu:SetFrameStrata("FULLSCREEN_DIALOG")
	for index = 1, #CHANNELS do
		local choice = CHANNELS[index]
		local button = self:CreatePushButton(menu, choice.label, 128, 22)
		button:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -6 - ((index - 1) * 24))
		button:SetScript("OnClick", function()
			NS:PickChannel(choice.id)
		end)
	end
	ui.channelMenu = menu

	self:PassWheel(scroller.child, scroller)
end
