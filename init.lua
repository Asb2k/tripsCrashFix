-- Trip's Crash Fix - Full Join Sanitizer
-- Covers UI + manager level crashes
-- Logs + delayed chat messages

local log_file_path = "mods/tripsCrashFix/crash_log.txt"

-- Logging
local function log_to_file(message)
    local file = io.open(log_file_path, "a")
    if file then
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        file:write("[" .. timestamp .. "] " .. message .. "\n")
        file:close()
    end
end

-- Peer name resolver
local function get_peer_name(peer_id)
    if peer_id and managers.network and managers.network:session() then
        local peer = managers.network:session():peer(peer_id)
        if peer then
            return peer:name() or peer:user_id() or "unknown"
        end
    end
    return "unknown"
end

-- Delayed chat message (5 seconds)
local function delayed_chat(message, id)
    if managers.chat then
        DelayedCalls:Add("tripsCrashFix_" .. id .. "_" .. tostring(os.time()), 5, function()
            pcall(function()
                managers.chat:feed_system_message(ChatManager.GAME, message)
            end)
        end)
    end
end

-- UI layer fix
local original_icon_data = SkillTreeTweakData.get_specialization_icon_data

function SkillTreeTweakData:get_specialization_icon_data(specialization_id, rank, peer_id)
    local default_icon = {icon = "guis/textures/pd2/none"}

    local specialization = self.specializations and self.specializations[specialization_id]

    if not specialization then
        local msg = string.format(
            "Missing specialization ID=%s (peer=%s)",
            tostring(specialization_id),
            tostring(peer_id or "N/A")
        )

        print("[CrashFix] " .. msg)
        log_to_file(msg)

        local peer_name = get_peer_name(peer_id)
        delayed_chat(
            "[Trip's Crash Guard] Player '" .. peer_name .. "' has invalid specialization (" ..
            tostring(specialization_id) .. ") - sanitized.",
            "spec_missing"
        )

        return default_icon
    end

    if not specialization.values or not specialization.values[rank] then
        local msg = string.format(
            "Missing rank %s for specialization '%s' (peer=%s)",
            tostring(rank),
            tostring(specialization.name),
            tostring(peer_id or "N/A")
        )

        print("[CrashFix] " .. msg)
        log_to_file(msg)

        local peer_name = get_peer_name(peer_id)
        delayed_chat(
            "[Trip's Crash Guard] Player '" .. peer_name .. "' has invalid perk rank (" ..
            tostring(rank) .. ") - sanitized.",
            "rank_missing"
        )

        return default_icon
    end

    -- Safe call
    local ok, result = pcall(original_icon_data, self, specialization_id, rank)
    if ok then
        return result
    else
        log_to_file("Icon function crashed for spec=" .. tostring(specialization_id))
        return default_icon
    end
end


-- Manager layer fix
local original_get_value = SkillTreeManager.get_specialization_value

function SkillTreeManager:get_specialization_value(...)
    local ok, result = pcall(original_get_value, self, ...)

    if ok then
        return result
    end

    local msg = "Prevented crash in get_specialization_value()"
    print("[Trip's Crash Fix] " .. msg)
    log_to_file(msg)

    delayed_chat(
        "Player sent invalid perk data - prevented crash.",
        "manager_protect"
    )

    return 0 -- Safe fallback
end

-- Optional hard sanitizer (clamps bad ranks)
Hooks:PostHook(SkillTreeManager, "set_current_specialization", "TripsCrashFix_SanitizeSpec", function(self, spec)
    if not tweak_data or not tweak_data.skilltree then return end

    local spec_data = tweak_data.skilltree.specializations[spec]
    if not spec_data then
        log_to_file("Sanitized invalid specialization selection: " .. tostring(spec))
        return
    end

    -- Clamp rank if needed
    local max_rank = #spec_data
    if self._current_specialization and self._current_specialization.rank then
        if self._current_specialization.rank > max_rank then
            log_to_file("Clamped invalid rank: " .. tostring(self._current_specialization.rank))
            self._current_specialization.rank = max_rank
        end
    end
end)
