-- Window, whisper tabs, broadcast list, and the side buttons.
local _, NS = ...

NS.COLOR = {
	bg = { 0.07, 0.06, 0.09, 0.97 },
	edge = { 0.62, 0.34, 0.48, 1 },
	panel = { 0.12, 0.09, 0.13, 1 },
	panelEdge = { 0.40, 0.24, 0.32, 1 },
	button = { 0.22, 0.13, 0.18, 1 },
	buttonHot = { 0.38, 0.18, 0.28, 1 },
	buttonDown = { 0.14, 0.08, 0.11, 1 },
	field = { 0.05, 0.04, 0.06, 1 },
	accent = { 0.95, 0.55, 0.72, 1 },
	gold = { 0.95, 0.82, 0.45, 1 },
	text = { 0.96, 0.93, 0.94, 1 },
	muted = { 0.68, 0.62, 0.66, 1 },
	danger = { 1, 0.45, 0.42, 1 },
}

function NS:ApplyBackdrop(frame, bg, edge)
	if not frame or not frame.SetBackdrop then
		return
	end
	local ok = pcall(frame.SetBackdrop, frame, {
		bgFile = "Interface/Buttons/WHITE8x8",
		edgeFile = "Interface/Buttons/WHITE8x8",
		edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	if not ok then
		return
	end
	frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
	frame:SetBackdropBorderColor(edge[1], edge[2], edge[3], edge[4] or 1)
end

function NS:CreateScroller(parent)
	local holder = CreateFrame("Frame", nil, parent)
	local scroll = CreateFrame("ScrollFrame", nil, holder)
	scroll:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
	scroll:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -14, 0)
	local child = CreateFrame("Frame", nil, scroll)
	child:SetSize(10, 10)
	scroll:SetScrollChild(child)

	local bar = CreateFrame("Slider", nil, holder)
	bar:SetOrientation("VERTICAL")
	bar:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, -2)
	bar:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, 2)
	bar:SetWidth(10)
	bar:SetValueStep(1)
	if bar.SetObeyStepOnDrag then
		bar:SetObeyStepOnDrag(true)
	end
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	bar:SetThumbTexture("Interface/Buttons/WHITE8x8")
	local thumb = bar:GetThumbTexture()
	if thumb then
		thumb:SetVertexColor(0.95, 0.55, 0.72, 0.95)
		thumb:SetSize(10, 28)
	end

	holder.scroll = scroll
	holder.child = child
	holder.bar = bar

	bar:SetScript("OnValueChanged", function(_, value)
		scroll:SetVerticalScroll(value or 0)
	end)

	local function OnWheel(_, delta)
		local _, maxValue = bar:GetMinMaxValues()
		if not maxValue or maxValue <= 0 then
			return
		end
		local nextValue = (bar:GetValue() or 0) - (delta * 36)
		if nextValue < 0 then
			nextValue = 0
		end
		if nextValue > maxValue then
			nextValue = maxValue
		end
		bar:SetValue(nextValue)
	end
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", OnWheel)
	holder:EnableMouseWheel(true)
	holder:SetScript("OnMouseWheel", OnWheel)
	child:EnableMouse(true)
	child:EnableMouseWheel(true)
	child:SetScript("OnMouseWheel", OnWheel)

	function holder:SetContentHeight(height)
		local viewW = scroll:GetWidth()
		local viewH = scroll:GetHeight()
		if not viewW or viewW < 1 then
			viewW = 1
		end
		if not viewH or viewH < 1 then
			viewH = 1
		end
		child:SetWidth(viewW)
		child:SetHeight(math.max(height or 1, 1))
		local maxValue = math.max(0, (height or 1) - viewH)
		if maxValue < 1 then
			bar:SetMinMaxValues(0, 1)
			bar:SetValue(0)
			bar:Hide()
		else
			bar:Show()
			bar:SetMinMaxValues(0, maxValue)
			local value = bar:GetValue() or 0
			if value > maxValue then
				bar:SetValue(maxValue)
			elseif value < 0 then
				bar:SetValue(0)
			end
		end
	end

	function holder:ScrollToBottom()
		local _, maxValue = bar:GetMinMaxValues()
		if maxValue and maxValue > 0 then
			bar:SetValue(maxValue)
		end
	end

	return holder
end

function NS:PassWheel(widget, scroller)
	widget:EnableMouseWheel(true)
	widget:SetScript("OnMouseWheel", function(_, delta)
		local handler = scroller.scroll:GetScript("OnMouseWheel")
		if handler then
			handler(scroller.scroll, delta)
		end
	end)
end

function NS:CreatePushButton(parent, label, width, height)
	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
	button:SetSize(width or 80, height or 24)
	self:ApplyBackdrop(button, self.COLOR.button, self.COLOR.panelEdge)
	button:RegisterForClicks("AnyUp")
	button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.label:SetPoint("LEFT", 6, 0)
	button.label:SetPoint("RIGHT", -6, 0)
	button.label:SetJustifyH("CENTER")
	button.label:SetWordWrap(false)
	button.label:SetText(label or "")
	button:SetScript("OnEnter", function(selfButton)
		NS:ApplyBackdrop(selfButton, NS.COLOR.buttonHot, NS.COLOR.accent)
		if selfButton.tipTitle then
			GameTooltip:SetOwner(selfButton, selfButton.tipAnchor or "ANCHOR_LEFT")
			GameTooltip:SetText(selfButton.tipTitle, 1, 0.86, 0.91)
			if selfButton.tipBody and selfButton.tipBody ~= "" then
				GameTooltip:AddLine(selfButton.tipBody, 1, 1, 1, true)
			end
			if selfButton.tipExtra then
				GameTooltip:AddLine(selfButton.tipExtra, 0.7, 0.7, 0.7, true)
			end
			GameTooltip:Show()
		end
	end)
	button:SetScript("OnLeave", function(selfButton)
		NS:ApplyBackdrop(selfButton, NS.COLOR.button, NS.COLOR.panelEdge)
		GameTooltip:Hide()
	end)
	button:SetScript("OnMouseDown", function(selfButton)
		NS:ApplyBackdrop(selfButton, NS.COLOR.buttonDown, NS.COLOR.accent)
	end)
	button:SetScript("OnMouseUp", function(selfButton)
		NS:ApplyBackdrop(selfButton, NS.COLOR.buttonHot, NS.COLOR.accent)
	end)
	return button
end

local function MeasuredHeight(fontString, fallbackText, width)
	local height = fontString:GetStringHeight() or 0
	if height >= 1 then
		return height
	end
	local perLine = math.max(math.floor((width or 100) / 7), 1)
	local length = #(fallbackText or "")
	if length < 1 then
		length = 1
	end
	return math.max(16, math.ceil(length / perLine) * 16)
end

function NS:SaveWindowPosition()
	local ui = self.ui
	if not ui then
		return
	end
	local frame = ui.frame
	local point, _, rel, x, y = frame:GetPoint(1)
	if type(point) == "string" then
		MaidRecruiterDB.window.point = point
		MaidRecruiterDB.window.rel = type(rel) == "string" and rel or point
		MaidRecruiterDB.window.x = x or 0
		MaidRecruiterDB.window.y = y or 0
	end
	if frame.collapsed then
		return
	end
	local width, height = frame:GetSize()
	if width and width >= 560 and height and height >= 340 then
		MaidRecruiterDB.window.width = width
		MaidRecruiterDB.window.height = height
	end
end

function NS:ApplyStatus()
	local ui = self.ui
	if not ui or not ui.status then
		return
	end
	ui.status:SetText(self.statusText or "")
	if self.statusIsError then
		ui.status:SetTextColor(self.COLOR.danger[1], self.COLOR.danger[2], self.COLOR.danger[3])
	else
		ui.status:SetTextColor(self.COLOR.muted[1], self.COLOR.muted[2], self.COLOR.muted[3])
	end
end

function NS:IsTyping()
	return self.ui and self.ui.replyEdit and self.ui.replyEdit:HasFocus()
end

function NS:FocusReply()
	if self.ui and self.ui.replyEdit and self.ui.replyEdit:IsVisible() then
		self.ui.replyEdit:SetFocus()
	end
end

function NS:RefreshReplyBox()
	local edit = self.ui and self.ui.replyEdit
	if not edit then
		return
	end
	local active = MaidRecruiterDB.activeTab
	local draft = ""
	if active and active ~= "BROADCAST" then
		draft = self:GetConversation(active).draft or ""
	end
	if edit:GetText() ~= draft then
		self._fillingReply = true
		edit:SetText(draft)
		self._fillingReply = false
	end
	if edit.placeholder then
		edit.placeholder:SetShown(draft == "")
	end
end

function NS:UpdateReminderStrip()
	local ui = self.ui
	if not ui or not ui.reminder then
		return
	end
	ui.reminder.text:SetText("Time to recruit.")
end

local function SetTabOffset(ui, offset)
	ui.tabContent.offset = offset
	ui.tabContent:ClearAllPoints()
	ui.tabContent:SetPoint("TOPLEFT", ui.tabClip, "TOPLEFT", offset, 0)
	ui.tabContent:SetPoint("BOTTOMLEFT", ui.tabClip, "BOTTOMLEFT", offset, 0)
end

function NS:CreateTabButton(parent)
	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
	button:SetHeight(26)
	self:ApplyBackdrop(button, self.COLOR.button, self.COLOR.panelEdge)
	button:RegisterForClicks("LeftButtonUp")
	button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.label:SetJustifyH("CENTER")
	button.label:SetWordWrap(false)
	button.bar = button:CreateTexture(nil, "OVERLAY")
	button.bar:SetPoint("BOTTOMLEFT", 4, 1)
	button.bar:SetPoint("BOTTOMRIGHT", -4, 1)
	button.bar:SetHeight(2)
	if button.bar.SetColorTexture then
		button.bar:SetColorTexture(self.COLOR.accent[1], self.COLOR.accent[2], self.COLOR.accent[3], 1)
	else
		button.bar:SetTexture("Interface/Buttons/WHITE8x8")
		button.bar:SetVertexColor(self.COLOR.accent[1], self.COLOR.accent[2], self.COLOR.accent[3], 1)
	end
	button.bar:Hide()
	local close = CreateFrame("Button", nil, button)
	close:SetSize(16, 16)
	close:SetPoint("RIGHT", -3, 0)
	close.text = close:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	close.text:SetAllPoints()
	close.text:SetText("x")
	close:SetScript("OnClick", function(selfButton)
		local tabId = selfButton:GetParent().id
		if tabId and tabId ~= "BROADCAST" then
			NS:CloseTab(tabId)
		end
	end)
	close:SetScript("OnEnter", function(selfButton)
		GameTooltip:SetOwner(selfButton, "ANCHOR_TOP")
		GameTooltip:SetText("Close this whisper")
		GameTooltip:Show()
	end)
	close:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	button.close = close
	button:SetScript("OnClick", function(selfButton)
		if selfButton.id then
			NS:SelectTab(selfButton.id)
		end
	end)
	button:SetScript("OnEnter", function(selfButton)
		if selfButton.tipTitle then
			GameTooltip:SetOwner(selfButton, "ANCHOR_TOP")
			GameTooltip:SetText(selfButton.tipTitle, 1, 0.86, 0.91)
			if selfButton.tipBody then
				GameTooltip:AddLine(selfButton.tipBody, 0.75, 0.75, 0.75, true)
			end
			GameTooltip:Show()
		end
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	return button
end

function NS:RenderTabs()
	local ui = self.ui
	local specs = {
		{ id = "BROADCAST", label = "Broadcast", closable = false },
	}
	local order = MaidRecruiterDB.tabOrder
	for index = 1, #order do
		local name = order[index]
		local convo = MaidRecruiterDB.conversations[name]
		specs[#specs + 1] = {
			id = name,
			label = self:ShortName(name),
			closable = true,
			unread = convo and convo.unread or false,
		}
	end

	local x = 0
	for index = 1, #specs do
		local spec = specs[index]
		local button = ui.tabButtons[index]
		if not button then
			button = self:CreateTabButton(ui.tabContent)
			ui.tabButtons[index] = button
		end
		button:Show()
		button.id = spec.id
		local text = spec.label
		if spec.unread and spec.id ~= MaidRecruiterDB.activeTab then
			text = "* " .. text
		end
		button.label:SetText(text)
		button.close:SetShown(spec.closable)
		local textWidth
		if button.label.GetUnboundedStringWidth then
			textWidth = button.label:GetUnboundedStringWidth()
		else
			textWidth = button.label:GetStringWidth()
		end
		textWidth = textWidth or 40
		local width = textWidth + (spec.closable and 28 or 16)
		if width < 84 then
			width = 84
		end
		if width > 180 then
			width = 180
		end
		button:SetWidth(width)
		button:ClearAllPoints()
		button:SetPoint("LEFT", ui.tabContent, "LEFT", x, 0)
		button.label:ClearAllPoints()
		button.label:SetPoint("LEFT", 8, 0)
		if spec.closable then
			button.label:SetPoint("RIGHT", button.close, "LEFT", -2, 0)
		else
			button.label:SetPoint("RIGHT", button, "RIGHT", -8, 0)
		end
		x = x + width + 4
		local active = MaidRecruiterDB.activeTab == spec.id
		if active then
			self:ApplyBackdrop(button, self.COLOR.buttonHot, self.COLOR.accent)
			button.bar:Show()
		else
			self:ApplyBackdrop(button, self.COLOR.button, self.COLOR.panelEdge)
			button.bar:Hide()
		end
		if spec.unread and not active then
			button.label:SetTextColor(self.COLOR.gold[1], self.COLOR.gold[2], self.COLOR.gold[3])
		else
			button.label:SetTextColor(self.COLOR.text[1], self.COLOR.text[2], self.COLOR.text[3])
		end
		if spec.id == "BROADCAST" then
			button.tipTitle = "Broadcast"
			button.tipBody = "Saved lines for yell, guild, and recruit channels."
		else
			button.tipTitle = spec.id
			button.tipBody = spec.unread and "Unread whisper." or nil
		end
	end
	for index = #specs + 1, #ui.tabButtons do
		ui.tabButtons[index]:Hide()
	end
	ui.tabContent:SetWidth(math.max(x, 1))

	local clipWidth = ui.tabClip:GetWidth() or 0
	if clipWidth > 0 then
		local minOffset = math.min(0, clipWidth - ui.tabContent:GetWidth())
		local offset = ui.tabContent.offset or 0
		if offset > 0 then
			offset = 0
		end
		if offset < minOffset then
			offset = minOffset
		end
		SetTabOffset(ui, offset)
	end
end

function NS:RenderLines()
	local ui = self.ui
	local full = MaidRecruiterDB.activeTab
	if not full or full == "BROADCAST" then
		return
	end
	local convo = self:GetConversation(full)
	local lines = convo.lines
	local child = ui.history.child
	local width = ui.history.scroll:GetWidth()
	if not width or width < 40 then
		width = child:GetWidth()
	end
	if not width or width < 40 then
		width = 200
	end
	child:SetWidth(width)
	ui.historyEmpty:SetShown(#lines == 0)
	ui.historyEmpty:ClearAllPoints()
	ui.historyEmpty:SetPoint("TOPLEFT", child, "TOPLEFT", 4, -8)
	ui.historyEmpty:SetWidth(math.max(width - 8, 40))

	local y = 6
	for index = 1, #lines do
		local row = ui.linePool[index]
		if not row then
			row = CreateFrame("Frame", nil, child, "BackdropTemplate")
			self:ApplyBackdrop(row, self.COLOR.panel, self.COLOR.panelEdge)
			row.text = row:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
			row.text:SetJustifyH("LEFT")
			row.text:SetJustifyV("TOP")
			row.text:SetWordWrap(true)
			row.text:SetPoint("TOPLEFT", 6, -4)
			ui.linePool[index] = row
		end
		local line = lines[index]
		row:Show()
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
		row:SetPoint("TOPRIGHT", child, "TOPRIGHT", 0, -y)
		local who = line.from == "out" and "You" or self:ShortName(full)
		local stamp = date("%H:%M", line.time or time())
		local nameColor = line.from == "out" and "7dffb3" or "ffd0e4"
		local body = line.text or ""
		row.text:SetText(string.format("|cff9a9398%s|r  |cff%s%s:|r  %s", stamp, nameColor, who, body))
		local textWidth = width - 16
		if textWidth < 20 then
			textWidth = 20
		end
		row.text:SetWidth(textWidth)
		local height = MeasuredHeight(row.text, body, textWidth)
		row:SetHeight(height + 10)
		y = y + height + 16
	end
	for index = #lines + 1, #ui.linePool do
		ui.linePool[index]:Hide()
	end
	if #lines == 0 then
		y = 36
	end
	ui.history:SetContentHeight(y + 8)
	if self._scrollHistory then
		self._scrollHistory = false
		ui.history:ScrollToBottom()
		if C_Timer and C_Timer.After then
			C_Timer.After(0, function()
				if ui.history:IsShown() then
					ui.history:ScrollToBottom()
				end
			end)
		end
	end
end

function NS:CreateBroadcastCard(parent)
	local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
	card:RegisterForClicks("LeftButtonUp")
	self:ApplyBackdrop(card, self.COLOR.panel, self.COLOR.panelEdge)
	card.channel = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	card.channel:SetPoint("TOPLEFT", 8, -8)
	card.channel:SetWidth(100)
	card.channel:SetJustifyH("LEFT")
	card.channel:SetTextColor(self.COLOR.gold[1], self.COLOR.gold[2], self.COLOR.gold[3])
	card.title = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	card.title:SetPoint("LEFT", card.channel, "RIGHT", 6, 0)
	card.title:SetJustifyH("LEFT")
	card.title:SetWordWrap(false)
	card.send = self:CreatePushButton(card, "Send", 58, 22)
	card.send:SetPoint("TOPRIGHT", -6, -6)
	card.title:SetPoint("RIGHT", card.send, "LEFT", -8, 0)
	card.body = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	card.body:SetPoint("TOPLEFT", 8, -32)
	card.body:SetJustifyH("LEFT")
	card.body:SetJustifyV("TOP")
	card.body:SetWordWrap(true)
	card.body:SetTextColor(self.COLOR.text[1], self.COLOR.text[2], self.COLOR.text[3])
	card:SetScript("OnClick", function(selfCard)
		if selfCard.index then
			NS:SendBroadcast(selfCard.index)
		end
	end)
	card.send:SetScript("OnClick", function(selfButton)
		local owner = selfButton:GetParent()
		if owner.index then
			NS:SendBroadcast(owner.index)
		end
	end)
	card:SetScript("OnEnter", function(selfCard)
		NS:ApplyBackdrop(selfCard, self.COLOR.button, self.COLOR.accent)
	end)
	card:SetScript("OnLeave", function(selfCard)
		NS:ApplyBackdrop(selfCard, NS.COLOR.panel, NS.COLOR.panelEdge)
	end)
	return card
end

function NS:RenderBroadcast()
	local ui = self.ui
	local child = ui.broadcast.child
	local width = ui.broadcast.scroll:GetWidth()
	if not width or width < 40 then
		width = 200
	end
	child:SetWidth(width)
	ui.broadcastHint:ClearAllPoints()
	ui.broadcastHint:SetPoint("TOPLEFT", child, "TOPLEFT", 2, -4)
	ui.broadcastHint:SetWidth(math.max(width - 8, 40))
	local hintHeight = MeasuredHeight(ui.broadcastHint, ui.broadcastHint:GetText(), width - 8)
	local y = hintHeight + 14
	local list = MaidRecruiterDB.broadcasts
	ui.broadcastEmpty:SetShown(#list == 0)
	ui.broadcastEmpty:ClearAllPoints()
	ui.broadcastEmpty:SetPoint("TOPLEFT", child, "TOPLEFT", 2, -y)
	ui.broadcastEmpty:SetWidth(math.max(width - 8, 40))
	if #list == 0 then
		y = y + 24
	end
	for index = 1, #list do
		local item = list[index]
		local card = ui.cardPool[index]
		if not card then
			card = self:CreateBroadcastCard(child)
			ui.cardPool[index] = card
		end
		card.index = index
		card:Show()
		card:ClearAllPoints()
		card:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
		card:SetPoint("TOPRIGHT", child, "TOPRIGHT", 0, -y)
		card.channel:SetText(self:ChannelLabel(item))
		local label = item.label
		if not label or label == "" then
			label = "Broadcast " .. index
		end
		card.title:SetText(label)
		local body = item.text
		if not body or body == "" then
			body = "(empty)"
		end
		card.body:SetText(body)
		local textWidth = width - 20
		if textWidth < 20 then
			textWidth = 20
		end
		card.body:SetWidth(textWidth)
		local bodyHeight = MeasuredHeight(card.body, body, textWidth)
		card:SetHeight(bodyHeight + 44)
		y = y + bodyHeight + 52
	end
	for index = #list + 1, #ui.cardPool do
		ui.cardPool[index]:Hide()
	end
	ui.broadcast:SetContentHeight(y + 8)
end

function NS:RenderSideButtons()
	local ui = self.ui
	local active = MaidRecruiterDB.activeTab
	local broadcastTab = (not active) or active == "BROADCAST"
	local list = broadcastTab and MaidRecruiterDB.broadcasts or MaidRecruiterDB.quickReplies
	local kind = broadcastTab and "broadcast" or "reply"
	ui.railTitle:SetText(broadcastTab and "Broadcast" or "Quick replies")
	if broadcastTab then
		ui.railHint:SetText("Click a button to post.")
	else
		ui.railHint:SetText("Click sends. Shift-click loads the box.")
	end

	local child = ui.railScroll.child
	local width = ui.railScroll.scroll:GetWidth()
	if not width or width < 20 then
		width = 130
	end
	child:SetWidth(width)
	ui.railEmpty:SetShown(#list == 0)
	local y = 2
	for index = 1, #list do
		local item = list[index]
		local button = ui.sideButtons[index]
		if not button then
			button = self:CreatePushButton(child, "", 120, 28)
			button:SetScript("OnClick", function(selfButton, mouseButton)
				if mouseButton == "RightButton" then
					return
				end
				if selfButton.kind == "reply" and IsShiftKeyDown() then
					NS:PasteQuickReply(selfButton.index)
				elseif selfButton.kind == "reply" then
					NS:SendQuickReply(selfButton.index)
				else
					NS:SendBroadcast(selfButton.index)
				end
			end)
			ui.sideButtons[index] = button
		end
		button.kind = kind
		button.index = index
		button:Show()
		local label = item.label
		if not label or label == "" then
			label = "Button " .. index
		end
		button.label:SetText(label)
		button:SetAlpha((not item.text or item.text == "") and 0.45 or 1)
		button.tipTitle = label
		button.tipBody = item.text or ""
		local slotNote = nil
		if kind == "reply" and index <= self.REPLY_BINDS then
			slotNote = "Click sends this whisper. Shift-click puts it in the box. Keybind slot " .. index .. "."
		elseif kind == "broadcast" and index <= self.BROADCAST_BINDS then
			slotNote = "Click sends to " .. self:ChannelLabel(item) .. ". Keybind slot " .. index .. "."
		elseif kind == "broadcast" then
			slotNote = "Click sends to " .. self:ChannelLabel(item) .. "."
		else
			slotNote = "Click sends this whisper. Shift-click puts it in the box."
		end
		button.tipExtra = slotNote
		button.tipAnchor = "ANCHOR_LEFT"
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
		button:SetPoint("TOPRIGHT", child, "TOPRIGHT", 0, -y)
		button:SetHeight(28)
		y = y + 32
	end
	for index = #list + 1, #ui.sideButtons do
		ui.sideButtons[index]:Hide()
	end
	if #list == 0 then
		y = 36
	end
	ui.railScroll:SetContentHeight(y)
end

function NS:Layout()
	local ui = self.ui
	local frame = ui.frame
	if frame.collapsed then
		return
	end
	local active = MaidRecruiterDB.activeTab
	local whisper = active and active ~= "BROADCAST" and not self.settingsOpen
	local due = MaidRecruiterDB.reminder.enabled and MaidRecruiterDB.reminderDue
	local bottom = 8

	ui.status:ClearAllPoints()
	ui.status:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, bottom)
	ui.status:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, bottom)
	bottom = bottom + 18

	ui.reminder:SetShown(due and true or false)
	if due then
		ui.reminder:ClearAllPoints()
		ui.reminder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, bottom)
		ui.reminder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, bottom)
		ui.reminder:SetHeight(30)
		bottom = bottom + 36
	end

	ui.replyBar:SetShown(whisper and true or false)
	if whisper then
		ui.replyBar:ClearAllPoints()
		ui.replyBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, bottom)
		ui.replyBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, bottom)
		ui.replyBar:SetHeight(32)
		bottom = bottom + 38
	end

	ui.body:ClearAllPoints()
	ui.body:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -68)
	ui.body:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, bottom)

	ui.rail:ClearAllPoints()
	ui.rail:SetPoint("TOPRIGHT", ui.body, "TOPRIGHT", 0, 0)
	ui.rail:SetPoint("BOTTOMRIGHT", ui.body, "BOTTOMRIGHT", 0, 0)
	ui.rail:SetWidth(158)

	ui.mainPane:ClearAllPoints()
	ui.mainPane:SetPoint("TOPLEFT", ui.body, "TOPLEFT", 0, 0)
	ui.mainPane:SetPoint("BOTTOMRIGHT", ui.rail, "BOTTOMLEFT", -8, 0)
end

function NS:Refresh()
	local ui = self.ui
	if not ui then
		return
	end
	local frame = ui.frame
	local collapsed = frame.collapsed and true or false
	ui.tabClip:SetShown(not collapsed)
	ui.body:SetShown(not collapsed)
	ui.status:SetShown(not collapsed)
	ui.grip:SetShown(not collapsed)
	if collapsed then
		ui.replyBar:Hide()
		ui.reminder:Hide()
		ui.settings:Hide()
		return
	end

	self:Layout()
	self:RenderTabs()
	local active = MaidRecruiterDB.activeTab
	local settings = self.settingsOpen and true or false
	local whisper = active and active ~= "BROADCAST" and not settings
	local broadcast = (not whisper) and not settings
	ui.history:SetShown(whisper and true or false)
	ui.broadcast:SetShown(broadcast and true or false)
	ui.rail:SetShown(not settings)
	ui.settings:SetShown(settings)
	if whisper then
		self:RenderLines()
		self:RefreshReplyBox()
	elseif broadcast then
		self:RenderBroadcast()
	end
	if not settings then
		self:RenderSideButtons()
	end
	self:UpdateReminderStrip()
	self:ApplyStatus()
end

function NS:SetCollapsed(collapsed)
	local frame = self.ui and self.ui.frame
	if not frame or (frame.collapsed and true or false) == (collapsed and true or false) then
		return
	end
	if collapsed then
		self:SaveWindowPosition()
		self._sizing = true
		frame.collapsed = true
		frame:SetHeight(36)
		self._sizing = false
		self.ui.minButton.label:SetText("+")
	else
		self._sizing = true
		frame.collapsed = false
		frame:SetHeight(MaidRecruiterDB.window.height or 460)
		self._sizing = false
		self.ui.minButton.label:SetText("_")
	end
	self:Refresh()
end

function NS:SetSettingsOpen(open)
	open = open and true or false
	if open == (self.settingsOpen and true or false) then
		if self.ui and self.ui.settings then
			self.ui.settings:SetShown(open and self.ui.frame:IsShown() and not self.ui.frame.collapsed)
		end
		return
	end
	self.settingsOpen = open
	if open and self.RebuildSettings then
		self:RebuildSettings("top")
	end
	if self.CloseChannelMenu then
		self:CloseChannelMenu()
	end
	if self.ui then
		self:Refresh()
	end
end

function NS:ShowWindow()
	self:InitDB()
	self:BuildUI()
	local frame = self.ui.frame
	self._sizing = true
	frame.collapsed = false
	frame:SetSize(MaidRecruiterDB.window.width, MaidRecruiterDB.window.height)
	self._sizing = false
	self.ui.minButton.label:SetText("_")
	frame:Show()
	self:Refresh()
end

function NS:ToggleWindow()
	self:BuildUI()
	local frame = self.ui.frame
	if frame:IsShown() and not frame.collapsed then
		frame:Hide()
	else
		self:ShowWindow()
	end
end

function NS:BuildUI()
	if self.ui then
		return
	end
	self:InitDB()
	local ui = {}
	self.ui = ui
	ui.tabButtons = {}
	ui.linePool = {}
	ui.cardPool = {}
	ui.sideButtons = {}

	local frame = CreateFrame("Frame", "MaidRecruiterFrame", UIParent, "BackdropTemplate")
	ui.frame = frame
	frame.collapsed = false
	self:ApplyBackdrop(frame, self.COLOR.bg, self.COLOR.edge)
	frame:SetFrameStrata("HIGH")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
	frame:EnableMouse(true)
	if frame.SetResizeBounds then
		frame:SetResizeBounds(560, 340, 1200, 900)
	elseif frame.SetMinResize and frame.SetMaxResize then
		frame:SetMinResize(560, 340)
		frame:SetMaxResize(1200, 900)
	end
	self._sizing = true
	frame:SetSize(MaidRecruiterDB.window.width, MaidRecruiterDB.window.height)
	frame:ClearAllPoints()
	local placed = pcall(frame.SetPoint, frame, MaidRecruiterDB.window.point, UIParent, MaidRecruiterDB.window.rel, MaidRecruiterDB.window.x, MaidRecruiterDB.window.y)
	if not placed then
		frame:ClearAllPoints()
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
	frame:Hide()
	self._sizing = false

	local title = CreateFrame("Frame", nil, frame)
	title:SetPoint("TOPLEFT", 8, -6)
	title:SetPoint("TOPRIGHT", -8, -6)
	title:SetHeight(28)
	title:EnableMouse(true)
	title:RegisterForDrag("LeftButton")
	title:SetScript("OnDragStart", function()
		frame:StartMoving()
	end)
	title:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
		self:SaveWindowPosition()
	end)
	ui.title = title

	local titleText = title:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	titleText:SetPoint("LEFT", 6, 0)
	titleText:SetJustifyH("LEFT")
	titleText:SetWordWrap(false)
	titleText:SetText("Maid Recruiter")
	titleText:SetTextColor(self.COLOR.accent[1], self.COLOR.accent[2], self.COLOR.accent[3])
	ui.titleText = titleText

	ui.closeButton = self:CreatePushButton(title, "X", 26, 22)
	ui.closeButton:SetPoint("RIGHT", 0, 0)
	ui.closeButton.tipTitle = "Close"
	ui.closeButton:SetScript("OnClick", function()
		frame:Hide()
	end)

	ui.minButton = self:CreatePushButton(title, "_", 26, 22)
	ui.minButton:SetPoint("RIGHT", ui.closeButton, "LEFT", -4, 0)
	ui.minButton.tipTitle = "Collapse"
	ui.minButton:SetScript("OnClick", function()
		self:SetCollapsed(not frame.collapsed)
	end)

	ui.settingsButton = self:CreatePushButton(title, "Settings", 78, 22)
	ui.settingsButton:SetPoint("RIGHT", ui.minButton, "LEFT", -4, 0)
	ui.settingsButton.tipTitle = "Edit buttons and the reminder"
	ui.settingsButton:SetScript("OnClick", function()
		self:SetSettingsOpen(not self.settingsOpen)
	end)
	ui.titleText:SetPoint("RIGHT", ui.settingsButton, "LEFT", -8, 0)

	ui.tabClip = CreateFrame("Frame", nil, frame)
	ui.tabClip:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -38)
	ui.tabClip:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -38)
	ui.tabClip:SetHeight(28)
	if ui.tabClip.SetClipsChildren then
		ui.tabClip:SetClipsChildren(true)
	end
	ui.tabClip:EnableMouseWheel(true)
	ui.tabContent = CreateFrame("Frame", nil, ui.tabClip)
	ui.tabContent:SetHeight(26)
	SetTabOffset(ui, 0)
	ui.tabClip:SetScript("OnMouseWheel", function(_, delta)
		local offset = (ui.tabContent.offset or 0) + (delta * 48)
		local minOffset = math.min(0, (ui.tabClip:GetWidth() or 0) - (ui.tabContent:GetWidth() or 0))
		if offset > 0 then
			offset = 0
		end
		if offset < minOffset then
			offset = minOffset
		end
		SetTabOffset(ui, offset)
	end)

	ui.body = CreateFrame("Frame", nil, frame)
	ui.mainPane = CreateFrame("Frame", nil, ui.body)
	ui.rail = CreateFrame("Frame", nil, ui.body, "BackdropTemplate")
	self:ApplyBackdrop(ui.rail, self.COLOR.panel, self.COLOR.panelEdge)
	ui.railTitle = ui.rail:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	ui.railTitle:SetPoint("TOPLEFT", 6, -4)
	ui.railTitle:SetPoint("TOPRIGHT", -6, -4)
	ui.railTitle:SetJustifyH("LEFT")
	ui.railTitle:SetText("Quick replies")
	ui.railHint = ui.rail:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	ui.railHint:SetPoint("TOPLEFT", 6, -18)
	ui.railHint:SetPoint("TOPRIGHT", -6, -18)
	ui.railHint:SetJustifyH("LEFT")
	ui.railHint:SetWordWrap(false)
	ui.railScroll = self:CreateScroller(ui.rail)
	ui.railScroll:SetPoint("TOPLEFT", ui.rail, "TOPLEFT", 6, -34)
	ui.railScroll:SetPoint("BOTTOMRIGHT", ui.rail, "BOTTOMRIGHT", -4, 6)
	ui.railEmpty = ui.railScroll.child:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	ui.railEmpty:SetPoint("TOPLEFT", 0, 0)
	ui.railEmpty:SetPoint("TOPRIGHT", 0, 0)
	ui.railEmpty:SetJustifyH("LEFT")
	ui.railEmpty:SetWordWrap(true)
	ui.railEmpty:SetText("Add buttons in Settings.")

	ui.history = self:CreateScroller(ui.mainPane)
	ui.history:SetAllPoints(ui.mainPane)
	ui.historyEmpty = ui.history.child:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	ui.historyEmpty:SetJustifyH("LEFT")
	ui.historyEmpty:SetWordWrap(true)
	ui.historyEmpty:SetText("No messages in this tab yet.")

	ui.broadcast = self:CreateScroller(ui.mainPane)
	ui.broadcast:SetAllPoints(ui.mainPane)
	ui.broadcastHint = ui.broadcast.child:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	ui.broadcastHint:SetJustifyH("LEFT")
	ui.broadcastHint:SetJustifyV("TOP")
	ui.broadcastHint:SetWordWrap(true)
	ui.broadcastHint:SetText("Whispers you receive show up as tabs. Click a message to post it. Nothing sends on its own.")
	ui.broadcastEmpty = ui.broadcast.child:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	ui.broadcastEmpty:SetJustifyH("LEFT")
	ui.broadcastEmpty:SetWordWrap(true)
	ui.broadcastEmpty:SetText("Add a broadcast in Settings.")

	ui.replyBar = CreateFrame("Frame", nil, frame)
	ui.sendButton = self:CreatePushButton(ui.replyBar, "Send", 72, 30)
	ui.sendButton:SetPoint("RIGHT", ui.replyBar, "RIGHT", 0, 0)
	ui.sendButton.tipTitle = "Send this whisper"
	ui.replyEdit = CreateFrame("EditBox", nil, ui.replyBar, "BackdropTemplate")
	ui.replyEdit:SetPoint("LEFT", ui.replyBar, "LEFT", 0, 0)
	ui.replyEdit:SetPoint("RIGHT", ui.sendButton, "LEFT", -6, 0)
	ui.replyEdit:SetHeight(30)
	ui.replyEdit:SetAutoFocus(false)
	ui.replyEdit:SetFontObject(ChatFontNormal)
	ui.replyEdit:SetTextInsets(8, 8, 0, 0)
	ui.replyEdit:SetMaxLetters(self.MAX_INPUT)
	self:ApplyBackdrop(ui.replyEdit, self.COLOR.field, self.COLOR.panelEdge)
	ui.replyEdit.placeholder = ui.replyEdit:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	ui.replyEdit.placeholder:SetPoint("LEFT", 10, 0)
	ui.replyEdit.placeholder:SetText("Write a whisper")
	ui.replyEdit:SetScript("OnEnterPressed", function(edit)
		local active = MaidRecruiterDB.activeTab
		if active and active ~= "BROADCAST" then
			NS:SendWhisper(active, edit:GetText() or "")
		end
	end)
	ui.replyEdit:SetScript("OnEscapePressed", function(edit)
		edit:ClearFocus()
	end)
	ui.replyEdit:SetScript("OnTextChanged", function(edit)
		local text = edit:GetText() or ""
		edit.placeholder:SetShown(text == "")
		if NS._fillingReply then
			return
		end
		local active = MaidRecruiterDB.activeTab
		if active and active ~= "BROADCAST" then
			NS:GetConversation(active).draft = text
		end
	end)
	ui.sendButton:SetScript("OnClick", function()
		local active = MaidRecruiterDB.activeTab
		if active and active ~= "BROADCAST" then
			NS:SendWhisper(active, ui.replyEdit:GetText() or "")
		end
	end)

	ui.reminder = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	self:ApplyBackdrop(ui.reminder, { 0.28, 0.12, 0.14, 1 }, self.COLOR.gold)
	ui.reminder.text = ui.reminder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	ui.reminder.text:SetPoint("LEFT", 8, 0)
	ui.reminder.text:SetPoint("RIGHT", -150, 0)
	ui.reminder.text:SetJustifyH("LEFT")
	ui.reminder.text:SetWordWrap(false)
	ui.reminder.text:SetText("Time to recruit.")
	ui.reminder.done = self:CreatePushButton(ui.reminder, "Done", 58, 22)
	ui.reminder.done:SetPoint("RIGHT", -6, 0)
	ui.reminder.done.tipTitle = "Restart the reminder interval"
	ui.reminder.done:SetScript("OnClick", function()
		NS:DismissReminder()
	end)
	ui.reminder.snooze = self:CreatePushButton(ui.reminder, "Snooze", 64, 22)
	ui.reminder.snooze:SetPoint("RIGHT", ui.reminder.done, "LEFT", -4, 0)
	ui.reminder.snooze.tipTitle = "Remind me again in 5 minutes"
	ui.reminder.snooze:SetScript("OnClick", function()
		NS:SnoozeReminder()
	end)

	ui.status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	ui.status:SetJustifyH("LEFT")
	ui.status:SetWordWrap(false)
	ui.status:SetTextColor(self.COLOR.muted[1], self.COLOR.muted[2], self.COLOR.muted[3])

	ui.grip = CreateFrame("Button", nil, frame)
	ui.grip:SetSize(16, 16)
	ui.grip:SetPoint("BOTTOMRIGHT", -2, 2)
	ui.grip:SetFrameLevel(frame:GetFrameLevel() + 20)
	ui.grip.mark = ui.grip:CreateTexture(nil, "OVERLAY")
	ui.grip.mark:SetAllPoints()
	if ui.grip.mark.SetColorTexture then
		ui.grip.mark:SetColorTexture(self.COLOR.accent[1], self.COLOR.accent[2], self.COLOR.accent[3], 0.7)
	else
		ui.grip.mark:SetTexture("Interface/Buttons/WHITE8x8")
		ui.grip.mark:SetVertexColor(self.COLOR.accent[1], self.COLOR.accent[2], self.COLOR.accent[3], 0.7)
	end
	ui.grip:SetScript("OnMouseDown", function()
		if frame.collapsed then
			return
		end
		frame:StartSizing("BOTTOMRIGHT")
	end)
	ui.grip:SetScript("OnMouseUp", function()
		frame:StopMovingOrSizing()
		self:SaveWindowPosition()
	end)

	ui.settings = CreateFrame("Frame", nil, ui.body, "BackdropTemplate")
	ui.settings:SetAllPoints(ui.body)
	ui.settings:EnableMouse(true)
	ui.settings:Hide()
	if self.BuildSettings then
		self:BuildSettings(ui.settings)
	end
	ui.settings:SetFrameLevel(ui.rail:GetFrameLevel() + 10)

	local listed = false
	if type(UISpecialFrames) == "table" then
		for index = 1, #UISpecialFrames do
			if UISpecialFrames[index] == "MaidRecruiterFrame" then
				listed = true
				break
			end
		end
		if not listed then
			table.insert(UISpecialFrames, "MaidRecruiterFrame")
		end
	end

	frame:SetScript("OnSizeChanged", function()
		if NS._sizing or not NS.ui then
			return
		end
		NS:SaveWindowPosition()
		NS:Refresh()
	end)
	frame:SetScript("OnHide", function()
		NS.settingsOpen = false
		if NS.ui and NS.ui.settings then
			NS.ui.settings:Hide()
		end
		if NS.CloseChannelMenu then
			NS:CloseChannelMenu()
		end
		NS:SaveWindowPosition()
	end)
end

SLASH_MAIDRECRUITER1 = "/maid"
SLASH_MAIDRECRUITER2 = "/mr"
SlashCmdList.MAIDRECRUITER = function(msg)
	msg = (msg or ""):lower()
	msg = msg:gsub("^%s+", "")
	msg = msg:gsub("%s+$", "")
	if msg == "config" or msg == "settings" then
		NS:ShowWindow()
		NS:SetSettingsOpen(true)
	elseif msg == "remind" then
		NS:PresentReminder()
	elseif msg == "help" then
		print("|cffffb3d0Maid Recruiter:|r /maid opens the window. /maid settings edits buttons. /maid remind tests the reminder.")
	else
		NS:ToggleWindow()
	end
end
