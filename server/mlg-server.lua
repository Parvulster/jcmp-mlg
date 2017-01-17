function ModuleLoad()
	SQL:Execute("CREATE TABLE IF NOT EXISTS mlg_enabled (steamid VARCHAR UNIQUE, enabled VARCHAR)")
	print("Module Loaded")
end

function ClientLoaded(args)
	print(args.player:GetName().." has loaded the client-side script.")
end

function EnabledUpdate(args, player)
	args = tostring(args)
	local cmd = SQL:Command("UPDATE mlg_enabled SET enabled = ? WHERE steamid = ?")
	cmd:Bind(1, args)
	cmd:Bind(2, player:GetSteamId().id)
	cmd:Execute()
	print(tostring(player:GetSteamId()).." changed enabled setting to "..args)
end

function FetchEnabled(args, player)
	local enabled = ""
	local query = SQL:Query("SELECT enabled FROM mlg_enabled WHERE steamid = ?")
	query:Bind(1, player:GetSteamId().id)
	local result = query:Execute()
	if #result > 0 then
		enabled = tostring(result[1].enabled)
		print(player:GetName().." has an enabled setting of "..enabled)
	else
		local cmd = SQL:Command("INSERT INTO mlg_enabled (steamid, enabled) values (?, ?)")
		cmd:Bind(1, player:GetSteamId().id)
		cmd:Bind(2, "false")
		cmd:Execute()
		enabled = "false"
		print(player:GetName().." is not in the db. Adding with enabled setting false.")
	end
	Network:Send(player, "ReturnFetchEnabled", enabled)
end

Events:Subscribe("ModuleLoad", ModuleLoad)
Events:Subscribe("ClientModuleLoad", ClientLoaded)
Network:Subscribe("EnabledUpdate", EnabledUpdate)
Network:Subscribe("FetchEnabled", FetchEnabled)