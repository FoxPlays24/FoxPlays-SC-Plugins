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

void SendTeamMessage(CBasePlayer@ sender, string msg) {
    g_EngineFuncs.ServerPrint(msg);

    // Send message to all team members
    for (int i = 1; i <= g_Engine.maxClients; i++) {
    	CBasePlayer@ plr = g_PlayerFuncs.FindPlayerByIndex(i);

	if (plr is null or !plr.IsConnected() or plr.Classify() != sender.Classify())
	    continue;
	
	NetworkMessage m(MSG_ONE, NetworkMessages::SayText, plr.edict());
	    m.WriteByte(sender.entindex());
	    m.WriteByte(2);
	    m.WriteString(msg);
	m.End();
    }
}

void SendMessage(CBasePlayer@ sender, string msg) {
    g_EngineFuncs.ServerPrint(msg);

    NetworkMessage m(MSG_ALL, NetworkMessages::SayText, null);
        m.WriteByte(sender.entindex());
        m.WriteByte(2);
        m.WriteString(msg);
    m.End();
}

HookReturnCode ClientSay(SayParameters@ pParams)
{
    const string msg = pParams.GetCommand();

    // If message contain ASCII chars, don't duplicate it
    if (HasASCII(msg))
        return HOOK_CONTINUE;
    
    CBasePlayer@ plr = pParams.GetPlayer();
    ClientSayType sayType = pParams.GetSayType();
    string fMsg = string(plr.pev.netname) + ": " + msg + "\n";

    if (sayType == ClientSayType::CLIENTSAY_SAYTEAM) {
        SendTeamMessage(plr, "(TEAM) " + fMsg);
	return HOOK_CONTINUE;
    }		 
    
    SendMessage(plr, fMsg);
    return HOOK_CONTINUE;
}
