object = nil
enabled = false
safetospawn = true
slowtimer = nil
ispilot = false
inplane = false
planelist = {24, 30, 34, 39, 51, 81, 85}
gear = nil
slowdowntimer = nil
cancelspeed = false
vehicle = nil
vehicleid = nil
infotimer = nil
inforeason = 0
mlgenabled = false

function PreTick()
	if mlgenabled == false then return end
	if ispilot == false or inplane == false then
		gear = nil
		DespawnObject()
		return
	elseif enabled == true then
		gear = true
		if safetospawn == true then
			if object ~= nil then
				MoveObject()
			elseif object == nil then
				SpawnObject()
			end
		elseif safetospawn == false then
			DespawnObject()
		end
	elseif enabled == false then
		gear = false
		DespawnObject()
	end
end

function MoveObject()
	if mlgenabled == false then return end
	if object == nil then return
	else
		local angle = LocalPlayer:GetAngle()
		local distance = angle * Vector3.Down * 5
		local position = LocalPlayer:GetPosition() + distance
		angle = angle * Angle(math.pi * -0.5, 0, 0)
		object:SetPosition(position)
		object:SetAngle(angle)
	end
end

function DespawnObject()
	if object ~= nil then
		object:Remove()
		object = nil
	end
end

function SpawnObject()
	if mlgenabled == false then return end
	if ispilot == false or inplane == false then
		return
	else
		DespawnObject()
		local angle = LocalPlayer:GetAngle()
		local distance = angle * Vector3.Down * 5
		local position = LocalPlayer:GetPosition() + distance
		angle = angle * Angle(math.pi * -0.5, 0, 0)
		spawnArgs = {}
		spawnArgs.position = position
		spawnArgs.angle = angle
		spawnArgs.model = "" -- areaset01.blz/gb245-d.lod
		spawnArgs.collision = "gb245_lod1-d_col.pfx" -- gb245_lod1-d_col.pfx
		object = ClientStaticObject.Create(spawnArgs)
	end
end

function EnteredVehicle()
	if mlgenabled == false then return end
	vehicle = LocalPlayer:GetVehicle()
	if vehicle == nil then return end
	vehicleid = vehicle:GetModelId()
	if CheckList(planelist, vehicleid) then
		inplane = true
		if LocalPlayer:GetSeat() == 0 then
			ispilot = true
			if safetospawn == true then
				enabled = false
			elseif safetospawn == false then
				enabled = true
			end
		end
	end
end

function ExitedVehicle()
	if mlgenabled == false then return end
	inplane = false
	ispilot = false
	gear = nil
end

function SlowDown()
	if mlgenabled == false then return end
	if inplane == false or ispilot == false then return end
	if slowdown == true then
		slowdowntimer = Timer()
		slowdown = false
		cancelspeed = true
	elseif slowdowntimer == nil then return
	elseif CheckList(planelist, vehicleid) and slowdowntimer:GetSeconds() > 2 and slowdowntimer:GetSeconds() < 4 then
		cancelspeed = true
		Input:SetValue(65, 100)
	elseif CheckList(planelist, vehicleid) and slowdowntimer:GetSeconds() >= 4 then
		cancelspeed = false
		slowdowntimer = nil
	end
end

function KeyDown(args)
	if mlgenabled == false then return end
	if args.key == string.byte("L") then
		if inplane == false or ispilot == false then return end
		if safetospawn == false then
			infotimer = Timer()
			inforeason = 4
			return
		end
		enabled = not enabled
		if enabled == true then
			slowdown = true
			infotimer = Timer()
			inforeason = 2
			gear = true
			SpawnObject()
		elseif enabled == false then
			infotimer = Timer()
			inforeason = 3
			gear = false
			DespawnObject()
		end
	end
end

function LocalPlayerChat(args)
	if args.text == "/mlg" then
		EnabledUpdate()
	end
end

function EnabledUpdate()
	mlgenabled = not mlgenabled
	Network:Send("EnabledUpdate", mlgenabled)
	if mlgenabled == true then
		infotimer = Timer()
		inforeason = 5
	elseif mlgenabled == false then
		enabled = false
		infotimer = Timer()
		inforeason = 6
	end
end

function CancelInput(args)
	if mlgenabled == false then return end
	local input = args.input
	if cancelspeed == true then
		if input == 64 then
			return false
		end
	end
end

function CheckList(list, var)
	for k,v in pairs(list) do
		if v == var then return true end
	end
	return false
end

function StupidSpawn()
	testSpawnArgs = {}
	testSpawnArgs.position = Vector3(0, -200, 0)
	testSpawnArgs.angle = Angle(0, 0, 0)
	testSpawnArgs.model = "areaset01.blz/gb245-d.lod"
	ClientStaticObject.Create(testSpawnArgs)
end

function ReturnFetchEnabled(args)
	mlgenabled = args
	print("MLG V1.0 Loaded")
end

function ModuleLoad()
	Network:Send("FetchEnabled")
	StupidSpawn()
	EnteredVehicle()
end

function ModuleUnload()
	DespawnObject()
	Events:Fire( "HelpRemoveItem", {
		name = "Manual Landing Gear"
	})
end

function ModulesLoad()
    Events:Fire("HelpAddItem", {
		name = "Manual Landing Gear",
		text = 
			"Want to manually control your landing gear? Well, then this is for you.\n"..
			"\n"..
			"Controls:\n"..
			"/mlg - enable and disable manual landing gear\n"..
			"L - raise and lower landing gear (defaults to lowered when entering a plane on the ground)\n"..
			"\n"..
			"Known Issues:\n"..
			"- You cannot be accelerating or using throttle control through autopilot when attempting to lower landing gear\n"..
			"- Pitching or rolling beyond 60° causes the gear to automatically disable\n"..
			"- Plane might explode if ejecting midair with landing gear down"
	})
end

function CheckExtremes()
	local pitch = nil
	local roll = nil
	if mlgenabled == false then return end
	if inplane == false or ispilot == false or enabled == false then return end
	pitch = math.abs(math.deg(vehicle:GetAngle().pitch))
	roll = math.abs(math.deg(vehicle:GetAngle().roll))
	if pitch > 60 or roll > 60 then
		enabled = false
		infotimer = Timer()
		inforeason = 1
	end
end

function RenderInfo()
	local infostring = ""
	local color = ""
	if infotimer ~= nil then
		if infotimer:GetSeconds() < 3 then
			color = Color.Aqua
			if inforeason == 1 then
				infostring = "You cannot pitch or roll beyond 60° with the gear down! Raising Gear."
			elseif inforeason == 2 then
				infostring = "Lowering Gear"
			elseif inforeason == 3 then
				infostring = "Raising Gear"
			elseif inforeason == 4 then
				infostring = "You can not raise or lower landing gear less than 20m from the ground!"
			elseif inforeason == 5 then
				infostring = "Manual Landing Gear Enabled"
			elseif inforeason == 6 then
				infostring = "Manual Landing Gear Disabled"
			end
		else
			infotimer = nil
			inforeason = 0
		end
	elseif inplane == false or ispilot == false or gear == nil or mlgenabled == false then return
	elseif gear == true then
		infostring = "Gear Down"
		color = Color.Lime
	elseif gear == false then
		infostring = "Gear Up"
		color = Color.Red
	end
	if infostring == "" then return end
	local position = Vector2(Render.Width / 2, Render.Height)
	position.y = position.y - Render:GetTextHeight(infostring, 24)
	position.x = position.x - Render:GetTextWidth(infostring, 24) / 2
	Render:DrawText(position, infostring, color, 24)
end

function GetHeight()
	if mlgenabled == false then return end
	local x = LocalPlayer:GetPosition().x
	local y = LocalPlayer:GetPosition().y - 200
	local z = LocalPlayer:GetPosition().z
	local height = Physics:GetTerrainHeight(Vector2(x, z)) - 200
	if height < 0 then height = 0 end
	local angle = LocalPlayer:GetAngle()
	local direction = angle * Vector3.Forward
	local position = LocalPlayer:GetPosition() + direction * 25
	local distance = y - height
	local futuredistance = position.y - height - 200
	if futuredistance < distance then futuredistance = distance end
	if futuredistance < 20 then
		safetospawn = false
	elseif futuredistance >= 20 then
		safetospawn = true
	end
end

Events:Subscribe("PreTick", GetHeight)
Events:Subscribe("LocalPlayerChat", LocalPlayerChat)
Events:Subscribe("Render", RenderInfo)
Events:Subscribe("PostTick", CheckExtremes)
Events:Subscribe("LocalPlayerInput", CancelInput)
Events:Subscribe("LocalPlayerEnterVehicle", EnteredVehicle)
Events:Subscribe("LocalPlayerExitVehicle", ExitedVehicle)
Events:Subscribe("InputPoll", SlowDown)
Events:Subscribe("PreTick", PreTick)
Events:Subscribe("KeyDown", KeyDown)
Events:Subscribe("ModuleLoad", ModuleLoad)
Events:Subscribe("ModuleUnload", ModuleUnload)
Events:Subscribe("ModulesLoad", ModulesLoad)
Network:Subscribe("ReturnFetchEnabled", ReturnFetchEnabled)