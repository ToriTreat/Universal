repeat
	task.wait()
until game:IsLoaded()
--hey skid dont skid pls pls pls pls :DDDDDDD
--open adonis bypass btw not mine but yeah its here ^^^^
do
	local function isAdonisAC(table)
		return rawget(table, "Detected")
			and typeof(rawget(table, "Detected")) == "function"
			and rawget(table, "RLocked")
	end

	for _, v in next, getgc(true) do
		if typeof(v) == "table" and isAdonisAC(v) then
			for i, v in next, v do
				if rawequal(i, "Detected") then
					local old
					old = hookfunction(v, function(action, info, crash)
						if rawequal(action, "_") and rawequal(info, "_") and rawequal(crash, false) then
							return old(action, info, crash)
						end
						return task.wait(9e9)
					end)
					warn("bypassed")
					break
				end
			end
		end
	end
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local plr = Players.LocalPlayer
local clonef = clonefunction
local format = clonef(string.format)
local gsub = clonef(string.gsub)
local match = clonef(string.match)
local append = clonef(appendfile)
local type = clonef(type)
local crunning = clonef(coroutine.running)
local cwrap = clonef(coroutine.wrap)
local cresume = clonef(coroutine.resume)
local cyield = clonef(coroutine.yield)
local pcall = clonef(pcall)
local pairs = clonef(pairs)
local Error = clonef(error)
local getnamecallmethod = clonef(getnamecallmethod)
local warn = clonef(warn)
local print = clonef(print)
local camera = Workspace.CurrentCamera
local mouse = plr:GetMouse()
local UIS = game:GetService("UserInputService")

getgenv().Settings = {
	SilentAim = { Toggle = false, Bone = "Head", Fov = 180 },
	Speed = 0.22,
	Spedtog = false,
	Jump = false,
	JumpHeight = 15,
	InfStamina = false,
	Nocombat = false,
	Noclip = false,
	Fovchanger = { Toggle = false, fov = 111 },
	Nospread = false,
	Instantlock = false,
	Spinbot = { Toggle = false, speed = 50 },
	Sound = true,
	Soundid = "rbxassetid://4817809188",
	Prediction = true,
	InstantPickup = true, --- did not implement hit sound yet
}

---rbxassetid://8323804973 -- moan
--bypasses
local getupvalues = clonef(debug.getupvalues)
local getconstants = clonef(debug.getconstants)
local getprotos = clonef(debug.getprotos)

local module
do
	for i, v in pairs(game:GetService("StarterPlayer").StarterPlayerScripts:GetDescendants()) do
		if v:IsA("ModuleScript") and v.Name == "XIIX" then
			module = v
		end
	end
end

--no combat log
module = require(module)
local ac = module["XIIX"]
local glob = getfenv(ac)["_G"]
local combat = glob["InCombatCheck"]
local stamina = getupvalues((getupvalues(glob["S_Check"]))[2])[1]

function infstamina()
	if stamina ~= nil then
		hookfunction(stamina, function()
			return 100, 100
		end)
	end
end

function nocombat()
	if combat ~= nil and isfunctionhooked(combat) == false then
		hookfunction(combat, function()
			return nil
		end)
	end
end
--esp

--silent aim functions yes yes
function getshoot()
	for i, v in getgc() do
		if
			type(v) == "function"
			and debug.info(v, "n") == "Shoot"
			and debug.info(v, "l") == 2100
			and type(getupvalues(v)) == "table"
			and string.find(debug.info(v, "s"), "Gun")
		then
			print("got the function")
			return v
		end
	end
end


	
function norecoil()
	task.spawn(function()
		local yes = getshoot()
		if getgenv().Settings.Nospread then
			if yes ~= nil then
				local camerashake = getupvalues(getupvalues(yes)[17])[17]
				if isfunctionhooked(camerashake) == false then
					hookfunction(camerashake, function()
						return 0
					end)
				end
			else
				yes = getshoot()
			end
		else
			if yes ~= nil then
				local camerashake = getupvalues(getupvalues(yes)[17])[17]
				if isfunctionhooked(camerashake) then
					restorefunction(camerashake)
				end
			else
				yes = getshoot()
			end
		end
	end)
end

function checkifvisible(target)
	if plr and target and plr.Character and target.Character then
		local playerRoot = plr.Character:FindFirstChild("HumanoidRootPart")
		local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
		if playerRoot and targetRoot then
			local direction = (targetRoot.Position - playerRoot.Position).unit
			local ray = Ray.new(playerRoot.Position, direction * (targetRoot.Position - playerRoot.Position).magnitude)
			local part, position = workspace:FindPartOnRayWithIgnoreList(ray, { plr.Character })
			if part and part:IsDescendantOf(target.Character) then
				print("yay")
				return true
			end
		end
	end
	return false
end

local sounds = {}
sounds["Skeet"] = "rbxassetid://4817809188"
sounds["uwu"] = "rbxassetid://8323804973"
sounds["stone"] = "rbxassetid://3581383408"
sounds["tf2"] = "rbxassetid://8255306220"

function playSound()
	if not getgenv().Settings.Sound then
		return
	end
	if plr.Character then
		local sound = Instance.new("Sound")
		sound.SoundId = getgenv().Settings.Soundid
		sound.Parent = plr.Character.HumanoidRootPart
		sound:Play()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end
end

function getenemy()
	local target = nil
	local maxDist = getgenv().Settings.SilentAim.Fov * 5
	for i, v in pairs(Players:GetPlayers()) do
		if v.Character then
			if
				v.Character:FindFirstChild("Humanoid")
				and v.Character.Humanoid.Health ~= 0
				and v.Character:FindFirstChild("HumanoidRootPart")
			then
				local pos, vis = camera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position)
				local dist = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(pos.X, pos.Y)).magnitude
				if dist < maxDist and vis then
					if checkifvisible(v) then
						playSound()
						target = v.Character
						maxDist = dist
					end
				end
			end
		end
	end
	return target
end

function predict(obj)
	if getgenv().Settings.Prediction then
		local dt = RunService.RenderStepped:Wait()
		local gravity = Vector3.new(0, -Workspace.Gravity, 0)
		local acceleration = gravity / obj:GetMass()
		local predictedPosition = obj.Position + obj.AssemblyLinearVelocity * dt
		predictedPosition = predictedPosition + 0.5 * acceleration * dt * dt
		return predictedPosition
	else
		return obj.Position
	end
end

function setupsilent(old, caller)
	local yes = getshoot()
	if getgenv().Settings.SilentAim.Toggle then
		if yes then
			caller = getupvalues(yes)[34]
			if not caller then
				yes = getshoot()
				caller = getupvalues(yes)[34]
			end
			if not isfunctionhooked(caller) then
				old = hookfunction(caller, function(self, ...)
					local target = getenemy()
					if target then
						print("Target found: " .. target.Name)
						playSound()
						return predict(target[getgenv().Settings.SilentAim.Bone])
					else
						print("No target found.")
						return old(self, ...)
					end
				end)
			end
		else
			print("No 'yes' function found.")
		end
	else
		if yes then
			caller = getupvalues(yes)[34]
			if not caller then
				yes = getshoot()
				caller = getupvalues(yes)[34]
			end
			if isfunctionhooked(caller) then
				restorefunction(caller)
			end
		end
	end
end

--misc functions
function lockpick()
	for i, v in getgc() do
		if type(v) == "function" and debug.info(v, "n") == "Complete" then
			return v
		end
	end
end

function instantlockpick()
	if getgenv().Settings.Instantlock then
		if plr.PlayerGui:FindFirstChild("LockpickGUI") then
			task.wait(0.15)
			local compl = lockpick()
			if compl then
				compl()
			end
		end
	end
end

function jumpheight()
	if getgenv().Settings.Jump == true then --lmfaoooooo
		if plr.Character and plr.Character:FindFirstChildWhichIsA("Humanoid") then
			plr.Character.Humanoid.UseJumpPower = false
			plr.Character.Humanoid.JumpHeight = getgenv().Settings.JumpHeight
		end
	else
		if plr.Character and plr.Character:FindFirstChildWhichIsA("Humanoid") then
			plr.Character.Humanoid.UseJumpPower = true
		end
	end
end

function nofalldmg() -- no questions lmfao shit simple
	local old
	old = hookmetamethod(game, "__namecall", function(self, ...)
		local args = { ... }
		if getnamecallmethod() == "FireServer" and not checkcaller() and args[1] == "FlllD" and args[4] == false then
			args[2] = 0
			args[3] = 0
		end
		return old(self, unpack(args))
	end)
end

function nofog()
	ReplicatedStorage.Values.SetFogValue.Value = 0
end

function fullbright()
	ReplicatedStorage.Values.BrightnessMulti.Value = 2
end

function fovchanger()
	if getgenv().Settings.Fovchanger.Toggle then
		Workspace.Camera.FieldOfView = getgenv().Settings.Fovchanger.fov
	end
end

--fov circle
local circle = Drawing.new("Circle")
circle.Color = Color3.fromRGB(224, 224, 224)
circle.Filled = false
circle.Position = Vector2.new(mouse.X, mouse.Y)
circle.Transparency = 0.7
circle.Visible = false

--speeed
_G.speed = 0.01

getgenv().Control = {
	left = 0,
	right = 0,
	back = 0,
	forward = 0,
}

UIS.InputBegan:Connect(function(k, gameProcessedEvent)
	if not gameProcessedEvent then
		if k.KeyCode == Enum.KeyCode.W then
			getgenv().Control.forward = _G.speed
		elseif k.KeyCode == Enum.KeyCode.S then
			getgenv().Control.back = -_G.speed
		elseif k.KeyCode == Enum.KeyCode.A then
			getgenv().Control.left = -_G.speed
		elseif k.KeyCode == Enum.KeyCode.D then
			getgenv().Control.right = _G.speed
		end
	end
end)

UIS.InputEnded:Connect(function(k, gameProcessedEvent)
	if not gameProcessedEvent then
		if k.KeyCode == Enum.KeyCode.W then
			getgenv().Control.forward = 0
		elseif k.KeyCode == Enum.KeyCode.S then
			getgenv().Control.back = 0
		elseif k.KeyCode == Enum.KeyCode.A then
			getgenv().Control.left = 0
		elseif k.KeyCode == Enum.KeyCode.D then
			getgenv().Control.right = 0
		end
	end
end)

function getvector()
	return Vector3.new(
		getgenv().Control.left + getgenv().Control.right,
		0,
		getgenv().Control.forward + getgenv().Control.back
	)
end

--pickup stuff

local esp = loadstring(game:HttpGet("https://raw.githubusercontent.com/mac2115/dsadassda/main/s", true))()
esp.options.names = false
esp.options.enabled = false
esp.options.fontSize = 13
esp.options.outOfViewArrowsFilled = false
esp.options.boxes = false
esp.options.boxFill = false
esp.options.healthBars = false
esp.options.distance = false
esp.options.healthText = false
esp:Load()

--shit stuff
local repo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local Window = Library:CreateWindow({

	Title = "Asteria.lol v1.0.3",
	Center = true,
	AutoShow = true,
	TabPadding = 8,
	MenuFadeTime = 0.2,
})

local Tabs = {
	Main = Window:AddTab("Main"),
	Visuals = Window:AddTab("Visuals"),
	Misc = Window:AddTab("Misc"),
	["UI Settings"] = Window:AddTab("UI Settings"),
}

local LeftGroupBox = Tabs.Main:AddLeftGroupbox("Main")

LeftGroupBox:AddToggle("Aimbot", {
	Text = "Silent aim toggle ",
	Default = false, -- Default value (true / false)
	Tooltip = "", -- Information shown when you hover over the toggle

	Callback = function(Value)
		getgenv().Settings.SilentAim.Toggle = Value
		setupsilent()
	end,
})

LeftGroupBox:AddToggle("Spread", {
	Text = "No spread toggle ",
	Default = false, -- Default value (true / false)
	Tooltip = "", -- Information shown when you hover over the toggle

	Callback = function(Value)
		getgenv().Settings.Nospread = Value
		norecoil()
	end,
})

LeftGroupBox:AddDropdown("MyDropdown", {
	Values = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" },
	Default = 1, -- number index of the value / string
	Multi = false, -- true / false, allows multiple choices to be selected

	Text = "Aim bone",
	Tooltip = "Determines which bone should aimbot aim at", -- Information shown when you hover over the dropdown
	Callback = function(Value)
		getgenv().Settings.SilentAim.Bone = Value
	end,
})

Options.MyDropdown:SetValue("Head")

LeftGroupBox:AddSlider("Fovaim", {
	Text = "Aimbot fov",
	Default = 180,
	Min = 1,
	Max = 360,
	Rounding = 0,
	Compact = false,

	Callback = function(Value)
		getgenv().Settings.SilentAim.Fov = Value
	end,
})

LeftGroupBox:AddToggle("Circle", {
	Text = "Fov circle toggle ",
	Default = false, -- Default value (true / false)
	Tooltip = "", -- Information shown when you hover over the toggle

	Callback = function(Value)
		circle.Visible = Value
	end,
})

LeftGroupBox:AddLabel("Arrow outline Color"):AddColorPicker("ColorPicker", {
	Default = Color3.new(0, 1, 0), -- Bright green
	Title = "Fov circle color", -- Optional. Allows you to have a custom color picker title (when you open it)
	Transparency = 0, -- Optional. Enables transparency changing for this color picker (leave as nil to disable)

	Callback = function(Value)
		circle.Color = Value
	end,
})
Options.ColorPicker:SetValueRGB(Color3.fromRGB(0, 255, 140))

LeftGroupBox:AddToggle("Hitsound", {
	Text = "Hitsound toggle ",
	Default = false, -- Default value (true / false)
	Tooltip = "", -- Information shown when you hover over the toggle

	Callback = function(Value)
		getgenv().Settings.Sound = Value
	end,
})

LeftGroupBox:AddDropdown("MyDropdown", {
	Values = { "Skeet", "uwu", "stone", "tf2" },
	Default = 1, -- number index of the value / string
	Multi = false, -- true / false, allows multiple choices to be selected
	Text = "Hitsound",
	Tooltip = "", -- Information shown when you hover over the dropdown
	Callback = function(Value)
		getgenv().Settings.Soundid = sounds[Value]
	end,
})

Options.MyDropdown:SetValue("Head")

LeftGroupBox:AddToggle("Jump", {
	Text = "Jump toggle ",
	Default = false, -- Default value (true / false)
	Tooltip = "", -- Information shown when you hover over the toggle

	Callback = function(Value)
		getgenv().Settings.Jump = Value
	end,
})

LeftGroupBox:AddSlider("Height", {
	Text = "Jump height",
	Default = 1,
	Min = 1,
	Max = 35,
	Rounding = 0,
	Compact = false,

	Callback = function(Value)
		getgenv().Settings.JumpHeight = Value
	end,
})

LeftGroupBox:AddToggle("Spedtog", {
	Text = "Speed toggle ",
	Default = false, -- Default value (true / false)
	Tooltip = "", -- Information shown when you hover over the toggle

	Callback = function(Value)
		getgenv().Settings.Spedtog = Value
		if not getgenv().Settings.Spedtog then
			_G.speed = 0.01
		end
	end,
})

LeftGroupBox:AddSlider("Speed", {
	Text = "Speed",
	Default = 1,
	Min = 1,
	Max = 100,
	Rounding = 0,
	Compact = false,

	Callback = function(Value)
		if getgenv().Settings.Spedtog then
			_G.speed = Value / 100
		else
			_G.speed = 0.01
		end
	end,
})

--misc
local LeftGroupBox = Tabs.Misc:AddLeftGroupbox("Visual related")

LeftGroupBox:AddToggle("Fov changer", {
	Text = "Fov changer toggle ",
	Default = false, -- Default value (true / false)
	Tooltip = "", -- Information shown when you hover over the toggle

	Callback = function(Value)
		getgenv().Settings.Fovchanger.Toggle = Value
	end,
})

LeftGroupBox:AddSlider("Speed", {
	Text = "Fov",
	Default = 100,
	Min = 1,
	Max = 120,
	Rounding = 0,
	Compact = false,

	Callback = function(Value)
		getgenv().Settings.Fovchanger.fov = Value
	end,
})


LeftGroupBox:AddToggle("Pickup", {
	Text = "Instant pickup toggle ",
	Default = false, -- Default value (true / false)
	Tooltip = "", -- Information shown when you hover over the toggle

	Callback = function(Value)
		getgenv().Settings.InstantPickup = Value
		pickup()
	end,
})


local MyButton = LeftGroupBox:AddButton({
	Text = "No fog",
	Func = function()
		nofog()
	end,
	DoubleClick = false,
	Tooltip = "",
})

local MyButton = LeftGroupBox:AddButton({
	Text = "Full bright",
	Func = function()
		fullbright()
	end,
	DoubleClick = false,
	Tooltip = "",
})

local MyButton = LeftGroupBox:AddButton({
	Text = "Chat logger",
	Func = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/mac2115/Cool-private/main/ESP"))()
	end,
	DoubleClick = false,
	Tooltip = "",
})

local LeftGroupBox = Tabs.Misc:AddLeftGroupbox("Character related")

LeftGroupBox:AddToggle("Instant lock pick", {
	Text = "Instant lockpick toggle",
	Default = false, -- Default value (true / false)
	Tooltip = "", -- Information shown when you hover over the toggle

	Callback = function(Value)
		getgenv().Settings.Instantlock = Value
	end,
})

local MyButton = LeftGroupBox:AddButton({
	Text = "Inf stamina",
	Func = function()
		infstamina()
	end,
	DoubleClick = false,
	Tooltip = "",
})

local MyButton = LeftGroupBox:AddButton({
	Text = "No fall damage",
	Func = function()
		nofalldmg()
	end,
	DoubleClick = false,
	Tooltip = "",
})

local LeftGroupBox = Tabs.Visuals:AddLeftGroupbox("Main ESP")

local MyButton = LeftGroupBox:AddButton({
	Text = "Reload esp",
	Func = function()
		esp:Unload()
		task.wait(0.1)
		esp:Load()
	end,
	DoubleClick = false,
	Tooltip = "",
})

LeftGroupBox:AddToggle("ESP Master Toggle", {
	Text = "ESP toggle",
	Default = false, -- Default value (true / false)
	Tooltip = "", -- Information shown when you hover over the toggle

	Callback = function(Value)
		esp.options.enabled = Value
	end,
})

LeftGroupBox:AddSlider("Font", {
	Text = "Font size",
	Default = 13,
	Min = 1,
	Max = 25,
	Rounding = 0,
	Compact = false,

	Callback = function(Value)
		esp.options.fontSize = Value
	end,
})

local LeftGroupBox = Tabs.Visuals:AddLeftGroupbox("Offscreen arrows")
LeftGroupBox:AddToggle("Offscreen arrows Toggle", {
	Text = "Offscreen arrows Toggle",
	Default = false, -- Default value (true / false)
	Tooltip = "", -- Information shown when you hover over the toggle

	Callback = function(Value)
		esp.options.outOfViewArrows = Value
	end,
})

LeftGroupBox:AddLabel("Arrow outline Color"):AddColorPicker("ColorPicker", {
	Default = Color3.new(0, 1, 0), -- Bright green
	Title = "Arrow outline color", -- Optional. Allows you to have a custom color picker title (when you open it)
	Transparency = 0, -- Optional. Enables transparency changing for this color picker (leave as nil to disable)

	Callback = function(Value)
		esp.options.outOfViewArrowsOutlineColor = Value
	end,
})
Options.ColorPicker:SetValueRGB(Color3.fromRGB(0, 255, 140))

LeftGroupBox:AddToggle("Offsc", {
	Text = "Filled",
	Default = false, -- Default value (true / false)
	Tooltip = "", -- Information shown when you hover over the toggle

	Callback = function(Value)
		esp.options.outOfViewArrowsFilled = Value
	end,
})

LeftGroupBox:AddLabel("Arrows fill Color"):AddColorPicker("ColorPicker", {
	Default = Color3.new(0, 1, 0), -- Bright green
	Title = "Arrow fill color", -- Optional. Allows you to have a custom color picker title (when you open it)
	Transparency = 0, -- Optional. Enables transparency changing for this color picker (leave as nil to disable)

	Callback = function(Value)
		esp.options.outOfViewArrowsColor = Value
	end,
})
Options.ColorPicker:SetValueRGB(Color3.fromRGB(0, 255, 140))
local LeftGroupBox = Tabs.Visuals:AddRightGroupbox("Texts")

LeftGroupBox:AddToggle("Offc", {
	Text = "Names",
	Default = false, -- Default value (true / false)
	Tooltip = "", -- Information shown when you hover over the toggle

	Callback = function(Value)
		esp.options.names = Value
	end,
})

LeftGroupBox:AddLabel("Names Color"):AddColorPicker("ColorPicker", {
	Default = Color3.new(0, 1, 0), -- Bright green
	Title = "Names color", -- Optional. Allows you to have a custom color picker title (when you open it)
	Transparency = 0, -- Optional. Enables transparency changing for this color picker (leave as nil to disable)

	Callback = function(Value)
		esp.options.nameColor = Value
	end,
})
Options.ColorPicker:SetValueRGB(Color3.fromRGB(0, 255, 140))

LeftGroupBox:AddToggle("Ofsa", {
	Text = "Health text",
	Default = false, -- Default value (true / false)
	Tooltip = "", -- Information shown when you hover over the toggle

	Callback = function(Value)
		esp.options.healthText = Value
	end,
})

LeftGroupBox:AddLabel("Health text Color"):AddColorPicker("ColorPicker", {
	Default = Color3.new(0, 1, 0), -- Bright green
	Title = "Health text Color", -- Optional. Allows you to have a custom color picker title (when you open it)
	Transparency = 0, -- Optional. Enables transparency changing for this color picker (leave as nil to disable)

	Callback = function(Value)
		esp.options.healthTextColor = Value
	end,
})
Options.ColorPicker:SetValueRGB(Color3.fromRGB(0, 255, 140))

LeftGroupBox:AddToggle("Ofsa", {
	Text = "Distance text",
	Default = false, -- Default value (true / false)
	Tooltip = "", -- Information shown when you hover over the toggle

	Callback = function(Value)
		esp.options.distance = Value
	end,
})

LeftGroupBox:AddLabel("Distance text Color"):AddColorPicker("ColorPicker", {
	Default = Color3.new(0, 1, 0), -- Bright green
	Title = "Distance text Color", -- Optional. Allows you to have a custom color picker title (when you open it)
	Transparency = 0, -- Optional. Enables transparency changing for this color picker (leave as nil to disable)

	Callback = function(Value)
		esp.options.distanceColor = Value
	end,
})

Options.ColorPicker:SetValueRGB(Color3.fromRGB(0, 255, 140))

local LeftGroupBox = Tabs.Visuals:AddLeftGroupbox("Boxes settings")
LeftGroupBox:AddToggle("Offsa", {
	Text = "Boxes",
	Default = false, -- Default value (true / false)
	Tooltip = "", -- Information shown when you hover over the toggle

	Callback = function(Value)
		esp.options.boxes = Value
	end,
})

LeftGroupBox:AddLabel("Boxes Color"):AddColorPicker("ColorPicker", {
	Default = Color3.new(0, 1, 0), -- Bright green
	Title = "Boxes Color", -- Optional. Allows you to have a custom color picker title (when you open it)
	Transparency = 0, -- Optional. Enables transparency changing for this color picker (leave as nil to disable)

	Callback = function(Value)
		esp.options.boxesColor = Value
	end,
})

LeftGroupBox:AddToggle("Ofsa", {
	Text = "Filled",
	Default = false, -- Default value (true / false)
	Tooltip = "", -- Information shown when you hover over the toggle

	Callback = function(Value)
		esp.options.boxFill = Value
	end,
})

LeftGroupBox:AddLabel("Boxes fill Color"):AddColorPicker("ColorPicker", {
	Default = Color3.new(0, 1, 0), -- Bright green
	Title = "Boxes fill Color", -- Optional. Allows you to have a custom color picker title (when you open it)
	Transparency = 0, -- Optional. Enables transparency changing for this color picker (leave as nil to disable)

	Callback = function(Value)
		esp.options.boxFillColor = Value
	end,
})
Options.ColorPicker:SetValueRGB(Color3.fromRGB(0, 255, 140))

LeftGroupBox:AddToggle("Ofsa", {
	Text = "Health bars",
	Default = false, -- Default value (true / false)
	Tooltip = "", -- Information shown when you hover over the toggle

	Callback = function(Value)
		esp.options.healthBars = Value
	end,
})

LeftGroupBox:AddLabel("Health bar Color"):AddColorPicker("ColorPicker", {
	Default = Color3.new(0, 1, 0), -- Bright green
	Title = "Health bar Color", -- Optional. Allows you to have a custom color picker title (when you open it)
	Transparency = 0, -- Optional. Enables transparency changing for this color picker (leave as nil to disable)

	Callback = function(Value)
		esp.options.healthBarsColor = Value
	end,
})

Options.ColorPicker:SetValueRGB(Color3.fromRGB(0, 255, 140))

local LeftGroupBox = Tabs.Visuals:AddLeftGroupbox("Chams settings")
LeftGroupBox:AddToggle("Ofsa", {
	Text = "Chams",
	Default = false, -- Default value (true / false)
	Tooltip = "", -- Information shown when you hover over the toggle

	Callback = function(Value)
		esp.options.chams = Value
	end,
})
LeftGroupBox:AddLabel("Chams fill  Color"):AddColorPicker("ColorPicker", {
	Default = Color3.new(0, 1, 0), -- Bright green
	Title = "Chams fill Color", -- Optional. Allows you to have a custom color picker title (when you open it)
	Transparency = 0, -- Optional. Enables transparency changing for this color picker (leave as nil to disable)

	Callback = function(Value)
		esp.options.chamsFillColor = Value
	end,
})
Options.ColorPicker:SetValueRGB(Color3.fromRGB(0, 255, 140))

LeftGroupBox:AddLabel("Chams outline Color"):AddColorPicker("ColorPicker", {
	Default = Color3.new(0, 1, 0), -- Bright green
	Title = "Chams outline Color", -- Optional. Allows you to have a custom color picker title (when you open it)
	Transparency = 0, -- Optional. Enables transparency changing for this color picker (leave as nil to disable)

	Callback = function(Value)
		esp.options.chamsOutlineColor = Value
	end,
})
Options.ColorPicker:SetValueRGB(Color3.fromRGB(0, 255, 140))

Library:SetWatermarkVisibility(false)

-- Example of dynamically-updating watermark with common traits (fps and ping)
local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60

local WatermarkConnection = game:GetService("RunService").RenderStepped:Connect(function()
	FrameCounter = FrameCounter + 1

	if (tick() - FrameTimer) >= 1 then
		FPS = FrameCounter
		FrameTimer = tick()
		FrameCounter = 0
	end

	Library:SetWatermark(
		("Asteria.lol| %s fps | %s ms"):format(
			math.floor(FPS),
			math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
		)
	)
end)

Library.KeybindFrame.Visible = false -- todo: add a function for this

Library:OnUnload(function()
	WatermarkConnection:Disconnect()

	print("Unloaded!")
	Library.Unloaded = true
end)

-- UI Settings
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)

local cButton = MenuGroup:AddButton({
	Text = "Copy discord link",
	Func = function()
		setclipboard("discord.gg/t2cXFpkGBh")
	end,
	DoubleClick = false,
	Tooltip = "",
})

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "End", NoUI = true, Text = "Menu keybind" })
Library.ToggleKeybind = Options.MenuKeybind -- Allows you to have a custom keybind for the menu
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("Asteria.lol")
SaveManager:SetFolder("Asteria.lol/Criminality")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

--loop stuff
setupsilent()

task.spawn(function()
	plr.PlayerGui.ChildAdded:Connect(function(child)
		if child.Name == "LockpickGUI" then
			instantlockpick()
		end
	end)
end)
task.spawn(function()
	plr.Character.ChildAdded:Connect(function()
		setupsilent()
	end)
end)

local movementVector
local moveDirection
local strafeDirection
local verticalDirection
local newPosition

task.spawn(function()
	RunService.RenderStepped:Connect(function()
		jumpheight()
		fovchanger()
		circle.Position = Vector2.new(mouse.X, mouse.Y)
		circle.Radius = getgenv().Settings.SilentAim.Fov
		if plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
			movementVector = getvector()
			moveDirection = plr.Character.HumanoidRootPart.CFrame.LookVector * movementVector.Z
			strafeDirection = plr.Character.HumanoidRootPart.CFrame.RightVector * movementVector.X
			verticalDirection = Vector3.new(0, 0, 0) -- No vertical movement
			plr.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame
				+ moveDirection
				+ strafeDirection
				+ verticalDirection
		end
	end)
end)
