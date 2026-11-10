-- Minimap Labels: names beside the minimap's dots (NodeScan.lua reads them,
-- Labels.lua draws them and the alerts, Options.lua is its page in the
-- game's Options > AddOns). The few helpers they share.
local _, ML = ...

ML.WHITE = { 1, 1, 1 }

function ML.Print(msg)
    print(NORMAL_FONT_COLOR_CODE .. "Minimap Labels|r: " .. tostring(msg))
end

function ML.InCombat()
    return type(InCombatLockdown) == "function" and InCombatLockdown()
end

-- Forever's gamepad navigation hooks the global CreateFrame and refreshes
-- its button groups from the caller's (tainted) context. Frames made
-- without a parent and parented afterwards aren't watched.
function ML.NewFrame(frameType, name, parent, template)
    local f = CreateFrame(frameType, name, nil, template)
    if parent then f:SetParent(parent) end
    return f
end

-- fn() once the character is in the world (the saved settings loaded)
local onLogin = {}
function ML.OnLogin(fn)
    onLogin[#onLogin + 1] = fn
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
    for _, fn in ipairs(onLogin) do fn() end
end)
