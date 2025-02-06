CClientCommand pmhCommand("pmh", "Set playermodel view height! (ex. .pmh gabumon 10)", @pmh);
CClientCommand pmhrCommand("pmhr", "Reset playermodel height to default: "+g_iDefaultHeight, @pmhr);
CClientCommand shlCommand("shl", "Set server height limits", @shl);
CClientCommand shlrCommand("shlr", "Reset server height limits to default: "+
                           HeightDef::Min+" "+HeightDef::Max+" "+HeightDef::Default, @shlr);

const string g_strCfgPath = "scripts/plugins/store/PlayerHeight.cfg";
namespace HeightMax { int16 Default = 28, Min = -128, Max = 128; }
namespace HeightDef { const int16 Default = 28, Min = -22, Max = 80; }

int16 g_iDefaultHeight = HeightDef::Default, g_iMinHeight = HeightDef::Min,
      g_iMaxHeight = HeightDef::Max;
dictionary g_dictPMHeights = {}; // model name = float
bool g_bDictChanged = false;

void println(const string &in text) { g_Game.AlertMessage(at_console, text+"\n"); }
void tellmsg(const string &in msg) { g_PlayerFuncs.SayTextAll(null, "[PlayerHeight] "+msg+"\n"); }
void tellmsg(CBasePlayer@ plr, const string msg) { g_PlayerFuncs.SayText(plr, "[PlayerHeight->"+plr.pev.netname+"] "+msg+"\n"); }

void PluginInit() {
  g_Module.ScriptInfo.SetAuthor("FoxPlays");
  g_Module.ScriptInfo.SetContactInfo("https://github.com/FoxPlays24/FoxPlays-SC-Plugins/tree/main/PlayerHeight");
}

void MapInit() {
  g_Hooks.RegisterHook(Hooks::Player::PlayerPreThink, @PlayerPreThink);
  g_Hooks.RegisterHook(Hooks::Game::MapChange, @MapChange);
  LoadConfig();
  tellmsg("\"PlayerHeight\" plugin is working");
}

string GetPlayerModel(CBasePlayer@ pPlayer) {
  return g_EngineFuncs.GetInfoKeyBuffer(pPlayer.edict()).GetValue("model").ToLowercase();
}

HookReturnCode PlayerPreThink(CBasePlayer@ pPlayer, uint &out uiDummy) {
  const bool bDucking = (pPlayer.pev.flags & FL_DUCKING) != 0;
  const string strModel = GetPlayerModel(pPlayer);
  if (!g_dictPMHeights.exists(strModel)) {
    if (!bDucking)
      pPlayer.pev.view_ofs.z = g_iDefaultHeight;
    return HOOK_CONTINUE;
  }

  int iHeight = 0;
  g_dictPMHeights.get(strModel, iHeight);

  // Make ensure that player doesn't go out of bounds, I also tried to make max 
  // height clamp based on ceiling height, but it was too buggy :d
  if (!bDucking || iHeight <= -6)
    pPlayer.pev.view_ofs.z = bDucking && iHeight < -8 ? HeightDef::Min+14 : iHeight;

  return HOOK_CONTINUE;
}

HookReturnCode MapChange(const string &in strLevel) {
  if (g_bDictChanged)
    WriteConfig();
  return HOOK_CONTINUE;
}

// PlayerModel Height
void pmh(const CCommand@ args) {
  CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
  const string strModel = GetPlayerModel(pPlayer);
  int iCurrHeight = g_iDefaultHeight;
  if (g_dictPMHeights.exists(strModel))
    g_dictPMHeights.get(strModel, iCurrHeight);

  if (args.ArgC() < 2) {
    tellmsg(pPlayer, "\""+strModel+"\" height is "+iCurrHeight+
            (iCurrHeight == HeightDef::Default ? " (default)" : "")+
            ". To change it, type \".pmh (height)\" in chat");
    return;
  }

  // BUG: It still resets to 0, and not g_iDefaultHeight
  const int16 iHeight = args.FindIntArg(args[0], g_iDefaultHeight);
  if (iHeight < g_iMinHeight || iHeight > g_iMaxHeight) {
    tellmsg("Height "+iHeight+" is out of the limits! (Min: "+g_iMinHeight+", Max: "+g_iMaxHeight+")");
    return;
  }

  if (iHeight == iCurrHeight) {
    tellmsg("\""+strModel+"\" height is already "+iHeight+"!");
    return;
  }

  g_dictPMHeights[strModel] = iHeight;
  g_bDictChanged = true;

  tellmsg("\""+strModel+"\" height is set to "+iHeight);
}

// PlayerModel Height Reset
void pmhr(const CCommand@ args) {
  CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
  const string strModel = GetPlayerModel(pPlayer);

  g_dictPMHeights[strModel] = g_iDefaultHeight;
  g_bDictChanged = true;

  tellmsg("\""+strModel+"\" height is reset to "+g_iDefaultHeight+" (default)");
}

// Server Height Limits
void shl(const CCommand@ args) {
  CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
  
  if (args.ArgC() < 2) {
    tellmsg(pPlayer, "Server height limits are "+g_iMinHeight+" "+g_iMaxHeight+
            " "+g_iDefaultHeight+" (min max default)");
    return;
  }
  else if (args.ArgC() < 3) {
    tellmsg(pPlayer, "To set server height limits, use it like: \".pmhl (min) (max) (default)\"");
    return;
  }

  const int16 iMin = args.FindIntArg(args[0], HeightDef::Min), 
              iMax = args.FindIntArg(args[1], HeightDef::Max),
              iDefault = args.FindIntArg(args[2], HeightDef::Default);
  SetServerHeightLimits(pPlayer, iMin, iMax, iDefault);
}

// Server Height Limits Reset
void shlr(const CCommand@ args) {
  CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

  g_iMinHeight = HeightDef::Min;
  g_iMaxHeight = HeightDef::Max;
  RefreshHeights();
  g_iDefaultHeight = HeightDef::Default;

  tellmsg("Server height limits are set to defaults: "+HeightDef::Min+
          " "+HeightDef::Max+" "+HeightDef::Default+" (min max default)");
}

void SetServerHeightLimits(CBasePlayer@ &in pCaller, const int16 &in iMin, 
                           const int16 &in iMax, const int16 &in iDefault) {
  // Check minimum value bounds
  if (iMin < HeightMax::Min) {
    tellmsg(pCaller, "Minimum height can't be greater than "+HeightMax::Min+"!");
    return;
  }

  // Check maximum value bounds
  if (iMax > HeightMax::Max) {
    tellmsg(pCaller, "Maximum height can't be greater than "+HeightMax::Max+"!");
    return;
  }  

  // Check default value limits
  if (iDefault < iMin || iDefault > iMax) {
    tellmsg(pCaller, "Default height "+iDefault+" is out of specified limits! Min: "+
            iMin+", Max: "+iMax);
    return;
  }

  g_iMinHeight = iMin;
  g_iMaxHeight = iMax;
  RefreshHeights();
  g_iDefaultHeight = iDefault;

  tellmsg("Server height limits are set to "+g_iMinHeight+" "+g_iMaxHeight+
          " "+g_iDefaultHeight+" (min max default)");
}

void RefreshHeights() {
  const array<string>@ pArrKeys = g_dictPMHeights.getKeys();
  int16 iHeight = 0;
  for (uint i = 0; i < pArrKeys.size(); i++) {
    g_dictPMHeights.get(pArrKeys[i], iHeight);
    g_dictPMHeights[pArrKeys[i]] = Math.clamp(g_iMinHeight, g_iMaxHeight, iHeight);
  }
  g_bDictChanged = true;
}

void LoadConfig() {
  File@ pFile = g_FileSystem.OpenFile(g_strCfgPath, OpenFile::READ);
  if (pFile is null || !pFile.IsOpen())
    return;

  string strOut = "";
  int iEqualsChar = 0;

  // Read height limits on line 1
  pFile.ReadLine(strOut);
  array<string>@ pArrSplit = strOut.Split(',');
  if (pArrSplit.size() < 3) {
    println("Can't read server height limits from config!");
  }
  else {
    println("Reading server height limits... " + strOut);
    SetServerHeightLimits(null, atoi(pArrSplit[0]), atoi(pArrSplit[1]), atoi(pArrSplit[2]));
  }
  strOut = "";

  while (!pFile.EOFReached()) {
    pFile.ReadLine(strOut);

    iEqualsChar = strOut.FindFirstOf("=", 0);
    if (iEqualsChar > 0)
      g_dictPMHeights[strOut.SubString(0, iEqualsChar).ToLowercase()] = 
        Math.clamp(g_iMinHeight, g_iMaxHeight, atoi(strOut.SubString(iEqualsChar+1, strOut.Length())));
  }
  pFile.Close();
  g_bDictChanged = false;
  
  println("\"PlayerHeight\" config has been loaded " + g_dictPMHeights.getSize() + " playermodel heights");
}

void WriteConfig() {
  File@ pFile = g_FileSystem.OpenFile(g_strCfgPath, OpenFile::WRITE);
  const array<string>@ pArrKeys = g_dictPMHeights.getKeys();
  int16 iHeight = 0;
  array<string> arrOut = {};

  for (uint i = 0; i < pArrKeys.size(); i++) {
    g_dictPMHeights.get(pArrKeys[i], iHeight);
    if (iHeight != g_iDefaultHeight)
      arrOut.insertLast(pArrKeys[i]+"="+iHeight);
  }

  pFile.Write(""+g_iMinHeight+","+g_iMaxHeight+","+g_iDefaultHeight+"\n");

  if (arrOut.size() > 0) {
    // Sort playermodel names a->z
    arrOut.sort(function(a,b) { return uint8(a[0]) < uint8(b[0]); });
    for (uint i = 0; i < arrOut.size(); i++)
      pFile.Write(arrOut[i]+(i != arrOut.size()-1 ? "\n" : ""));
  }

  pFile.Close();
}
