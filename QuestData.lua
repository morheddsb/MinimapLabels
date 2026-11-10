-- The quest data the labels use, from QuestieDB (its LibQuestieDB API) when
-- it's installed: which NPC has a quest for the character or takes one in,
-- a quest's name and items, an NPC's ID by its name. Without QuestieDB
-- every answer is nil: quest givers are labelled as NPCs, and objectives get
-- the generic icon of their kind. Every read guarded.
local _, ML = ...

local QD = {}
ML.Quest = QD

local lib                      -- LibQuestieDB; false: not installed or too old
-- (QD.enabled, set by Labels.lua: only while quest or objective labels are
-- on, so QuestieDB's caches aren't filled otherwise)
local function DB()
    if not QD.enabled then return nil end
    if lib == nil then
        lib = false
        local l = _G.LibQuestieDB
        if l and l.RequireContract and l.Npc and l.Quest then
            local ok, pass = pcall(l.RequireContract, 1)
            if ok and pass then lib = l end
        end
    end
    return lib or nil
end

function QD.Installed()
    return _G.LibQuestieDB ~= nil
end

local function Get(entity, id, key)
    local ok, v = pcall(entity.Get, id, key)
    return ok and v or nil
end

local function QuestField(questID, key)
    local Q = DB()
    return Q and Get(Q.Quest, questID, key)
end

-- NPC IDs by name (the minimap's dots give only names)
local function NpcIds(name)
    local Q = DB()
    if not Q or not Q.Npc.IdsByName then return nil end
    local ok, ids = pcall(Q.Npc.IdsByName, name)
    return ok and ids or nil
end

function QD.NpcByName(name)
    local ids = NpcIds(name)
    return ids and ids[1]
end

function QD.QuestName(questID)
    return QuestField(questID, "name")
end

-- A quest's items: its item objectives, the items it needs and the one it
-- gives to start -> { itemID } or nil
function QD.QuestItems(questID)
    local items = {}
    local objectives = QuestField(questID, "objectives")
    for _, o in ipairs(objectives and objectives[3] or {}) do
        if type(o) == "table" and o[1] then items[#items + 1] = o[1] end
    end
    for _, id in ipairs(QuestField(questID, "requiredSourceItems") or {}) do items[#items + 1] = id end
    local source = QuestField(questID, "sourceItemId")
    if source and source ~= 0 then items[#items + 1] = source end
    return #items > 0 and items or nil
end

---------------------------------------------------------------------------
-- Whether the character can take a quest
---------------------------------------------------------------------------
-- QuestieDB's race masks (its Enum.raceMaskById): one bit a race, the
-- Skyborne past 32 bits (no 32-bit bit ops: plain arithmetic)
local RACE_MASK = { [1] = 1, [2] = 2, [3] = 4, [4] = 8, [5] = 16, [6] = 32, [7] = 64, [8] = 128,
    [9] = 256, [10] = 512, [11] = 1024, [22] = 2097152, [95] = 4294967296, [96] = 8589934592 }

local function HasBit(mask, bit)
    return mask and bit and math.floor(mask / bit) % 2 == 1 or false
end

local function RaceMask()
    local race = select(3, UnitRace("player"))
    local masks = lib and lib.Enum and lib.Enum.raceMaskById
    return (masks and race and masks[race]) or RACE_MASK[race or 0]
end

local function Completed(questID)
    local log = C_QuestLog
    return log and log.IsQuestFlaggedCompleted and log.IsQuestFlaggedCompleted(questID) or false
end

local function InLog(questID)
    local log = C_QuestLog
    if log and log.GetLogIndexForQuestID then return log.GetLogIndexForQuestID(questID) ~= nil end
    return log and log.IsOnQuest and log.IsOnQuest(questID) or false
end

-- Not done, its race and class, and no quest it shuts out done already
local function Open(questID)
    if Completed(questID) or QuestField(questID, "name") == nil then return false end
    local races = QuestField(questID, "requiredRaces")
    local mine = RaceMask()
    if races and races > 0 and mine and not HasBit(races, mine) then return false end
    local classes = QuestField(questID, "requiredClasses")
    local class = select(3, UnitClass("player"))
    if classes and classes > 0 and class and not HasBit(classes, 2 ^ (class - 1)) then return false end
    for _, other in ipairs(QuestField(questID, "exclusiveTo") or {}) do
        if Completed(other) then return false end
    end
    return true
end

-- Open, not in the log, its level reached and one of the quests before it done
local function Available(questID)
    if InLog(questID) or not Open(questID) then return false end
    local level = QuestField(questID, "requiredLevel")
    if level and level > (UnitLevel("player") or 0) then return false end
    local before = QuestField(questID, "preQuestSingle")
    if type(before) == "table" and #before > 0 then
        for _, id in ipairs(before) do
            if Completed(id) then return true end
        end
        return false
    end
    return true
end

-- "end": an NPC a quest in the log is handed in to; "start": one with a
-- quest the character can take; nil: neither (or an NPC not known). And
-- those quests' IDs
function QD.QuestNpc(name)
    local Q = DB()
    local npcs = Q and NpcIds(name)
    if not npcs then return nil end
    local ids = {}
    for _, npc in ipairs(npcs) do
        for _, id in ipairs(Get(Q.Npc, npc, "questEnds") or {}) do
            if InLog(id) then ids[#ids + 1] = id end
        end
    end
    if #ids > 0 then return "end", ids end
    for _, npc in ipairs(npcs) do
        for _, id in ipairs(Get(Q.Npc, npc, "questStarts") or {}) do
            if Available(id) then ids[#ids + 1] = id end
        end
    end
    if #ids > 0 then return "start", ids end
    return nil
end
