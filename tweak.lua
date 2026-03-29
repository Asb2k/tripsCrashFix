local TCF = TripsCrashFix
if not TCF then return end

if not SkillTreeTweakData then return end

local original_icon_data = SkillTreeTweakData.get_specialization_icon_data

function SkillTreeTweakData:get_specialization_icon_data(specialization_id, rank, peer_id)
    local default_icon = { icon = "guis/textures/pd2/none" }

    local specialization = self.specializations and self.specializations[specialization_id]

    if not specialization then
        local msg = string.format(
            "Missing specialization ID=%s (peer=%s)",
            tostring(specialization_id),
            tostring(peer_id or "N/A")
        )

        log("[CrashFix] " .. msg)
        TCF.log(msg)

        local peer_name = TCF.get_peer_name(peer_id)
        TCF.delayed_chat(
            "[Trip's Crash Fix] Player '" .. peer_name .. "' has invalid specialization (" ..
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

        log("[CrashFix] " .. msg)
        TCF.log(msg)

        local peer_name = TCF.get_peer_name(peer_id)
        TCF.delayed_chat(
            "[Trip's Crash Fix] Player '" .. peer_name .. "' has invalid perk rank (" ..
            tostring(rank) .. ") - sanitized.",
            "rank_missing"
        )

        return default_icon
    end

    local ok, result = pcall(original_icon_data, self, specialization_id, rank, peer_id)

    if ok then
        return result
    else
        TCF.log("Icon function crashed for spec=" .. tostring(specialization_id))
        return default_icon
    end
end
