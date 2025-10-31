local base = "pure_skin_element"

DEFINE_BASECLASS(base)

HUDELEMENT.Base = base

if CLIENT then -- CLIENT
  local pad = 7 -- padding
  local iconSize = 64

  local const_defaults = {
    basepos = {x = 0, y = 0},
    size = {w = 365, h = 32},
    minsize = {w = 225, h = 32}
  }

  function HUDELEMENT:PreInitialize()
    BaseClass.PreInitialize(self)

    local hud = huds.GetStored("pure_skin")
    if hud then
      hud:ForceElement(self.id)
    end

    -- set as fallback default, other skins have to be set to true!
    self.disabledUnlessForced = false
  end

  function HUDELEMENT:Initialize()
    self.scale = 1.0
    self.basecolor = self:GetHUDBasecolor()
    self.pad = pad
    self.iconSize = iconSize

    BaseClass.Initialize(self)
  end

  function HUDELEMENT:GetDefaults()
    const_defaults["basepos"] = {
      x = 10 * self.scale,
      y = ScrH() - self.size.h - 146 * self.scale - self.pad - 10 * self.scale
    }

    return const_defaults
  end

  function HUDELEMENT:PerformLayout()
    self.scale = self:GetHUDScale()
    self.basecolor = self:GetHUDBasecolor()
    self.iconSize = iconSize * self.scale
    self.pad = pad * self.scale

    BaseClass.PerformLayout(self)
  end

  function HUDELEMENT:ShouldDraw()
    local client = LocalPlayer()

    return IsValid(client)
  end

  function HUDELEMENT:Draw()
    local TTT2SleeperAgent = TTT2SleeperAgent
    local mult = nil
    local time_scale = nil
    local color = nil
    -- TODO: I do not like this displacement hack to get the UI to align correct when spectating,
    -- but I do not know how to set its alignment to the player healthbar yet.
    local displacement = 0
    local text = "ttt2_sleeper_multiplier_text"

    local client = LocalPlayer()
    local show_bar = false
    if IsValid(client) and TTT2SleeperAgent then
      if client:Alive() then
        show_bar = client:IsActive() and client:GetSubRole() == ROLE_SLEEPER
      else
        local spectated = client:GetObserverTarget()
        show_bar = IsValid(spectated) and spectated:IsPlayer() and spectated:Alive() and spectated:GetSubRole() == ROLE_SLEEPER
        displacement = -36
        text = "ttt2_sleeper_spectated_text"
      end
    end

    if show_bar then
      local mults = TTT2SleeperAgent.mults
      local sleep_times = TTT2SleeperAgent.sleep_times
      local dt = CurTime() - TTT2SleeperAgent.start_time

      local i = 1
      while i < #mults and dt >= sleep_times[i] do
        dt = dt - sleep_times[i]
        i = i + 1
      end

      mult = mults[i]
      color = TTT2SleeperAgent.colors[i]
      if i < #mults and dt > 0.0 then
        time_scale = 1.0 - (dt / sleep_times[i])
      else
        time_scale = 1.0
      end
    elseif HUDEditor.IsEditing then
      mult = 1.0
      time_scale = 0.66
      color = Color(20, 160, 20)
    end

    if mult then
      -- print("hello")
      local pos = self:GetPos()
      local size = self:GetSize()
      local x, y = pos.x, pos.y + displacement
      local w, h = size.w, size.h

      self:DrawBg(x, y, w, h, self.basecolor)

      local text = LANG.GetParamTranslation(text, {multiplier = tostring(math.floor(mult * 100) / 100)})
      self:DrawBar(x + pad, y + pad, w - pad * 2, h - pad * 2, color, time_scale, self.scale, text)

      self:DrawLines(x, y, w, h, self.basecolor.a)
    end
  end
end
