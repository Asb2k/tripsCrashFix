-- Trip's Crash Fix - Core utilities

TripsCrashFix = TripsCrashFix or {}
local TCF = TripsCrashFix

TCF.log_file_path = "mods/tripsCrashFix/crash_log.txt"

function TCF.log(message)
    local file = io.open(TCF.log_file_path, "a")
    if file then
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        file:write("[" .. timestamp .. "] " .. message .. "\n")
        file:close()
    end
end

function TCF.get_peer_name(peer_id)
    if peer_id and managers.network and managers.network:session() then
        local peer = managers.network:session():peer(peer_id)
        if peer then
            return peer:name() or peer:user_id() or "unknown"
        end
    end
    return "unknown"
end

function TCF.delayed_chat(message, id)
    if managers.chat and DelayedCalls then
        DelayedCalls:Add("TCF_" .. id .. "_" .. tostring(os.time()), 5, function()
            pcall(function()
                managers.chat:feed_system_message(ChatManager.GAME, message)
            end)
        end)
    end
end