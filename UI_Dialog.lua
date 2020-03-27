
RT_Dialog = {

}

function RT_Dialog:ShowToggle( frame, isShow )
	frame = (type(frame) == "string") and _G[frame] or frame
	if not frame then return end
	if not frame:IsVisible() or isShow then
		frame:Show()
	else
		frame:Hide()
	end
end

function RT_Dialog:TransparentToggle( frame, isTransparent )
	frame = (type(frame) == "string") and _G[frame] or frame
	if not frame then return end

	local isTr = not (not isTransparent)
	local isAl = (frame:GetAlpha() ~= 1)

	if isTr ~= isAl then frame:SetAlpha(isTr and 0.5 or 1.0) end
end

function RT_Dialog:InteractiveToggle( frame, isInteractive )
	frame = (type(frame) == "string") and _G[frame] or frame
	if not frame then return end

	--local rt = RaidTracker
	local isIn = not (not isInteractive)	--try not to change state. this sucks, makes certain assumptions, like frame modes will never change. got to be done though

	local isKb,isMs,isSc = not (not frame:IsKeyboardEnabled()), not (not frame:IsMouseEnabled()),
		not (not frame:IsMouseWheelEnabled())

	if isKb then frame._wasKb = 1 end
	if isMs then frame._wasMs = 1 end
	if isSc then frame._wasSc = 1 end

	if (isIn and frame._wasKb) or (not isIn and isKb) then frame:EnableKeyboard(isIn and 1 or nil)
		--rt:Debug("kb",frame:GetName(),"was",frame._wasKb,"is",isKb,"to",isIn)
	end
	if (isIn and frame._wasMs) or (not isIn and isMs) then frame:EnableMouse(isIn and 1 or nil)
		--rt:Debug("ms",frame:GetName(),"was",frame._wasMs,"is",isMs,"to",isIn)
	end
	if (isIn and frame._wasSc) or (not isIn and isSc) then frame:EnableMouseWheel(isIn and 1 or nil)
		--rt:Debug("sc",frame:GetName(),"was",frame._wasSc,"is",isSc,"to",isIn)
	end
end

function RT_Dialog:ShowPT( frame, type1, t )
	self:Show( frame, type1, t.what, t.raidid, t.itemid, t.playerid, t.zone, t.boss, t.eventid )
end

function RT_Dialog:Show( frame, type1, what, raidid, itemid, playerid, zone, boss, eventid )
	frame = (type(frame) == "string") and _G[frame] or frame
	if not frame then return end
	frame:Hide()
	if type1 then frame.type = type1 end
	if what then frame.what = what end
	if raidid then frame.raidid = raidid end
	if itemid then frame.itemid = itemid end
	if playerid then frame.playerid = playerid end
	if eventid then frame.eventid = eventid end
	if zone then frame.zone = zone end
	if boss then frame.boss = boss end
	frame:Show()
end


function RT_Dialog:Edit_OnShow( frame )
	if not frame then return end
	local f,rt = frame, RaidTracker
	local db,o,L = rt._db,rt._options,rt.L

	local item, raid, event
	raid = db.Log[f.raidid]
	if f.itemid then
		item = raid.Loot[f.itemid]
	end
	if f.eventid then
		event = raid.Events[f.eventid]
	end

	local ftype,what,value,hText,hName,hColor,hNote,hWay,hNameAs,hNameOf = f.type, f.what
	local uType,uWhat = ftype and ftype:gsub("^%l", strupper), what and what:gsub("^%l", strupper)
	local hTitle,hVerb = L["Edit "..uType], L["Editing"]

	if ftype == "delete" then
		hTitle,hVerb,hWay,hNote = L["Delete "..uWhat], L["Really"], " "..L[uType.." "..uWhat].." ", "?"
	elseif ftype == "note" then
		if what == "raid" then			value = raid.note;
		elseif what == "player" then	value = raid.Players[f.playerid] and raid.Players[f.playerid].note
		elseif what == "item" then		value = item.note
		elseif what == "event" then		value = event.note	end
	elseif ftype == "time" then
		hNote = "\n(as server time, 24 hour, ex: mm/dd/yy h:m:s)"
		if what == "raid" then			hVerb = hVerb.." "..L:T("start"); value = rt:GetDisplayDate(raid.key)
		elseif what == "raidend" then	hVerb = hVerb.." "..L:T("end"); value = rt:GetDisplayDate(raid.End or rt:GetTimestamp()); what = "raid";
		elseif what == "item" then		value = rt:GetDisplayDate(item.time)
		elseif what == "event" then		value = rt:GetDisplayDate(event.time)	end
	elseif ftype == "boss" then
		if what == "item" then		    value = item.boss
		elseif what == "event" then	    value = event.boss
		elseif what == "next" then		hText = L["Please select the next boss you are going to."]	end
	elseif ftype == "zone" then
		if what == "raid" then			value = raid.zone
		elseif what == "event" then		value = event.zone	end
	elseif ftype == "export" then
		hTitle,hVerb,hNameAs,hNameOf,hNote = L["Export String"],"Showing","using",RT_Options.desc.export[o.ExportFormat]," string for upload"
		if not raid.End then
			rt:Print(L["You have to end the raid before you exporting it"])
			f:Hide(); return
		end
		value = RT_Export:ExportSession(raid,o.ExportFormat,o.ExportStrict)
	elseif ftype == "count" then
		if what == "item" then	value = item.item.count and item.item.count or 1 end
	elseif ftype == "cost" then
		if what == "item" then
			hNote = ((item.item.ilevel) and (" iLevel \"|c00ffffff"..item.item.ilevel.."|r\"") or "") ..
					((item.player) and (" for |Hplayer:"..item.player.."|h|c00ffffff["..item.player.."]|r|h"))
			value = tostring(item.cost or "")
		end
	elseif ftype == "looter" then
		value = item.player
	elseif ftype == "wipe" then
		hTitle,hText = L["Group Wipe"], L["Is it a Wipe?"]
	elseif ftype == "join" or ftype == "leave" then
		hVerb,Note = L["Editing player"],"\n(as server time, 24 hour, ex: mm/dd/yy h:m:s)"
	end

	if f.GetName then
		local frameName = f:GetName()
		if not hText and hVerb then
			if not hName then
				if what == "raid" then
					hName = rt:GetRaidTitle(f.raidid,true).."|r' " .. (hNameAs or "on") ..
						" '|c00ffffff"..(hNameOf or rt:GetRaidTitle(f.raidid,nil,"default"));	hColor = "0000ff00"
				elseif what == "player" then hName = f.playerid
				elseif what == "item" then hName = item.item.name; hColor = item.item.c;
				elseif what == "event" then	hName = (event.boss and (event.boss.." ") or "") .. rt:GetDisplayDate(event.time) end
			end
			rt:Debug(what)
			hColor = hColor or "00ffffff"
			hWay = hWay or ((ftype and (" "..L:T(ftype).." ") or "") .. ((what) and ("for "..L:T(what).." ") or ""))
			hText = hVerb .. hWay .. "'|c"..hColor..hName.."|r'" .. ((hNote) and hNote or "")
		end
		if hTitle then f._csHeaderTitle:SetText(hTitle); end
		if hText then f._csHeaderText:SetText(hText); end
		if f._ceText then
			f._ceText:SetText(value or "")
			f._ceText:HighlightText()
		end
	end
	PlaySound(1115)	--"UChatScrollButton"

	rt:Debug("RT_Dialog:Edit_OnShow", f.GetName and f:GetName() or nil,
		f.type, f.what, f.raidid, f.itemid, hTitle, hText, value)
end


function RT_Dialog:Edit_OnSave( frame, option )
	if not frame then return end
	local f,rt = frame, RaidTracker
	local db,o,L = rt._db,rt._options,rt.L

	local value, item, raid;
	raid = db.Log[f.raidid]
	if f.itemid then
		item = raid.Loot[f.itemid]
	end
	if f.eventid then
		event = raid.Events[f.eventid]
	end
	if f._ceText then
		value = f._ceText:GetText()
	else
		value = f.value
	end
	if type(value) == "string" then value = strtrim(value); if value == "" then value = nil end; end
	rt:Debug("RT_Dialog:Edit_OnSave", f and f.GetName and f:GetName(), f.type, f.what, f.raidid, f.itemid, option, value)

	if f.type == "note" then
		if f.what == "raid" then
			raid.note = value
			rt:FrameUpdate()
		elseif f.what == "player" then
			if not raid.Players[f.playerid] then
				raid.Players[f.playerid] = { }
			end
			raid.Players[f.playerid].note = value
		elseif f.what == "item" then
			item.note = value
		elseif f.what == "event" then
			event.note = value
		end
	elseif f.type == "time" then
		value = rt:GetTimestamp(value, 0)
		if not value then
			RaidTracker:Print("Edit Time: Invalid Time format")
		else
			if		f.what == "raidend" then	raid.End = value; rt:FrameUpdate()
			elseif	f.what == "raid" then		raid.key = value; rt:FrameUpdate()
			elseif	f.what == "item" then		item.time = value
			elseif	f.what == "event" then		event.time = value end
		end
	elseif f.type == "boss" then
		if f.what == "item" then
			item.boss = value
		elseif f.what == "event" then
			event.boss = value
		elseif f.what == "next" then
			value = UIDropDownMenu_GetText(RT_EditBossFrameMenu)
			if value then value = strtrim(value) end
			if strlen(value) == 0 then value = nil end
			raid.bossnext = value
		end
	elseif f.type == "zone" then
		if value and raid.zone ~= value then
			if not db.Zones[value] then
				db.Zones[value] = { id=0, pid=0, rel=0, name=value }
				rt:Print("Added custom zone: \""..value.."\"")
			end
		end
		if f.what == "raid" then
			raid.zone = value
		elseif f.what == "event" then
			event.zone = value
		end
		rt:FrameUpdate()
	elseif f.type == "looter" then
		if value then
			item.player = value
		end
	elseif f.type == "count" then
		if f.what == "item" then
			value = value and tonumber(value)
			if not value or value==0 then	rt:Print("Edit Count: Invalid value.")
			else							item.item.count = (value > 1) and value  end
		end
	elseif f.type == "cost" then
		if f.what == "item" then
			if value and (not tonumber(value) or not string.find(value, "^(%d+%.?%d*)$")) then
			rt:Print("Edit Cost: Invalid value")
			else
				item.cost = value
				if type(dkpp_ctra_sub) == "function" then
					dkpp_ctra_sub(f.raidid, f.itemid)
				end
			end
			if option == "bank" or option == "disenchanted" then item.player = option end
		end
	elseif f.type == "wipe" then
		if not option then
			rt:AddWipeDB()
		else												-- wait 10 secs on maybe, else full cooldown
			o.WipeLast = GetTime() + ((option=="maybe") and (-o.WipeCooldown + 10) or 0)
		end
	elseif f.type == "join" or f.type == "leave" then
		local f2 = RT_JoinLeaveFrame
		local name,note,time = f2._ceName:GetText(), f2._ceNote:GetText(), f2._ceTime:GetText()
		local ts = rt:GetTimestamp(time, 0)
		if not name or name == "" then
			rt:Print("Raid Tracker Join/Leave: No player")
		elseif not ts then
			rt:Print("Raid Tracker Join/Leave: Invalid Time format")
		else
			tinsert( (f.type == "join") and raid.Join or raid.Leave, { player = name, time = ts } )
			db.Online[name] = 1
			rt:Print(name .. " manual " .. f.type .. " at " .. time)
			if not raid.Players[name] then raid.Players[name] = { }	end
			if note and note ~= "" then
				raid.Players[name].note = note
			end
		end
	elseif f.type == "whisper" then
		rt:InitWhisper(f.playerid)
	elseif f.type == "invite" then
		if UnitInRaid(f.playerid) then
			rt:Print(L:F("%s is already in the group.", f.playerid))
		else
			SendChatMessage(L:F("%s is inviting you to a group using Raid Tracker.",UnitName("player")), "WHISPER", nil, f.playerid);
			InviteUnit(f.playerid)
		end
	end

	f.type = nil
	f.what = nil
	f.raidid = nil
	f.itemid = nil
	f.playerid = nil
	f.eventid = nil
	f.zone = nil
	f.boss = nil

	rt:FrameUpdateView()
end


function RT_Dialog:Delete_OnSave( frame )
	if not frame then return end
	local f,rt = frame, RaidTracker
	local db,o,L = rt._db,rt._options,rt.L
	rt:Debug("RT_Dialog:Delete_OnSave", f:GetName(), f.raidid, option)

	local raid = db.Log[f.raidid]

	if f.type == "delete" then
		if f.what == "raid" then
			rt:DeleteSessionDB(f.raidid)
		elseif f.what == "item" then
			tremove(raid.Loot, f.itemid)
			for i,v in pairs(raid.Loot) do
				v.id = i
			end
		elseif f.what == "event" then
			tremove(raid.Events, f.eventid)
			for i,v in pairs(raid.Events) do
				v.id = i
			end
		elseif f.what == "player" then
			for k, v in pairs(raid.Join) do
				if v.player == f.playerid then
					tremove(raid.Join, k)
				end
			end
			for k, v in pairs(raid.Leave) do
				if v.player == f.playerid then
					tremove(raid.Leave, k)
				end
			end
			if id == db.Options.CurrentRaid then
				db.Online[f.playerid] = nil
			end
			if raid.Players then
				raid.Players[f.playerid] = nil
			end
		end
		rt:FrameUpdate()
	end

	f.type = nil
	f.what = nil
	f.raidid = nil
	f.itemid = nil
	f.playerid = nil
	f.eventid = nil
	f.zone = nil
	f.boss = nil

	rt:FrameUpdateView()
end
