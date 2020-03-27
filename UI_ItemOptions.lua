-- Raid Item Maintainance Dialog


RT_ItemOptions = {
	sortName = function(a, b) return (a.name or "") < (b.name or "") end,
	sortId = function(a, b) return (a.id or 0) < (b.id or 0) end,
}

function RT_ItemOptions:GetItemIid( id )
	if id and type(id)=="string" then
		_,_,id = string.find(id,"(%d+)")
	end
	return id and tonumber(id)
end

function RT_ItemOptions:GetDispName( item, isTitle )
	if not item then return "" end
	local frame,rt = RT_ItemOptionsFrame, RaidTracker
	local db,o,L = rt._db,rt._options,rt.L

	local tag = rawget(frame.items, item.id) and "Unsaved" or (not rawget(db.ItemOptions, item.id) and "Default")

	if not item.name or not item.quality then
		local name, _, quality = GetItemInfo(item.id)
		if name and not item.name then item.name = name end
		if quality and not item.quality then item.quality = quality end
	end
	if not item.c then
		local color
		if item.quality then
			_, _, _, color = GetItemQualityColor(item.quality)
		end
		if color then item.c = strsub(color,3) end
	end
	local t
	if item.name then
		t = (item.c) and ("|cFF"..item.c..item.name.."|r") or item.name
		--rt:Debug("io table",item.c,item.name)
	else
		t = L["Unknown"] .. " (ID: "..item.id..")"
	end
	if tag and (isTitle or tag~="Default") then
		t = t .. " ("..L[tag]..")"
	end
	-- ("("..item.id..")  " ..

	return t, tag
end


function RT_ItemOptions:OnLoad( frame )
	local L = RaidTracker.L
	local desc = RT_Options.desc

	frame._csHeaderTitle:SetText(L["Raid Tracker"].." - "..L["Item Options"])
	frame._csHeaderText:SetText("")

	local info = {
		Log = { title="Log", type="Slider", class="RT_SliderTemplate", opts = desc.itemopt, desc = "Log this item. Default uses the default options.", },
		Stack = { title="Stack", type="Slider", class="RT_SliderTemplate", opts = desc.itemopt, desc = "Stack this item rather than log individualy.  Default uses the default options.", },
		CostGet = { title="Get Cost", type="Slider", class="RT_SliderTemplate", opts = desc.itemopt, desc = "Get cost for this item from an external cost system, such as Hellbender DKP or ItemLevelDKP. Default uses the default options.", },
		CostAsk = { title="Ask Cost", type="Slider", class="RT_SliderTemplate", opts = desc.itemopt, desc = "Ask for cost using a popup box as loot is received. Get Cost always happens before Ask Cost. Default uses the default options.", },
	}

	RT_Templates:InitWidgets( frame._cfEdit, RT_Button, info )
end


function RT_ItemOptions:OnShow( frame )
	if self.OnLoad then self:OnLoad(frame); self.OnLoad = nil end
	RT_ItemOptions:Update()
end


function RT_ItemOptions:Update( )
	local f,rt = RT_ItemOptionsFrame, RaidTracker
	local db,o,L = rt._db,rt._options,rt.L
	f.itemid = self:GetItemIid(f.itemid)
	f.items = f.items or setmetatable( {}, { __index = db.ItemOptions } )

	-- get items, allow for called edit or add through interface
	if f.itemid and not f.items[f.itemid] then
		f.items[f.itemid] = { id = f.itemid, Log = 0, Stack = 1, CostGet = 0, CostAsk = 0, }
	end
	f.list = rt:TableGetValues(f.items, self.sortName )
	if f.itemid then								-- requesting to edit or add a specific one
		for i,v in pairs(f.list) do
			if v.id == f.itemid then o.ItemOptionsSelected = i break end
		end
		f.itemid = nil
	end
	RT_ItemOptionsItems_ScrollUpdate()

	local fe = f._cfEdit
	if not o.ItemOptionsSelected then
		fe:Hide()
		return
	elseif o.ItemOptionsSelected > #f.list then
		o.ItemOptionsSelected = #f.list
	end

	local item = f.list[o.ItemOptionsSelected]
	local title, tag = self:GetDispName(item, true)
	fe:Hide()
	fe.id = o.ItemOptionsSelected
	fe.item = item
	fe._csTitle:SetText( title )
	fe._csLinkID:SetText( "Item ID: " .. item.id )
	fe.Log:SetValue( item.Log and (item.Log + 1) or 0 );
	fe.Stack:SetValue( item.Stack and (item.Stack + 1) or 0 );
	fe.CostGet:SetValue( item.CostGet and (item.CostGet + 1) or 0 );
	fe.CostAsk:SetValue( item.CostAsk and (item.CostAsk + 1) or 0 )
	if tag == "Default" then
		fe._cbDelete:Disable()
	else
		fe._cbDelete:Enable()
	end
	fe:Show()
end


function RT_ItemOptions:Edit_Save( frame )
	local rt = RaidTracker
	local db = rt._db

	-- propagate default values or add new item to database
	local item = rt:TableSet(db.ItemOptions, frame.item.id, frame.item, true)
	frame:GetParent().items[item.id] = nil

	i = frame.Log:GetValue(); item.Log = (i ~= 0) and i-1 or nil
	i = frame.Stack:GetValue(); item.Stack = (i ~= 0) and i-1 or nil
	i = frame.CostGet:GetValue(); item.CostGet = (i ~= 0) and i-1 or nil
	i = frame.CostAsk:GetValue(); item.CostAsk = (i ~= 0) and i-1 or nil;

	RT_ItemOptions:Update()
end

function RT_ItemOptions:Delete( frame )
	local rt = RaidTracker;	local db = rt._db
	local itemId = frame.item.id
	db.ItemOptions[itemId] = nil;
	frame:GetParent().items[itemId] = nil;
	RT_ItemOptions:Update()
end


function RT_ItemOptionsItems_ScrollUpdate( )
	local _frame,rt = RT_ItemOptionsFrame, RaidTracker
	local frame = _frame._cfList._csfItems
	local db,o = rt._db, rt._options

	local data = _frame.list
	local maxlines = #data
	local lines, count = frame.lines, frame.listcount

	FauxScrollFrame_Update(frame, maxlines, count, frame.listheight)
	local offset = FauxScrollFrame_GetOffset(frame)
	for i = 1,count do
		local id = i + offset
		local line = lines[i]

		if id > maxlines then
			line:Hide()
		else
			local item = data[id]
			local title, tag = RT_ItemOptions:GetDispName(item)
			line.id = id
			line.item = item
			line.selected = (o.ItemOptionsSelected == id) and 1 or nil
			line:SetText(title)
			if tag == "Unsaved" then
				line:GetFontString():SetTextColor(0.85,0.75,0.10,1)
				line:SetNormalFontObject("GameFontNormal")
			elseif tag == "Default" then
				line:GetFontString():SetTextColor(0.85,0.75,0.10,0.70)
				line:SetNormalFontObject("GameFontNormalSmall")
			else
				line:GetFontString():SetTextColor(0.85,0.75,0.10,1)
				line:SetNormalFontObject("GameFontNormal")
			end
			if line.selected then
				line.mouseover:Show()
				line:SetNormalFontObject("GameFontNormal")
			else
				line.mouseover:Hide()
			end
			line:Show()
		end
	end
	frame:Show()
end


