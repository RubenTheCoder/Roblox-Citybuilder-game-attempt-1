--Datastore
DSS = game:GetService("DataStoreService")
Datastore = DSS:GetDataStore("PlayerData")

--ServerStorage
ServerStorage = game.ServerStorage
Assets = ServerStorage.Assets
Buildings = Assets.Buildings
Objects = Assets.Objects
Zones = Assets.Zones
PlayerData = ServerStorage.PlayerData

--Serialisation
SerializeCode = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789[]"
ColorCodes = {}
do
	local R = 0
	local G = 0
	local B = 0
	for i = 1,64 do
		if R == 256 then
			R = 0
			G += 64	
		end
		if G == 256 then
			G = 0
			B += 64
		end
		print("Code: "..string.sub(SerializeCode,i,i).." - Color: R"..R.."G"..G.."B"..B.."")
		ColorCodes[i] = Color3.fromRGB(R,G,B)
		R += 64
	end
end





function DeserializeSnake(LocationID,BuildingID)
	local BuildingInfo = {}
	BuildingInfo["X"] = string.sub(LocationID,2,string.find(LocationID,"Y") -1)
	BuildingInfo["Y"] = string.sub(LocationID,string.find(LocationID,"Y") + 1,-1)
	BuildingInfo["ID"] = string.sub(BuildingID,1,3)
	BuildingInfo["Rotation"] = 0
	if string.sub(BuildingID,1,1) == string.sub(string.upper(BuildingID,1,1),1,1) then
		BuildingInfo["Rotation"] = 90
		if string.sub(BuildingID,2,2) == string.sub(string.upper(BuildingID,2,2),2,2) then
			BuildingInfo["Rotation"] = 180
			if string.sub(BuildingID,3,3) == string.sub(string.upper(BuildingID,3,3),3,3) then
				BuildingInfo["Rotation"] = 270
			end
		end
	end
	BuildingInfo["ColorA"] = ColorCodes[string.find(SerializeCode,string.sub(BuildingID,4,4))]
	BuildingInfo["ColorB"] = ColorCodes[string.find(SerializeCode,string.sub(BuildingID,5,5))]
	BuildingInfo["ColorC"] = ColorCodes[string.find(SerializeCode,string.sub(BuildingID,6,6))]
	BuildingInfo["Floors"] = string.find(SerializeCode,string.sub(BuildingID,7,7))
	return (BuildingInfo)
end





function PlaceBuilding(LocationID,BuildingID)
	local City = workspace.City
	local BuildingInfo = DeserializeSnake(LocationID,BuildingID)
end





function CompileData(Player)
	local Data = {}
	local CityData = {}
	if PlayerData:FindFirstChild(Player.UserId) then
		local PlayerDataMap =  PlayerData:FindFirstChild(Player.UserId)
		local City = workspace.City
		for index,Item in pairs(PlayerDataMap:GetDescendants()) do
			if Item:IsA("StringValue") then
				Data[Item.Name] = Item.Value
			end
			wait()
		end
		for index,Building in pairs(City:GetChildren()) do
			if Building:IsA("Model") then
				CityData[Building.Name] = Building.BuildingID.Value
			end
			wait()
		end
	end
	return Data, CityData or nil
end





function DecompileData(Player,Data)
	if PlayerData:FindFirstChild(Player.UserId) then
		local PlayerDataMap =  PlayerData:FindFirstChild(Player.UserId)
		local City = workspace.City
		for index,Item in pairs(Data["Data"]) do
			PlayerDataMap:FindFirstDescendant(index).Value = Item
		end
		for index,Item in pairs(Data["CityData"]) do
			PlaceBuilding(index,Item)
			wait()
		end
	end
end





function SaveData(Player)
	local HasSaved = false
	local Data = {}
	Data["Data"], Data["CityData"] = CompileData(Player)
	if Data then
		local Success, Result = pcall(function()
			Datastore:SetAsync(Player.UserId,Data)
		end)
		if Success then
			HasSaved = true
		else
			warn(Result)
		end
	end
	return HasSaved
end





function LoadData(Player)
	local HasLoaded = false
	local ToDestroy = workspace.City:GetChildren()
	if #ToDestroy > 0 then
		ToDestroy:Destroy()
	end
	local Data
	local Success, Result = pcall(function()
		Data = Datastore:GetAsync(Player.UserId)
	end)
	if Success then
		HasLoaded = true
		DecompileData(Player,Data)
	else
		warn(Result)
	end
	return HasLoaded
end





function LoadZone(Player,Zone)
	local Char = workspace:WaitForChild(Player.Name)
	Char:WaitForChild("HumanoidRootPart").Anchored = true
	local ToDestroy = workspace.Zone:FindFirstChildOfClass("Folder")
	if ToDestroy then
		ToDestroy:Destroy()
	end 
	local NewZone = Zones[Zone]:Clone()
	NewZone.Parent = workspace.Zone
	Char:SetPrimaryPartCFrame(NewZone:WaitForChild("Spawn").CFrame)
	Char:WaitForChild("HumanoidRootPart").Anchored = false
	return true
end





function TpToZone(Player,Zone)
	
end





function PlayerJoined(Player)
	local Char = workspace:WaitForChild(Player.Name)
	local Humanoid = Char:WaitForChild("Humanoid")
	Humanoid.WalkSpeed = 0
	Humanoid.JumpHeight = 0
	local PlayerDataMap = Objects.PlayerDataMap:Clone()
	PlayerDataMap.Name = Player.UserId
	PlayerDataMap.Parent = PlayerData
	repeat
		local Success = LoadData(Player)
		wait(5)
	until Success
	local NewColor = ColorCodes[string.find(SerializeCode,PlayerDataMap.Player.AvatarColor.Value)]
	for index,Part in pairs(Char:GetChildren()) do
		if Part:IsA("BasePart") or Part:IsA("MeshPart") then
			if Part.BrickColor == BrickColor.new("Deep blue") then
				Part.Color = NewColor
			end
		end
	end
	local Zone = PlayerDataMap.Game.CurrentZone.Value
	local LoadedZone = LoadZone(Player,Zone)
	Humanoid.WalkSpeed = 16
	Humanoid.JumpHeight = 7
end




game.Players.PlayerAdded:Connect(PlayerJoined)
