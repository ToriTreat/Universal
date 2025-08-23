local main = {}

local config
local framework
local appsConfig
local radioConfig
local phoneConfig
local systemConfig
local economyConfig
local quickRadioConfig

local players
local teamService
local marketplaceService

local mdtSystem
local overheadSystem

local locationsFolder
local locationParts

local phoneServerF
local phoneClientE
local radioServerF
local radioClientE
local radioVCE

local sounds
local phoneSounds
local radioSounds

local systemGuis
local systemAssets
local systemEvents
local systemFunctions

local lastMessageTimestamps = {}
local lastMessageCooldownStart = {}

local lastQuickRadioTimestamps = {}
local lastQuickRadioCooldownStart = {}

local lastPanicTimes = {}
local lastTeam = {}

local channelLogs = {}
local callsigns = {}
local invites = {}
local squads = {}
local calls = {}

local messagesLogs = {}

local baseSquadFreq = 100
local maxMessages = 10
local callId = 0
local msgId = 0

local find, useService, addComma, getPlayerEconomy, getLibrary, replicateUI, notificationEvent, getSystemCompatibility

-- || SYSTEM FUNCTIONS || --

-- < RADIO FUNCTIONS > --
-- < Callsigns > --
local function removeCallsignFromPlayer(player: Player)
	for pos, callsign in pairs(callsigns) do
		if callsign.user == player then
			table.remove(callsigns, pos)
		end
	end
end

local function getCallsignFromPlayer(player: Player)
	for _, callsign in pairs(callsigns) do
		if callsign.user == player then
			return callsign
		end
	end
	return nil
end

local function callsignRemoval(player: Player)
	if getCallsignFromPlayer(player) then
		removeCallsignFromPlayer(player)
		radioClientE:FireAllClients("updateUnits", callsigns)
	end
end

local function callsignCheck(player: Player, callsign)
	if type(callsign) ~= "string" then
		return false
	end

	local minLen, maxLen = unpack(radioConfig.callsign.length)
	local len = #callsign
	if len < minLen or len > maxLen then
		notificationEvent(player, "client", "Invalid Callsign", `Your callsign must be between {minLen} and {maxLen} characters long.`, 3, "warning")
		return false
	end

	local letterCount = 0
	for i = 1, len do
		local c = callsign:sub(i, i)
		if c:match("%a") then
			if not radioConfig.callsign.letters.allowed then
				notificationEvent(player, "client", "Invalid Callsign", "Letters are not allowed in your callsign.", 3, "warning")
				return false
			end
			letterCount += 1

		elseif c:match("%d") then
			if not radioConfig.callsign.numbers.allowed then
				notificationEvent(player, "client", "Invalid Callsign", "Numbers are not allowed in your callsign.", 3, "warning")
				return false
			end

		else
			notificationEvent(player, "client", "Invalid Callsign", "Your callsign may only contain letters and numbers.", 3, "warning")
			return false
		end
	end

	if radioConfig.callsign.letters.allowed and letterCount > radioConfig.callsign.letters.max then
		notificationEvent(player, "client", "Invalid Callsign", `Your callsign cannot contain more than {radioConfig.callsign.letters.max} letters.`, 3, "warning")
		return false
	end

	for _, entry in pairs(callsigns) do
		if entry.callsign == callsign then
			notificationEvent(player, "client", "Callsign Taken", "That callsign is already taken.", 3, "warning")
			return false
		elseif entry.user == player then
			return false
		end
	end

	return true
end

local function callsignOverheadSystem(player: Player)
	local callsignObj = getCallsignFromPlayer(player)
	if callsignObj and overheadSystem and radioConfig.callsign.displayCallsignInOverhead then
		local character = player.Character
		local teamT = find(character, "Head/overheadUI/playerTeam/playerTeam", true):: TextLabel
		if teamT then
			teamT.Text = `{player.Team.Name} [{callsignObj.callsign}]`
		end
	end
end

local function callsignCreation(player: Player, newCallsign)
	local newCallsignUpper = string.upper(newCallsign)
	if callsignCheck(player, newCallsignUpper) then
		table.insert(callsigns, {
			callsign = newCallsignUpper,
			user = player,
			status = "onDuty"
		})
		warn(callsigns)
		callsignOverheadSystem(player)
		radioClientE:FireAllClients("updateUnits", callsigns)
		return true
	end
	return false
end

-- < Status > --
local function updateStatus(player: Player, newStatus)
	local callsign = getCallsignFromPlayer(player)
	if not callsign then return end
	callsign.status = newStatus
	radioClientE:FireAllClients("updateUnits", callsigns)
end

-- < Squads > --
local function squadCheck(player: Player, team: Team, squadCallsign)
	if type(squadCallsign) ~= "string" then
		return false
	end

	local minLen, maxLen = unpack(radioConfig.squad.length)
	local len = #squadCallsign
	if len < minLen or len > maxLen then
		notificationEvent(player, "client", "Invalid Squad Callsign", `Your squad callsign must be between {minLen} and {maxLen} characters long.`, 3, "warning")
		return false
	end

	local letterCount = 0
	for i = 1, len do
		local c = squadCallsign:sub(i, i)
		if c:match("%a") then
			if not radioConfig.squad.letters.allowed then
				notificationEvent(player, "client", "Invalid Squad Callsign", "Letters are not allowed in your squad callsign.", 3, "warning")
				return false
			end
			letterCount += 1

		elseif c:match("%d") then
			if not radioConfig.squad.numbers.allowed then
				notificationEvent(player, "client", "Invalid Squad Callsign", "Numbers are not allowed in your squad callsign.", 3, "warning")
				return false
			end

		else
			notificationEvent(player, "client", "Invalid Squad Callsign", "Your squad callsign may only contain letters and numbers.", 3, "warning")
			return false
		end
	end

	if radioConfig.squad.letters.allowed and letterCount > radioConfig.squad.letters.max then
		notificationEvent(player, "client", "Invalid Squad Callsign", `Your squad callsign cannot contain more than {radioConfig.squad.letters.max} letters.`, 3, "warning")
		return false
	end

	for _, entry in pairs(squads) do
		if entry.team == team then
			if entry.callsign == squadCallsign then
				notificationEvent(player, "client", "Squad Callsign Taken", "That squad callsign is already taken.", 3, "warning")
				return false
			end
		end

		if entry.user == player then
			return false
		end
	end

	return true
end

local function getSquadsCallsign(playersList)
	local result = {}
	for i, player in ipairs(playersList) do
		local entry = getCallsignFromPlayer(player)
		result[i] = entry or ""
	end
	return result
end

local function getSquadFromPlayer(player: Player)
	for _, squadData in ipairs(squads) do
		for _, memberData in ipairs(squadData.members) do
			if memberData.user == player then
				return squadData
			end
		end
	end
	return nil
end

local function getSquadInfoForTeam(playersList)
	local result = {}

	for i, player in ipairs(playersList) do
		local entry = getCallsignFromPlayer(player)
		local callsign = entry and entry.callsign or ""
		local theirSquad = getSquadFromPlayer(player)

		result[i] = {
			callsign = callsign,
			squad    = theirSquad,
			user     = player,
		}
	end

	return result
end

local function getAccessibleChannelsFor(player: Player)
	local result = {}

	for name, data in pairs(radioConfig.channels) do
		if table.find(data.teamAccess, player.Team.Name) then
			table.insert(result, {
				name      = name,
				frequency = data.frequency,
				color     = data.color,
				isSquad   = false,
			})
		end
	end

	local mySquad = getSquadFromPlayer(player)
	if mySquad then
		local squadIndex = table.find(squads, mySquad)
		local freq       = baseSquadFreq + squadIndex
		table.insert(result, {
			name      = `SQUAD-{mySquad.callsign}`,
			frequency = freq,
			color     = player.Team.TeamColor.Color, 
			isSquad   = true,
		})
	end

	return result
end

local function squadCreation(player: Player, newSquadCallsign)
	local team = player.Team

	if squadCheck(player, team, newSquadCallsign) then
		table.insert(squads, {
			team = team,
			callsign = newSquadCallsign,
			creator = player,
			members = {getCallsignFromPlayer(player)
			}})
		radioClientE:FireAllClients("updateSquads", squads)
		return true
	end
end

local function squadRemoval(player: Player)
	for squadIdx, squadData in ipairs(squads) do
		if squadData.creator == player then
			for _, memberData in ipairs(squadData.members) do
				local member = memberData.user
				if member ~= player then
					notificationEvent(
						member,
						"client",
						"Squad Disbanded",
						`Your squad '{squadData.callsign}' was deleted by the creator.`,
						3,
						"info"
					)
				end
			end

			local squadFreq = baseSquadFreq + squadIdx
			table.remove(squads, squadIdx)

			for i, logEntry in ipairs(channelLogs) do
				if logEntry.frequency == squadFreq then
					table.remove(channelLogs, i)
					break
				end
			end

			radioClientE:FireAllClients("updateSquads", squads)

			notificationEvent(
				player,
				"client",
				"Squad Deleted",
				`Your squad '{squadData.callsign}' has been deleted.`,
				3,
				"warning"
			)
			return true
		end
	end

	return false
end

local function addPlayerToSquad(player: Player, squadCallsign: string)
	for _, squadData in ipairs(squads) do
		if squadData.callsign == squadCallsign and squadData.team == player.Team then

			for _, member in ipairs(squadData.members) do
				if member.user == player then
					warn(("Squad System Warning: %s is already in squad %s."):format(player.Name, squadCallsign))
					return false
				end
			end

			if radioConfig.squad.limit.maxMembersEnabled and #squadData.members >= radioConfig.squad.limit.maxMembers then
				notificationEvent(
					squadData.creator,
					"client",
					"Squad Full",
					`Cannot add {player.Name}; squad '{squadCallsign}' is full (max {radioConfig.squad.limit.maxMembers} members).`,
					5,
					"warning"
				)
				return false
			end

			local entry = getCallsignFromPlayer(player)
			table.insert(squadData.members, entry)
			radioClientE:FireAllClients("updateSquads", squads)
			return true
		end
	end
	return false
end

local function removePlayerFromSquad(player: Player)
	local playerCallsignObj = getCallsignFromPlayer(player)
	if not playerCallsignObj then
		return false
	end

	for squadIdx, squadData in ipairs(squads) do
		if squadData.creator == player then
			squadRemoval(player)
		end

		local members = squadData.members
		for memberIdx, callsignObj in ipairs(members) do
			if callsignObj.user == player then
				table.remove(members, memberIdx)
				if #members == 0 then
					table.remove(squads, squadIdx)
				end

				radioClientE:FireAllClients("updateSquads", squads)
				return true
			end
		end
	end

	return false
end

local function leaveSquad(player: Player)
	local squadData = getSquadFromPlayer(player)

	if not squadData then return end
	local squadCreator = squadData.creator

	removePlayerFromSquad(player)

	if player ~= squadCreator then
		notificationEvent(
			squadCreator,
			"client",
			"Squad Member Left",
			`{player.Name} has left your squad.`,
			3,
			"warning"
		)
	end
end

local function squadAdmin(player: Player, action: string, target: Player)
	local squad = getSquadFromPlayer(player)
	local targetCallsign = getCallsignFromPlayer(target)
	if not squad then
		return false
	end

	if squad.creator ~= player then
		return false
	end

	if not targetCallsign then
		notificationEvent(
			player,
			"client",
			"Invite Failed",
			`Failed to send invite to {target.Name}.`,
			3,
			"warning"
		)
		return false
	end

	if action == "invite" then
		if radioConfig.squad.limit.maxMembersEnabled and #squad.members >= radioConfig.squad.limit.maxMembers then
			notificationEvent(
				player,
				"client",
				"Invite Failed",
				`Cannot invite {target.Name}; squad '{squad.callsign}' has reached max members ({radioConfig.squad.limit.maxMembers}).`,
				5,
				"warning"
			)
			return false
		end

		table.insert(invites, {
			inviteAuthor = player,
			squadCallsign = squad.callsign,
			invited = target
		})
		radioClientE:FireClient(target, "squadInvitation", player)
		notificationEvent(
			player,
			"client",
			"Invite Sent",
			`{target.Name} has been invited to your squad.`,
			3,
			"success"
		)
	elseif action == "kick" then
		removePlayerFromSquad(target)
		notificationEvent(
			target,
			"client",
			"Kicked from Squad",
			`{player.Name} has kicked you from the squad.`,
			3,
			"warning"
		)
		notificationEvent(
			player,
			"client",
			"Player Kicked",
			`{target.Name} has been kicked from your squad.`,
			3,
			"success"
		)
	end

	return true
end

local function squadInvitation(decision: string, player: Player)
	local foundInvite
	local foundIdx
	for i, invite in ipairs(invites) do
		if invite.invited == player then
			foundInvite = invite
			foundIdx    = i
			break
		end
	end

	if not foundInvite then
		warn(`Squad System Warning: No invite found for {player.Name}`)
		return false
	end

	if decision == "accept" then
		addPlayerToSquad(player, foundInvite.squadCallsign)
		notificationEvent(
			player,
			"client",
			"Joined Squad",
			`You have joined {foundInvite.inviteAuthor}'s squad.`,
			3,
			"success"
		)

		notificationEvent(
			foundInvite.inviteAuthor,
			"client",
			"Squad Member Joined",
			(`{player.Name} has joined your squad.`),
			3,
			"success"
		)

	elseif decision == "decline" then
		notificationEvent(
			foundInvite.inviteAuthor,
			"client",
			"Invitation Rejected",
			`{player.Name} has declined your squad invitation.`,
			3,
			"error"
		)

	else
		warn(`Squad System Warning: Unknown decision {decision} for {player.Name}`)
		return false
	end

	table.remove(invites, foundIdx)
	return true
end
--warn(`URBAN STUDIOS - Radio & Phone System Warning: text`)

local function getSquads(targetPlayer: Player)
	radioClientE:FireClient(targetPlayer, "updateSquads", squads)
end

-- < Messaging and Channels > --
local function getNearestLocation(player: Player)
	local char = player.Character
	if not char or not char.PrimaryPart then return nil end

	local pos = char.PrimaryPart.Position
	local bestDist2 = math.huge
	local bestName

	for _, part in ipairs(locationParts) do
		local d2 = (part.Position - pos).Magnitude^2
		if d2 < bestDist2 then
			bestDist2 = d2
			bestName = part.Name
		end
	end

	return bestName
end

local function getOrCreateChannelLog(frequency: number)
	for _, channel in ipairs(channelLogs) do
		if channel.frequency == frequency then
			return channel
		end
	end
	local newLog = { frequency = frequency, log = {} }
	table.insert(channelLogs, newLog)
	return newLog
end

local function isCallAuthor(player)
	for _, callInfo in ipairs(calls) do
		if callInfo.author == player.Name then
			return true
		end
	end
	return false
end

local function getCalls(player: Player)
	radioClientE:FireClient(player, "updateCalls", calls)
end

local function radioMessageHandler(player: Player, message: string, frequency: number, msgType: string, includeLoc: boolean)
	--if not find(player, "PlayerGui/radioUI") or not getCallsignFromPlayer(player) or not isCallAuthor(player) then return end

	local now = tick()
	local color = player.TeamColor.Color

	if msgType == "panic" then
		color = Color3.fromRGB(232, 155, 0)
		local lastTime = lastPanicTimes[player]
		if lastTime and now - lastTime < radioConfig.panicCooldown then
			local remaining = math.ceil(radioConfig.panicCooldown - (now - lastTime))
			notificationEvent(player, "client", "Active Cooldown",
				`Please wait {remaining}s before using panic.`, 3, "error")
			return
		end
		lastPanicTimes[player] = now
	elseif msgType == "call" then
		color = Color3.fromRGB(198, 198, 198)
	elseif msgType == "message" and not includeLoc then -- Regular message
		local cdStart = lastMessageCooldownStart[player]
		if cdStart and now - cdStart < radioConfig.messageCooldown then
			local remaining = math.ceil(radioConfig.messageCooldown - (now - cdStart))
			notificationEvent(
				player,
				"client",
				"Active Cooldown",
				`Please wait {remaining}s before sending another message.`,
				3,
				"error"
			)
			return
		end

		local timesList = lastMessageTimestamps[player]
		if not timesList then
			timesList = {}
			lastMessageTimestamps[player] = timesList
		end

		table.insert(timesList, now)
		while #timesList > 0 and timesList[1] < now - radioConfig.messageCooldown do
			table.remove(timesList, 1)
		end

		if #timesList >= 3 then
			lastMessageCooldownStart[player] = now
			table.clear(timesList)
			notificationEvent(
				player,
				"client",
				"Active Cooldown",
				"You are sending messages too quickly.",
				3,
				"error"
			)
			return
		end

	elseif msgType == "message" and includeLoc then -- Quick Radio message
		local cdStart = lastQuickRadioCooldownStart[player]
		if cdStart and now - cdStart < radioConfig.quickRadioCooldown then
			local remaining = math.ceil(radioConfig.quickRadioCooldown - (now - cdStart))
			notificationEvent(
				player,
				"client",
				"Active Cooldown",
				`Please wait {remaining}s before sending another message.`,
				3,
				"error"
			)
			return
		end

		local timesList = lastQuickRadioTimestamps[player]
		if not timesList then
			timesList = {}
			lastQuickRadioTimestamps[player] = timesList
		end

		table.insert(timesList, now)
		while #timesList > 0 and timesList[1] < now - radioConfig.quickRadioCooldown do
			table.remove(timesList, 1)
		end

		if #timesList >= 3 then
			lastQuickRadioCooldownStart[player] = now
			table.clear(timesList)
			notificationEvent(player, "client", "Active Cooldown",
				"You are sending quick messages too quickly.", 3, "error")
			return
		end
	end

	if includeLoc then
		local loc = getNearestLocation(player) or "Unknown location"
		message = ("%s - %s"):format(message, loc)
	end

	local textObject = textFiltering.getTextObject(message, player.UserId)
	local filteredMessage = textFiltering.getFilteredMessage(textObject)

	local channelData = getOrCreateChannelLog(frequency)
	local channelLog = channelData.log

	msgId += 1

	table.insert(channelLog, 1, {
		id       = msgId,
		author   = player.Name,
		color    = color,
		callsign = (msgType == "call" and "") or getCallsignFromPlayer(player).callsign,
		message  = filteredMessage,
		class    = msgType,
	})

	while #channelLog > maxMessages do
		table.remove(channelLog)
	end

	if frequency >= baseSquadFreq then
		local squad = getSquadFromPlayer(player)
		if not squad then return end
		for _, memberData in ipairs(squad.members) do
			radioClientE:FireClient(memberData.user, "updateMessages", channelData)
		end
	else
		radioClientE:FireAllClients("updateMessages", channelData)
	end
end

-- < Radio Setup > --
local function onCharacterAdded(player: Player)
	local teamName = player.Team and player.Team.Name
	if not teamName then return end

	local hasAccess = false
	for _, channelData in pairs(radioConfig.channels) do
		if table.find(channelData.teamAccess, teamName) then
			hasAccess = true
			break
		end
	end

	local existing = find(player, "PlayerGui/radioUI")
	if hasAccess then
		if not existing then
			replicateUI(player, systemGuis, "radioUI")
		end
	else
		if existing and not hasAccess then
			existing:Destroy()
		end
	end
	callsignOverheadSystem(player)
end

local function promptRadioUI(player: Player)
	replicateUI(player, systemGuis, "radioUI")
end

local function teamHasAccess(teamName: string)
	for _, channelData in pairs(radioConfig.channels) do
		if table.find(channelData.teamAccess, teamName) then
			return true
		end
	end
	return false
end

local function setupTeamChangeListener(player: Player)
	lastTeam[player] = player.Team and player.Team.Name or nil

	player:GetPropertyChangedSignal("Team"):Connect(function()
		local oldTeam = lastTeam[player]
		local newTeam = player.Team and player.Team.Name or nil

		local hadAccessBefore = oldTeam and teamHasAccess(oldTeam) or false
		local hasAccessNow = newTeam and teamHasAccess(newTeam) or false

		if (not hadAccessBefore) and hasAccessNow then
			promptRadioUI(player)
		end

		if hadAccessBefore and hasAccessNow and oldTeam ~= newTeam then
			leaveSquad(player)
			callsignRemoval(player)

			local existingUI = find(player, "PlayerGui/radioUI")
			if existingUI then existingUI:Destroy() end
			promptRadioUI(player)
		end

		if hadAccessBefore and (not hasAccessNow) then
			local existingUI = find(player, "PlayerGui/radioUI")
			if existingUI then existingUI:Destroy() end
			leaveSquad(player)
			callsignRemoval(player)
		end

		lastTeam[player] = newTeam
	end)
end

-- < PHONE FUNCTIONS > --

-- < Messages App > --
local lastCallTimes = {}
local emergencyStates = {}

local function chatRemoval(player: Player)
	local playerId = tostring(player.UserId)
	for chatKey in pairs(messagesLogs) do
		if chatKey:match(`^{playerId}_`) or chatKey:match(`_{playerId}$`) then
			messagesLogs[chatKey] = nil
		end
	end
end

local function getChatKey(a: Player, b: Player)
	local idA, idB = tostring(a.UserId), tostring(b.UserId)
	if idA < idB then
		return `{idA}_{idB}`
	else
		return `{idB}_{idA}`
	end
end

local function getChatLogs(player: Player, contact: Player)
	local chatKey = getChatKey(player, contact)
	return messagesLogs[chatKey] or {}
end

local function phoneMessageHandler(player: Player, contact: Player, message: string)
	local textObject       = textFiltering.getTextObject(message, player.UserId)
	local filteredMessage  = textFiltering.getFilteredMessage(textObject)
	local chatKey          = getChatKey(player, contact)

	messagesLogs[chatKey] = messagesLogs[chatKey] or {}

	table.insert(messagesLogs[chatKey], {
		--id       = msgId,
		author   = player,
		receiver = contact,
		message  = filteredMessage,
	})

	local chatLog = messagesLogs[chatKey]
	phoneClientE:FireClient(player, "messageUpdater", contact, chatLog)
	phoneClientE:FireClient(contact, "messageUpdater", player, chatLog)
end

local function emergencyCallHandler(player: Player, action: string, answer: string)
	if action == "cancelCall" then
		if emergencyStates[player] then
			emergencyStates[player] = nil
			phoneClientE:FireClient(player, "serverMessageUpdater", {})
			notificationEvent(
				player, "client",
				"Call Cancelled",
				"Your emergency call has been cancelled.",
				3,
				"info"
			)
		end
		return false
	end

	if action == "newCall" then
		local now  = tick()
		local last = lastCallTimes[player]
		if last and (now - last) < appsConfig.messages.callCooldown * 60 then
			local remaining = math.ceil((appsConfig.messages.callCooldown * 60 - (now - last)) / 60)
			local tempLog = {}
			table.insert(tempLog, {
				author  = "server",
				message = `Please wait {remaining} more minute(s) before calling 911 again.`
			})
			phoneClientE:FireClient(player, "serverMessageUpdater", tempLog)
			return false
		end

		emergencyStates[player] = {
			step     = 1,
			service  = nil,
			details  = nil,
			location = nil,
			log      = {}
		}
		local state = emergencyStates[player]

		local services = appsConfig.messages.services
		local names = {}
		for name in pairs(services) do
			table.insert(names, name:lower())
		end

		local prompt = `911, what service are you requesting? Available services: {table.concat(names, ", ")}`
		table.insert(state.log, { author = "server", message = prompt })
		phoneClientE:FireClient(player, "serverMessageUpdater", state.log)

	elseif action == "response" then
		local state = emergencyStates[player]
		if not state then return end

		table.insert(state.log, { author = player, message = answer })

		if state.step == 1 then
			local services = appsConfig.messages.services
			local normalized = string.lower(answer)
			local matchedKey

			for name in pairs(services) do
				if string.lower(name) == normalized then
					matchedKey = name
					break
				end
			end

			if not matchedKey then
				local names = {}
				for name in pairs(services) do
					table.insert(names, name:lower())
				end
				local msg = `Invalid service. Available: {table.concat(names, ", ")}`
				table.insert(state.log, { author = "server", message = msg })
				phoneClientE:FireClient(player, "serverMessageUpdater", state.log)
				return false
			end

			state.service = matchedKey
			state.step    = 2
			table.insert(state.log, { author = "server", message = "Explain your emergency" })
			phoneClientE:FireClient(player, "serverMessageUpdater", state.log)
		elseif state.step == 2 then
			state.details = answer
			state.step    = 3
			table.insert(state.log, { author = "server", message = "What is your location?" })
			phoneClientE:FireClient(player, "serverMessageUpdater", state.log)

		elseif state.step == 3 then
			local serviceData = appsConfig.messages.services[state.service]
			local frequency = serviceData.frequency
			local newCall = {
				id       = callId + 1,
				author   = player.Name,
				service  = state.service,
				details  = state.details,
				location = answer,
			}

			state.location = answer
			table.insert(calls, newCall)
			table.insert(state.log, { author = "server", message = `Your call has been sent to {state.service}` })
			phoneClientE:FireClient(player, "serverMessageUpdater", state.log)
			radioMessageHandler(player, `We have a new call from {player.Name}.`, frequency, "call", false)
			radioClientE:FireAllClients("updateCalls", calls)

			local expireTime = radioConfig.callRemovalTime * 60 or 300
			task.delay(expireTime, function()
				for i, callInfo in ipairs(calls) do
					if callInfo.id == newCall.id then
						table.remove(calls, i)
						break
					end
				end
				radioClientE:FireAllClients("updateCalls", calls)
			end)

			emergencyStates[player] = nil
			lastCallTimes[player] = tick()
		end
	end
end

-- < Jobs App > --
local function teamChange(player: Player, teamToChange: Team)
	local wantedChange = true
	local wanted = false
	if mdtSystem then
		local wantedV = find(player, "mdt/wanted")
		local mdtConfig = require(find(mdtSystem, "Config"))
		wantedChange = mdtConfig.systemConfig.wanted.canChangeTeam
		wanted = wantedV.Value
	end

	if not wantedChange and wanted then
		notificationEvent(player, "client", "Failed to change team", "You cannot change teams while being wanted.", 3, "error")
		return false
	end
	local playerTeam = player.Team
	local teamSring = teamToChange.Name
	local teamConfig = appsConfig.jobs.teams[teamSring]

	if not teamConfig then
		notificationEvent(player, "client", "Failed to change team", "Team configuration not found.", 3, "error")
		return false
	end

	if not teamToChange then
		notificationEvent(player, "client", "Failed to change team", "Team not found.", 3, "error")
		return false
	end

	if playerTeam == teamToChange then
		notificationEvent(player, "client", "Failed to change team", "You are already in this team.", 3, "error")
		return false
	end

	local permissions = teamConfig.permissions

	if permissions.gamepass.enabled then
		local requiredGamepassId = permissions.gamepass.id
		if requiredGamepassId then
			local success, ownsGamepass = pcall(marketplaceService.UserOwnsGamePassAsync, marketplaceService, player.UserId, requiredGamepassId)
			if success and not ownsGamepass then
				notificationEvent(player, "client", "Failed to change team", "You do not own the required gamepass.", 3, "error")
				return false
			elseif not success then
				warn("URBAN STUDIOS - Phone System Error: Error checking gamepass ownership for player:", player.UserId)
			end
		else
			warn("URBAN STUDIOS -Phone System Warning: Gamepass ID not specified for team:", teamSring)
		end
	end

	if permissions.group.enabled then
		local requiredGroupId = permissions.group.id
		local minRank = permissions.group.minRank or 0
		if requiredGroupId then
			if not player:IsInGroup(requiredGroupId) or player:GetRankInGroup(requiredGroupId) < minRank then
				notificationEvent(player, "client", "Failed to change team", "You do not have the required group rank.", 3, "error")
				return false
			end
		else
			warn("URBAN STUDIOS - Phone System Warning: Group ID not specified for team:", teamSring)
		end
	end

	if permissions.limit.enabled then
		local maxCapacity = permissions.limit.capacity
		if maxCapacity then
			local currentPlayersInTeam = #teamToChange:GetPlayers()
			if currentPlayersInTeam >= maxCapacity then
				notificationEvent(player, "client", "Failed to change team", "The team has reached maximum capacity.", 3, "error")
				return false
			end
		else
			warn("URBAN STUDIOS - Phone System Warning: Max capacity not specified for team:", teamSring)
		end
	end

	player.Team = teamToChange
	player:LoadCharacter()
end

-- < Bank App > --
local lastTransactionTimes = {}
local transactionHistory = {}

local function safeNumber(str)
	local cleaned = tostring(str):gsub("[^%d%.%-]", "")
	return tonumber(cleaned)
end

local function transactionsRemoval(player: Player)
	transactionHistory[player.UserId] = nil
end

local function transactionsLimit(transactions)
	while #transactions > 10 do
		table.remove(transactions, 1)
	end
end

local function bankFunctions(player: Player, action: string, amount: string, target: Player)
	if not player or not action then
		return {false, "nil", "nil"}
	end

	amount = safeNumber(amount)
	if not amount or amount <= 0 then
		notificationEvent(player, `client`, `Bank Alert`, `Invalid or unspecified amount.`, 3, `error`)
		return false
	end

	local bankSettings = appsConfig.bank
	local economyData = getPlayerEconomy(player)
	local currencySymbol = economyConfig.currencySymbol

	local tabName = action:sub(1,1):upper() .. action:sub(2)
	local tabCfg  = bankSettings.tabs[tabName]

	local uid = player.UserId

	if not tabCfg or not tabCfg.enabled then
		notificationEvent(player, `client`, `Bank Alert`, `{tabName} is disabled.`, 3, `error`)
		return false
	end

	if tabCfg.limits.enabled and amount > tabCfg.limits.maxAmount then
		local maxAmount = addComma(tabCfg.limits.maxAmount)
		notificationEvent(
			player,
			"client", 
			"Bank Alert", 
			`Maximum {action} amount is {currencySymbol}{maxAmount}.`,
			3,
			"warning"
		)
		return false
	end

	if tabCfg.cooldown.enabled then
		lastTransactionTimes[uid] = lastTransactionTimes[uid] or {}
		local playerTimes = lastTransactionTimes[uid]
		local lastTime    = playerTimes[action]
		local cdSeconds   = tabCfg.cooldown.time * 60
		local now         = os.time()

		if lastTime and (now - lastTime) < cdSeconds then
			local remaining = cdSeconds - (now - lastTime)
			notificationEvent(
				player,
				"client", 
				"Bank Alert", 
				`Wait {remaining}s before next {action}.`,
				3,
				"warning"
			)
			return false
		end

		playerTimes[action] = now
	end

	if economyData then
		transactionHistory[uid] = transactionHistory[uid] or {}
		local wallet = economyData.wallet
		local bank = economyData.bank

		if action == "deposit" then
			if amount <= wallet.Value then
				local formatted = `{currencySymbol}{addComma(amount)}` 
				local transactions = transactionHistory[uid]

				bank.Value += amount
				wallet.Value -= amount

				table.insert(transactionHistory[uid], {
					action = tabName,
					amount = `+ {formatted}`,
					time = os.time(),
				})
				transactionsLimit(transactions)
				phoneClientE:FireClient(player, "bankTransactionsUpdater", transactions)
				notificationEvent(player, `client`, `Deposit completed`, `You have deposited {formatted}.`, 3, `success`)
				return true
			else
				notificationEvent(player, `client`, `Bank Alert`, `Insufficient funds in wallet.`, 3, `warning`)
				return false
			end

		elseif action == "withdraw" then
			if amount <= bank.Value then
				local formatted = `{currencySymbol}{addComma(amount)}`
				local transactions = transactionHistory[uid]

				wallet.Value += amount
				bank.Value -= amount

				table.insert(transactions, {
					action = tabName,
					amount = `- {formatted}`,
					time = os.time(),
				})
				transactionsLimit(transactions)
				phoneClientE:FireClient(player, "bankTransactionsUpdater", transactions)
				notificationEvent(player, `client`, `Withdraw completed`, `You have withdrawn {formatted}.`, 3, `success`)
				return true
			else
				notificationEvent(player, `client`, `Bank Alert`, `Insufficient funds in bank.`, 3, `warning`)
				return false
			end

		elseif action == "transfer" then
			if not target or not target.Name then
				notificationEvent(player, `client`, `Bank Alert`, `Recipient not specified.`, 3, `error`)
				return false
			end

			local playersService = useService("Players")
			local targetInstance = find(playersService, target.Name)
			if not targetInstance then
				notificationEvent(player, `client`, `Bank Alert`, `Recipient not found.`, 3, `error`)
				return false
			end

			if targetInstance == player then
				notificationEvent(player, `client`, `Bank Alert`, `Cannot transfer to your own account.`, 3, `error`)
				return false
			end

			if amount <= bank.Value then
				local economyTargetData = getPlayerEconomy(targetInstance)
				if economyTargetData then
					local formatted = `{currencySymbol}{addComma(amount)}`
					local transactions = transactionHistory[uid]
					local targetBank = economyTargetData.bank

					targetBank.Value += amount
					bank.Value -= amount

					table.insert(transactionHistory[uid], {
						action = `{tabName} to {targetInstance.Name}`,
						amount = `- {formatted}`,
						time = os.time(),
					})
					transactionsLimit(transactions)
					phoneClientE:FireClient(player, "bankTransactionsUpdater", transactions)
					notificationEvent(player, `client`, `Transfer completed`, `You have transferred {currencySymbol}{addComma(amount)} to {targetInstance.Name}.`, 3, `success`)
					return true
				else
					return false
				end
			else
				notificationEvent(player, `client`, `Bank Alert`, `Insufficient funds in bank.`, 3, `warning`)
				return false
			end

		else
			notificationEvent(player, `client`, `Bank Alert`, `Invalid action.`, 3, `error`)
			return false
		end
	else
		return false
	end
end

-- || FRAMEWORK FUNCTIONS || --

function main.initialize(_framework, system)
	find = _framework.find
	addComma = _framework.addComma
	getLibrary = _framework.getLibrary
	useService = _framework.useService
	replicateUI = _framework.replicateUI
	getPlayerEconomy = _framework.getPlayerEconomy
	notificationEvent = _framework.notificationEvent
	getSystemCompatibility = _framework.getSystemCompatibility

	overheadSystem = getSystemCompatibility("Advanced Overhead System")
	mdtSystem = getSystemCompatibility("Advanced MDT/CAD System")

	framework			= _framework
	config				= require(system.Config)
	economyConfig		= config.economyConfig
	systemConfig		= config.systemConfig

	quickRadioConfig	= systemConfig.quickRadio
	radioConfig			= systemConfig.radio
	phoneConfig			= systemConfig.phone
	appsConfig			= phoneConfig.apps

	locationsFolder = find(workspace, "locationsF", true):: Folder
	locationParts = locationsFolder:GetChildren()

	systemGuis = system.Guis
	systemAssets = system.Assets
	systemEvents = system.Events
	systemFunctions = system.Functions

	sounds = find(systemAssets, "Sounds"):: Folder
	phoneSounds = find(sounds, "phone"):: Folder
	radioSounds = find(sounds, "radio"):: Folder

	marketplaceService	= useService("MarketplaceService"):: MarketplaceService
	players				= useService("Players"):: Players
	teamService			= useService("Teams"):: Teams

	textFiltering		= getLibrary("textFiltering")

	players.PlayerAdded:Connect(function(player)
		setupTeamChangeListener(player)

		player.CharacterAdded:Connect(function(character)
			repeat wait() until player.Team
			onCharacterAdded(player)
		end)
	end)

	players.PlayerRemoving:Connect(function(player)
		leaveSquad(player)
		chatRemoval(player)
		callsignRemoval(player)
		transactionsRemoval(player)
	end)

	if radioConfig.sounds.enabled then
		for _, snd in ipairs(radioSounds:GetChildren()) do
			if snd:IsA("Sound") then
				local id = radioConfig.sounds[snd.Name]
				if id then
					snd.SoundId = `rbxassetid://{id}`
				end
			end
		end
	end

	if phoneConfig.sounds.enabled then
		for _, snd in ipairs(phoneSounds:GetChildren()) do
			if snd:IsA("Sound") then
				local id = phoneConfig.sounds[snd.Name]
				if id then
					snd.SoundId = `rbxassetid://{id}`
				end
			end
		end
	end
end

function main.initiate(framework, system)
	radioServerF = find(systemFunctions, "radioServer"):: RemoteFunction
	radioClientE = find(systemEvents, "radioClient"):: RemoteEvent
	radioVCE = find(systemEvents, "radioVC"):: RemoteEvent

	phoneServerF = find(systemFunctions, "phoneServer"):: RemoteFunction
	phoneClientE = find(systemEvents, "phoneClient"):: RemoteEvent

	radioServerF.OnServerInvoke = function(...)
		local inputs = {...}
		local player = inputs[1]
		local action = inputs[2]

		if action == "newCallsign" then
			local newCallsign = inputs[3]
			return callsignCreation(player, newCallsign)
		elseif action == "getMessages" then
			local frequency = inputs[3]
			return getOrCreateChannelLog(frequency)
		elseif action == "getAccessibleChannels" then
			return getAccessibleChannelsFor(player)
		elseif action == "newSquad" then
			local newSquadCallsign = inputs[3]
			return squadCreation(player, newSquadCallsign)
		elseif action == "removeSquad" then
			return squadRemoval(player)
		elseif action == "getSquadInfoForTeam" then
			local playersList = inputs[3]
			return getSquadInfoForTeam(playersList)
		elseif action == "getSquad" then
			local player = inputs[3]
			return getSquadFromPlayer(player)
		end
	end

	radioClientE.OnServerEvent:Connect(function(...)
		local inputs = {...}
		local player = inputs[1]
		local action = inputs[2]

		if action == "statusUpdate" then
			local newStatus = inputs[3]
			updateStatus(player, newStatus)
		elseif action == "squadUpdate" then
			getSquads(player)
		elseif action == "callsUpdate" then
			getCalls(player)
		elseif action == "newMessage" then
			local message = inputs[3]
			local frequency = inputs[4]
			local msgType = inputs[5]
			local includeLoc = inputs[6]
			radioMessageHandler(player, message, frequency, msgType, includeLoc)
		elseif action == "squadAdmin" then
			local action = inputs[3]
			local target = inputs[4]
			squadAdmin(player, action, target)
		elseif action == "invitationResult" then
			local decision = inputs[3]
			squadInvitation(decision, player)
		elseif action == "leaveSquad" then
			leaveSquad(player)
		end
	end)

	phoneServerF.OnServerInvoke = function(...)
		local inputs = {...}
		local player = inputs[1]
		local action = inputs[2]

		if action == "getChatLogs" then
			local contact = inputs[3]
			return getChatLogs(player, contact)
		elseif action == "bank" then
			local action = inputs[3]
			local amount = inputs[4]
			local target = inputs[5]
			return bankFunctions(player, action, amount, target)
		end
	end

	phoneClientE.OnServerEvent:Connect(function(...)
		local inputs = {...}
		local player = inputs[1]
		local action = inputs[2]

		if action == "newMessage" then
			local contact = inputs[3]
			local message = inputs[4]
			phoneMessageHandler(player, contact, message)
		elseif action == "emergencyCall" then
			local action = inputs[3]
			local message = inputs[4]
			emergencyCallHandler(player, action, message)
		elseif action == "teamChange" then
			local team = inputs[3]
			teamChange(player, team)
		end
	end)
end

return main
