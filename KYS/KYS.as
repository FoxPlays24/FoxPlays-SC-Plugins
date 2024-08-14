CClientCommand kysCommand("kys", "Your life is NOTHING, you serve ZERO purpose. You should  kill yourself, NOW!", @KYS);
CCVar@ noDelay = CCVar("no_delay", 0, "Shoot lightning without delay! (0/1 - enable/disable delay)", ConCommandFlag::AdminOnly);

const string beamSprite = "sprites/hunger/tesla_beam.spr",
             kysSound = "foxplays_sc_plugins/KYS.ogg";

bool isActive = false;

void PluginInit()
{
    g_Module.ScriptInfo.SetAuthor("FoxPlays");
    g_Module.ScriptInfo.SetContactInfo("https://github.com/FoxPlays24/FoxPlays-SC-Plugins/tree/main/KYS");
    g_Module.ScriptInfo.SetMinimumAdminLevel(ADMIN_YES);
}

void MapInit()
{
    g_Game.PrecacheModel(beamSprite);
    g_Game.PrecacheGeneric("sound/" + kysSound);
    g_SoundSystem.PrecacheSound(kysSound);
}

void tellmsg(CBasePlayer@ plr, const string msg)
{
    g_PlayerFuncs.SayText(plr, msg + "\n");
}

void NetworkBeam(Vector start, Vector end, 
    string sprite = "sprites/laserbeam.spr", uint8 frameStart = 0, 
    uint8 frameRate = 100, uint8 life = 10, uint8 width = 32, uint8 noise = 1, 
    RGBA c = PURPLE, uint8 scroll = 32)
{
    NetworkMessage m(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
    m.WriteByte(TE_BEAMPOINTS);
    m.WriteVector(start);
    m.WriteVector(end);
    m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
    m.WriteByte(frameStart);
    m.WriteByte(frameRate);
    m.WriteByte(life);
    m.WriteByte(width);
    m.WriteByte(noise);
    m.WriteByte(c.r);
    m.WriteByte(c.g);
    m.WriteByte(c.b);
    m.WriteByte(c.a);
    m.WriteByte(scroll);
    m.End();
}

void Kill(CBasePlayer@ plr, CBaseEntity@ target)
{
    for (uint i = 0; i < 8; i++)
        NetworkBeam(target.pev.origin+Vector(0, 0, 4096), target.pev.origin+Vector(Math.RandomFloat(-20, 20), Math.RandomFloat(-20, 20), 0), beamSprite, 10*i, 100, 1+i/2, 255, 20, RGBA(120, 255, 255), 128);
    for (uint i = 0; i < 4; i++)
        g_EntityFuncs.CreateExplosion(target.pev.origin, Vector(0, 0, 0), target.edict(), 100, false);
    
    if (target.IsAlive())
        target.Killed(target.pev, GIB_ALWAYS);

    isActive = false;
}

void KYS(const CCommand@ args)
{
    CBasePlayer@ plr = g_ConCommandSystem.GetCurrentPlayer();
    CBaseEntity@ target = g_Utility.FindEntityForward(plr, 1024);

    if (target is null) {
        tellmsg(plr, "KYS: No target found!"); 
        return;
    }

    if (!target.IsAlive()) {
        tellmsg(plr, "KYS: Entity is not alive!");
        return;
    }

    if (isActive and !noDelay.GetBool())
        return;

    isActive = true;
    g_SoundSystem.PlaySound(plr.edict(), CHAN_AUTO, kysSound, 1, 1);
    g_Scheduler.SetTimeout("Kill", 5.4, @plr, @target);
}
