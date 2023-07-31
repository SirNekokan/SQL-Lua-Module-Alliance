local storedGuilds = {}
local availableGuilds = {}
local guildHistoryLimit = 100
function getGuildIdByName(name)
	local guildId
	
	local resultGuild = db.storeQuery("SELECT `id` FROM `guilds` WHERE `name` = " .. db.escapeString(name))
	if resultGuild == false then
		return false
	end
		
	guildId = result.getNumber(resultGuild, "id")
	result.free(resultGuild)
		
	return guildId
end

function refreshGuildInfo(guildId, forceRefresh)
		if not storedGuilds[guildId] then
			storedGuilds[guildId] = {}
		end
		
		local resultGuild = db.storeQuery("SELECT `name`, `ownerid`, `creationdata`, `motd`, `wins`, `join_level`, `members`, `paid`, `open`, `password` FROM `guilds` WHERE `id` = " .. guildId)
		if resultGuild ~= false then
			storedGuilds[guildId].wins = result.getNumber(resultGuild, "wins")
			storedGuilds[guildId].id = guildId
			storedGuilds[guildId].ownerId = result.getNumber(resultGuild, "ownerid")
			storedGuilds[guildId].name = result.getString(resultGuild, "name")
			storedGuilds[guildId].creationData = result.getNumber(resultGuild, "creationdata")
			storedGuilds[guildId].slogan = result.getString(resultGuild, "motd")
			storedGuilds[guildId].joinMembers = result.getNumber(resultGuild, "members") --
			storedGuilds[guildId].joinLevel = result.getNumber(resultGuild, "join_level") --
			storedGuilds[guildId].paid = result.getNumber(resultGuild, "paid") --
			storedGuilds[guildId].open = result.getNumber(resultGuild, "open") --
			storedGuilds[guildId].password = result.getString(resultGuild, "password") or "" --
			storedGuilds[guildId].joinType = storedGuilds[guildId].open > 0 and "Open" or storedGuilds[guildId].paid > 0 and "Paid" or storedGuilds[guildId].password ~= "" and "Password" or "Request"
		end
		result.free(resultGuild)
end

function refreshGuildRanks(guildId, forceRefresh)
		if not storedGuilds[guildId] then
			storedGuilds[guildId] = {}
		end
		
		local ranks = {}
		local resultRanks = db.storeQuery("SELECT `id`, `name`, `level` FROM `guild_ranks` WHERE `guild_id` = " .. guildId)
		if resultRanks ~= false then
			repeat
				local rankInfo = {}
				rankInfo.id = result.getNumber(resultRanks, "id")
				rankInfo.level = result.getNumber(resultRanks, "level")
				rankInfo.name = result.getString(resultRanks, "name")
				ranks[rankInfo.level] = rankInfo
			until not result.next(resultRanks)
		end
		result.free(resultRanks)
		storedGuilds[guildId].ranks = ranks
	end
	
function refreshGuildHistory(guildId, forceRefresh)
		if not storedGuilds[guildId] then
			storedGuilds[guildId] = {}
		end
		
		local history = {}
		local resultHistory = db.storeQuery("SELECT `description`, `date` FROM `guild_history` WHERE `guild_id` = " .. guildId .." ORDER BY `date` DESC LIMIT "..guildHistoryLimit)
		if resultHistory ~= false then
			repeat
				local historyLabel = {}
				historyLabel.date = result.getNumber(resultHistory, "date")
				historyLabel.description = result.getString(resultHistory, "description")
				table.insert(history, historyLabel)
			until not result.next(resultHistory)
		end
		result.free(resultHistory)
		storedGuilds[guildId].history = history
	end
	
function refreshGuildDepot(guildId, forceRefresh)
		if not storedGuilds[guildId] then
			storedGuilds[guildId] = {}
		end
		
		local depot = {}
		local resultDepot = db.storeQuery("SELECT `itemtype`, `count` FROM `guild_depot` WHERE `guild_id` = " .. guildId )
		if resultDepot ~= false then
			repeat
				local depotLabel = {}
				depotLabel.itemtype = result.getNumber(resultDepot, "itemtype")
				depotLabel.count = result.getNumber(resultDepot, "count")
				depotLabel.clientId = ItemType(depotLabel.itemtype):getClientId()
				table.insert(depot, depotLabel)
			until not result.next(resultDepot)
		end
		result.free(resultDepot)
		storedGuilds[guildId].depot = depot
	end
	
function refreshGuildInvites(guildId, forceRefresh)
		if not storedGuilds[guildId] then
			storedGuilds[guildId] = {}
		end
		
		local invites = {}
		local resultInvitations = db.storeQuery("SELECT `player_id`, `requested` FROM `guild_invites` WHERE `guild_id` = " .. guildId)
		if resultInvitations ~= false then
			repeat
				local memberInfo = {}
				memberInfo.id = result.getNumber(resultInvitations, "player_id")
				
				if result.getNumber(resultInvitations, "requested") == 0 then
					memberInfo.status = "Invited"
				else
					memberInfo.status = "Requested"
				end
				
				local resultPlayerInfo = db.storeQuery("SELECT `name` FROM `players` WHERE `id` = " .. memberInfo.id)
				if resultPlayerInfo ~= false then
					memberInfo.name = result.getString(resultPlayerInfo, "name")
				end
				result.free(resultPlayerInfo)
				
				table.insert(invites,memberInfo)
			until not result.next(resultInvitations)
		end
		result.free(resultInvitations)
		
		storedGuilds[guildId].invites = invites
end
function refreshGuildMembers(guildId, forceRefresh)
		if not storedGuilds[guildId] then
			storedGuilds[guildId] = {}
		end

		local members = {}
		local resultMembers = db.storeQuery("SELECT `player_id`, `rank_id`, `nick`, `kills` FROM `guild_membership` WHERE `guild_id` = " .. guildId)
		if resultMembers ~= false then
			repeat
				local memberInfo = {}
				memberInfo.id = result.getNumber(resultMembers, "player_id")
				memberInfo.rank = result.getNumber(resultMembers, "rank_id")
				memberInfo.kills = result.getNumber(resultMembers, "kills")
				memberInfo.nick = result.getString(resultMembers, "nick")
				table.insert(members,memberInfo)
			until not result.next(resultMembers)
		end
		result.free(resultMembers)
		
		for i,child in pairs(members) do
			local resultPlayerInfo = db.storeQuery("SELECT `name` FROM `players` WHERE `id` = " .. child.id)
			if resultPlayerInfo ~= false then
				child.name = result.getString(resultPlayerInfo, "name")
				if storedGuilds[guildId].ownerId == child.id then
					storedGuilds[guildId].owner = child.name
				end
			end
			result.free(resultPlayerInfo)
			local getOnline = Player(child.name)
			if getOnline then
				child.status = "Online"
			else
				child.status = "Offline"
			end
			result.free(resultPlayerStatus)
		end
		if storedGuilds[guildId].joinMembers ~= #members then
			db.asyncQuery("UPDATE `guilds` SET `members`='".. #members .."' WHERE `id`='".. guildId .."'");
			storedGuilds[guildId].joinMembers = #members
		end
		storedGuilds[guildId].members = members
end
function refreshGuildWars(guildId, forceRefresh)
		if not storedGuilds[guildId] then
			storedGuilds[guildId] = {}
		end
		
		local wars = {}
		local resultWars = db.storeQuery("SELECT `id`, `guild1`, `guild2`, `name1`, `name2`, `status`, `started`, `ended`, `limit` FROM `guild_wars` WHERE (`guild1` = " .. guildId .. " OR `guild2` = " .. guildId .. ")" )
		if resultWars ~= false then
			repeat
				local warInfo = {}
				warInfo.id = result.getNumber(resultWars, "id")
				if guildId == result.getNumber(resultWars, "guild1") then
					warInfo.guildId = result.getNumber(resultWars, "guild1")
					warInfo.enemyId = result.getNumber(resultWars, "guild2")
					warInfo.enemyName = result.getString(resultWars, "name2")
				else
					warInfo.guildId = result.getNumber(resultWars, "guild2")
					warInfo.enemyId = result.getNumber(resultWars, "guild1")
					warInfo.enemyName = result.getString(resultWars, "name1")
				end
				warInfo.kills = 0
				warInfo.points = 0
				warInfo.inviteGuild = result.getString(resultWars, "guild1")
				warInfo.status = result.getNumber(resultWars, "status")
				warInfo.started = result.getNumber(resultWars, "started")
				warInfo.ended = result.getNumber(resultWars, "ended")
				local resultKills = db.storeQuery("SELECT COUNT('id') AS `count` FROM `guildwar_kills` WHERE `killerguild` = " .. warInfo.enemyId .." AND `warid` = ".. warInfo.id ..";")
				if resultKills ~= false then
					warInfo.kills = result.getNumber(resultKills, "count")
				end
				result.free(resultKills)
				
				local resultPoints = db.storeQuery("SELECT COUNT('id') AS `count` FROM `guildwar_kills` WHERE `killerguild` = " .. warInfo.guildId .." AND `warid` = ".. warInfo.id ..";")
				if resultPoints ~= false then
					warInfo.points = result.getNumber(resultPoints, "count")
				end
				result.free(resultPoints)
				warInfo.goal = result.getNumber(resultWars, "limit")
				table.insert(wars,warInfo)
			until not result.next(resultWars)
		end
		result.free(resultWars)
		storedGuilds[guildId].wars = wars
end

function refreshAvailableGuilds()
	availableGuilds = {}
		local resultAvailable = db.storeQuery("SELECT `id`, `name`, `motd`, `ownerid`, `wins`, `join_level`, `members`, `paid`, `open`, `password` FROM `guilds`")
		if resultAvailable ~= false then
			repeat
				local localGuild = {}		
				localGuild.id = result.getNumber(resultAvailable, "id")
				localGuild.wins = result.getNumber(resultAvailable, "wins")
				localGuild.ownerId = result.getNumber(resultAvailable, "ownerid")
				localGuild.name = result.getString(resultAvailable, "name")
				localGuild.joinMembers = result.getNumber(resultAvailable, "members") --
				localGuild.joinLevel = result.getNumber(resultAvailable, "join_level") --
				localGuild.paid = result.getNumber(resultAvailable, "paid") --
				localGuild.open = result.getNumber(resultAvailable, "open") --
				localGuild.password = result.getString(resultAvailable, "password") or "" --
				localGuild.slogan = result.getString(resultAvailable, "motd")
				local resultPlayerInfo = db.storeQuery("SELECT `name` FROM `players` WHERE `id` = " .. localGuild.ownerId)
				if resultPlayerInfo ~= false then
					localGuild.owner = result.getString(resultPlayerInfo, "name")
				end
				result.free(resultPlayerInfo)
				
				localGuild.joinType = localGuild.open > 0 and "Open" or localGuild.paid > 0 and "Paid" or localGuild.password:len() > 2 and "Password" or "Request"
				availableGuilds[localGuild.name:lower()] = localGuild
			until not result.next(resultAvailable)
		end
		result.free(resultAvailable)
end
	
function getGuildInfo(playerId, forceRefresh)
	local player = Player(playerId)
	if not player then return end
	local playerDatabaseId = player:getGuid()

	local resultMember = db.storeQuery("SELECT `guild_id` FROM `guild_membership` WHERE `player_id` = " .. playerDatabaseId)
	if resultMember == false then
	
		local invites = {}
		local resultInvitations = db.storeQuery("SELECT `guild_id`, `requested` FROM `guild_invites` WHERE `player_id` = " .. playerDatabaseId)
		if resultInvitations ~= false then
			repeat
				local joinGuildId = result.getNumber(resultInvitations, "guild_id")
				local requested = result.getNumber(resultInvitations, "requested") == 0 and "Invited" or "Requested"
				table.insert(invites, {id = joinGuildId,status = requested})
			until not result.next(resultInvitations)
		end
		result.free(resultInvitations)
		
		refreshAvailableGuilds()
		
			repetitiveSend(player, GUILD_OPCODE, "refreshJoin", {availableGuilds = availableGuilds, invites = invites})
	else
		local guildId = result.getNumber(resultMember, "guild_id")
		
		if not storedGuilds[guildId] then
			storedGuilds[guildId] = {}
		end
	
		refreshGuildInfo(guildId, forceRefresh)
		refreshGuildRanks(guildId, forceRefresh)
		refreshGuildInvites(guildId, forceRefresh)
		refreshGuildMembers(guildId, forceRefresh)
		refreshGuildWars(guildId, forceRefresh)
		refreshGuildHistory(guildId, forceRefresh)
		refreshGuildDepot(guildId, forceRefresh)
		local ownerSend = 0
		if player:getGuid() == storedGuilds[guildId].ownerId then
			storedGuilds[guildId].ownerSend = 1
		end
		
			repetitiveSend(player, GUILD_OPCODE, "refreshGuild", {guildInfo = storedGuilds[guildId], owner = ownerSend}) 
		
	end
	result.free(resultMember)


	local guildId = result.getNumber(resultId, "id")
	result.free(resultId)
	return guildId
end

storedGuildInfo = {}

depotActionSingleton = {}
local depotClientIdMap
function manageGuildDepot(player, guildId, action, clientId, count)
	if not depotClientIdMap then
		depotClientIdMap = {}
		for i = 100,20000 do
			local getItem = ItemType(i)
			if getItem and getItem:isPickupable() then
				depotClientIdMap[getItem:getClientId()] = i
			end
		end
	end
	local info = depotClientIdMap[clientId]
	if not info then
		return addEvent(sendMessageBox, 250, player:getId(), "Error", "Not founded item by client id")
	end
	
	local getItem = ItemType(info)
	if not getItem then return end
	
	if action == "addDepot" then
		if player:getItemCount(info) < count then
			addEvent(getGuildInfo, 50, player:getId(), true)
			return
		end
		player:removeItem(info, count)
		
		local resultAlreadyAdded = db.storeQuery("SELECT `count` FROM `guild_depot` WHERE `guild_id` = " .. guildId .. " AND `itemtype` = ".. info .."")
		if resultAlreadyAdded == false then	
			db.query("INSERT INTO `guild_depot` (`guild_id`, `itemtype`, `count`) VALUES ('"..guildId.."', '"..info.."', '"..count.."')")
		else
			local itemCount = result.getNumber(resultAlreadyAdded, "count") + count
			db.query("UPDATE `guild_depot` SET `count`='".. itemCount .."' WHERE `guild_id` = " .. guildId .. " AND `itemtype` = ".. info .."");
		end
		result.free(resultAlreadyAdded)
		
		addGuildHistory(guildId, player:getName().." has added "..count.." "..getItem:getName().." to depot")
		addEvent(getGuildInfo, 50, player:getId(), true)
	elseif action == "removeDepot" then
		local resultAlreadyAdded = db.storeQuery("SELECT `count` FROM `guild_depot` WHERE `guild_id` = " .. guildId .. " AND `itemtype` = ".. info .."")
		if resultAlreadyAdded == false then	
			result.free(resultAlreadyAdded)
			return
		end
		local needSlots
		if getItem:isPickupable() then
			if getItem:isStackable() then
				needSlots = math.ceil(count/100)
			else
				needSlots = count
			end
		end
		if not needSlots then return end
		
		local backpack = player:getSlotItem(CONST_SLOT_BACKPACK)
		if not backpack or backpack:getEmptySlots(true) < needSlots then
			addEvent(sendMessageBox, 250, player:getId(), "Error", "You dont have enough space in your backpack")
			addEvent(getGuildInfo, 50, player:getId(), true)
			return
		end
		
		local itemCount = result.getNumber(resultAlreadyAdded, "count")
		result.free(resultAlreadyAdded)
		if count > itemCount then
			addEvent(getGuildInfo, 50, player:getId(), true)
			return
		end
		itemCount = itemCount - count
		player:addItem(info, count)
		
		if itemCount <= 0 then
			db.query("DELETE FROM `guild_depot` WHERE `guild_id` = ".. guildId .." AND `itemtype` = ".. info .."");
		else
			db.query("UPDATE `guild_depot` SET `count`='".. itemCount .."' WHERE `guild_id` = " .. guildId .. " AND `itemtype` = ".. info .."");
		end
		
		
		addGuildHistory(guildId, player:getName().." has removed "..count.." "..getItem:getName().." from depot")
		addEvent(getGuildInfo, 50, player:getId(), true)
	end
end

function manageGuild(player, guildId, action, info, joinLevel)
	--local changeAction = "Owner"/"Join"/"Slogan"/"Leave"
	if action == "ownerGuild" then
	
		if player:getName():lower() == info:lower() then
			return addEvent(sendMessageBox, 250, player:getId(), "Error", "You are already leader of this guild")
		end
		refreshGuildMembers(guildId, true)
		refreshGuildRanks(guildId, true)
		
		local getViceRankId = storedGuilds[guildId].ranks[2].id
		local getOwnerRankId = storedGuilds[guildId].ranks[3].id
		local newOwnerId
		local newOwnerName
		for i,child in pairs(storedGuilds[guildId].members) do
			if child.name:lower() == info:lower() then 
				newOwnerId = child.id
				newOwnerName = child.name
			end
		end
		
		if not newOwnerId then
			return addEvent(sendMessageBox, 250, player:getId(), "Error", "This player is not member of your guild")
		end
		
		db.asyncQuery("UPDATE `guild_membership` SET `rank_id`='".. getViceRankId .."' WHERE `player_id`='".. player:getGuid() .."'");
		db.asyncQuery("UPDATE `guild_membership` SET `rank_id`='".. getOwnerRankId .."' WHERE `player_id`='".. newOwnerId .."'");
		db.asyncQuery("UPDATE `guilds` SET `ownerid`='".. newOwnerId .."' WHERE `id`='".. guildId .."'");
		addGuildHistory(guildId, player:getName().." has changed guild owner to "..newOwnerName)
		addEvent(getGuildInfo, 50, player:getId(), true)
	elseif action == "joinTypeGuild" then
		db.asyncQuery("UPDATE `guilds` SET `password`='".. info.password .."', `paid`='".. info.paid .."', `open`='".. info.open .."', `join_level`='".. joinLevel .."' WHERE `id`='".. guildId .."'");
		local joinName = info.open > 0 and "Open" or info.paid > 0 and "Paid" or info.password:len() > 2 and "Password" or "Request"
		addGuildHistory(guildId, player:getName().." has changed guild join type to "..joinName)
	elseif action == "sloganGuild" then
		db.asyncQuery("UPDATE `guilds` SET `motd`='".. info .."' WHERE `id`='".. guildId .."'");
		addGuildHistory(guildId, player:getName().." has changed guild slogan to "..info)
		addEvent(getGuildInfo, 50, player:getId(), true)
	elseif action == "leaveGuild" then
		refreshGuildMembers(guildId, true)
		refreshGuildRanks(guildId, true)
		
		local getOwnerRankId = storedGuilds[guildId].ranks[3].id
		local getNewOwner = false
		for i,child in pairs(storedGuilds[guildId].members) do
			if child.name:lower() == player:getName():lower() and child.rank == getOwnerRankId then 
				getNewOwner = true
			end
		end
				
		db.query("DELETE FROM `guild_membership` WHERE `player_id`='".. player:getGuid() .."' LIMIT 1;");
		
		local resultAlreadyAdded = db.storeQuery("SELECT `player_id` FROM `guild_membership` WHERE `guild_id` = " .. guildId .. " LIMIT 1;")
		if resultAlreadyAdded ~= false then	
			addGuildHistory(guildId, player:getName().." has left guild")
			if getNewOwner then
				local newOwner = result.getNumber(resultAlreadyAdded, "player_id")
				db.asyncQuery("UPDATE `guilds` SET `ownerid`='".. newOwner .."' WHERE `id`='".. guildId .."'");
			end
		else
			db.query("DELETE FROM `guilds` WHERE `id` = ".. guildId .."");
		end
		result.free(resultAlreadyAdded)
		
		addEvent(getGuildInfo, 50, player:getId(), true)
	end
end

function manageGuildInvite(player, guildId, action, actionInfo)
	--local action = "send"/"accept"/"decline"/"request"
	--local joinType = "password"/"paid"/"open"/"request"
	
	refreshGuildInfo(guildId, true)
	local joinType = storedGuilds[guildId].joinType
	local joinLevel = storedGuilds[guildId].joinLevel
	
	if action == "requestInvite" then
			if player:getLevel() < joinLevel then
				return addEvent(sendMessageBox, 250, player:getId(), "Error", "Your level is too low")
			end
		if joinType == "Open" then
			
			db.asyncQuery("DELETE FROM `guild_invites` WHERE `player_id`='".. player:getGuid() .."' AND `guild_id`='".. guildId .."' LIMIT 1;");
			refreshGuildRanks(guildId, true)
			local storedRankId = storedGuilds[guildId].ranks[1].id
			db.asyncQuery("INSERT INTO `guild_membership` (`player_id`, `guild_id`, `rank_id`, `nick`) VALUES ('"..player:getGuid().."', '"..guildId.."', '"..storedRankId.."', '')")
			addGuildHistory(guildId, player:getName().." has joined guild")
			addEvent(getGuildInfo, 50, player:getId(), true)
		elseif joinType == "Paid" then
			if not player:removeTotalMoney(storedGuilds[guildId].paid) then
			return addEvent(sendMessageBox, 250, player:getId(), "Error", "Not enough money")
			end
			db.asyncQuery("DELETE FROM `guild_invites` WHERE `player_id`='".. player:getGuid() .."' AND `guild_id`='".. guildId .."' LIMIT 1;");
			refreshGuildRanks(guildId, true)
			local storedRankId = storedGuilds[guildId].ranks[1].id
			db.asyncQuery("INSERT INTO `guild_membership` (`player_id`, `guild_id`, `rank_id`, `nick`) VALUES ('"..player:getGuid().."', '"..guildId.."', '"..storedRankId.."', '')")
			addGuildHistory(guildId, player:getName().." has paid "..storedGuilds[guildId].paid.." to join guild")
			addEvent(getGuildInfo, 50, player:getId(), true)
		elseif joinType == "Password" then
			if storedGuilds[guildId].password ~= actionInfo then
			return addEvent(sendMessageBox, 250, player:getId(), "Error", "Wrong password")
			end
			db.asyncQuery("DELETE FROM `guild_invites` WHERE `player_id`='".. player:getGuid() .."' AND `guild_id`='".. guildId .."' LIMIT 1;");
			refreshGuildRanks(guildId, true)
			local storedRankId = storedGuilds[guildId].ranks[1].id
			db.asyncQuery("INSERT INTO `guild_membership` (`player_id`, `guild_id`, `rank_id`, `nick`) VALUES ('"..player:getGuid().."', '"..guildId.."', '"..storedRankId.."', '')")
			addGuildHistory(guildId, player:getName().." used password to join guild")
			addEvent(getGuildInfo, 50, player:getId(), true)
		elseif joinType == "Request" then
			refreshGuildInvites(guildId, true)
			local alreadyInvited
			for i, child in pairs(storedGuilds[guildId].invites) do
				if child.id == player:getGuid() then
					alreadyInvited = child.status
				end
			end
			
			if not alreadyInvited then
				db.asyncQuery("INSERT INTO `guild_invites` (`player_id`, `guild_id`, `requested`) VALUES ('"..player:getGuid().."', '"..guildId.."', '1')")
			addGuildHistory(guildId, player:getName().." has requested to join guild")
				addEvent(getGuildInfo, 50, player:getId(), true)
				return 
			end
			
			if alreadyInvited == "Requested" then
			return addEvent(sendMessageBox, 250, player:getId(), "Error", "You already requested to join this guild")
			end
			
			if alreadyInvited == "Invited" then
				db.asyncQuery("DELETE FROM `guild_invites` WHERE `player_id`='".. player:getGuid() .."' AND `guild_id`='".. guildId .."' LIMIT 1;");
				refreshGuildRanks(guildId, true)
				local storedRankId = storedGuilds[guildId].ranks[1].id
				db.asyncQuery("INSERT INTO `guild_membership` (`player_id`, `guild_id`, `rank_id`, `nick`) VALUES ('"..player:getGuid().."', '"..guildId.."', '"..storedRankId.."', '')")
				addGuildHistory(guildId, player:getName().." has accepted invite to join guild")
				addEvent(getGuildInfo, 50, player:getId(), true)
			end
		end
	elseif action == "acceptInvite" then
						
			local resultGuildFinded = db.storeQuery("SELECT `guild_id` FROM `guild_membership` WHERE `player_id` = " .. actionInfo)
			if resultGuildFinded ~= false then
				result.free(resultGuildFinded)
				return addEvent(sendMessageBox, 250, player:getId(), "Error", "This player is already in guild")
			end
			result.free(resultGuildFinded)
		
			local invitedPlayer
			local invitedName
			refreshGuildInvites(guildId, true)
			for i, child in pairs(storedGuilds[guildId].invites) do
				if child.id == actionInfo then
					invitedPlayer = child.status
					invitedName = child.name
				end
			end
			
			if not invitedPlayer then
				return addEvent(sendMessageBox, 250, player:getId(), "Error", "Not finded invitation")
			end
			
			if invitedPlayer == "Invited" then
				return addEvent(sendMessageBox, 250, player:getId(), "Error", "Wrong invitation status")
			end
			
			db.asyncQuery("DELETE FROM `guild_invites` WHERE `player_id`='".. actionInfo .."' AND `guild_id`='".. guildId .."' LIMIT 1;");
			refreshGuildRanks(guildId, true)
			local storedRankId = storedGuilds[guildId].ranks[1].id
			db.asyncQuery("INSERT INTO `guild_membership` (`player_id`, `guild_id`, `rank_id`, `nick`) VALUES ('".. actionInfo .."', '".. guildId .."', '".. storedRankId .."', '');")
			addGuildHistory(guildId, player:getName().." has accepted request from ".. invitedName .." to join guild")
			addEvent(getGuildInfo, 50, player:getId(), true)
			
	elseif action == "declineInvite" then
						
			--local resultGuildFinded = db.storeQuery("SELECT `guild_id` FROM `guild_membership` WHERE `player_id` = " .. actionInfo)
			--if resultGuildFinded ~= false then
			--	result.free(resultGuildFinded)
			--	return addEvent(sendMessageBox, 250, player:getId(), "Error", "This player is already in guild")
			--end
			--result.free(resultGuildFinded)
		
			local invitedPlayer
			local invitedName
			refreshGuildInvites(guildId, true)
			for i, child in pairs(storedGuilds[guildId].invites) do
				if child.id == actionInfo then
					invitedPlayer = child.status
					invitedName = child.name
				end
			end
			
			if not invitedPlayer then
				return addEvent(sendMessageBox, 250, player:getId(), "Error", "Not finded invitation")
			end
			
			--if invitedPlayer == "Invited" then
			--	return print("errorbox: Wrong invitation status") 
			--end
			
			db.asyncQuery("DELETE FROM `guild_invites` WHERE `player_id`='".. actionInfo .."' AND `guild_id`='".. guildId .."' LIMIT 1;");
			addGuildHistory(guildId, player:getName().." has declined request from ".. invitedName .." to join guild")
			addEvent(getGuildInfo, 50, player:getId(), true)
	
	elseif action == "kickPlayer" then
						
			--local resultGuildFinded = db.storeQuery("SELECT `guild_id` FROM `guild_membership` WHERE `player_id` = " .. actionInfo)
			--if resultGuildFinded ~= false then
			--	result.free(resultGuildFinded)
			--	return addEvent(sendMessageBox, 250, player:getId(), "Error", "This player is already in guild")
			--end
			--result.free(resultGuildFinded)
			if actionInfo == player:getGuid() then
				return addEvent(sendMessageBox, 250, player:getId(), "Error", "You cant kick yourself from guild")
			end
			refreshGuildMembers(guildId, true)
			
			local playerName
			for i,child in pairs(storedGuilds[guildId].members) do
				if child.id == actionInfo then 
					playerName = child.name
				end
			end
			
			if not playerName then
				return addEvent(sendMessageBox, 250, player:getId(), "Error", "This player is not member of your guild")
			end
			
			db.asyncQuery("DELETE FROM `guild_membership` WHERE `player_id`='".. actionInfo .."' AND `guild_id`='".. guildId .."' LIMIT 1;");
			addGuildHistory(guildId, player:getName().." has kicked "..playerName.." from guild")
			addEvent(getGuildInfo, 50, player:getId(), true)
	
	elseif action == "sendInvite" then
			local resultPlayerInfo = db.storeQuery("SELECT `id`, `level` FROM `players` WHERE `name` = " .. db.escapeString(actionInfo))
			if resultPlayerInfo == false then
				result.free(resultPlayerInfo)
				return addEvent(sendMessageBox, 250, player:getId(), "Error", "Not finded player with this name")
			end
			
			if result.getNumber(resultPlayerInfo, "level") < storedGuilds[guildId].joinLevel then
				return addEvent(sendMessageBox, 250, player:getId(), "Error", "This player level is too low")
			end
	
			local invitePlayerId = result.getNumber(resultPlayerInfo, "id")
			result.free(resultPlayerInfo)
						
			local resultGuildFinded = db.storeQuery("SELECT `guild_id` FROM `guild_membership` WHERE `player_id` = " .. invitePlayerId)
			if resultGuildFinded ~= false then
				result.free(resultGuildFinded)
				return addEvent(sendMessageBox, 250, player:getId(), "Error", "This player is already in guild")
			end
			result.free(resultGuildFinded)
			
		db.asyncQuery("INSERT INTO `guild_invites` (`player_id`, `guild_id`, `requested`) VALUES ('"..invitePlayerId.."', '"..guildId.."', '0')")
		addGuildHistory(guildId, player:getName().." has sended ".. actionInfo .." invite to join guild")
		addEvent(getGuildInfo, 50, player:getId(), true)
	end
end
function sendMessageBox(playerId,title,message)
	local getPlayer = Player(playerId)
	if getPlayer then
		repetitiveSend(getPlayer, GUILD_OPCODE, "messageBox", {title = title, message = message})
	end
end
function manageGuildWar(player, guildId, action, actionInfo, finishKills)
	--local joinType = "invite"/"accept"/"decline"/"progress"
	
	if action == "inviteWar" then
		refreshAvailableGuilds()
		local getEnemy = availableGuilds[actionInfo:lower()]
		if not getEnemy then
			return addEvent(sendMessageBox, 250, player:getId(), "Error", "There is no guild with this name")
		end
		
		local getEnemyId = getEnemy.id
		local getEnemyName = getEnemy.name
		local getGuildName = storedGuilds[guildId].name
		db.asyncQuery("INSERT INTO `guild_wars` (`guild1`, `guild2`, `name1`, `name2`, `status`, `started`, `ended`, `limit`) VALUES ('".. guildId .."', '".. getEnemyId .."', '".. getGuildName .."', '".. getEnemyName .."', '0', '".. os.time() .."', '0', '"..finishKills.."');")
		addGuildHistory(guildId, player:getName().." has invited ".. getEnemyName .." to start war")
		addEvent(getGuildInfo, 50, player:getId(), true)
	elseif action == "acceptWar" then
		db.asyncQuery("UPDATE `guild_wars` SET `status` = 1 WHERE `id` = '".. actionInfo.id .."';")
		addGuildHistory(guildId, player:getName().." has accepted war with ".. actionInfo.name .."")
		addEvent(getGuildInfo, 50, player:getId(), true)
	elseif action == "declineWar" then
		db.asyncQuery("DELETE FROM `guild_wars` WHERE `id`='".. actionInfo.id .."' LIMIT 1;")
		addGuildHistory(guildId, player:getName().." has declined war invitiation from ".. actionInfo.name .."")
		addEvent(getGuildInfo, 50, player:getId(), true)
	elseif action == "progressWar" then
	end
end

function manageGuildRank(player, guildId, action, actionInfo, rankLevel)
		-- Find rank id for regular member in this guild
		--$guildrank = mysql_select_single("SELECT `id` FROM `guild_ranks` WHERE `guild_id`='$gid' AND `level`='1' LIMIT 1;");
	--local joinType = "Add"/"Remove"/"Name"/"Access"
	if action == "nameRank" then
		db.asyncQuery("UPDATE `guild_ranks` SET `name`=".. db.escapeString(actionInfo) .." WHERE `guild_id`='".. guildId .."' AND `level`='".. rankLevel .."'");
		addGuildHistory(guildId, player:getName().." has changed name for ".. rankLevel .." access rank with ".. actionInfo)
		addEvent(getGuildInfo, 50, player:getId(), true)
	elseif action == "changeRank" then
		if rankLevel == 3 then
			return manageGuild(player, guildId, "ownerGuild", actionInfo)
		end
		refreshGuildMembers(guildId, true)
		refreshGuildRanks(guildId, true)
		
		local newRank = storedGuilds[guildId].ranks[rankLevel].id
		local newRankId
		local newRankName
		for i,child in pairs(storedGuilds[guildId].members) do
			if child.name:lower() == actionInfo:lower() then 
				newRankId = child.rank
				newRankName = child.name
				playerId = child.id
			end
		end
		
		if not newRankId then
			return addEvent(sendMessageBox, 250, player:getId(), "Error", "This player is not member of your guild")
		end
		
		if newRankId == newRank then
			return addEvent(sendMessageBox, 250, player:getId(), "Error", "This player already have this rank")
		end
		
		db.asyncQuery("UPDATE `guild_membership` SET `rank_id`='".. newRank .."' WHERE `player_id`='".. playerId .."'");
		addGuildHistory(guildId, player:getName().." has changed "..newRankName.." rank to "..storedGuilds[guildId].ranks[rankLevel].name)
		addEvent(getGuildInfo, 50, player:getId(), true)
	end
end

function createGuild(player, name, slogan, joinType, joinLevel)
	local guildCheck = getGuildIdByName(name)
	if guildCheck and guildCheck > 0 then
		return addEvent(sendMessageBox, 250, player:getId(), "Error", "This guild name is already taken")
	end
	
	local resultGuild = db.storeQuery("SELECT `id`, `name` FROM `guilds` WHERE `ownerid` = " .. player:getGuid())
	if resultGuild ~= false then
		return addEvent(sendMessageBox, 250, player:getId(), "Error", "You are already owner of ".. name .." guild")
	end
	
	if player:getLevel() < joinLevel then
		return addEvent(sendMessageBox, 250, player:getId(), "Error", "Your level is too low")
	end
	
	
	db.query("INSERT INTO `guilds` (`name`, `ownerid`, `creationdata`, `motd`, `join_level`, `members`, `open`, `password`, `paid`) VALUES (".. db.escapeString(name) ..", '".. player:getGuid() .."', '".. os.time() .."', ".. db.escapeString(slogan) ..", '".. joinLevel .."', '1', '".. joinType.open .."', ".. db.escapeString(joinType.password) ..", '".. joinType.paid .."');")
	local guildId = getGuildIdByName(name)
	if not guildId then
		return addEvent(sendMessageBox, 250, player:getId(), "Error", "Not finded guild id after creation")
	end
	
	--db.asyncQuery("INSERT INTO `guild_ranks` (`guild_id`, `name`, `level`) VALUES ('".. guildId .."', 'a Member', '1');");
	--db.asyncQuery("INSERT INTO `guild_ranks` (`guild_id`, `name`, `level`) VALUES ('".. guildId .."', 'a Vice-Leader', '2');");
	--db.asyncQuery("INSERT INTO `guild_ranks` (`guild_id`, `name`, `level`) VALUES ('".. guildId .."', 'the Leader', '3');");
	
	refreshGuildRanks(guildId, true)
	local storedRankId = storedGuilds[guildId].ranks[3].id
	db.asyncQuery("INSERT INTO `guild_membership` (`player_id`, `guild_id`, `rank_id`, `nick`) VALUES ('".. player:getGuid() .."', '".. guildId .."', '".. storedRankId .."', '');");
	addGuildHistory(guildId, "Created guild by ".. player:getName())
	addEvent(getGuildInfo, 50, player:getId(), true)
end

function addGuildHistory(guildId, description)
	db.asyncQuery("INSERT INTO `guild_history` (`guild_id`, `description`, `date`) VALUES ('".. guildId .."', '".. description .."', '".. os.time() .."');");
end

function sendJSONEvent(playerId, opcode, action, data)
	local getPlayer = Player(playerId)
	if not getPlayer then return end
	
	local msg = NetworkMessage()
	msg:addByte(50)
	msg:addByte(opcode)
	msg:addString(json.encode({action = action, data = data}))
	msg:sendToPlayer(getPlayer)
end
function repetitiveSend(player,opcode,action,data)
	local getBuffer = json.encode(data)
	local lastGroup = math.ceil(string.len(getBuffer)/5000)
	local actualI=0
	for i = 1,lastGroup do
		local sendData = string.sub(getBuffer, ((i-1)*5000)+1, i*5000)
		local sendFirst = "false"
		local sendLast = "false"
		actualI = (actualI+1)
		if i == lastGroup then
			sendLast = "true"
		end
		if i == 1 then
			sendFirst = "true"
		end
        addEvent(sendJSONEvent,(actualI*60), player:getId(), opcode, action, {opcodeDataFirst = sendFirst,opcodeDataLast = sendLast,opcodeData = sendData} )
	end
end

GUILD_OPCODE = 150
local guildOpcode = CreatureEvent("guildOpcode")
function guildOpcode.onExtendedOpcode(player, opcode, buffer)
    local status, json_data = pcall(function()
        return json.decode(buffer)
    end)
    if not status then
        return false
    end
    local action = json_data['action']
    local data = json_data['data']
    if opcode == GUILD_OPCODE then
		if action == "openWindow" then
			addEvent(getGuildInfo, 50, player:getId(), true)
		elseif action == "createGuild" then
			createGuild(player, data['name'], data['slogan'], data['joinType'], data['joinLevel'])
		elseif action == "requestInvite" or action == "sendInvite" or action == "acceptInvite" or action == "declineInvite" or action == "kickPlayer" then
			manageGuildInvite(player, data['guildId'], action, data['actionInfo'])
		elseif action == "inviteWar" or  action == "declineWar" or  action == "acceptWar" then
			manageGuildWar(player, data['guildId'], action, data['actionInfo'], data['finishKills'])
		elseif action == "nameRank" or action == "changeRank" then --elseif action == "addRank" or  action == "removeRank" or  action == "nameRank" or  action == "accessRank" then
			manageGuildRank(player, data['guildId'], action, data['actionInfo'], data['rankLevel'])
		elseif action == "ownerGuild" or action == "joinTypeGuild" or action == "sloganGuild" or action == "leaveGuild" then
			manageGuild(player, data['guildId'], action, data['actionInfo'], data['joinLevel'])
		elseif action == "addDepot" or  action == "removeDepot" then
			manageGuildDepot(player, data['guildId'], action, data['actionType'], data['actionInfo'])
		end
    end
end
guildOpcode:register()
local guildLogin = CreatureEvent("guildLogin")
function guildLogin.onLogin(player)
    player:registerEvent("guildOpcode")
    return true
end
guildLogin:register()


