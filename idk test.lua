local main = {}

local collectionService
local voiceChatService
local userInputService
local textChatService
local tweenService
local soundService
local framework
local lighting
local players
local player
local teams

local sounds
local systemGuis
local phoneSounds
local systemAssets
local systemEvents
local systemFunctions

local config
local currencySymbol
local economyConfig
local systemConfig

local radioConfig
local phoneConfig
local appsConfig
local soundsConfig
local widgetsConfig

local hoverS
local notificationS

local phoneClientE
local phoneServerF

local find, useService, addComma, getPlayerEconomy

local UI
local decoFld
local mockupF
local interfaceF

local screenF

-- Apps Frames --
local appsFld
local calculatorApp
local emergencyApp
local messagesApp
local configApp
local phoneApp
local moneyApp
local notesApp
local jobsApp
local bankApp

-- Home Frames --
local homescreenF
local widgetF
local dockF
local mainF
local appsF

local topF
local backB
local wallpaperI

local currentScreen
local maxDockApps = 4

local inApp = false
local uiDebounce = false
local actionDebounce = false

local connections = {}

local positionConfigs = { -- Phone UI animations
	open  = UDim2.new(0.5, 0, 0.5, 0),
	close = UDim2.new(0.5, 0, 1.3, 0),
}

local sizeConfigs = { -- App animations
	openApp = { start = UDim2.new(0, 0,   0, 0), finish = UDim2.new(1, 0, 1, 0) },
	closeApp = { start = UDim2.new(1, 0, 1, 0), finish = UDim2.new(0, 0, 0, 0) },
}

-- || UI FUNCTIONS || --

local function uiTransition(action, element, tweenDuration)
	if not element or not element.Parent then return end
	
	local pCfg = positionConfigs[action]
	if pCfg and element.TweenPosition then
		element:TweenPosition(
			pCfg,
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Sine,
			tweenDuration,
			false
		)
	end

	local sCfg = sizeConfigs[action]
	if sCfg and element.TweenSize then

		element.Size    = sCfg.start
		element.Visible = true

		element:TweenSize(
			sCfg.finish,
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Sine,
			tweenDuration,
			false,
			function()
				if action == "closeApp" then
					element.Visible = false
				end
			end
		)
	end
end

local function returnFromScreen(returnFrom: Frame, returnTarget: Frame)
	returnFrom.Visible = false
	returnTarget.Visible = true
end

local function searchHandler(framesLookup: Frame, box: TextBox)
	local query = box.Text:lower()
	for _, frame in ipairs(framesLookup:GetChildren()) do
		if frame:IsA("Frame") or frame:IsA("TextButton") or frame:IsA("TextLabel") then
			frame.Visible = query == "" or frame.Name:lower():find(query, 1, true) ~= nil
		end
	end
end

local function updateBalance(bank: IntValue, balanceT: TextLabel, extraText: string)
	balanceT.Text = extraText and `{extraText} {economyConfig.currencySymbol}{addComma(bank.Value)}` or `{economyConfig.currencySymbol}{addComma(bank.Value)}`
end

local function themeHandler(appF: Frame)
	local h, s, v	= appF.BackgroundColor3:ToHSV()
	local isDarkBg	= (v < 0.5)
	local textColor = isDarkBg and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
	local iconColor = textColor
	local backgroundColor = isDarkBg and Color3.fromRGB(215, 215, 215) or Color3.fromRGB(70, 70, 70)

	for _, gui in ipairs(screenF:GetDescendants()) do
		if collectionService:HasTag(gui, "theme") then
			if gui.BackgroundTransparency == 1 and (gui:IsA("TextLabel") or gui:IsA("TextButton")) then
				gui.TextColor3 = textColor
			elseif gui:IsA("ImageLabel") or gui:IsA("ImageButton") then
				gui.ImageColor3 = iconColor
			elseif gui:IsA("TextButton") and gui.BackgroundTransparency == 0 then
				gui.BackgroundColor3 = backgroundColor
			end
		end
	end
end

local function cleanText(...)
	for _, textInstance in ipairs({...}) do
		if typeof(textInstance) == "Instance" and (textInstance:IsA("TextBox") or textInstance:IsA("TextLabel")) then
			textInstance.Text = ""
		end
	end
end

local function capitalizeFirst(str: string)
	if #str == 0 then return str end
	return str:sub(1,1):upper() .. str:sub(2)
end

-- || PHONE FUNCTIONS || --

local appUnreadCount = 0

function appHandler(app: string)
	local appF = find(appsFld, app):: Frame
	if not appF then return end

	inApp = true
	currentScreen = appF
	uiTransition("openApp", appF, 0.3)
	task.wait(0.3)
	homescreenHandler("hide")
	resetAppUnreads(appF)
	themeHandler(appF)
end

function resetAppUnreads(appF: Frame)
	local appB = find(appsF, appF.Name):: TextButton
	if not appB then return end

	local unreadT = find(appB, "unread"):: TextLabel
	if not unreadT or not unreadT.Visible then return end

	appUnreadCount  = 0
	unreadT.Text    = "0"
	unreadT.Visible = false
end

function homescreenSetup()
	local tod = lighting.TimeOfDay
	local dockCount = 0
	
	topF.time.Text = tod:sub(1, 5)
	
	for app, config in pairs(appsConfig) do
		if not config.enabled then
			continue
		end

		local template = find(appsF, "template/appName"):Clone() :: TextButton
		local visualConfig = config.visual

		template.Name			= app
		template.appName.Text	= visualConfig.appName
		template.icon.Image		= `http://www.roblox.com/asset/?id={visualConfig.icon}`

		template.LayoutOrder		= visualConfig.order
		template.BackgroundColor3	= visualConfig.color

		template.MouseEnter:Connect(function()
			template.UIStroke.Enabled = true
			soundService:PlayLocalSound(hoverS)
			if visualConfig.inDock then return end
			template.appName.Visible = true
		end)

		template.MouseLeave:Connect(function()
			template.UIStroke.Enabled = false
			if visualConfig.inDock then return end
			template.appName.Visible = false
		end)

		local parentContainer
		if visualConfig.inDock and dockCount < maxDockApps then
			dockCount += 1
			parentContainer = dockF
			template.Size = UDim2.new(0.179, 0, 0.778, 0)
		else
			parentContainer = appsF
		end

		template.Parent  = parentContainer
		template.Visible = true

		template.Activated:Connect(function() appHandler(app) end)
	end
	
	table.insert(connections, lighting:GetPropertyChangedSignal("TimeOfDay"):Connect(function()
		topF.time.Text = lighting.TimeOfDay:sub(1,5)
	end))
end

function homescreenHandler(action)
	if action == "show" then
		homescreenF.Visible = true
		wallpaperI.Visible = true
	elseif action == "hide" then
		homescreenF.Visible = false
		wallpaperI.Visible = false
	end
end

function homeHandler()
	if not inApp then return end

	if currentScreen.Name == messagesApp.Name then
		returnFromChat()
	end

	inApp = false
	homescreenHandler("show")
	uiTransition("closeApp", currentScreen, 0.3)
	themeHandler(wallpaperI)

	currentScreen = homescreenF
end

-- < Widgets > --
local function widgetSetup()
	local defaultWidget = string.lower(widgetsConfig.default)
	local widget = find(widgetF, defaultWidget):: Frame

	if not widget then return end
	widget.Visible = true

	-- Wallet Widget Setup --
	local walletW = find(widgetF, "wallet"):: TextButton
	if economyData then
		local bank = economyData.bank
		local balanceT = find(walletW, "balance"):: TextLabel
		updateBalance(bank, balanceT)

		table.insert(connections, bank:GetPropertyChangedSignal("Value"):Connect(function()
			updateBalance(bank, balanceT)
		end))
	end
end

-- < Calculator > --
local currentInput = ""
local leftOperand = nil
local operator = nil
local displayExpression = ""

local function updateResultDisplay()
	resultT.Text = displayExpression ~= "" and displayExpression or "0"
	operationT.Text = ""
end

local function onClear()
	currentInput, leftOperand, operator, displayExpression = "", nil, nil, ""
	resultT.Text, operationT.Text = "0", ""
end

local function onNumberInput(digit)
	if operator == nil and displayExpression == "" and currentInput ~= "" then
		currentInput = ""
	end

	if currentInput == "0" then
		if digit ~= "0" then
			currentInput = digit
			displayExpression = digit
		end
	else
		currentInput = currentInput .. digit
		displayExpression = displayExpression .. digit
	end
	updateResultDisplay()
end

local function onDotInput()
	if operator == nil and displayExpression == "" and currentInput ~= "" then
		currentInput = ""
		displayExpression = ""
	end

	if not currentInput:find("%.") then
		if currentInput == "" then
			currentInput = "0."
			displayExpression = displayExpression .. "0."
		else
			currentInput = currentInput .. "."
			displayExpression = displayExpression .. "."
		end
		updateResultDisplay()
	end
end

local function onPercent()
	if currentInput ~= "" then
		currentInput = tostring(tonumber(currentInput) / 100)
		displayExpression = currentInput
		updateResultDisplay()
	end
end

local function applyOperator(right)
	if operator == "+" then
		leftOperand = leftOperand + right
	elseif operator == "-" then
		leftOperand = leftOperand - right
	elseif operator == "x" then
		leftOperand = leftOperand * right
	elseif operator == "/" then
		if right == 0 then
			resultT.Text = "Error"
			return false
		end
		leftOperand = leftOperand / right
	end
	return true
end

local function onChangeSign()
	if currentInput == "" and displayExpression:sub(-1):match("[%+%-%x%/]") then
		currentInput = "-"
		displayExpression = displayExpression .. "-"
		updateResultDisplay()
		return
	end

	local operandStr, base
	if currentInput ~= "" then
		operandStr = currentInput
		base = displayExpression:sub(1, #displayExpression - #operandStr)
	else
		local pos = displayExpression:find("[^%+%-%x%/]+$")
		base = pos and displayExpression:sub(1, pos - 1) or ""
		operandStr = pos and displayExpression:sub(pos) or ""
	end

	if operandStr:sub(1,1) == "(" and operandStr:sub(-1) == ")" then
		operandStr = operandStr:sub(2, -2)
	end

	local newInner = (operandStr:sub(1,1) == "-" and operandStr:sub(2)) or ("-" .. operandStr)
	local num = tonumber(newInner) or 0

	if not leftOperand then
		leftOperand = num
	else
		applyOperator(num)
	end

	operator = "x"
	currentInput = ""
	displayExpression = base .. "(" .. newInner .. ")" .. "x"
	updateResultDisplay()
end

local function onOperatorInput(sym)
	if currentInput == "" and displayExpression ~= "" then
		local lastChar = displayExpression:sub(-1)
		if lastChar == "x" and sym == "-" then
			displayExpression = displayExpression .. "-"
			operator = "x"
			updateResultDisplay()
			return
		end
		displayExpression = displayExpression:sub(1, -2) .. sym
		operator = sym
		updateResultDisplay()
		return
	end

	local num = tonumber(currentInput) or 0
	if not leftOperand then
		leftOperand = num
	else
		if not applyOperator(num) then return end
	end

	displayExpression = (displayExpression == "" and tostring(num) or displayExpression) .. sym
	currentInput = ""
	operator = sym
	updateResultDisplay()
end

local function onEqual()
	if not operator or currentInput == "" then return end
	operationT.Text = displayExpression
	if applyOperator(tonumber(currentInput)) then
		resultT.Text = tostring(leftOperand)
	end
	currentInput, leftOperand, operator, displayExpression = tostring(leftOperand), nil, nil, ""
end

local function calculatorAppSetup()
	if not appsConfig.calculator.enabled then return end
	
	local operatorsF = find(calculatorApp, "operators"):: Frame
	operationT = find(calculatorApp, "operation"):: TextLabel
	resultT = find(calculatorApp, "result"):: TextLabel

	onClear()

	for _, actionB in pairs(operatorsF:GetChildren()) do
		if actionB:IsA("TextButton") then
			actionB.Activated:Connect(function()
				local action, txt = actionB.Name, actionB.Text
				if tonumber(txt) then
					onNumberInput(txt)
				elseif action == "dot" then
					onDotInput()
				elseif action == "addless" then
					onChangeSign()
				elseif action == "percent" then
					onPercent()
				elseif action == "equal" then
					onEqual()
				elseif action == "zero" then
					onClear()
				elseif action == "add" or action == "substract" or action == "multiplication" or action == "division" then
					txt = actionB:GetAttribute("action")
					onOperatorInput(txt)
				end
			end)
		end
	end
end

-- < Jobs > --
local tweenInfoOut = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweenInfoIn = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local teamDebounce = false

local function getPlayersCountInTeam(teamName)
	local players = {}

	for _, serverPlayer in pairs(players:GetPlayers()) do
		if serverPlayer.Team.Name == teamName then
			table.insert(players, serverPlayer)
		end
	end

	return #players
end

local function teamChangeHandler(team: Team)
	if teamDebounce then return end
	teamDebounce = true

	phoneClientE:FireServer("teamChange", team)

	task.delay(1, function()
		teamDebounce = false
	end)
end

local function jobsAppSetup()
	if not appsConfig.jobs.enabled then return end
	
	local jobsDisplay = find(jobsApp, "jobsDisplay"):: Frame
	local searchBox = find(jobsApp, "search/box"):: TextBox

	local jobsCounter = 0
	for _, team in ipairs(teams:GetChildren()) do
		local teamData = appsConfig.jobs.teams[team.Name]
		if teamData then
			local template = find(jobsDisplay, "template/teamName"):Clone() :: TextButton
			local displayF = find(template, "display"):: Frame
			jobsCounter += 1

			local loop = true
			local currentTween
			local hoverDebounce = false

			template.Name = team.Name
			template.teamName.Text = team.Name
			template.LayoutOrder = teamData.priority

			template.Visible = true
			template.Parent = jobsDisplay

			local function updateJoinStatus()
				if player.Team == team then
					local uiStroke = find(template, "UIStroke"):: UIStroke
					if not uiStroke then return end

					template.UIStroke.Color = Color3.fromRGB(180, 54, 68)
					template.limit.TextColor3 = Color3.fromRGB(250, 250, 250)
					template.teamName.TextColor3 = Color3.fromRGB(255, 255, 255)
					template.BackgroundColor3 = Color3.fromRGB(209, 63, 78)

					displayF.title.Text = "JOINED"
					displayF.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
					displayF.BackgroundTransparency = 0.5

					displayF.Size = UDim2.new(1, 0, 1, 0)
				else
					local uiStroke = find(template, "UIStroke"):: UIStroke
					if not uiStroke then return end

					template.UIStroke.Color = Color3.fromRGB(145, 145, 145)
					template.limit.TextColor3 = Color3.fromRGB(54, 54, 54)
					template.teamName.TextColor3 = Color3.fromRGB(0, 0, 0)
					template.BackgroundColor3 = Color3.fromRGB(250, 250, 250)

					displayF.title.Text = "JOIN"
					displayF.BackgroundColor3 = Color3.fromRGB(154, 59, 59)
					displayF.BackgroundTransparency = 0.3

					displayF.Size = UDim2.new(1, 0, 0, 0)
				end
			end

			local function playTween(size, info)
				if currentTween then
					currentTween:Cancel()
				end
				currentTween = tweenService:Create(displayF, info, { Size = size })
				currentTween:Play()
			end

			local function onMouseEnter()
				if player.Team.Name == template.Name or hoverDebounce then return end
				hoverDebounce = true
				playTween(UDim2.new(1, 0, 1, 0), tweenInfoOut)
				template.UIStroke.Color = Color3.fromRGB(180, 54, 68)
				currentTween.Completed:Connect(function() hoverDebounce = false end)
			end

			local function onMouseLeave()
				if player.Team.Name == template.Name or hoverDebounce then return end
				hoverDebounce = true
				playTween(UDim2.new(1, 0, 0, 0), tweenInfoIn)
				template.UIStroke.Color = Color3.fromRGB(145, 145, 145)
				currentTween.Completed:Connect(function() hoverDebounce = false end)
			end

			if teamData.permissions.limit.enabled then
				task.spawn(function()
					while loop do
						local success, err = pcall(function()
							template.limit.Text = `{tostring(getPlayersCountInTeam(team.Name))}/{teamData.permissions.limit.capacity}`
						end)
						task.wait(1)
					end
				end)
			else
				template.limit.Visible = false
			end

			template.Activated:Connect(function()
				teamChangeHandler(team)
			end)

			updateJoinStatus()
			template.MouseEnter:Connect(onMouseEnter)
			template.MouseLeave:Connect(onMouseLeave)

			jobsApp.jobsCount.Text = `Available Jobs ({jobsCounter})`
			player:GetPropertyChangedSignal("Team"):Connect(updateJoinStatus)
		end
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		searchHandler(jobsDisplay, searchBox)
	end)
end

-- < Messaging > --
local chatF
local messageF
local messagesS

local mainF
local personalF
local contactsS

local emergencyF
local emergencyMsgF
local emergencyMsgS
local emergencyMsgBox

local pageLayout
local messageBox
local searchBox

local activeChatContact = nil
local msgSilenced = false

local msgDebounce = false
local msgSilenceDebounce = false

local function setupSendColor(box: TextBox, btn: TextButton)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		btn.ImageColor3 = (box.Text ~= "" and Color3.fromRGB(0, 122, 255)) or Color3.fromRGB(145, 145, 148)
	end)
end

local function reorderContact(contact: Player)
	local contactB = find(contactsS, contact.Name):: TextButton
	if not contactB then return end
	contactB.LayoutOrder = -DateTime.now().UnixTimestamp
end

local function truncate(text: string, maxLen: number)
	if #text <= maxLen then
		return text
	end
	return `{text:sub(1, maxLen)}...`
end

local function messagePreviewer(contact: Player, chatLog)
	local contactB = find(contactsS, contact.Name):: TextButton
	local previewT = find(contactB, "preview"):: TextLabel
	local lastMsg = chatLog[#chatLog] and chatLog[#chatLog].message or ""

	previewT.Text = truncate(lastMsg, 15)
end

local function updateUnread(contact: Player)
	if activeChatContact == contact then return end

	local contactB = find(contactsS, contact.Name):: TextButton
	if contactB then
		local unreadT = find(contactB, "unread"):: TextLabel
		if unreadT then
			local n = tonumber(unreadT.Text) or 0
			n += 1
			unreadT.Text    = tostring(n)
			unreadT.Visible = true
		end
	end

	if currentScreen ~= messagesApp then
		appUnreadCount += 1
		local appB = find(appsF, messagesApp.Name):: TextButton
		if appB then
			local unreadT = find(appB, "unread"):: TextLabel
			if unreadT then
				unreadT.Text    = tostring(appUnreadCount)
				unreadT.Visible = true
			end
		end
	end
end

local function updateMessages(contact: Player, chatLog)
	for _, message in pairs(messagesS:GetChildren()) do
		if message:IsA("Frame") then
			message:Destroy()
		end
	end

	for i, entry in ipairs(chatLog) do
		local templatePath = entry.author == player and "template/local" or "template/contact"
		local template = find(messagesS, templatePath):Clone() :: Frame

		template.message.Text   = entry.message
		template.LayoutOrder    = i
		template.Parent         = messagesS
		template.Visible        = true

		task.defer(function()
			local bounds = template.message.TextBounds
			local height = bounds.Y < 25 and 25 or bounds.Y
			template.Size = UDim2.new(template.Size.X.Scale, template.Size.X.Offset, 0, height)

			local corner = template:FindFirstChildOfClass("UICorner")
			if corner then
				local scale = (height == 25 or height == 28) and 1 or 0.3
				corner.CornerRadius = UDim.new(scale, 0)
			end
		end)
	end

	task.defer(function()
		local totalH = messagesS.AbsoluteCanvasSize.Y
		local viewH  = messagesS.AbsoluteSize.Y
		local padding = 10
		messagesS.CanvasPosition = Vector2.new(0, math.max(0, totalH - viewH + padding))
	end)
end

local function messageHandler(contact: Player)
	if msgDebounce then return end
	msgDebounce = true

	local message = messageBox.Text
	if message == "" then return end
	phoneClientE:FireServer("newMessage", contact, message)
	cleanText(messageBox)

	task.delay(1, function()
		msgDebounce = false
	end)
end

local function msgSilenceHandler()
	if msgSilenceDebounce then return end
	msgSilenceDebounce = true

	msgSilenced = not msgSilenced
	mainF.top.noDisturb.Image = msgSilenced and "rbxassetid://6034304894" or "rbxassetid://6034308946"

	task.delay(1, function()
		msgSilenceDebounce = false
	end)
end

local function chatHandler(contact: Player)
	if not chatF then return end
	local topF = find(chatF, "top")
	local chatLog = phoneServerF:InvokeServer("getChatLogs", contact)
	topF.contactName.Text = contact.Name
	topF.contactIcon.Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150", contact.UserId)

	activeChatContact = contact
	updateMessages(contact, chatLog)

	messageF.send.Activated:Connect(function()
		messageHandler(contact)
	end)
end

local function updateServerMessages(chatLog)
	for _, message in pairs(emergencyMsgS:GetChildren()) do
		if message:IsA("Frame") then
			message:Destroy()
		end
	end
	
	for i, entry in ipairs(chatLog) do
		local templatePath = entry.author == "server" and "template/server" or "template/local"
		local template = find(emergencyMsgS, templatePath):Clone() :: Frame

		template.message.Text   = entry.message
		template.LayoutOrder    = i
		template.Parent         = emergencyMsgS
		template.Visible        = true

		task.defer(function()
			local bounds = template.message.TextBounds
			local height = bounds.Y < 25 and 25 or bounds.Y
			template.Size = UDim2.new(template.Size.X.Scale, template.Size.X.Offset, 0, height)

			local corner = template:FindFirstChildOfClass("UICorner")
			if corner then
				local scale = (height == 25 or height == 28) and 1 or 0.3
				corner.CornerRadius = UDim.new(scale, 0)
			end
		end)
	end

	task.defer(function()
		local totalH = emergencyMsgS.AbsoluteCanvasSize.Y
		local viewH  = emergencyMsgS.AbsoluteSize.Y
		local padding = 10
		emergencyMsgS.CanvasPosition = Vector2.new(0, math.max(0, totalH - viewH + padding))
	end)
end

local function emergencyMsgHandler()
	if msgDebounce then return end
	msgDebounce = true
	
	local message = emergencyMsgBox.Text
	if message == "" then return end

	phoneClientE:FireServer("emergencyCall", "response", message)
	cleanText(emergencyMsgBox)
	
	task.delay(1, function()
		msgDebounce = false
	end)
end

local function emergencyChat()
	pageLayout:JumpTo(emergencyF)
	phoneClientE:FireServer("emergencyCall", "newCall")
	
	emergencyMsgF.send.Activated:Connect(function()
		emergencyMsgHandler()
	end)
end

local function messagesAppSetup()
	if not appsConfig.messages.enabled then return end
	
	mainF       = find(messagesApp, "main"):: Frame
	personalF   = find(mainF, "personal"):: Frame
	contactsS   = find(mainF, "contacts"):: ScrollingFrame
	pageLayout  = find(messagesApp, "UIPageLayout"):: UIPageLayout

	chatF		= find(messagesApp, "chat"):: Frame
	messageF	= find(chatF, "message"):: Frame
	messagesS	= find(chatF, "messages"):: ScrollingFrame
	messageBox	= find(messageF, "box"):: TextBox
	searchBox	= find(mainF, "top/search/box"):: TextBox
	
	emergencyF	= find(messagesApp, "emergency"):: Frame
	emergencyMsgF	= find(emergencyF, "message"):: Frame
	emergencyMsgS	= find(emergencyF, "messages"):: ScrollingFrame
	emergencyMsgBox = find(emergencyMsgF, "box"):: TextBox

	personalF.playerName.Text = player.Name
	personalF.playerIcon.Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150", player.UserId)

	local function updateContactsCount()
		local total = 0
		for _, child in pairs(contactsS:GetChildren()) do
			if child:IsA("TextButton") then
				total += 1
			end
		end
		personalF.contactsCount.Text = `{total} contact(s)`
	end

	local function addContact(serverPlayer)
		local template = find(contactsS, "template/playerName"):Clone() :: TextButton

		template.Name = serverPlayer.Name
		template.playerName.Text = serverPlayer.Name
		template.playerIcon.Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150", serverPlayer.UserId)

		template.Visible = true
		template.Parent = contactsS

		template.Activated:Connect(function()
			chatHandler(serverPlayer)
			pageLayout:JumpTo(chatF)

			template.unread.Text = "0"
			template.unread.Visible = false
		end)
	end

	local function removeContact(serverPlayer)
		local contact = find(contactsS, serverPlayer.Name)
		if contact then contact:Destroy() end
	end

	for _, serverPlayer in pairs(players:GetPlayers()) do
		if serverPlayer ~= player then
			addContact(serverPlayer)
		end
	end
	updateContactsCount()

	players.PlayerAdded:Connect(function(newPlayer)
		if newPlayer ~= player then
			addContact(newPlayer)
			updateContactsCount()
		end
	end)

	players.PlayerRemoving:Connect(function(leavingPlayer)
		if leavingPlayer ~= player then
			removeContact(leavingPlayer)
			updateContactsCount()
			returnFromChat()
		end
	end)
	
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		searchHandler(contactsS, searchBox)
	end)
	
	personalF.emergency.Activated:Connect(emergencyChat)
	
	chatF.top.back.Activated:Connect(returnFromChat)
	mainF.top.noDisturb.Activated:Connect(msgSilenceHandler)
	emergencyF.top.back.Activated:Connect(returnFromEmergency)
	
	setupSendColor(messageBox, messageF.send)
	setupSendColor(emergencyMsgBox, emergencyMsgF.send)
end

function returnFromEmergency()
	phoneClientE:FireServer("emergencyCall", "cancelCall")
	pageLayout:JumpTo(mainF)
end

function returnFromChat()
	activeChatContact = nil
	pageLayout:JumpTo(mainF)
end

-- < Bank > --
local homeF
local cardF
local historyF
local personalF
local interactionsF

local deposit_withdrawF
local deposit_withdraw_cardF
local deposit_withdraw_paddingF
local deposit_withdraw_accountF
local deposit_withdraw_amountF
local deposit_withdraw_topF

local deposit_withdraw_interactionsF
local deposit_withdraw_actionB
local deposit_withdraw_inputs
local deposit_withdraw_swipeF

local transferF
local transfer_input
local transfer_input_interactionsF
local transfer_input_paddingF
local transfer_input_inputsF
local transfer_input_amountF
local transfer_input_actionB

local transfer_selectorF
local transfer_selector_interactionsF
local transfer_selector_selectedF
local transfer_selector_contactsS
local transfer_selector_paddingF
local transfer_selector_limitsF

local currentInput = "0"
local selectedRecipient = nil
local transactionFrames = {}

local bankDebounce = false

local function resetInput(inputT: TextLabel)
	currentInput = "0"
	inputT.Text = `{currencySymbol}0`
end

local function handleInput(name)
	if tonumber(name) then
		currentInput = (currentInput == "0") and name or `{currentInput}{name}`
	elseif name == "backspace" then
		if #currentInput > 1 then
			currentInput = currentInput:sub(1, -2)
		else
			currentInput = "0"
		end
	end
end

local function setupInputs(inputsFrame: Frame, outputLabel:TextLabel)
	for _, input in pairs(inputsFrame:GetChildren()) do
		if input:IsA("TextButton") then
			input.Activated:Connect(function()
				handleInput(input.Name)
				outputLabel.Text = `{currencySymbol}{currentInput}`
			end)
		end
	end
end

local function resetSelected()
	transfer_selector_selectedF.selectedRecipient.Text = "None"
	selectedRecipient = nil
end

local function updateTransactions(transactions)
	local transactionsS = find(historyF, "transactions"):: ScrollingFrame
	local newFrames = {}

	for index, transaction in ipairs(transactions) do
		local action = transaction.action
		local amount = transaction.amount
		local id = transaction.time

		local template = transactionFrames[id]
		if not template then
			template = find(transactionsS, "template/transactionId"):Clone() :: Frame
		end

		newFrames[id] = template
		template.Name = id
		template.title.Text = action
		template.amount.Text = amount

		template.Visible = true
		template.LayoutOrder = index
		template.Parent = transactionsS
	end

	for cs, template in pairs(transactionFrames) do
		if not newFrames[cs] then
			template:Destroy()
		end
	end

	transactionFrames = newFrames
end

local function bankActionHandler(action: string, amount: string, target: Player)
	if bankDebounce then return end
	bankDebounce = true
	
	local success = phoneServerF:InvokeServer("bank", action, amount, target)
	task.delay(1, function()
		bankDebounce = false
	end)
	return success
end

local function bankScreenHandler(action: string)
	if action == "deposit" or action == "withdraw" then
		deposit_withdraw_topF.title.Text = capitalizeFirst(action)
		deposit_withdraw_actionB.Text = string.upper(action)
		
		deposit_withdrawF.Visible = true
		homeF.Visible = false
		
		deposit_withdraw_actionB.Activated:Connect(function()
			if bankActionHandler(action, deposit_withdraw_amountF.input.Text) then
				resetInput(deposit_withdraw_amountF.input)
			end
		end)
	elseif action == "transfer" then
		transferF.Visible = true
		homeF.Visible = false
		
		transfer_input_actionB.Activated:Connect(function()
			if bankActionHandler(action, transfer_input_amountF.input.Text, selectedRecipient) then
				resetInput(transfer_input_amountF.input)
			end
		end)
	end
end

local function setupCurrencyFormatter(textBox: TextBox)
	textBox:GetPropertyChangedSignal("Text"):Connect(function()
		local digits = textBox.Text:gsub("%D", "")
		if digits == "" then return end

		local formatted = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
		local newText   = `{currencySymbol}{formatted}`

		if textBox.Text ~= newText then
			textBox.Text = newText
		end
	end)
end

local function bankAppSetup()
	if not appsConfig.bank.enabled then return end
	
	homeF				= find(bankApp, "home"):: Frame
	transferF			= find(bankApp, "transfer"):: Frame
	deposit_withdrawF	= find(bankApp, "deposit_withdraw"):: Frame

	cardF			= find(homeF, "card"):: Frame
	historyF		= find(homeF, "history"):: Frame
	personalF		= find(homeF, "personal"):: Frame
	interactionsF	= find(homeF, "interactions"):: Frame

	deposit_withdraw_paddingF = find(deposit_withdrawF, "padding"):: Frame
	deposit_withdraw_accountF = find(deposit_withdraw_paddingF, "account"):: Frame
	deposit_withdraw_amountF = find(deposit_withdraw_paddingF, "amount"):: Frame
	deposit_withdraw_cardF = find(deposit_withdraw_paddingF, "card"):: Frame
	deposit_withdraw_topF = find(deposit_withdraw_paddingF, "top"):: Frame

	deposit_withdraw_interactionsF = find(deposit_withdrawF, "interactions"):: Frame
	deposit_withdraw_actionB = find(deposit_withdraw_interactionsF, "action"):: TextButton
	deposit_withdraw_inputs = find(deposit_withdraw_interactionsF, "inputs"):: Frame
	deposit_withdraw_swipeF = find(deposit_withdraw_interactionsF, "swipe"):: Frame
	
	transfer_input = find(transferF, "input"):: Frame
	transfer_input_interactionsF = find(transfer_input, "interactions"):: Frame
	transfer_input_paddingF = find(transfer_input, "padding"):: Frame
	
	transfer_input_amountF = find(transfer_input_paddingF, "amount"):: Frame
	transfer_input_inputsF = find(transfer_input_interactionsF, "inputs"):: Frame
	transfer_input_actionB = find(transfer_input_interactionsF, "action"):: TextButton

	transfer_selectorF				= find(transferF, "selector"):: Frame
	transfer_selector_interactionsF = find(transfer_selectorF, "interactions"):: Frame
	
	transfer_selector_paddingF		= find(transfer_selectorF, "padding"):: Frame
	transfer_selector_limitsF		= find(transfer_selector_paddingF, "limits"):: Frame
	transfer_selector_selectedF		= find(transfer_selector_paddingF, "selected"):: Frame
	transfer_selector_contactsS		= find(transfer_selector_interactionsF, "contacts"):: ScrollingFrame
	
	local bankTransferConfig = appsConfig.bank.tabs["Transfer"]
	transfer_selector_limitsF.maxTransfer.Text = bankTransferConfig.limits.enabled and `{currencySymbol}{addComma(bankTransferConfig.limits.maxAmount)}` or `UNLIMITED`
	
	local userId = player.UserId
	local idStr = tostring(userId)
	local last4 = #idStr > 4 and idStr:sub(-4) or idStr
	 
	cardF.number.Text = `**** **** **** {last4}`
	personalF.title.Text = `Hi, {player.Name}`
	personalF.playerIcon.Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150", userId)
	
	for _, button in pairs(interactionsF:GetChildren()) do
		if button:IsA("TextButton") then
			button.Activated:Connect(function()
				bankScreenHandler(button.Name)
			end)
		end
	end
	
	for tabName, tabConfig in pairs(appsConfig.bank.tabs) do
		local button = find(interactionsF, string.lower(tabName))
		if button and button:IsA("TextButton") then
			button.Visible = tabConfig.enabled
		end
	end
	
	if economyData then
		local bank = economyData.bank
		
		for _, balanceT in pairs(bankApp:GetDescendants()) do
			if balanceT:IsA("TextLabel") and balanceT.Name == "balance" then
				updateBalance(bank, balanceT, balanceT:GetAttribute("text"))
				
				table.insert(connections, bank:GetPropertyChangedSignal("Value"):Connect(function()
					updateBalance(bank, balanceT, balanceT:GetAttribute("text"))
				end))
			end
		end
	end
	
	-- < Deposit_Withdraw Frame > --
	deposit_withdraw_amountF.input.Text = `{currencySymbol}0`
	transfer_input_amountF.input.Text = `{currencySymbol}0`
	
	-- < Transfer Frame > --
	local function addContact(serverPlayer)
		local template = find(transfer_selector_contactsS, "template/playerName"):Clone() :: TextButton

		template.Name = serverPlayer.Name
		template.playerName.Text = serverPlayer.Name
		template.initial.Text = serverPlayer.Name:sub(1,1):upper()

		template.Visible = true
		template.Parent = transfer_selector_contactsS

		template.Activated:Connect(function()
			selectedRecipient = serverPlayer
			transfer_selector_selectedF.selectedRecipient.Text = serverPlayer.Name
			transfer_selector_selectedF.initial.Text = serverPlayer.Name:sub(1,1):upper()
		end)
	end

	local function removeContact(serverPlayer)
		local contact = find(transfer_selector_contactsS, serverPlayer.Name)
		if contact then contact:Destroy() end
	end

	for _, serverPlayer in pairs(players:GetPlayers()) do
		if serverPlayer ~= player then
			addContact(serverPlayer)
		end
	end

	players.PlayerAdded:Connect(function(newPlayer)
		if newPlayer ~= player then
			addContact(newPlayer)
		end
	end)

	players.PlayerRemoving:Connect(function(leavingPlayer)
		if leavingPlayer ~= player then
			removeContact(leavingPlayer)
			returnFromChat()
		end
	end)
	
	transfer_selector_interactionsF.continue.Activated:Connect(function()
		if not selectedRecipient then return end
		transfer_selectorF.Visible = false
		transfer_input.Visible = true
	end)
	
	deposit_withdraw_topF.back.Activated:Connect(function()
		returnFromScreen(deposit_withdrawF, homeF)
		resetInput(deposit_withdraw_amountF.input)
	end)
	
	transfer_selector_paddingF.top.back.Activated:Connect(function()
		returnFromScreen(transferF, homeF)
		resetSelected()
	end)
	
	transfer_input_paddingF.top.back.Activated:Connect(function()
		returnFromScreen(transfer_input, transfer_selectorF)
		resetInput(transfer_input_amountF.input)
	end)
	
	setupInputs(deposit_withdraw_inputs, deposit_withdraw_amountF.input)
	setupInputs(transfer_input_inputsF, transfer_input_amountF.input)

	setupCurrencyFormatter(deposit_withdraw_amountF.input)
	setupCurrencyFormatter(transfer_input_amountF.input)
end

-- < Notes > --
local notesText = ""

local function notesAppSetup()
	if not appsConfig.notes.enabled then return end
	
	local mainF    = find(notesApp, "main"):: Frame
	local notesBox = find(mainF, "notes"):: TextBox
	
	notesBox.Text = notesText
	
	notesBox:GetPropertyChangedSignal("Text"):Connect(function()
		notesText = notesBox.Text
	end)
end

-- || FRAMEWORK FUNCTIONS || --

function main.initialize(_framework, system)
	find = _framework.find
	addComma = _framework.addComma
	useService = _framework.useService
	getPlayerEconomy = _framework.getPlayerEconomy

	framework		= _framework
	config			= require(system.Config)
	systemConfig	= config.systemConfig
	economyConfig	= config.economyConfig
	currencySymbol	= economyConfig.currencySymbol

	radioConfig		= systemConfig.radio
	phoneConfig		= systemConfig.phone
	appsConfig		= phoneConfig.apps
	soundsConfig	= phoneConfig.sounds
	widgetsConfig	= phoneConfig.widgets

	systemGuis = system.Guis
	systemAssets = system.Assets
	systemEvents = system.Events
	systemFunctions = system.Functions

	sounds = find(systemAssets, "Sounds"):: Folder
	phoneSounds = find(sounds, "phone"):: Folder

	hoverS = find(phoneSounds, "hover"):: Sound
	notificationS = find(phoneSounds, "notification")::  Sound

	phoneClientE = find(systemEvents, "phoneClient"):: RemoteEvent
	phoneServerF = find(systemFunctions, "phoneServer"):: RemoteFunction
	
	lighting		= useService("Lighting"):: Lighting
	tweenService	= useService("TweenService"):: TweenService
	soundService	= useService("SoundService"):: SoundService
	textChatService	= useService("TextChatService"):: TextChatService
	userInputService = useService("UserInputService"):: UserInputService
	voiceChatService = useService("VoiceChatService"):: VoiceChatService
	collectionService = useService("CollectionService"):: CollectionService

	players		= useService("Players"):: Players
	player		= players.LocalPlayer:: Player
	teams		= useService("Teams"):: Teams
	economyData = getPlayerEconomy(player)

	UI = find(player.PlayerGui, script.Name, true)
	if not UI then return end

	interfaceF = find(UI, "interface"):: Folder
	mockupF = find(interfaceF, "mockup"):: Frame
	decoFld = find(mockupF, "deco"):: Folder

	screenF			= find(mockupF, "screen"):: Frame
	appsFld			= find(screenF, "apps"):: Folder
	calculatorApp	= find(appsFld, "calculator"):: Frame
	emergencyApp	= find(appsFld, "emergency"):: Frame
	messagesApp		= find(appsFld, "messages"):: Frame
	configApp		= find(appsFld, "config"):: Frame
	moneyApp		= find(appsFld, "money"):: Frame
	phoneApp		= find(appsFld, "phone"):: Frame
	notesApp		= find(appsFld, "notes"):: Frame
	jobsApp			= find(appsFld, "jobs"):: Frame
	bankApp			= find(appsFld, "bank"):: Frame

	homescreenF = find(screenF, "homescreen"):: Frame
	dockF		= find(homescreenF, "dock"):: Frame
	mainF		= find(homescreenF, "main"):: Frame
	widgetF		= find(mainF, "widget"):: Frame
	appsF		= find(mainF, "apps"):: Frame

	topF		= find(screenF, "top"):: Frame
	backB		= find(screenF, "back"):: TextButton
	wallpaperI	= find(screenF, "wallpaper"):: ImageLabel

	currentScreen = homescreenF

	themeHandler(wallpaperI)
	mockupF.Position = UDim2.new(0.5, 0, 1.3, 0)
	uiTransition("open", mockupF, 0.6)
end

function main.initiate(framework, system, tool: Tool)
	widgetSetup()
	bankAppSetup()
	jobsAppSetup()
	notesAppSetup()
	homescreenSetup()
	messagesAppSetup()
	calculatorAppSetup()

	table.insert(connections, phoneClientE.OnClientEvent:Connect(function(...)
		local inputs = {...}
		local action = inputs[1]

		if action == "messageUpdater" then
			local contact = inputs[2]
			local chatLog = inputs[3]

			local lastEntry = chatLog[#chatLog]
			if lastEntry and lastEntry.author ~= player and not msgSilenced then
				soundService:PlayLocalSound(notificationS)
			end

			reorderContact(contact)
			messagePreviewer(contact, chatLog)

			if contact ~= activeChatContact then
				updateUnread(contact)
				return
			end

			updateMessages(contact, chatLog)
		elseif action == "serverMessageUpdater" then
			local chatLog = inputs[2]
			updateServerMessages(chatLog)
		elseif action == "bankTransactionsUpdater" then
			local transactions = inputs[2]
			updateTransactions(transactions)
		end
	end))

	table.insert(connections, tool.Unequipped:Connect(function()
		for _, conn in ipairs(connections) do
			conn:Disconnect()
		end

		homeHandler()
		activeChatContact = nil
		selectedRecipient = nil

		uiTransition("close", mockupF, 0.6)
	end))

	screenF.home.Activated:Connect(homeHandler)
end

return main
