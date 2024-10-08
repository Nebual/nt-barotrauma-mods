print("Initializing Radio Broadcast")

local BROADCAST_CHANNEL = 9

Hook.Patch('RadioBroadcastOverride', 'Barotrauma.Items.Components.WifiComponent', 'CanReceive', function (instance, ptable)
	local sender = ptable['sender']
	local recipient = instance
	if not SERVER then
		-- vanilla bug: clientside in VoipClient.cs, this is called as `senderRadio.CanReceive(recipientRadio)`,
		-- which is backwards from VoipServer.cs's call and the function signature. This cost me an hour of debugging >.> , though it doesn't actually matter since I switched to bidirectional radio
		sender = instance
		recipient = ptable['sender']
	end
	if (sender.Channel == BROADCAST_CHANNEL and recipient.Channel <= 9) or (recipient.Channel == BROADCAST_CHANNEL and sender.Channel <= 9) then
		ptable.PreventExecution = true
		return true
	end
end, Hook.HookMethodType.Before)
