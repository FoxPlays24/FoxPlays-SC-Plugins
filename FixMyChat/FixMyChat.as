void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor("FoxPlays");
	g_Module.ScriptInfo.SetContactInfo("https://github.com/FoxPlays24");
	g_Hooks.RegisterHook(Hooks::Player::ClientSay, @ClientSay);
}

bool HasASCII(string msg)
{
	if(msg.Length() == 0) 
		return true;
		
	for (uint i = 0; i < msg.Length(); i++)
	if (uint8(msg[i]) < 0x80 && uint8(msg[i]) != 0x20)
		return true;

	return false;
}

// Got this part from "ChatSounds" plugin by wootguy (player_say func) and slightly modified it, thanks to him :)
void SendMessage(CBaseEntity@ plr, string msg, ClientSayType isTeamMsg) {
	string teamPrefix = isTeamMsg == ClientSayType::CLIENTSAY_SAYTEAM ? "(TEAM) " : "";
	
    NetworkMessage m(MSG_ALL, NetworkMessages::SayText, null);
        m.WriteByte(plr.entindex());
        m.WriteByte(2);
        m.WriteString(teamPrefix + plr.pev.netname + ": " + msg + "\n");
    m.End();

    g_Game.AlertMessage(at_logged, "\"%1<%2><%3><player>\" say \"%4\"\n", plr.pev.netname, string(g_EngineFuncs.GetPlayerUserId(plr.edict())), g_EngineFuncs.GetPlayerAuthId(plr.edict()), msg);
	g_EngineFuncs.ServerPrint(teamPrefix + plr.pev.netname + ": " + msg + "\n");
}

HookReturnCode ClientSay(SayParameters@ pParams)
{
	const string message = pParams.GetCommand();

	// If message doesn't contain ASCII chars, duplicate it
	if (!HasASCII(message))
		SendMessage(pParams.GetPlayer(), message, pParams.GetSayType());
	
	return HOOK_CONTINUE;
}
