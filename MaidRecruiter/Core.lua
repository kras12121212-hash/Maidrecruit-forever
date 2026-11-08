-- Whisper inbox, click-to-send recruitment, and a reminder that never sends chat.
local ADDON_NAME, NS = ...

NS.ADDON_NAME = ADDON_NAME
NS.MAX_CHUNK = 255
NS.MAX_CHUNKS = 3
NS.MAX_INPUT = 600
NS.MAX_HISTORY = 50
NS.REPLY_BINDS = 8
NS.BROADCAST_BINDS = 6

NS.DEFAULT_REPLIES = {
	{ label = "Greeting", text = "Hi! Domestic Catgirl Corp is recruiting. Want to hear a bit about the guild?" },
	{ label = "About us", text = "Domestic Catgirl Corp is a social guild. We group up, help each other, and keep chat friendly. Ask me anything." },
	{ label = "How to join", text = "If you want in, tell me your class and what you like to do. I will invite you when it looks like a fit." },
}

NS.DEFAULT_BROADCASTS = {
	{ label = "City yell", text = "Domestic Catgirl Corp is recruiting friendly players. Whisper me if you want an invite.", channel = "YELL", channelName = "" },
	{ label = "Recruit channel", text = "Domestic Catgirl Corp is recruiting. Whisper me if you want a guild that actually talks back.", channel = "CHANNEL", channelName = "Trade" },
	{ label = "Guild chat", text = "Recruitment check: if you know a good fit for Domestic Catgirl Corp, send them to me.", channel = "GUILD", channelName = "" },
}

BINDING_HEADER_MAIDRECRUITER = "Maid Recruiter"
for i = 1, NS.REPLY_BINDS do
	_G["BINDING_NAME_MAIDRECRUITER_REPLY" .. i] = "Whisper button " .. i
end
for i = 1, NS.BROADCAST_BINDS do
	_G["BINDING_NAME_MAIDRECRUITER_CAST" .. i] = "Broadcast button " .. i
end

local function CopyValue(value)
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for key, child in pairs(value) do
		out[key] = CopyValue(child)
	end
	return out
end

local function NextUtf8(text, index)
	local byte = text:byte(index)
	if not byte then
		return nil
	end
	local length = 1
	if byte >= 240 then
		length = 4
	elseif byte >= 224 then
		length = 3
	elseif byte >= 192 then
		length = 2
	end
	local last = index + length - 1
	if last > #text then
		return nil
	end
	return last, byte, length
end

function NS:Now()
	if type(GetServerTime) == "function" then
		return GetServerTime()
	end
	return time()
end

function NS:IsSecret(value)
	if value == nil then
		return false
	end
	if type(issecretvalue) == "function" then
		local ok, secret = pcall(issecretvalue, value)
		if ok and secret then
			return true
		end
	end
	if type(canaccessvalue) == "function" then
		local ok, access = pcall(canaccessvalue, value)
		if ok and not access then
			return true
		end
	end
	return false
end

function NS:Sanitize(text)
	text = tostring(text or "")
	text = text:gsub("%z", "")
	text = text:gsub("[\r\n]+", " ")
	-- A raw pipe is an invalid chat escape and can disconnect the client.
	text = text:gsub("|", "/")
	text = text:gsub("%s+", " ")
	text = text:gsub("^%s+", "")
	text = text:gsub("%s+$", "")
	return text
end

function NS:SplitMessage(text)
	text = self:Sanitize(text)
	if text == "" then
		return {}, ""
	end
	local chunks = {}
	local remaining = text
	while remaining ~= "" and #chunks < self.MAX_CHUNKS do
		if #remaining <= self.MAX_CHUNK then
			chunks[#chunks + 1] = remaining
			remaining = ""
			break
		end
		local limit = self.MAX_CHUNK
		local index = 1
		local lastOk = 0
		local lastSpace = nil
		while index <= #remaining do
			local last, byte, length = NextUtf8(remaining, index)
			if not last or last > limit then
				break
			end
			lastOk = last
			if length == 1 and byte == 32 then
				lastSpace = last
			end
			index = last + 1
		end
		if lastOk < 1 then
			break
		end
		local cut = lastOk
		if lastSpace and lastSpace >= limit - 40 and lastSpace > 1 then
			cut = lastSpace - 1
		end
		local head = remaining:sub(1, cut)
		if head == "" then
			break
		end
		chunks[#chunks + 1] = head
		remaining = remaining:sub(cut + 1):gsub("^%s+", "")
	end
	return chunks, remaining
end

function NS:PlainName(sender)
	sender = tostring(sender or "")
	sender = sender:gsub("|c%x%x%x%x%x%x%x%x", "")
	sender = sender:gsub("|r", "")
	sender = sender:gsub("^%s+", "")
	sender = sender:gsub("%s+$", "")
	return sender
end

function NS:CompactRealm(realm)
	if self:IsSecret(realm) or type(realm) ~= "string" then
		return ""
	end
	return (realm:gsub("%s+", "")):lower()
end

function NS:IsMyRealm(realm)
	local compact = self:CompactRealm(realm)
	if compact == "" then
		return false
	end
	if type(GetRealmName) == "function" then
		local mine = self:CompactRealm(GetRealmName())
		if mine ~= "" and mine == compact then
			return true
		end
	end
	if type(GetNormalizedRealmName) == "function" then
		local mine = self:CompactRealm(GetNormalizedRealmName())
		if mine ~= "" and mine == compact then
			return true
		end
	end
	return false
end

function NS:AmbiguateName(name)
	if self:IsSecret(name) or type(name) ~= "string" or name == "" then
		return ""
	end
	if type(Ambiguate) == "function" then
		local ok, short = pcall(Ambiguate, name, "none")
		if ok and type(short) == "string" and short ~= "" and not self:IsSecret(short) then
			return short
		end
	end
	return name
end

-- Same-realm whisper targets are the bare character name. A realm glued on
-- with spaces (this client's GetRealmName) is not a name the game will deliver.
function NS:CanonicalName(sender)
	if self:IsSecret(sender) then
		return ""
	end
	sender = self:PlainName(sender)
	if sender == "" then
		return ""
	end
	local name, realm = sender:match("^(.-)%-(.+)$")
	if not name or name == "" or not realm or realm == "" then
		return self:AmbiguateName(sender)
	end
	if self:IsMyRealm(realm) then
		return self:AmbiguateName(name)
	end
	local compactRealm = realm:gsub("%s+", "")
	if compactRealm ~= realm then
		return self:AmbiguateName(name .. "-" .. compactRealm)
	end
	return self:AmbiguateName(name .. "-" .. realm)
end

function NS:ShortName(full)
	full = self:PlainName(full)
	local short = full:match("^([^%-]+)")
	if short and short ~= "" then
		return short
	end
	return full
end

function NS:ChannelLabel(item)
	local channel = item and item.channel or "YELL"
	if channel == "YELL" then
		return "Yell"
	end
	if channel == "SAY" then
		return "Say"
	end
	if channel == "GUILD" then
		return "Guild"
	end
	if channel == "CHANNEL" then
		if item.channelName and item.channelName ~= "" then
			return item.channelName
		end
		return "Channel"
	end
	return channel
end

local function RepairButtons(list, withChannel)
	local out = {}
	if type(list) ~= "table" then
		return out
	end
	for index = 1, #list do
		local item = list[index]
		if type(item) == "table" then
			local copy = {
				label = type(item.label) == "string" and item.label or ("Button " .. index),
				text = type(item.text) == "string" and item.text or "",
			}
			if withChannel then
				local channel = item.channel
				if channel ~= "YELL" and channel ~= "SAY" and channel ~= "GUILD" and channel ~= "CHANNEL" then
					channel = "YELL"
				end
				copy.channel = channel
				copy.channelName = type(item.channelName) == "string" and item.channelName or ""
			end
			out[#out + 1] = copy
		end
	end
	return out
end

local function RepairConversation(value)
	if type(value) ~= "table" then
		value = {}
	end
	if type(value.lines) ~= "table" then
		value.lines = {}
	end
	if type(value.draft) ~= "string" then
		value.draft = ""
	end
	if type(value.unread) ~= "boolean" then
		value.unread = false
	end
	if type(value.guid) ~= "string" or value.guid == "" then
		value.guid = nil
	end
	while #value.lines > NS.MAX_HISTORY do
		table.remove(value.lines, 1)
	end
	return value
end

function NS:InitDB()
	if type(MaidRecruiterDB) ~= "table" then
		MaidRecruiterDB = {}
	end
	local db = MaidRecruiterDB
	if not db.initialized then
		db.quickReplies = CopyValue(self.DEFAULT_REPLIES)
		db.broadcasts = CopyValue(self.DEFAULT_BROADCASTS)
		db.reminder = { enabled = true, minutes = 15 }
		db.window = { point = "CENTER", rel = "CENTER", x = 0, y = 0, width = 680, height = 460 }
		db.conversations = {}
		db.tabOrder = {}
		db.activeTab = "BROADCAST"
		db.openOnWhisper = true
		db.soundOnWhisper = false
		db.reminderNextAt = 0
		db.reminderDue = false
		db.initialized = true
	end

	db.quickReplies = RepairButtons(db.quickReplies, false)
	db.broadcasts = RepairButtons(db.broadcasts, true)
	if type(db.reminder) ~= "table" then
		db.reminder = { enabled = true, minutes = 15 }
	end
	if type(db.reminder.enabled) ~= "boolean" then
		db.reminder.enabled = true
	end
	db.reminder.minutes = tonumber(db.reminder.minutes) or 15
	if db.reminder.minutes < 1 then
		db.reminder.minutes = 1
	elseif db.reminder.minutes > 180 then
		db.reminder.minutes = 180
	end
	if type(db.window) ~= "table" then
		db.window = {}
	end
	db.window.point = type(db.window.point) == "string" and db.window.point or "CENTER"
	db.window.rel = type(db.window.rel) == "string" and db.window.rel or "CENTER"
	db.window.x = tonumber(db.window.x) or 0
	db.window.y = tonumber(db.window.y) or 0
	db.window.width = tonumber(db.window.width) or 680
	db.window.height = tonumber(db.window.height) or 460
	if db.window.width < 560 then
		db.window.width = 560
	elseif db.window.width > 1200 then
		db.window.width = 1200
	end
	if db.window.height < 340 then
		db.window.height = 340
	elseif db.window.height > 900 then
		db.window.height = 900
	end
	if type(db.conversations) ~= "table" then
		db.conversations = {}
	end
	if type(db.tabOrder) ~= "table" then
		db.tabOrder = {}
	end
	local kept = {}
	local order = {}
	local merged = {}
	local consumed = {}
	for index = 1, #db.tabOrder do
		local oldName = db.tabOrder[index]
		if type(oldName) == "string" and oldName ~= "" and not consumed[oldName] and type(db.conversations[oldName]) == "table" then
			consumed[oldName] = true
			local name = self:CanonicalName(oldName)
			if name == "" then
				name = oldName
			end
			local convo = RepairConversation(db.conversations[oldName])
			local existing = merged[name]
			if existing then
				for lineIndex = 1, #convo.lines do
					existing.lines[#existing.lines + 1] = convo.lines[lineIndex]
				end
				while #existing.lines > self.MAX_HISTORY do
					table.remove(existing.lines, 1)
				end
				if existing.draft == "" and convo.draft ~= "" then
					existing.draft = convo.draft
				end
				if not existing.guid and convo.guid then
					existing.guid = convo.guid
				end
				existing.unread = existing.unread or convo.unread
			else
				merged[name] = convo
				kept[name] = true
				order[#order + 1] = name
			end
		end
	end
	db.conversations = merged
	db.tabOrder = order
	if type(db.activeTab) ~= "string" or db.activeTab == "" then
		db.activeTab = "BROADCAST"
	elseif db.activeTab ~= "BROADCAST" then
		local active = self:CanonicalName(db.activeTab)
		if active ~= "" and kept[active] then
			db.activeTab = active
		else
			db.activeTab = "BROADCAST"
		end
	end
	if type(db.openOnWhisper) ~= "boolean" then
		db.openOnWhisper = true
	end
	if type(db.soundOnWhisper) ~= "boolean" then
		db.soundOnWhisper = false
	end
	db.reminderNextAt = tonumber(db.reminderNextAt) or 0
	if type(db.reminderDue) ~= "boolean" then
		db.reminderDue = false
	end
end

function NS:SetStatus(text, isError)
	self.statusText = text or ""
	self.statusIsError = isError and true or false
	if self.ApplyStatus then
		self:ApplyStatus()
	end
	if isError and text and text ~= "" then
		local shown = self.ui and self.ui.frame and self.ui.frame:IsShown() and not self.ui.frame.collapsed
		if not shown then
			print("|cffffb3d0Maid Recruiter:|r " .. text)
		end
	end
end

function NS:GetConversation(fullName)
	local convo = MaidRecruiterDB.conversations[fullName]
	if type(convo) ~= "table" then
		convo = { lines = {}, draft = "", unread = false }
		MaidRecruiterDB.conversations[fullName] = convo
	end
	return convo
end

function NS:EnsureTab(fullName)
	local order = MaidRecruiterDB.tabOrder
	for index = 1, #order do
		if order[index] == fullName then
			return
		end
	end
	order[#order + 1] = fullName
	self:GetConversation(fullName)
end

function NS:AppendLine(fullName, direction, text)
	local convo = self:GetConversation(fullName)
	local lines = convo.lines
	local now = time()
	local last = lines[#lines]
	if last and last.from == direction and last.text == text and math.abs((last.time or 0) - now) < 2 then
		return false
	end
	lines[#lines + 1] = { from = direction, text = text, time = now }
	while #lines > self.MAX_HISTORY do
		table.remove(lines, 1)
	end
	return true
end

function NS:CloseTab(fullName)
	local order = MaidRecruiterDB.tabOrder
	for index = #order, 1, -1 do
		if order[index] == fullName then
			table.remove(order, index)
		end
	end
	MaidRecruiterDB.conversations[fullName] = nil
	if MaidRecruiterDB.activeTab == fullName then
		MaidRecruiterDB.activeTab = "BROADCAST"
	end
	if self.Refresh then
		self:Refresh()
	end
end

function NS:SelectTab(tabId)
	MaidRecruiterDB.activeTab = tabId or "BROADCAST"
	if tabId and tabId ~= "BROADCAST" then
		local convo = MaidRecruiterDB.conversations[tabId]
		if convo then
			convo.unread = false
		end
	end
	self._scrollHistory = true
	if self.Refresh then
		self:Refresh()
	end
end

function NS:PlayNamedSound(key)
	if type(PlaySound) ~= "function" or type(SOUNDKIT) ~= "table" then
		return
	end
	local id = SOUNDKIT[key]
	if type(id) ~= "number" then
		return
	end
	pcall(PlaySound, id, "Master")
end

function NS:PlayReminderSound()
	if type(SOUNDKIT) ~= "table" then
		return
	end
	if SOUNDKIT.RAID_WARNING then
		self:PlayNamedSound("RAID_WARNING")
	elseif SOUNDKIT.READY_CHECK_READY then
		self:PlayNamedSound("READY_CHECK_READY")
	elseif SOUNDKIT.ALARM_CLOCK_WARNING_3 then
		self:PlayNamedSound("ALARM_CLOCK_WARNING_3")
	end
end

function NS:SendChunks(chunks, chatType, target)
	if type(SendChatMessage) ~= "function" then
		self:SetStatus("Chat sending is not available.", true)
		return false
	end
	-- Called directly from the click or key handler. pcall would drop the
	-- hardware-event flag and the client would reject yell, say, and channel.
	for index = 1, #chunks do
		SendChatMessage(chunks[index], chatType, nil, target)
	end
	return true
end

function NS:ResolveChannel(channelName)
	if type(channelName) ~= "string" or channelName == "" then
		return nil, "Set a channel name, such as Trade or 2."
	end
	local asNumber = tonumber(channelName)
	if asNumber then
		if asNumber < 1 then
			return nil, "That channel number is not valid."
		end
		return asNumber
	end
	if type(GetChannelName) ~= "function" then
		return nil, "This client cannot look up channel names. Use the channel number instead."
	end
	local id = GetChannelName(channelName)
	if type(id) == "number" and id > 0 then
		return id
	end
	return nil, "Join " .. channelName .. " first, or set the channel number."
end

function NS:SendWhisper(fullName, text)
	if not fullName or fullName == "" or fullName == "BROADCAST" then
		self:SetStatus("Open a person's tab first.", true)
		return false
	end
	local target = self:CanonicalName(fullName)
	if target == "" then
		self:SetStatus("That player name cannot be whispered.", true)
		return false
	end
	local chunks, rest = self:SplitMessage(text)
	if #chunks == 0 then
		self:SetStatus("Nothing to send.", true)
		return false
	end
	if not self:SendChunks(chunks, "WHISPER", target) then
		return false
	end
	local convo = self:GetConversation(fullName)
	convo.draft = rest or ""
	if self.RefreshReplyBox then
		self:RefreshReplyBox()
	end
	if rest and rest ~= "" then
		self:SetStatus("Sent " .. #chunks .. " parts to " .. target .. ". The box still has the rest.")
	else
		self:SetStatus("Whispered " .. target .. ".")
	end
	return true
end

function NS:SubmitReply(text)
	local now = nil
	if type(GetTime) == "function" then
		now = GetTime()
	end
	if self._sendingReply then
		return false
	end
	if now and self._replySentAt and (now - self._replySentAt) < 0.05 then
		return self._replySentOk and true or false
	end
	self._sendingReply = true
	local active = MaidRecruiterDB and MaidRecruiterDB.activeTab
	local ok = false
	if not active or active == "" or active == "BROADCAST" then
		self:SetStatus("Open a person's tab first.", true)
	else
		ok = self:SendWhisper(active, text or "") and true or false
	end
	self._sendingReply = false
	self._replySentAt = now
	self._replySentOk = ok
	return ok
end

function NS:SendQuickReply(index)
	local item = MaidRecruiterDB.quickReplies[index]
	if not item then
		self:SetStatus("No whisper button in slot " .. index .. ".", true)
		return
	end
	local active = MaidRecruiterDB.activeTab
	if not active or active == "BROADCAST" then
		self:SetStatus("Open a person's tab, then use that button.", true)
		return
	end
	self:SendWhisper(active, item.text)
end

function NS:PasteQuickReply(index)
	local item = MaidRecruiterDB.quickReplies[index]
	if not item then
		return
	end
	local active = MaidRecruiterDB.activeTab
	if not active or active == "BROADCAST" then
		self:SetStatus("Open a person's tab first.", true)
		return
	end
	local convo = self:GetConversation(active)
	local draft = convo.draft or ""
	local extra = self:Sanitize(item.text)
	if extra == "" then
		self:SetStatus("That button has no text.", true)
		return
	end
	if draft ~= "" then
		draft = self:Sanitize(draft .. " " .. extra)
	else
		draft = extra
	end
	if #draft > self.MAX_INPUT then
		draft = draft:sub(1, self.MAX_INPUT)
	end
	convo.draft = draft
	if self.RefreshReplyBox then
		self:RefreshReplyBox()
	end
	if self.FocusReply then
		self:FocusReply()
	end
	self:SetStatus("Loaded into the reply box.")
end

function NS:SendBroadcast(index)
	local item = MaidRecruiterDB.broadcasts[index]
	if not item then
		self:SetStatus("No broadcast button in slot " .. index .. ".", true)
		return
	end
	local chunks, rest = self:SplitMessage(item.text)
	if #chunks == 0 then
		self:SetStatus("That broadcast is empty.", true)
		return
	end
	local chatType = item.channel or "YELL"
	local target = nil
	if chatType == "CHANNEL" then
		local id, err = self:ResolveChannel(item.channelName)
		if not id then
			self:SetStatus(err, true)
			return
		end
		target = id
	elseif chatType == "GUILD" then
		if type(IsInGuild) == "function" and not IsInGuild() then
			self:SetStatus("You are not in a guild.", true)
			return
		end
	elseif chatType ~= "YELL" and chatType ~= "SAY" then
		self:SetStatus("Unknown destination.", true)
		return
	end
	if not self:SendChunks(chunks, chatType, target) then
		return
	end
	self:ResetReminder()
	if rest and rest ~= "" then
		self:SetStatus("Sent " .. #chunks .. " parts. Still unsent: " .. rest:sub(1, 80))
	else
		self:SetStatus("Sent to " .. self:ChannelLabel(item) .. ".")
	end
end

function NS:ResetReminder()
	local minutes = MaidRecruiterDB.reminder.minutes or 15
	MaidRecruiterDB.reminderNextAt = self:Now() + math.floor(minutes * 60)
	MaidRecruiterDB.reminderDue = false
	MaidRecruiterDB.reminderWaitingOutCombat = false
	self._reminderSoundPlayed = false
	self._reminderPresented = false
	if self.Refresh then
		self:Refresh()
	end
end

function NS:SnoozeReminder()
	MaidRecruiterDB.reminderNextAt = self:Now() + (5 * 60)
	MaidRecruiterDB.reminderDue = false
	MaidRecruiterDB.reminderWaitingOutCombat = false
	self._reminderSoundPlayed = false
	self._reminderPresented = false
	self:SetStatus("Reminder snoozed for 5 minutes.")
	if self.Refresh then
		self:Refresh()
	end
end

function NS:DismissReminder()
	self:ResetReminder()
	self:SetStatus("Reminder reset.")
end

function NS:SetReminderEnabled(enabled)
	MaidRecruiterDB.reminder.enabled = enabled and true or false
	if not MaidRecruiterDB.reminder.enabled then
		MaidRecruiterDB.reminderDue = false
		MaidRecruiterDB.reminderWaitingOutCombat = false
		self._reminderSoundPlayed = false
		self._reminderPresented = false
	elseif (MaidRecruiterDB.reminderNextAt or 0) <= 0 then
		self:ResetReminder()
		return
	end
	if self.Refresh then
		self:Refresh()
	end
end

function NS:SetReminderMinutes(minutes)
	minutes = tonumber(minutes)
	if not minutes then
		return
	end
	minutes = math.floor(minutes)
	if minutes < 1 then
		minutes = 1
	elseif minutes > 180 then
		minutes = 180
	end
	local changed = MaidRecruiterDB.reminder.minutes ~= minutes
	MaidRecruiterDB.reminder.minutes = minutes
	if changed and MaidRecruiterDB.reminder.enabled and not MaidRecruiterDB.reminderDue then
		self:ResetReminder()
	end
end

function NS:PresentReminder()
	if not MaidRecruiterDB.reminder.enabled then
		return
	end
	if InCombatLockdown() then
		MaidRecruiterDB.reminderDue = true
		MaidRecruiterDB.reminderWaitingOutCombat = true
		return
	end
	MaidRecruiterDB.reminderDue = true
	MaidRecruiterDB.reminderWaitingOutCombat = false
	self._reminderPresented = true
	if self.ShowWindow then
		self:ShowWindow()
	end
	if not self._reminderSoundPlayed then
		self._reminderSoundPlayed = true
		self:PlayReminderSound()
	end
end

function NS:ReminderTick()
	if type(MaidRecruiterDB) ~= "table" or type(MaidRecruiterDB.reminder) ~= "table" then
		return
	end
	if not MaidRecruiterDB.reminder.enabled then
		return
	end
	if InCombatLockdown() then
		return
	end
	if MaidRecruiterDB.reminderDue and not self._reminderPresented then
		self:PresentReminder()
		return
	end
	if MaidRecruiterDB.reminderDue or MaidRecruiterDB.reminderWaitingOutCombat then
		if MaidRecruiterDB.reminderWaitingOutCombat then
			self:PresentReminder()
		end
		return
	end
	local nextAt = MaidRecruiterDB.reminderNextAt or 0
	if nextAt > 0 and self:Now() >= nextAt then
		self:PresentReminder()
	end
end

function NS:StartReminder()
	if self._tickerStarted then
		return
	end
	self._tickerStarted = true
	if (MaidRecruiterDB.reminderNextAt or 0) <= 0 then
		self:ResetReminder()
	end
	local watcher = self.eventFrame
	if C_Timer and C_Timer.NewTicker then
		C_Timer.NewTicker(1, function()
			self:ReminderTick()
		end)
		return
	end
	local elapsedAcc = 0
	watcher:SetScript("OnUpdate", function(_, elapsed)
		elapsedAcc = elapsedAcc + elapsed
		if elapsedAcc < 1 then
			return
		end
		elapsedAcc = 0
		self:ReminderTick()
	end)
end

function NS:OnIncomingWhisper(message, sender)
	if self:IsSecret(message) or self:IsSecret(sender) then
		return
	end
	if type(message) ~= "string" or type(sender) ~= "string" then
		return
	end
	sender = self:CanonicalName(sender)
	message = self:Sanitize(message)
	if sender == "" or message == "" then
		return
	end
	self:EnsureTab(sender)
	if not self:AppendLine(sender, "in", message) then
		return
	end
	local convo = self:GetConversation(sender)
	local windowOpen = self.ui and self.ui.frame and self.ui.frame:IsShown() and not self.ui.frame.collapsed
	local typing = self.IsTyping and self:IsTyping()
	local viewing = windowOpen and MaidRecruiterDB.activeTab == sender and not self.settingsOpen
	convo.unread = not viewing
	local idleOnBroadcast = windowOpen and MaidRecruiterDB.activeTab == "BROADCAST" and not typing and not self.settingsOpen
	if MaidRecruiterDB.openOnWhisper and not InCombatLockdown() then
		if not windowOpen then
			self.settingsOpen = false
			if not typing then
				MaidRecruiterDB.activeTab = sender
				convo.unread = false
				self._scrollHistory = true
			end
			if self.ShowWindow then
				self:ShowWindow()
			end
		elseif idleOnBroadcast then
			MaidRecruiterDB.activeTab = sender
			convo.unread = false
			self._scrollHistory = true
		end
	end
	if viewing then
		self._scrollHistory = true
	end
	if convo.unread and MaidRecruiterDB.soundOnWhisper then
		self:PlayNamedSound("TELL_MESSAGE")
	end
	if self.Refresh then
		self:Refresh()
	end
end

function NS:OnOutgoingWhisper(message, sender)
	if self:IsSecret(message) or self:IsSecret(sender) then
		return
	end
	if type(message) ~= "string" or type(sender) ~= "string" then
		return
	end
	sender = self:CanonicalName(sender)
	message = self:Sanitize(message)
	if sender == "" or message == "" then
		return
	end
	self:EnsureTab(sender)
	if not self:AppendLine(sender, "out", message) then
		return
	end
	if MaidRecruiterDB.activeTab == sender then
		self._scrollHistory = true
	end
	if self.Refresh then
		self:Refresh()
	end
end

function MaidRecruiter_FireReply(index)
	if type(MaidRecruiterDB) ~= "table" then
		return
	end
	NS:SendQuickReply(index)
end

function MaidRecruiter_FireBroadcast(index)
	if type(MaidRecruiterDB) ~= "table" then
		return
	end
	NS:SendBroadcast(index)
end

local eventFrame = CreateFrame("Frame")
NS.eventFrame = eventFrame
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
eventFrame:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
eventFrame:SetScript("OnEvent", function(_, event, ...)
	if event == "ADDON_LOADED" then
		local name = ...
		if name ~= ADDON_NAME then
			return
		end
		NS:InitDB()
	elseif event == "PLAYER_LOGIN" then
		NS:InitDB()
		NS:StartReminder()
		if not MaidRecruiterDB.seenWelcome then
			print("|cffffb3d0Maid Recruiter:|r type /maid to open the window. Whispers show up as tabs.")
			MaidRecruiterDB.seenWelcome = true
		end
		if NS.BuildUI then
			NS:BuildUI()
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		NS:ReminderTick()
	elseif event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM" then
		local message, sender = ...
		local handler = event == "CHAT_MSG_WHISPER" and NS.OnIncomingWhisper or NS.OnOutgoingWhisper
		local ok, err = pcall(handler, NS, message, sender)
		if not ok and not NS._whisperError then
			NS._whisperError = true
			print("|cffffb3d0Maid Recruiter:|r could not read a whisper: " .. tostring(err))
		end
	end
end)
