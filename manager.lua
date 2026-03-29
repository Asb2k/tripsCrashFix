local TCF = TripsCrashFix
if not TCF then return end

if not SkillTreeManager then return end
if not SkillTreeManager.get_specialization_value then return end

-- Safe override
local original_get_value = SkillTreeManager.get_specialization_value

function SkillTreeManager:get_specialization_value(...)
    local ok, result = pcall(original_get_value, self, ...)

    if ok then
        return result
    end

    local msg = "Prevented crash in get_specialization_value()"
    log("[Trip's Crash Fix] " .. msg)
    TCF.log(msg)

    TCF.delayed_chat(
        "Player sent invalid perk data - prevented crash.",
        "manager_protect"
    )

    return 0
end

-- Rank + spec sanitizer
Hooks:PostHook(SkillTreeManager, "set_current_specialization", "TCF_SanitizeSpec", function(self, spec)
    if not tweak_data or not tweak_data.skilltree then return end

    local spec_data = tweak_data.skilltree.specializations[spec]

    if not spec_data then
        TCF.log("Sanitized invalid specialization selection: " .. tostring(spec))
        return
    end

    local max_rank = #spec_data

    if self._current_specialization and self._current_specialization.rank then
        if self._current_specialization.rank > max_rank then
            TCF.log("Clamped invalid rank: " .. tostring(self._current_specialization.rank))
            self._current_specialization.rank = max_rank
        end
    end
end)