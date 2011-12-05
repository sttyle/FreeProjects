--
-- Cooling
-- Copyright (C) 2005-2010 Kimmo Teräväinen
--
-- General GNU Public license.
--
-- This interface addon shows spells,action and items on cooldown.
-- It has table based rules to select/disable/direct cooldowns into user
-- definable icon groups.
--
-- Author: Kimmo Teräväinen <teardroppixie@sourceforge.net>
--
-- See CHANGES.txt to view recent changes and history.
-- See TODO.txt to view known bugs and requested upcoming features.

COOLING2_VERSION = "4.0.0"

local Cooling2_Config_Loaded = nil;
local Cooling2_Profile = nil;
local Cooling2_ProfileClass = nil;
local Cooling2_SetupMode = nil;
local Cooling2_LastUpdate = 0;
local Cooling2_Elapsed = 0;
local COOLING_BUTTONS = 15;
-- FIXME: icon/button settings should not be in this local object
local Cooling2_Cooldown = {};
Cooling2_Cooldown[0] = { count=0 };
Cooling2_Cooldown[1] = { count=0, firstbutton=1, lastbutton = 6 };
Cooling2_Cooldown[2] = { count=0, firstbutton=7, lastbutton = 12 };
Cooling2_Cooldown[3] = { count=0, firstbutton=13, lastbutton = 15 };

local Cooling2_Default = {};
Cooling2_Default.button = {};
--
Cooling2_Default.button[0] = {};
Cooling2_Default.button[0][1] = {};
Cooling2_Default.button[0][1][1] = "142,110s1.25a1";
Cooling2_Default.button[0][1][2] = "30,0s1.25a1";
Cooling2_Default.button[0][1][3] = "60,0s1.25a1";
Cooling2_Default.button[0][1][4] = "90,0s1.25a1";
Cooling2_Default.button[0][1][5] = "120,0s.251a1";
Cooling2_Default.button[0][1][6] = "150,0s1.25a1";
Cooling2_Default.button[0][2] = {};
Cooling2_Default.button[0][2][1] = "142,140s1.25a1";
Cooling2_Default.button[0][2][2] = "30,0s1.25a1";
Cooling2_Default.button[0][2][3] = "60,0s1.25a1";
Cooling2_Default.button[0][2][4] = "90,0s1.25a1";
Cooling2_Default.button[0][2][5] = "120,0s1.25a1";
Cooling2_Default.button[0][2][6] = "150,0s1.25a1";
Cooling2_Default.button[0][3] = {};
Cooling2_Default.button[0][3][1] = "82,110s1.6a1";
Cooling2_Default.button[0][4] = {};
Cooling2_Default.button[0][4][1] = "82,140s1.6a1";
Cooling2_Default.button[0][5] = {};
Cooling2_Default.button[0][5][1] = "82,170s1.6a1";
--
Cooling2_Default.button[1] = {};
Cooling2_Default.button[1][1] = {};
Cooling2_Default.button[1][1][1] = "427,196s1.25a1";
Cooling2_Default.button[1][1][2] = "22,0s1.25a1";
Cooling2_Default.button[1][1][3] = "44,0s1.25a1";
Cooling2_Default.button[1][1][4] = "66,0s1.25a1";
Cooling2_Default.button[1][1][5] = "88,0s1.25a1";
Cooling2_Default.button[1][1][6] = "110,0s1.25a1";
Cooling2_Default.button[1][2] = {};
Cooling2_Default.button[1][2][1] = "427,174s1.25a1";
Cooling2_Default.button[1][2][2] = "22,0s1.25a1";
Cooling2_Default.button[1][2][3] = "44,0s1.25a1";
Cooling2_Default.button[1][2][4] = "66,0s1.25a1";
Cooling2_Default.button[1][2][5] = "88,0s1.25a1";
Cooling2_Default.button[1][2][6] = "110,0s1.25a1";
Cooling2_Default.button[1][3] = {};
Cooling2_Default.button[1][3][1] = "351,118s1.6a1";
Cooling2_Default.button[1][3][2] = "22,0s1.6a1";
Cooling2_Default.button[1][3][3] = "44,0s1.6a1";
--Cooling2_DefaultComputed = nil;


-- Setup default Icon positions, alpha and scale for all icons
-- This does nothing if those are already set. To reset
-- Cooling2_Config[Cooling2_Profile].button_alpha = {}; before Call.
--
local function Cooling2_SetupDefault(layout)
	local b=1;
	local i=1;
	if(not Cooling2_Default.button[layout]) then return; end

	while(Cooling2_Default.button[layout][i]) do
		local j=1;
		local a=b;
		while(Cooling2_Default.button[layout][i][j]) do
			local button = getglobal ("Cooling2_Button"..b);
			if (button) then
				if (not Cooling2_Config[Cooling2_Profile].button_alpha[b]) then
					local idx = string.find(Cooling2_Default.button[layout][i][j],"s");
					local tleft = string.sub(Cooling2_Default.button[layout][i][j],1,idx-1);
					local tright = string.sub(Cooling2_Default.button[layout][i][j],idx+1);
					idx = string.find(tleft,",");
					local left = string.sub(tleft,1,idx-1) / UIParent:GetScale();
					local top = string.sub(tleft,idx+1) / UIParent:GetScale();
					idx = string.find(tright,"a");
					local scale = string.sub(tright,1,idx-1);
					local alpha = string.sub(tright,idx+1);

					Cooling2_Config[Cooling2_Profile].button_x[b] = left;
					Cooling2_Config[Cooling2_Profile].button_y[b] = top;
					Cooling2_Config[Cooling2_Profile].button_scale[b] = scale;
					Cooling2_Config[Cooling2_Profile].button_digital[b] = 0;
					Cooling2_Config[Cooling2_Profile].button_shadow[b] = 1;
					Cooling2_Config[Cooling2_Profile].button_alpha[b] = alpha;
					Cooling2_Config[Cooling2_Profile].button_anchor[b] = a;
				end
			end
			b=b+1;
			j=j+1;
		end
		i=i+1;
	end
end


local function Cooling2_SetDefaultRuleset()
	local blaahclass, unitclass = UnitClass("player");
	-- rules for spellbook
	Cooling2_Ruleset[Cooling2_Profile][0] = {  }
	Cooling2_Ruleset[Cooling2_Profile][0][0] = { target=1, rule = {} }
	Cooling2_Ruleset[Cooling2_Profile][0][0].rule[0] = { minimum=3.0, maximum=60, match="" }
	Cooling2_Ruleset[Cooling2_Profile][0][1] = { target=2, rule = {} }
	Cooling2_Ruleset[Cooling2_Profile][0][1].rule[0] = { minimum=60, maximum=300, match="" }
	Cooling2_Ruleset[Cooling2_Profile][1] = {  }
	Cooling2_Ruleset[Cooling2_Profile][1][0] = { target=1, rule = {} }
	Cooling2_Ruleset[Cooling2_Profile][1][0].rule[0] = { minimum=3.0, maximum=60, match="" }
	Cooling2_Ruleset[Cooling2_Profile][1][1] = { target=2, rule = {} }
	Cooling2_Ruleset[Cooling2_Profile][1][1].rule[0] = { minimum=60, maximum=300, match="" }
	Cooling2_Ruleset[Cooling2_Profile][2] = {  }
	Cooling2_Ruleset[Cooling2_Profile][2][0] = { target=1, rule = {} }
	Cooling2_Ruleset[Cooling2_Profile][2][0].rule[0] = { minimum=3.0, maximum=60, match="" }
	Cooling2_Ruleset[Cooling2_Profile][2][1] = { target=2, rule = {} }
	Cooling2_Ruleset[Cooling2_Profile][2][1].rule[0] = { minimum=60, maximum=300, match="" }
	Cooling2_Ruleset[Cooling2_Profile][3] = {  }
	Cooling2_Ruleset[Cooling2_Profile][3][0] = { target=1, rule = {} }
	Cooling2_Ruleset[Cooling2_Profile][3][0].rule[0] = { minimum=3.0, maximum=60, match="" }
	Cooling2_Ruleset[Cooling2_Profile][3][1] = { target=2, rule = {} }
	Cooling2_Ruleset[Cooling2_Profile][3][1].rule[0] = { minimum=60, maximum=300, match="" }
	-- rules for pet spellbook
	Cooling2_Ruleset[Cooling2_Profile][4] = {  }
	Cooling2_Ruleset[Cooling2_Profile][4][0] = { target=1, rule = {} }
	Cooling2_Ruleset[Cooling2_Profile][4][0].rule[0] = { minimum=3.0, maximum=60, match="" }
	Cooling2_Ruleset[Cooling2_Profile][4][1] = { target=2, rule = {} }
	Cooling2_Ruleset[Cooling2_Profile][4][1].rule[0] = { minimum=60, maximum=300, match="" }
	-- rules for equipment
	Cooling2_Ruleset[Cooling2_Profile][5] = {  }
	Cooling2_Ruleset[Cooling2_Profile][5][0] = { target=1, rule = {} }
	Cooling2_Ruleset[Cooling2_Profile][5][0].rule[0] = { minimum=3.0, maximum=60, match="" }
	Cooling2_Ruleset[Cooling2_Profile][5][1] = { target=3, rule = {} }
	Cooling2_Ruleset[Cooling2_Profile][5][1].rule[0] = { minimum=60, maximum=1000000, match="" }
	-- rules for containers
	Cooling2_Ruleset[Cooling2_Profile][6] = {  }
	Cooling2_Ruleset[Cooling2_Profile][6][0] = { target=1, rule = {} }
	Cooling2_Ruleset[Cooling2_Profile][6][0].rule[0] = { minimum=3.0, maximum=60, match="" }
	Cooling2_Ruleset[Cooling2_Profile][6][1] = { target=3, rule = {} }
	Cooling2_Ruleset[Cooling2_Profile][6][1].rule[0] = { minimum=60, maximum=1000000, match="" }
	
	--rules based on unitclass (counterspell detection & talent tree cooldowns)
	if(unitclass=="DEATHKNIGHT") then
        Cooling2_Ruleset[Cooling2_Profile][0] = {  }
        Cooling2_Ruleset[Cooling2_Profile][0][0] = { target=1, rule = {} }
        Cooling2_Ruleset[Cooling2_Profile][0][0].rule[0] = { minimum=3.0, maximum=60, match="" }
        Cooling2_Ruleset[Cooling2_Profile][0][1] = { target=2, rule = {} }
        Cooling2_Ruleset[Cooling2_Profile][0][1].rule[0] = { minimum=60, maximum=300, match="" }
        Cooling2_Ruleset[Cooling2_Profile][1] = {  }
        Cooling2_Ruleset[Cooling2_Profile][1][0] = { target=1, rule = {} }
        Cooling2_Ruleset[Cooling2_Profile][1][0].rule[0] = { minimum=10.0, maximum=60, match="" }
        Cooling2_Ruleset[Cooling2_Profile][1][0].rule[1] = { minimum=2.5, maximum=10, match="Dark Command"}
        Cooling2_Ruleset[Cooling2_Profile][1][1] = { target=2, rule = {} }
        Cooling2_Ruleset[Cooling2_Profile][1][1].rule[0] = { minimum=60, maximum=300, match="" }
        Cooling2_Ruleset[Cooling2_Profile][2] = {  }
        Cooling2_Ruleset[Cooling2_Profile][2][0] = { target=1, rule = {} }
        Cooling2_Ruleset[Cooling2_Profile][2][0].rule[0] = { minimum=10.0, maximum=60, match="" }
		Cooling2_Ruleset[Cooling2_Profile][2][0].rule[1] = { minimum=2.5, maximum=10, match="Mind Freeze"}
        Cooling2_Ruleset[Cooling2_Profile][2][1] = { target=2, rule = {} }
        Cooling2_Ruleset[Cooling2_Profile][2][1].rule[0] = { minimum=60, maximum=300, match="" }
        Cooling2_Ruleset[Cooling2_Profile][3] = {  }
        Cooling2_Ruleset[Cooling2_Profile][3][0] = { target=1, rule = {} }
        Cooling2_Ruleset[Cooling2_Profile][3][0].rule[0] = { minimum=10.0, maximum=60, match="" }
        Cooling2_Ruleset[Cooling2_Profile][3][1] = { target=2, rule = {} }
        Cooling2_Ruleset[Cooling2_Profile][3][1].rule[0] = { minimum=60, maximum=300, match="" }
		Cooling2_Ruleset[Cooling2_Profile][3][1].rule[1] = { minimum=2.5, maximum=600, match="Army of the Dead"}
		Cooling2_Ruleset[Cooling2_Profile][3][1].rule[2] = { minimum=2.5, maximum=600, match="Raise Ally"}
	elseif(unitclass=="DRUID") then
		--FIXME: maybe add separate rule/icon for Mangle (feral druids)
		Cooling2_Ruleset[Cooling2_Profile][1][2] = { target=3, rule = {} }
		Cooling2_Ruleset[Cooling2_Profile][1][2].rule[0] = { minimum=2.5, maximum=1000000, match="Moonfire"}
		Cooling2_Ruleset[Cooling2_Profile][1][2].rule[1] = { minimum=2.5, maximum=1000000, match="Maim"}
		Cooling2_Ruleset[Cooling2_Profile][1][2].rule[2] = { minimum=2.5, maximum=1000000, match="Growl"}
		Cooling2_Ruleset[Cooling2_Profile][1][2].rule[3] = { minimum=2.5, maximum=1000000, match="Healing Touch"}
	elseif(unitclass=="MAGE") then
		Cooling2_Ruleset[Cooling2_Profile][1][2] = { target=3, rule = {} }
		Cooling2_Ruleset[Cooling2_Profile][1][2].rule[0] = { minimum=2.5, maximum=1000000, match="Missiles"}
		Cooling2_Ruleset[Cooling2_Profile][1][2].rule[1] = { minimum=2.5, maximum=1000000, match="Fireball"}
		Cooling2_Ruleset[Cooling2_Profile][1][2].rule[2] = { minimum=2.5, maximum=1000000, match="Frostbolt"}
	elseif(unitclass=="PRIEST") then
		Cooling2_Ruleset[Cooling2_Profile][1][2] = { target=3, rule = {} }
		Cooling2_Ruleset[Cooling2_Profile][1][2].rule[0] = { minimum=2.5, maximum=1000000, match="Shield"}
		Cooling2_Ruleset[Cooling2_Profile][1][2].rule[1] = { minimum=2.5, maximum=1000000, match="Heal"}
		Cooling2_Ruleset[Cooling2_Profile][1][2].rule[2] = { minimum=2.5, maximum=1000000, match="Pain"}
	elseif(unitclass=="WARLOCK") then
		Cooling2_Ruleset[Cooling2_Profile][3][3] = { target=3, rule = {} }
		Cooling2_Ruleset[Cooling2_Profile][3][3].rule[0] = { minimum=2.5, maximum=1000000, match="Shadow Bolt"}
		Cooling2_Ruleset[Cooling2_Profile][3][3].rule[1] = { minimum=2.5, maximum=1000000, match="Immolation"}
		
	--FIXME: PALADIN & SHAMAN counterspell detection
	--FIXME: WARRIOR & ROGUE special talent tree cooldowns - look druid rule for Maim/Growl
	end
	
end


local function Cooling2_SetLocations()
	local i,d=1;
	local anchor=0;
	
	--while(Cooling2_Cooldown[d]) do
	--	anchor = Cooling2_Cooldown[d].firstbutton;
	--	local button = getglobal("Cooling2_Button"..anchor);
	--	button.anchor=0; i=anchor+1;
	--	while(i<=Cooling2_Cooldown[d].lastbutton) do
	--		local button = getglobal("Cooling2_Button"..i);
	--		button.anchor=anchor;
	--		i = i + 1;
	--	end
	--	d = d +1;
	--end

	for i = 1, COOLING_BUTTONS, 1 do
		local button = getglobal ("Cooling2_Button"..i);
		if (button) then
			local left = Cooling2_Config[Cooling2_Profile].button_x[i];
			local top = Cooling2_Config[Cooling2_Profile].button_y[i];
			button:ClearAllPoints();
			button:SetScale(Cooling2_Config[Cooling2_Profile].button_scale[i]);
			--FIXME: save anchor information to button (allowing more flexible anchoring)
			if(i==Cooling2_Config[Cooling2_Profile].button_anchor[i]) then
				button:SetPoint("TOPLEFT","UIParent","BOTTOMLEFT",left,top);
			else
				button:SetPoint("TOPLEFT","Cooling2_Button"..Cooling2_Config[Cooling2_Profile].button_anchor[i],"TOPLEFT",left,top);
			end
		end
	end
end


-- This routine ensures that basic profile settings are present
-- It should do nothing othervise.
local function Cooling2_ConfigInit()
	if(not Cooling2_Profile or not Cooling2_Config_Loaded) then return; end
	
	if(not Cooling2_Config) then Cooling2_Config = {}; end
	if(not Cooling2_Ruleset) then Cooling2_Ruleset = {}; end
	
	if (not Cooling2_Config[Cooling2_Profile]) then Cooling2_Config[Cooling2_Profile] = {}; end
	if (not Cooling2_Ruleset[Cooling2_Profile]) then
		Cooling2_Ruleset[Cooling2_Profile] = {};
		Cooling2_SetDefaultRuleset();
	end	
	
	if (not Cooling2_Config[Cooling2_Profile].button_anchor) then
		Cooling2_Config[Cooling2_Profile].button_x = {};
		Cooling2_Config[Cooling2_Profile].button_y = {};
		Cooling2_Config[Cooling2_Profile].button_shadow = {};
		Cooling2_Config[Cooling2_Profile].button_scale = {};
		Cooling2_Config[Cooling2_Profile].button_digital = {};
		Cooling2_Config[Cooling2_Profile].button_alpha = {};
		Cooling2_Config[Cooling2_Profile].button_anchor = {};
	end
	Cooling2_SetupDefault(1);
end


local function Cooling2_ClearCooldowns()
	local b;
	local d=0;
	Cooling2_Cooldown = {};
	Cooling2_Cooldown[0] = {};
	Cooling2_Cooldown[0].count = 0;
	for b = 1, COOLING_BUTTONS, 1 do
		if(Cooling2_Config[Cooling2_Profile].button_anchor[b]==b) then
			d=d+1;
			Cooling2_Cooldown[d] = {};
			Cooling2_Cooldown[d].count = 0;
			Cooling2_Cooldown[d].firstbutton = b;
		end
		Cooling2_Cooldown[d].lastbutton = b;
	end
	--while(Cooling2_Cooldown[d]) do
	--	Cooling2_Cooldown[d].count = 0;
	--	d=d+1;
	--end
end


local function Cooling2_SetTexture(button, texture)
	button.texture = texture;
	local icon = getglobal(button:GetName().."Icon");
	icon:SetTexture(button.texture);
end


local function Cooling2_AddCooldown(target, starttime, endtime, texture, name)
	local i=0;
	-- FIXME: hack to ensure that SCT exists before it is called
	--if(target==0 and not SCT) then return; end 

	-- it is possible there is a rule, but not a target - then cooldown is silently ignored
	if(not Cooling2_Cooldown[target]) then 
        return; 
    end
	
	-- see if we are already tracking a cooldown with the same name
    while(i<Cooling2_Cooldown[target].count) do
        if(Cooling2_Cooldown[target][i].name==name) then 
            return; 
        end
		i = i + 1;
	end

    i = 0;

    while(i<Cooling2_Cooldown[target].count) do
        if(Cooling2_Cooldown[target][i].endtime<=endtime) then 
            break; 
        end
		i = i + 1;
	end
    
	if(i<Cooling2_Cooldown[target].count and Cooling2_Cooldown[target][i].endtime<endtime) then
		local j=Cooling2_Cooldown[target].count;
        
		while(i<=j) do
			Cooling2_Cooldown[target][j+1] = Cooling2_Cooldown[target][j];
			j=j-1;
		end
        
		Cooling2_Cooldown[target].count=Cooling2_Cooldown[target].count+1;
	end
    
    if(i==Cooling2_Cooldown[target].count) then 
        Cooling2_Cooldown[target].count=Cooling2_Cooldown[target].count+1; 
    end
	
    Cooling2_Cooldown[target][i] = { endtime=endtime, starttime=starttime, name=name, texture=texture };
	
    --FIXME: You may want to keep texture/name if cooldown is replaced with another 1
end


local function Cooling2_CheckCooldown(source, starttime, duration, texture, name)
	local d=0; -- destination in rule set (temp variable)
	
	while (Cooling2_Ruleset[Cooling2_Profile][source][d]) do
		local r=0;
		while(Cooling2_Ruleset[Cooling2_Profile][source][d].rule[r]) do
			if(Cooling2_Ruleset[Cooling2_Profile][source][d].rule[r].minimum<duration and duration<=Cooling2_Ruleset[Cooling2_Profile][source][d].rule[r].maximum and string.find(name,Cooling2_Ruleset[Cooling2_Profile][source][d].rule[r].match)) then
				--if(Cooling2_Ruleset[Cooling2_Profile][source][d].rule[r].accept) then
					-- Add this cooldown to target list
					Cooling2_AddCooldown(Cooling2_Ruleset[Cooling2_Profile][source][d].target, starttime, starttime+duration, texture, name);
				--end
				break;
			end
			r=r+1;
		end
		d=d+1;
	end	
end


local function CleanLink(link)
	return string.gsub(link,"[^%[]*%[([^%]]*)%][^%]]*","%1");
end


local function Cooling2_CheckCooldowns()
    local searchName, subName, start, duration, enable, autocast;

	if (Cooling2_Config and Cooling2_Config[Cooling2_Profile]) then
		-- check general (spellbook) cooldowns
		for tab=1, MAX_SKILLLINE_TABS do
			local name, texture, offset, numSpells = GetSpellTabInfo(tab);
			if(not name) then break; end
			for id= offset+1, offset+numSpells do
				searchName, subName = GetSpellBookItemName(id, BOOKTYPE_SPELL);
	
				start, duration, enable = GetSpellCooldown(id, BOOKTYPE_SPELL);

				if (0<enable and 0<start) then
					Cooling2_CheckCooldown(tab-1, start, duration, GetSpellTexture(id, BOOKTYPE_SPELL),searchName);
                end
	
			end
		end
		
		-- check pet (spellbook) cooldowns
		--if(Cooling2_Config[Cooling2_Profile].pet and UnitExists("pet")) then
		if(UnitExists("pet")) then
			local id = 1;
			while (true) do
				searchName, subName = GetSpellBookItemName(id,BOOKTYPE_PET);
				if (not searchName) then break; end
				_,autocast=GetSpellAutocast(id,BOOKTYPE_PET);

				start, duration, enable = GetSpellCooldown(id, BOOKTYPE_PET);

                if (0<enable and 0<start and (not autocast)) then
					Cooling2_CheckCooldown(4, start, duration, GetSpellTexture(id, BOOKTYPE_PET),searchName);
				end

				id = id + 1;
			end
		end

		-- check inventory (equipment) slots
		if(not Cooling2_Config[Cooling2_Profile].noinventory) then
			local id = 0;
			for id=0, 19 do
				if( GetInventoryItemTexture("player", id) ~= nil ) then
					start, duration = GetInventoryItemCooldown("player", id);

                    if(0<start and 0<duration) then
						Cooling2_CheckCooldown(5, start, duration, GetInventoryItemTexture("player", id),CleanLink(GetInventoryItemLink("player", id)) );
					end
				end
			end
		end
		
		-- check container (bags) slots
		if(not Cooling2_Config[Cooling2_Profile].nocontainers) then
			local id = 0;
			for id=0, 4 do
				local bagType = GetBagName(id);
				--if (bagType ) and not ( string.find(bagType, "Ammo") or string.find(bagType, "Quiver") or string.find(bagType, "Wrapped") ) then
					local d;
					for d=1, GetContainerNumSlots(id) do
						local texture = GetContainerItemInfo(id, d);
						if( texture ) then
							start, duration = GetContainerItemCooldown(id,d);

                            if(0<start and 0<duration) then
								Cooling2_CheckCooldown(6, start, duration, texture, CleanLink(GetContainerItemLink(id,d)));
							end
						end
					end
				--end
			end
		end
	end
end


local function Cooling2_SlashCmd(msg)
	--msg = string.lower(msg);
	local firstword = nil;
	local restwords = nil;
	local idx = string.find(msg," ");
	if (idx) then
		firstword = string.sub(msg,1,idx-1);
		restwords = string.sub(msg,idx+1);
	else
		firstword = msg;
	end

	if (firstword == "reset") then
		if(restwords) then
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: Resetting display positions to layout "..restwords..".");
			Cooling2_Config[Cooling2_Profile].button_alpha = {};
			Cooling2_SetupDefault(restwords+0);
			Cooling2_SetLocations();
			Cooling2_ClearCooldowns();
		else
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: Not resetting display positions!");
			DEFAULT_CHAT_FRAME:AddMessage("To reset them specify layout. f.e");
			DEFAULT_CHAT_FRAME:AddMessage("/cooling reset 0 -- bottomleft (test) positions");
			DEFAULT_CHAT_FRAME:AddMessage("/cooling reset 1 -- middle (default) positions");
		end
	elseif (firstword == "refresh") then
		if (restwords == "on") then
			Cooling2_Config[Cooling2_Profile].refresh = 1;
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: Automatic refresh is now on.");
		elseif (restwords == "off") then
			Cooling2_Config[Cooling2_Profile].refresh = nil;
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: Automatic refresh is now off.");
		else
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: Refreshing cooldowns.");
			Cooling2_ClearCooldowns();
			Cooling2_CheckCooldowns();
		end

	elseif (firstword == "digital") then
		if(restwords) then idx = string.find(restwords," "); else idx=nil; end
		if (idx) then
			local bid = string.sub(restwords,1,idx-1) + 0;
			local setting = string.sub(restwords,idx+1);
			if(1<=bid and bid <=COOLING_BUTTONS) then
				if(setting=="on") then
					Cooling2_Config[Cooling2_Profile].button_digital[bid] = 1;
				elseif(setting=="off") then
					Cooling2_Config[Cooling2_Profile].button_digital[bid] = 0;
				end
			end
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: button["..bid.."].digital = "..Cooling2_Config[Cooling2_Profile].button_digital[bid]..".");
		else
			for idx=1, COOLING_BUTTONS do
				DEFAULT_CHAT_FRAME:AddMessage("Cooling: button["..idx.."].digital = "..Cooling2_Config[Cooling2_Profile].button_digital[idx]..".");
			end		
		end

	elseif (firstword == "shadow") then
		if(restwords) then idx = string.find(restwords," "); else idx=nil; end
		if (idx) then
			local bid = string.sub(restwords,1,idx-1) + 0;
			local setting = string.sub(restwords,idx+1);
			if(1<=bid and bid <=COOLING_BUTTONS) then
				if(setting=="on") then
					Cooling2_Config[Cooling2_Profile].button_shadow[bid] = 1;
				elseif(setting=="off") then
					Cooling2_Config[Cooling2_Profile].button_shadow[bid] = 0;
				end
			end
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: button["..bid.."].shadow = "..Cooling2_Config[Cooling2_Profile].button_shadow[bid]..".");
		else
			for idx=1, COOLING_BUTTONS do
				DEFAULT_CHAT_FRAME:AddMessage("Cooling: button["..idx.."].shadow = "..Cooling2_Config[Cooling2_Profile].button_shadow[idx]..".");
			end		
		end

	elseif (firstword == "alpha") then
		if(restwords) then idx = string.find(restwords," "); else idx=nil; end
		if (idx) then
			local bid = string.sub(restwords,1,idx-1) + 0;
			local setting = string.sub(restwords,idx+1);
			if(1<=bid and bid <=COOLING_BUTTONS) then
				if(setting and 0<=(setting+0.0) and (setting+0.0)<=1.0) then
					Cooling2_Config[Cooling2_Profile].button_alpha[bid] = 0.0+setting;
				else
					Cooling2_Config[Cooling2_Profile].button_alpha[bid] = 1.0;
				end
				Cooling2_SetLocations();
			end
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: button["..bid.."].alpha = "..Cooling2_Config[Cooling2_Profile].button_alpha[bid]..".");
		else
			for idx=1, COOLING_BUTTONS do
				DEFAULT_CHAT_FRAME:AddMessage("Cooling: button["..idx.."].alpha = "..Cooling2_Config[Cooling2_Profile].button_alpha[idx]..".");
			end		
		end

	elseif (firstword == "scale") then
		if(restwords) then idx = string.find(restwords," "); else idx=nil; end
		if (idx) then
			local bid = string.sub(restwords,1,idx-1) + 0;
			local setting = string.sub(restwords,idx+1);			
			if(1<=bid and bid <=COOLING_BUTTONS) then
				if(setting and 0.1<(setting+0.0)) then
					Cooling2_Config[Cooling2_Profile].button_scale[bid] = 0.0+setting;
				else
					Cooling2_Config[Cooling2_Profile].button_scale[bid] = 1.0;
				end
				Cooling2_SetLocations();
			end
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: button["..bid.."].scale = "..Cooling2_Config[Cooling2_Profile].button_scale[bid]..".");
		else
			for idx=1, COOLING_BUTTONS do
				DEFAULT_CHAT_FRAME:AddMessage("Cooling: button["..idx.."].scale = "..Cooling2_Config[Cooling2_Profile].button_scale[idx]..".");
			end		
		end

	elseif (firstword == "rule" or firstword == "r") then
		local cmd, src, dst, num, minimum, maximum, action, match;
		if(restwords) then
			idx = string.find(restwords," ");
			if(idx) then
				cmd = string.sub(restwords,1,idx-1);
				match = string.sub(restwords,idx+1);
				idx = string.find(match," ");
				if(idx) then
					src = string.sub(match,1,idx-1) + 0;
					restwords = string.sub(match,idx+1);
					idx = string.find(restwords," ");
					if(idx) then
						dst = string.sub(restwords,1,idx-1)+ 0;
						match = string.sub(restwords,idx+1);
						idx = string.find(match," ");
						if(idx) then
							num = string.sub(match,1,idx-1) + 0;
							restwords = string.sub(match,idx+1);
							idx = string.find(restwords," ");
							if(idx) then
								minimum = string.sub(restwords,1,idx-1)+ 0;
								match = string.sub(restwords,idx+1);
								idx = string.find(match," ");
								if(idx) then
									maximum = string.sub(match,1,idx-1) + 0;
									restwords = string.sub(match,idx+1);
									match=restwords;
								else
									maximum=match+0;
									match="";
								end
							end
						else
							num=match+0;
						end
					end
				end
			else
				cmd=restwords;
			end
		end
		if(cmd and (cmd=="list" or cmd=="l")) then
			src=0;
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: -- Listing rulesets");
			while(Cooling2_Ruleset[Cooling2_Profile][src]) do
				dst=0;
				while(Cooling2_Ruleset[Cooling2_Profile][src][dst]) do
					local i=0;
					while(Cooling2_Ruleset[Cooling2_Profile][src][dst].rule[i]) do
						DEFAULT_CHAT_FRAME:AddMessage("Cooling: S:"..src.." D:"..Cooling2_Ruleset[Cooling2_Profile][src][dst].target.." §§ R#"..i.." = ( "..Cooling2_Ruleset[Cooling2_Profile][src][dst].rule[i].minimum.."< \""..Cooling2_Ruleset[Cooling2_Profile][src][dst].rule[i].match.."\" <="..Cooling2_Ruleset[Cooling2_Profile][src][dst].rule[i].maximum.." )");
						i=i+1;
					end					
					dst=dst+1;
				end
				src=src+1;				
			end
		elseif(cmd and cmd=="reset") then
			Cooling2_SetDefaultRuleset();
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: Rulesets reset");
		elseif(cmd and cmd=="clear") then
			src=0;
			while(Cooling2_Ruleset[Cooling2_Profile][src]) do
				Cooling2_Ruleset[Cooling2_Profile][src]={};
				src=src+1;				
			end
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: Rulesets cleared");
		elseif(cmd and num) then
			if(cmd=="del" or cmd=="d") then
				if(0<=num and Cooling2_Ruleset[Cooling2_Profile][src]) then
					local d=0;
					while(Cooling2_Ruleset[Cooling2_Profile][src][d]) do
						if(Cooling2_Ruleset[Cooling2_Profile][src][d].target==dst) then
							local i=num;
							while(Cooling2_Ruleset[Cooling2_Profile][src][d].rule[num+1]) do
								Cooling2_Ruleset[Cooling2_Profile][src][d].rule[num]=Cooling2_Ruleset[Cooling2_Profile][src][d].rule[num+1];
								num=num+1;
							end
							Cooling2_Ruleset[Cooling2_Profile][src][d].rule[num] = nil;
							DEFAULT_CHAT_FRAME:AddMessage("Cooling: S:"..src.." D:"..Cooling2_Ruleset[Cooling2_Profile][src][d].target.." -- R#"..i.." deleted");
							if(num==0) then
								--delete this scr-des ruleset completely and shift others
								local t=Cooling2_Ruleset[Cooling2_Profile][src][d].target;
								i=d;
								while(Cooling2_Ruleset[Cooling2_Profile][src][i+1]) do
									Cooling2_Ruleset[Cooling2_Profile][src][i]=Cooling2_Ruleset[Cooling2_Profile][src][i+1];
									i=i+1;
								end
								Cooling2_Ruleset[Cooling2_Profile][src][i] = nil;								
								DEFAULT_CHAT_FRAME:AddMessage("Cooling: S:"..src.." D:"..t.." ruleset deleted");
							end
							break;
						end
						d=d+1;
					end
				end
			elseif(cmd=="ins" or cmd=="i" or cmd=="add" or cmd=="a") then
				if(match and Cooling2_Ruleset[Cooling2_Profile][src]) then
					local d=0;
					local i=0;
					while(Cooling2_Ruleset[Cooling2_Profile][src][d]) do
						if(Cooling2_Ruleset[Cooling2_Profile][src][d].target==dst) then break; end
						d=d+1;
					end
					if(not Cooling2_Ruleset[Cooling2_Profile][src][d]) then
						Cooling2_Ruleset[Cooling2_Profile][src][d]  = { target=dst, rule = {} };
					end
					while(Cooling2_Ruleset[Cooling2_Profile][src][d].rule[i]) do i=i+1; end
					if(num<0 or i<num) then num=i; end
					while(num<i) do
						Cooling2_Ruleset[Cooling2_Profile][src][d].rule[i]=Cooling2_Ruleset[Cooling2_Profile][src][d].rule[i-1];
						i=i-1;
					end
					Cooling2_Ruleset[Cooling2_Profile][src][d].rule[num]={ minimum=minimum, maximum=maximum, match=match };
					DEFAULT_CHAT_FRAME:AddMessage("Cooling: S:"..src.." D:"..Cooling2_Ruleset[Cooling2_Profile][src][d].target.." ++ R#"..i.." = ( "..Cooling2_Ruleset[Cooling2_Profile][src][d].rule[num].minimum.."< \""..Cooling2_Ruleset[Cooling2_Profile][src][d].rule[num].match.."\" <="..Cooling2_Ruleset[Cooling2_Profile][src][d].rule[num].maximum.." )");
				end
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: Rule view/edit");
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: valid sources (S): 0=general, 1-3=spell tree 1-3, 4=pet, 5=equipment, 6=bags");
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: valid targets (D): 0=Scrolling combat text, 1..15=Icon groups (user definable)");
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: /cooling rule list");
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: /cooling rule reset");
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: /cooling rule clear");
			--DEFAULT_CHAT_FRAME:AddMessage("Cooling: /cooling rule add <source> <target> <min> <max> <match>");
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: /cooling rule ins <source> <target> <num> <min> <max> <match>");
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: /cooling rule del <source> <target> <num>");
		end


	elseif (firstword == "setup") then
		if (Cooling2_SetupMode) then
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: Leaving setup mode.");
			Cooling2_SetupMode = nil;
			local i;
			for i = 1, COOLING_BUTTONS, 1 do
				local move = getglobal("Cooling2_Button"..i.."_Move");
				local text = getglobal ("Cooling2_Button"..i.."Text");
				text:SetText("");
				move.moving = nil;
				move:Hide();
				getglobal("Cooling2_Button"..i):Hide();
			end
			Cooling2_SetLocations();
			Cooling2_ClearCooldowns();
			Cooling2_CheckCooldowns();
			Cooling2_OnUpdate(nil, 1);
		else
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: Entering setup mode.");
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: -->Left mouse button to move icons.");
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: -->Right mouse button to modify icon groups.");

			--local d=1;
			--while(Cooling2_Cooldown[d]) do
			--	local i;
			--	for i = Cooling2_Cooldown[d].firstbutton, Cooling2_Cooldown[d].lastbutton, 1 do
			--		local button = getglobal("Cooling2_Button"..i);
			--		local text = getglobal ("Cooling2_Button"..i.."Text");
			--		text:SetText(""..d.."."..(i-Cooling2_Cooldown[d].firstbutton+1));
			--		--text:SetText(i);
			--		getglobal("Cooling2_Button"..i):Show();
			--		getglobal("Cooling2_Button"..i.."_Move"):Show();
			--	end
			--	d = d + 1;
			--end
			
			local i;
			for i = 1, COOLING_BUTTONS, 1 do
				local button = getglobal("Cooling2_Button"..i);
			--	local text = getglobal ("Cooling2_Button"..i.."Text");
			--	text:SetText(i);
				getglobal("Cooling2_Button"..i):Show();
				getglobal("Cooling2_Button"..i.."_Move"):Show();
			end
			Cooling2_SetupMode = 1;
			Cooling2_SetLocations();
			Cooling2_ClearCooldowns();
			Cooling2_OnUpdate(nil, 1);
		end

	elseif (firstword == "copy" and restwords) then
		local charname = string.upper(string.sub(restwords,1,1))..string.sub(restwords,2);
		if (Cooling2_Config[charname]) then
			Cooling2_Config[Cooling2_Profile].button_alpha = {};
			local i;
			for i = 1, COOLING_BUTTONS, 1 do
				if (Cooling2_Config[charname].button_alpha[i]) then
					Cooling2_Config[Cooling2_Profile].button_x[i] = Cooling2_Config[charname].button_x[i];
					Cooling2_Config[Cooling2_Profile].button_y[i] = Cooling2_Config[charname].button_y[i];
					Cooling2_Config[Cooling2_Profile].button_scale[i] = Cooling2_Config[charname].button_scale[i];
					Cooling2_Config[Cooling2_Profile].button_digital[i] = Cooling2_Config[charname].button_digital[i];
					Cooling2_Config[Cooling2_Profile].button_shadow[i] = Cooling2_Config[charname].button_shadow[i];
					Cooling2_Config[Cooling2_Profile].button_alpha[i] = Cooling2_Config[charname].button_alpha[i];
					Cooling2_Config[Cooling2_Profile].button_anchor[i] = Cooling2_Config[charname].button_anchor[i];
				end
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("Cooling: No such config \""..charname.."\" to copy from.");
		end
		Cooling2_SetLocations();
		Cooling2_ClearCooldowns();
		Cooling2_OnUpdate(nil, 1);
	else

		DEFAULT_CHAT_FRAME:AddMessage("/cooling (or /cooldown or /cool)");
		DEFAULT_CHAT_FRAME:AddMessage("/cooling setup -- Toggle setup mode.");
		DEFAULT_CHAT_FRAME:AddMessage("/cooling rule -- List/edit rulesets.");
		DEFAULT_CHAT_FRAME:AddMessage("/cooling refresh [on/off] -- Refresh cooldowns or setup automatic refresh");
		DEFAULT_CHAT_FRAME:AddMessage("/cooling digital [button] [on/off] -- Toggle digital cooldown display.");
		DEFAULT_CHAT_FRAME:AddMessage("/cooling shadow [button] [on/off] -- Toggle clockvise cooldown shadow frame.");
		DEFAULT_CHAT_FRAME:AddMessage("/cooling alpha [button] [num] -- Set transparency 0.0 .. 1.0.");
		DEFAULT_CHAT_FRAME:AddMessage("/cooling scale [button] [num] -- Set scaling - suggested values 0.5 .. 2.0.");
		DEFAULT_CHAT_FRAME:AddMessage("/cooling copy <character> -- Copy button locations from <character>'s config.");
		DEFAULT_CHAT_FRAME:AddMessage("/cooling reset <layout> -- Reset display positions");
	end
end


function Cooling2_OnLoad(this)
	this:RegisterEvent("SPELL_UPDATE_COOLDOWN");
	--this:RegisterEvent("PLAYER_ENTER_COMBAT");
	--this:RegisterEvent("PLAYER_LEAVE_COMBAT");
	--this:RegisterEvent("PLAYER_REGEN_ENABLED");
	--this:RegisterEvent("PLAYER_REGEN_DISABLED");
	--this:RegisterEvent("TRADE_SKILL_UPDATE");
	this:RegisterEvent("PLAYER_ENTERING_WORLD");
	this:RegisterEvent("SPELLS_CHANGED");

	SLASH_COOLING1 = "/cooling";
	SLASH_COOLING2 = "/cooldown";
	SLASH_COOLING3 = "/cool";
	SlashCmdList["COOLING"] = function (msg)
		Cooling2_SlashCmd(msg);
	end

	Cooling2_Profile = UnitName("player");
	
	DEFAULT_CHAT_FRAME:AddMessage("Cooling ("..COOLING2_VERSION..") loaded. '/cooling' for command list.");
end


function Cooling2_OnEvent(event)
	if (event == "SPELL_UPDATE_COOLDOWN") then
		if (Cooling2_Profile and Cooling2_Config_Loaded) then
			if(Cooling2_Config[Cooling2_Profile].refresh) then Cooling2_ClearCooldowns(); end

            Cooling2_CheckCooldowns();
		end
	elseif (event == "SPELLS_CHANGED" and Cooling2_Profile and Cooling2_Config_Loaded) then
		Cooling2_ClearCooldowns();
		Cooling2_CheckCooldowns();
	elseif (event == "PLAYER_ENTERING_WORLD") then
		if (not Cooling2_Config_Loaded) then
			Cooling2_Config_Loaded = 1;
			Cooling2_ConfigInit();
			Cooling2_SetLocations();
		end
		Cooling2_ClearCooldowns();
		Cooling2_CheckCooldowns();
	end
end


function Cooling2_OnUpdate(self, elapsed)
	Cooling2_LastUpdate = Cooling2_LastUpdate + elapsed;

	if (not Cooling2_Config or not Cooling2_Profile or not Cooling2_Config[Cooling2_Profile]) then
		return;
	end

	if (Cooling2_LastUpdate > 0.1) then
		Cooling2_LastUpdate = 0;

		-- Check SCT list - and spawn SCT Message
		while(0<Cooling2_Cooldown[0].count) do
			local timeleft = Cooling2_Cooldown[0][Cooling2_Cooldown[0].count-1].endtime - GetTime();
			if(timeleft<0) then
				local color = {r = 0.0, g = 1.0, b = 1.0};
				Cooling2_Cooldown[0].count=Cooling2_Cooldown[0].count-1;
				-- FIXME: maybe do another kind of check if SCT exists
				if (SCT) then
					SCT:DisplayText(Cooling2_Cooldown[0][Cooling2_Cooldown[0].count].name.." is ready!", color, nil, "event", 1);
				elseif (CombatText_AddMessage) then
					CombatText_AddMessage(Cooling2_Cooldown[0][Cooling2_Cooldown[0].count].name.." is ready", CombatText_StandardScroll, 0.5, 1, 1, "crit", true);
				end
				--Cooling2_Cooldown[0][Cooling2_Cooldown[0].count]=nil;
			else
				break;
			end
		end
		
		if (Cooling2_SetupMode) then
		    local i,j,k;
		    j=0;
			for i = 1, COOLING_BUTTONS, 1 do
				local button = getglobal("Cooling2_Button"..i);
				local icon = getglobal("Cooling2_Button"..i.."Icon");
				local text = getglobal ("Cooling2_Button"..i.."Text");
				--Cooling2_Config[Cooling2_Profile].button_anchor[i]
				if(Cooling2_Config[Cooling2_Profile].button_anchor[i]==i) then
					j=j+1; k=1;
					icon:SetTexture("Interface\\Icons\\Spell_Ice_Lament");
				else
					k=k+1;
					icon:SetTexture("Interface\\Icons\\Spell_Frost_Frost");
				end
				text:SetText(""..i..":"..j);
				button:SetAlpha(1.0);
				button:Show();
			end
		else
			local i;
			local d = 1;
			while(Cooling2_Cooldown[d]) do
				local c=0;
				-- check ending cooldowns
				while(0<Cooling2_Cooldown[d].count) do
					local timeleft = Cooling2_Cooldown[d][Cooling2_Cooldown[d].count-1].endtime - GetTime();
					if(timeleft<0) then
						Cooling2_Cooldown[d].count=Cooling2_Cooldown[d].count-1;
						Cooling2_Cooldown[d][Cooling2_Cooldown[d].count]=nil;
					else
						break;
					end
				end
				-- form (simple) icons from cooldown list
				for i=Cooling2_Cooldown[d].firstbutton, Cooling2_Cooldown[d].lastbutton, 1 do
					local button = getglobal("Cooling2_Button"..i);
					local text = getglobal ("Cooling2_Button"..i.."Text");
					local icon = getglobal("Cooling2_Button"..i.."Icon");
					local cooldown = getglobal("Cooling2_Button"..i.."Cooldown");
					if(c<Cooling2_Cooldown[d].count) then
						local timeleft = Cooling2_Cooldown[d][c].endtime - GetTime();
						
						button:SetAlpha(Cooling2_Config[Cooling2_Profile].button_alpha[i]);
						icon:SetTexture(Cooling2_Cooldown[d][c].texture);
						button:Show();
						if (Cooling2_Config[Cooling2_Profile].button_digital[i] == 1) then
							if(timeleft < 2) then
								timeleft = math.ceil(10*timeleft)/10;
								text:SetText(timeleft);
							elseif(timeleft < 100) then
								timeleft = math.ceil(timeleft);
								text:SetText(timeleft);
							elseif(timeleft < 6000) then
								timeleft = math.ceil(timeleft/60);
								text:SetText(timeleft.."m");
							else
								timeleft = math.ceil(timeleft/3600);
								text:SetText(timeleft.."h");
							end
						else
							text:SetText("");
						end
						if(Cooling2_Config[Cooling2_Profile].button_shadow[i] == 1) then
							CooldownFrame_SetTimer(cooldown, Cooling2_Cooldown[d][c].starttime, Cooling2_Cooldown[d][c].endtime - Cooling2_Cooldown[d][c].starttime, 1);
						else
							CooldownFrame_SetTimer(cooldown, Cooling2_Cooldown[d][c].starttime, 0, 0);
						end
					else
						button:Hide();
						button.mouseover = nil; -- FIXME: wtf mouseover
					end
					
					c=c+1;	
				end
				d=d+1;
			end
			
		end
	end
end

function Cooling2_ButtonPress(this, button)
	if(button=="LeftButton") then
		local xPos, yPos = GetCursorPosition();
		local button = this:GetParent();
		xPos = xPos / UIParent:GetScale()/Cooling2_Config[Cooling2_Profile].button_scale[button:GetID()];
		yPos = yPos / UIParent:GetScale()/Cooling2_Config[Cooling2_Profile].button_scale[button:GetID()];
		this.moveoffsetx=Cooling2_Config[Cooling2_Profile].button_x[button:GetID()]-xPos;
		this.moveoffsety=Cooling2_Config[Cooling2_Profile].button_y[button:GetID()]-yPos;
	elseif(button=="RightButton") then
		this.splitjoin=1;
	end
end

function Cooling2_ButtonRelease(this, button)
	if(button=="LeftButton" and this.moveoffsetx) then
		local xPos, yPos = GetCursorPosition();
		local button = this:GetParent();
		xPos = xPos / UIParent:GetScale()/Cooling2_Config[Cooling2_Profile].button_scale[button:GetID()];
		yPos = yPos / UIParent:GetScale()/Cooling2_Config[Cooling2_Profile].button_scale[button:GetID()];
		xPos = xPos + this.moveoffsetx;
		yPos = yPos + this.moveoffsety;
		button:ClearAllPoints();
		if(button:GetID()==Cooling2_Config[Cooling2_Profile].button_anchor[button:GetID()]) then
			button:SetPoint("TOPLEFT","UIParent","BOTTOMLEFT",xPos,yPos);
		else
			button:SetPoint("TOPLEFT","Cooling2_Button"..Cooling2_Config[Cooling2_Profile].button_anchor[button:GetID()],"TOPLEFT",xPos,yPos);
		end
		Cooling2_Config[Cooling2_Profile].button_x[button:GetID()] = xPos;
		Cooling2_Config[Cooling2_Profile].button_y[button:GetID()] = yPos;
		this.moveoffsetx = nil;
		this.moveoffsety = nil;
	elseif(button=="RightButton" and this.splitjoin) then
		local button = this:GetParent();
		if(1<button:GetID()) then
			local oldanchor,anchor,i;
			i=button:GetID();
			if(Cooling2_Config[Cooling2_Profile].button_anchor[i]==i) then
				-- reference to self -> join icon group
				local xPos, yPos;
				oldanchor=Cooling2_Config[Cooling2_Profile].button_anchor[i];
				anchor=Cooling2_Config[Cooling2_Profile].button_anchor[i-1];
				xPos=Cooling2_Config[Cooling2_Profile].button_x[i]-Cooling2_Config[Cooling2_Profile].button_x[anchor];
				yPos=Cooling2_Config[Cooling2_Profile].button_y[i]-Cooling2_Config[Cooling2_Profile].button_y[anchor];
				Cooling2_Config[Cooling2_Profile].button_x[i]=xPos;
				Cooling2_Config[Cooling2_Profile].button_y[i]=yPos;
				Cooling2_Config[Cooling2_Profile].button_anchor[i]=anchor;
				button:ClearAllPoints();
				button:SetPoint("TOPLEFT","Cooling2_Button"..Cooling2_Config[Cooling2_Profile].button_anchor[i],"TOPLEFT",Cooling2_Config[Cooling2_Profile].button_x[i],Cooling2_Config[Cooling2_Profile].button_y[i]);
				i=i+1;
				while(Cooling2_Config[Cooling2_Profile].button_anchor[i] and Cooling2_Config[Cooling2_Profile].button_anchor[i]==oldanchor) do
					local buttoni = getglobal ("Cooling2_Button"..i);
					Cooling2_Config[Cooling2_Profile].button_x[i]=Cooling2_Config[Cooling2_Profile].button_x[i]+xPos;
					Cooling2_Config[Cooling2_Profile].button_y[i]=Cooling2_Config[Cooling2_Profile].button_y[i]+yPos;
					Cooling2_Config[Cooling2_Profile].button_anchor[i]=anchor;
					buttoni:ClearAllPoints();
					buttoni:SetPoint("TOPLEFT","Cooling2_Button"..Cooling2_Config[Cooling2_Profile].button_anchor[i],"TOPLEFT",Cooling2_Config[Cooling2_Profile].button_x[i],Cooling2_Config[Cooling2_Profile].button_y[i]);
					i=i+1;
				end
			else
				local xPos, yPos;
				oldanchor=Cooling2_Config[Cooling2_Profile].button_anchor[i];
				anchor=i;
				xPos=Cooling2_Config[Cooling2_Profile].button_x[i];
				yPos=Cooling2_Config[Cooling2_Profile].button_y[i];
				Cooling2_Config[Cooling2_Profile].button_x[i]=xPos+Cooling2_Config[Cooling2_Profile].button_x[oldanchor];
				Cooling2_Config[Cooling2_Profile].button_y[i]=yPos+Cooling2_Config[Cooling2_Profile].button_y[oldanchor];
				Cooling2_Config[Cooling2_Profile].button_anchor[i]=anchor;
				button:ClearAllPoints();
				button:SetPoint("TOPLEFT","UIParent","BOTTOMLEFT",Cooling2_Config[Cooling2_Profile].button_x[i],Cooling2_Config[Cooling2_Profile].button_y[i]);
				i=i+1;
				while(Cooling2_Config[Cooling2_Profile].button_anchor[i] and Cooling2_Config[Cooling2_Profile].button_anchor[i]==oldanchor) do
					local buttoni = getglobal ("Cooling2_Button"..i);
					Cooling2_Config[Cooling2_Profile].button_x[i]=Cooling2_Config[Cooling2_Profile].button_x[i]-xPos;
					Cooling2_Config[Cooling2_Profile].button_y[i]=Cooling2_Config[Cooling2_Profile].button_y[i]-yPos;
					Cooling2_Config[Cooling2_Profile].button_anchor[i]=anchor;
					buttoni:ClearAllPoints();
					buttoni:SetPoint("TOPLEFT","Cooling2_Button"..Cooling2_Config[Cooling2_Profile].button_anchor[i],"TOPLEFT",Cooling2_Config[Cooling2_Profile].button_x[i],Cooling2_Config[Cooling2_Profile].button_y[i]);
					i=i+1;
				end
			end
			--i=button:GetID();
			--while(Cooling2_Config[Cooling2_Profile].button_anchor[i] and Cooling2_Config[Cooling2_Profile].button_anchor[i]==oldanchor) do
			--	Cooling2_Config[Cooling2_Profile].button_anchor[i]=anchor;
			--	i = i +1;
			--end
		end
		this.splitjoin=nil;
	end
end

function Cooling2_Button_OnUpdate(this, elapsed)
    if (this.moveoffsetx) then
		local xPos, yPos = GetCursorPosition();
		local button = this:GetParent();
		xPos = xPos / UIParent:GetScale()/Cooling2_Config[Cooling2_Profile].button_scale[button:GetID()];
		yPos = yPos / UIParent:GetScale()/Cooling2_Config[Cooling2_Profile].button_scale[button:GetID()];		
		xPos = xPos + this.moveoffsetx;
		yPos = yPos + this.moveoffsety;
		button:ClearAllPoints();
		if(button:GetID()==Cooling2_Config[Cooling2_Profile].button_anchor[button:GetID()]) then
			button:SetPoint("TOPLEFT","UIParent","BOTTOMLEFT",xPos,yPos);
		else
			button:SetPoint("TOPLEFT","Cooling2_Button"..Cooling2_Config[Cooling2_Profile].button_anchor[button:GetID()],"TOPLEFT",xPos,yPos);
		end
	end
end

