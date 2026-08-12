---@mod yt-player.state Centralized playback state
local M = {}

M.config = {}

M.current = {
	title = nil,
	artist = nil,
	album = nil,
	duration = 0,
	position = 0,
	playing = false,
	volume = 100,
	muted = false,
	speed = 1,
	connected = false,
	playlist = {},
	playlist_pos = 0,
	playlist_count = 0,
	playlist_meta = {},
	artist_map = {},
	radio_enabled = true,
	radio_fetching = false,
}

function M.setup(config)
	M.config = config
	if M.config.radio and M.config.radio.enabled ~= nil then
		M.current.radio_enabled = M.config.radio.enabled ~= false
	end
end

-- Throttle statusline redraws to max 5/sec
local last_redraw = 0

function M.update(data)
	-- Notify on track change
	if data.title and data.title ~= M.current.title then
		if M.config.notifications and M.config.notifications.notify_on_track_change then
			require("yt-player.notify").track_change(data.title, data.artist)
		end
	end

	-- Shallow merge (avoids tbl_deep_extend overhead on frequent time-pos updates)
	for k, v in pairs(data) do
		M.current[k] = v
	end

	-- Trigger Radio check on track/playlist updates
	if data.playlist_pos or data.playlist then
		pcall(function()
			require("yt-player.radio").check_and_trigger()
		end)
	end

	local now = vim.loop.now()
	if now - last_redraw > 200 then
		last_redraw = now
		pcall(vim.cmd, "redrawstatus!")
	end
end

function M.set_connected(connected)
	M.current.connected = connected
	pcall(vim.cmd, "redrawstatus!")
end

function M.get_current()
	return M.current
end

return M
