-- The settings: a page of the game's own Options > AddOns (its vertical
-- layout: checkboxes, dropdowns, a button), saved in MinimapLabelsDB. And
-- the button that makes the /mlabels macro, for an action bar or a key.
local _, ML = ...

local MM = ML.Labels
local N = ML.NodeScan

local MACRO, MACRO_ICON, MACRO_BODY = "Minimap Labels", "INV_Misc_Map_01", "/mlabels"

-- A general macro "Minimap Labels" that shows / hides the labels (made
-- once; there already, left as it is)
local function MakeMacro()
    if ML.InCombat() then return ML.Print("Macros can't be made in combat.") end
    if GetMacroIndexByName(MACRO) == 0 then
        local ok, index = pcall(CreateMacro, MACRO, MACRO_ICON, MACRO_BODY, false)
        if not ok or not index or index == 0 then
            return ML.Print("Couldn't make the macro: your general macros are full.")
        end
    end
    ML.Print("The \"" .. MACRO .. "\" macro is in your general macros (/macro): drag it to an action bar,"
        .. " then bind that slot in Key Bindings.")
end

local function Register()
    local s = MM.Settings()
    local category, layout = Settings.RegisterVerticalLayoutCategory("Minimap Labels")

    local function Setting(key, name)
        return Settings.RegisterAddOnSetting(category, "MinimapLabels_" .. key, key, s, type(MM.DEFAULTS[key]),
            name, MM.DEFAULTS[key])
    end

    local function Checkbox(key, name, tip, onChange, parent)
        local setting = Setting(key, name)
        if onChange then setting:SetValueChangedCallback(function(_, value) onChange(value) end) end
        local init = Settings.CreateCheckbox(category, setting, tip)
        if parent then init:SetParentInitializer(parent, function() return s[parent.key] end) end
        init.key = key
        return init
    end

    local function Dropdown(key, name, tip, choices, parent)
        local setting = Setting(key, name)
        setting:SetValueChangedCallback(function() MM.ApplyAlert() end)
        local function Options()
            local c = Settings.CreateControlTextContainer()
            for _, choice in ipairs(choices) do c:Add(choice[1], choice[2]) end
            return c:GetData()
        end
        local init = Settings.CreateDropdown(category, setting, Options, tip)
        init:SetParentInitializer(parent, function() return s[parent.key] end)
    end

    local function Header(text)
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
    end

    -- Labels
    Header("Labels")
    local labels = Checkbox("labels", "Show labels",
        "Each dot on the minimap of the kinds chosen below gets its name beside it. /mlabels shows or hides them too.",
        function(on) MM.SetLabels(on) end)
    layout:AddInitializer(CreateSettingsButtonInitializer("Toggle macro", "Make macro", MakeMacro,
        "Makes a general macro, \"" .. MACRO .. "\", that shows or hides the labels. Put it on an action bar"
            .. " to click it or bind a key to it.", true))
    local apply = function() MM.ApplyLabels() end
    Checkbox("herb", "Herbs", "Herbs, in their skill colour. They show on the minimap while Find Herbs is on.",
        apply, labels)
    Checkbox("ore", "Ore", "Ore veins, in their skill colour. They show on the minimap while Find Minerals is on.",
        apply, labels)
    Checkbox("objective", "Objectives", "Your quests' areas the minimap marks, each objective's count beside it,"
        .. " and the creatures and objects a quest still needs.", apply, labels)
    Checkbox("quest", "Quests", "In yellow, beside its NPC: the quest to hand in there, or the quest an NPC has"
        .. " for you." .. (ML.Quest.Installed() and "" or " Quest givers need the QuestieDB addon."), apply, labels)
    Checkbox("npc", "NPCs", "The other NPCs and creatures on the minimap: the ones its tracking shows.",
        apply, labels)
    Checkbox("party", "Party members", "Your party or raid members, in their class colour.", apply, labels)
    Checkbox("colors", "Skill colours", "Herbs and ore are coloured by the skill point they give, as the game"
        .. " colours recipes: orange always, yellow mostly, green rarely, grey never; red is beyond your skill.",
        nil, labels)
    Checkbox("need", "Skill needed", "A herb or ore beyond your skill (red) shows the skill it needs after its"
        .. " name: Bruiseweed (100).", nil, labels)

    -- Alerts
    Header("Alerts")
    local alert = Checkbox("alert", "Alerts", "The minimap is read every few seconds; a node worth having that"
        .. " appears plays a sound and says what and where (and pulses a controller in use). Not in combat.",
        function(on)
            if on then N.Check() end
            MM.ApplyAlert()
        end)
    Dropdown("alertFor", "Alert for", "Which nodes alert. Skill colours decide the first two.", {
        { "skill", "Skill-ups" },
        { "gather", "Any I can gather" },
        { "any", "Any herb or ore" },
        { "all", "Anything on the minimap" },
    }, alert)
    Dropdown("alertWith", "Alert with", "How an alert tells you. The message at the top of the screen always"
        .. " shows; vibration needs a controller.", {
        { "both", "Vibration and sound" },
        { "vibe", "Vibration" },
        { "sound", "Sound" },
        { "show", "Message only" },
    }, alert)
    Dropdown("interval", "Look every", "How often the minimap is read for alerts.", {
        { 2, "2 seconds" }, { 3, "3 seconds" }, { 5, "5 seconds" }, { 10, "10 seconds" },
    }, alert)

    Settings.RegisterAddOnCategory(category)
end

ML.OnLogin(function()
    if Settings and Settings.RegisterVerticalLayoutCategory then Register() end
end)
