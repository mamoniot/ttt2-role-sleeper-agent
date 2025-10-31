if SERVER then
  AddCSLuaFile()
  resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_sleeper.vmt")
end

local flags = {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}

local convar_mults = {}
local convar_sleeps = {}
for i = 1, 9 do
  convar_mults[i] = "ttt2_sleeper_damage_mult" .. tostring(i)
  convar_sleeps[i] = "ttt2_sleeper_sleep_time" .. tostring(i)
end

CreateConVar(convar_mults[1], 0.0, flags)
CreateConVar(convar_sleeps[1], 60, flags)
CreateConVar(convar_mults[2], 0.5, flags)
CreateConVar(convar_sleeps[2], 60, flags)
CreateConVar(convar_mults[3], 1.0, flags)
CreateConVar(convar_sleeps[3], 60, flags)
CreateConVar(convar_mults[4], 1.5, flags)
CreateConVar(convar_sleeps[4], 1.0, flags)
for i = 5, #convar_mults do
  CreateConVar(convar_mults[i], 0.0, flags)
  CreateConVar(convar_sleeps[i], 0.0, flags)
end

function ROLE:PreInitialize()
  self.color = Color(187, 156, 155, 255)

  self.abbr = "sleeper"
  self.surviveBonus = 0.5
  self.scoreKillsMultiplier = 5
  self.scoreTeamKillsMultiplier = -16
  self.preventFindCredits = false
  self.preventKillCredits = false
  self.preventTraitorAloneCredits = false

  self.isOmniscientRole = true

  self.defaultEquipment = SPECIAL_EQUIPMENT
  self.defaultTeam = TEAM_TRAITOR

  self.conVarData = {
    pct = 0.17, -- necessary: percentage of getting this role selected (per player)
    maximum = 3, -- maximum amount of roles in a round
    minPlayers = 5, -- minimum amount of players until this role is able to get selected
    credits = 1, -- the starting credits of a specific role
    togglable = true, -- option to toggle a role for a client if possible (F1 menu)
    random = 49,
    traitorButton = 1, -- can use traitor buttons
    shopFallback = SHOP_FALLBACK_TRAITOR
  }
end

function ROLE:Initialize()
  roles.SetBaseRole(self, ROLE_TRAITOR)
end

local color0 = Color(230, 20, 20)
local color1 = Color(170, 160, 0)
local color2 = Color(20, 160, 20)

local function SleeperAgentCacheConVars()
  TTT2SleeperAgent = TTT2SleeperAgent or {start_time = 0.0}
  local mults = {1.0}
  local sleep_times = {1.0}
  TTT2SleeperAgent.mults = mults
  TTT2SleeperAgent.sleep_times = sleep_times

  local j = 0
  -- Convert ConVars into a cached timeline.
  for i = 1, #convar_mults do
    local sleep_time = GetConVar(convar_sleeps[i]):GetFloat() or 0.0
    if sleep_time > 0.0 then
      local mult = math.max(0.0, GetConVar(convar_mults[i]):GetFloat())
      if mults[j] == mult then
        sleep_times[j] = sleep_times[j] + sleep_time
      else
        j = j + 1
        mults[j] = mult
        sleep_times[j] = sleep_time
      end
    end
  end
  if CLIENT then
    TTT2SleeperAgent.colors = {}
    for i = 1, #mults do
      local mult = mults[i]
      if mult <= 1.0 then
        local r = color0.r - (color0.r - color1.r) * mult
        local g = color0.g - (color0.g - color1.g) * mult
        local b = color0.b - (color0.b - color1.b) * mult
        TTT2SleeperAgent.colors[i] = Color(r, g, b, 255)
      else
        TTT2SleeperAgent.colors[i] = color2
      end
    end
  end
end

SleeperAgentCacheConVars()
hook.Add("TTTBeginRound", "SleeperAgentBeginRound", function()
  SleeperAgentCacheConVars()
  TTT2SleeperAgent.start_time = CurTime()
end)

if SERVER then
  local function SleeperAgentDealDamage(ply, inflictor, killer, amount, dmginfo)
    local attacker = dmginfo:GetAttacker()
    if not IsValid(attacker) or not attacker:IsPlayer() or attacker:GetSubRole() ~= ROLE_SLEEPER then return end

    local mults = TTT2SleeperAgent.mults
    local sleep_times = TTT2SleeperAgent.sleep_times
    local dt = CurTime() - TTT2SleeperAgent.start_time

    local i = 1
    while i < #mults and dt >= sleep_times[i] do
      dt = dt - sleep_times[i]
      i = i + 1
    end
    dmginfo:ScaleDamage(mults[i])
  end
  hook.Add("PlayerTakeDamage", "SleeperAgentDealDamage", SleeperAgentDealDamage)
end

if CLIENT then
  function ROLE:AddToSettingsMenu(parent)
    local form = vgui.CreateTTT2Form(parent, "header_roles_additional")

    for i = 1, #convar_mults do
      form:MakeSlider({
        serverConvar = convar_mults[i],
        label = "label_" .. convar_mults[i],
        min = 0.0,
        max = 10.0,
        decimal = 2,
      })
      form:MakeSlider({
        serverConvar = convar_sleeps[i],
        label = "label_" .. convar_sleeps[i],
        min = 0.0,
        max = 600.0,
        decimal = 0,
      })
    end
  end
end
