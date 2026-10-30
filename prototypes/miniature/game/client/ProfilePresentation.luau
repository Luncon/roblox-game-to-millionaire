--!strict
local Presentation = {}
export type View = {
	loaded: boolean?,
	writable: boolean?,
	profileStatus: string?,
	profileReason: string?,
	lastSavedAt: number?,
	storageLabel: string?,
}
export type Status = { status: string, text: string, expanded: boolean, warning: boolean }

function Presentation.describe(view: View?, fallbackStorage: string?): Status
	local status = if view then view.profileStatus else "loading"
	if status == nil or status == "ready" then
		status = if not view or not view.loaded then "loading" elseif not view.writable then "read_only" else "ready"
	end
	local reason = view and view.profileReason
	local text
	if status == "ready" then
		local storage = view and view.storageLabel or fallbackStorage
		if storage == "InjectedFakeProfileStore" then
			text = "Temporary Studio progress"
		elseif view and type(view.lastSavedAt) == "number" then
			text = "Saved " .. os.date("!%H:%M", view.lastSavedAt) .. " UTC"
		else
			text = "Progress ready"
		end
	elseif status == "retrying" then
		text = if reason == "profile_in_use"
			then "Waiting for your previous session to close. Please keep this window open."
			else "Retrying saved progress. Please wait; purchases stay unavailable until loading finishes."
	elseif status == "save_retry" then
		text = "Save delayed; retrying."
	elseif status == "read_only" then
		text = "Progress is read only. Rejoin to continue; further purchases are blocked."
	elseif status == "error" then
		text = if reason == "invalid_saved_data"
			then "Saved progress is unavailable. Rejoin or contact the developer; nothing has been reset."
			else "Progress could not load. Rejoin to retry; stored progress has not been reset."
	elseif status == "closing" then
		text = "Saving and closing your progress…"
	else
		status, text = "loading", "Loading saved progress. Please wait."
	end
	return {
		status = status,
		text = text,
		expanded = status ~= "ready" and status ~= "save_retry",
		warning = status == "error" or status == "read_only" or status == "save_retry",
	}
end

return table.freeze(Presentation)
