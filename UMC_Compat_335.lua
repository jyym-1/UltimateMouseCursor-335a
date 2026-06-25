-- 3.3.5a compatibility layer for Ultimate Mouse Cursor.
-- Prefer real implementations from !!!ClassicAPI when present; otherwise provide safe fallbacks.

UltimateMouseCursor = UltimateMouseCursor or {}
local UMC = UltimateMouseCursor

local _, _, _, interfaceVersion = GetBuildInfo()
UMC.interfaceVersion = interfaceVersion or 0
UMC.IS_WRATH_335 = (UMC.interfaceVersion > 0 and UMC.interfaceVersion <= 30300)

UMC.atlasFallbacks = UMC.atlasFallbacks or {
    ["uitools-icon-chevron-down"] = "Interface\\AddOns\\UltimateMouseCursor\\media\\Reticle_Dot",
    ["uitools-icon-plus"] = "Interface\\AddOns\\UltimateMouseCursor\\media\\Reticle_Circle",
    ["UF-SoulShard-FX-FrameGlow"] = "Interface\\AddOns\\UltimateMouseCursor\\media\\Reticle_Circle",
    ["uitools-icon-minus"] = "Interface\\AddOns\\UltimateMouseCursor\\media\\Reticle_Dot",
    ["AftLevelup-WhiteStarBurst"] = "Interface\\AddOns\\UltimateMouseCursor\\media\\Reticle_Dot",
    ["ProgLan-w-4"] = "Interface\\AddOns\\UltimateMouseCursor\\media\\Reticle_Dot",
    ["uitools-icon-close"] = "Interface\\AddOns\\UltimateMouseCursor\\media\\Reticle_Circle",
    ["Adventures-Buff-Heal-Burst"] = "Interface\\AddOns\\UltimateMouseCursor\\media\\Reticle_Dot",
}

local function PatchPrototype(object, methods)
    if not object then return end
    local mt = getmetatable(object)
    local proto = mt and mt.__index
    if type(proto) ~= "table" then return end
    for name, func in pairs(methods) do
        if proto[name] == nil then
            proto[name] = func
        end
    end
end

-- Texture methods added after 3.3.5a.
do
    local frame = CreateFrame("Frame")
    local texture = frame:CreateTexture(nil, "ARTWORK")
    PatchPrototype(texture, {
        SetColorTexture = function(self, r, g, b, a)
            self:SetTexture(r or 1, g or 1, b or 1, a == nil and 1 or a)
        end,
        SetAtlas = function(self, atlas)
            local fallback = UMC.atlasFallbacks and UMC.atlasFallbacks[atlas]
            self:SetTexture(fallback or "Interface\\AddOns\\UltimateMouseCursor\\media\\Reticle_Dot")
        end,
    })
end

-- Cooldown helpers used by modern clients and by ClassicAPI.  When ClassicAPI is
-- installed these functions should already exist and are left untouched.
do
    local cooldown = CreateFrame("Cooldown")
    PatchPrototype(cooldown, {
        SetSwipeTexture = function(self, texturePath)
            if not self.UMC_SwipeTexture then
                local tex = self:CreateTexture(nil, "ARTWORK")
                tex:SetAllPoints(self)
                self.UMC_SwipeTexture = tex
            end
            self.UMC_SwipeTexture:SetTexture(texturePath)
        end,
        SetSwipeColor = function(self, r, g, b, a)
            if self.UMC_SwipeTexture then
                self.UMC_SwipeTexture:SetVertexColor(r or 1, g or 1, b or 1, a == nil and 1 or a)
            end
        end,
        SetReverse = function(self, reverse) self.UMC_Reverse = reverse end,
        SetHideCountdownNumbers = function(self, hide) self.UMC_HideCountdownNumbers = hide end,
        SetRotation = function(self, radians) self.UMC_Rotation = radians end,
        Clear = function(self) self:SetCooldown(0, 0) end,
    })
end

-- Dragonflight-era slider helper.  In 3.3.5a SetValueStep is enough.
do
    local slider = CreateFrame("Slider")
    PatchPrototype(slider, {
        SetObeyStepOnDrag = function(self, obey) self.UMC_ObeyStepOnDrag = obey end,
    })
end

-- Retail color API shim.
C_ClassColor = C_ClassColor or {}
if not C_ClassColor.GetClassColor then
    function C_ClassColor.GetClassColor(class)
        if class and RAID_CLASS_COLORS then
            return RAID_CLASS_COLORS[class]
        end
    end
end

-- Retail spell cooldown API shim.
C_Spell = C_Spell or {}
if not C_Spell.GetSpellCooldown and GetSpellCooldown then
    function C_Spell.GetSpellCooldown(spell)
        local startTime, duration, enabled = GetSpellCooldown(spell)
        if startTime == nil then return nil end
        return { startTime = startTime or 0, duration = duration or 0, isEnabled = enabled }
    end
end

-- Power API shims for very old 3.3.5a cores/client variants.
if not UnitPowerType then
    function UnitPowerType(unit)
        return 0, "MANA"
    end
end

if not UnitPower then
    function UnitPower(unit, powerType)
        local pType = powerType
        if pType == nil then pType = UnitPowerType(unit) or 0 end
        if pType == 1 and UnitRage then return UnitRage(unit) end
        if pType == 3 and UnitEnergy then return UnitEnergy(unit) end
        if pType == 6 and UnitRunicPower then return UnitRunicPower(unit) end
        if UnitMana then return UnitMana(unit) end
        return 0
    end
end

if not UnitPowerMax then
    function UnitPowerMax(unit, powerType)
        local pType = powerType
        if pType == nil then pType = UnitPowerType(unit) or 0 end
        if pType == 1 and UnitRageMax then return UnitRageMax(unit) end
        if pType == 3 and UnitEnergyMax then return UnitEnergyMax(unit) end
        if pType == 6 and UnitRunicPowerMax then return UnitRunicPowerMax(unit) end
        if UnitManaMax then return UnitManaMax(unit) end
        return 0
    end
end

-- Mount/flying guards for 3.3.5a forks that do not expose every helper.
if not IsMounted then function IsMounted() return false end end
if not IsFlying then function IsFlying() return false end end
if not HasBonusActionBar then function HasBonusActionBar() return false end end
if not GetActionBarPage then function GetActionBarPage() return 1 end end
if not GetShapeshiftFormID then function GetShapeshiftFormID() return nil end end

-- WotLK color picker uses function fields instead of SetupColorPickerAndShow.
if ColorPickerFrame and not ColorPickerFrame.SetupColorPickerAndShow then
    function ColorPickerFrame:SetupColorPickerAndShow(info)
        self.func = info.swatchFunc
        self.cancelFunc = info.cancelFunc
        self.hasOpacity = info.hasOpacity
        self.opacityFunc = info.opacityFunc
        if self.SetColorRGB then
            self:SetColorRGB(info.r or 1, info.g or 1, info.b or 1)
        end
        self:Show()
    end
end


function UMC:SetRegionSize(region, width, height)
    if not region then return end
    width = width or 1
    height = height or width
    if region.SetSize then
        region:SetSize(width, height)
    else
        if region.SetWidth then region:SetWidth(width) end
        if region.SetHeight then region:SetHeight(height) end
    end
end

function UMC:SetTextureOrAtlas(texture, path, fallback)
    if not texture then return end
    if path and texture.SetAtlas then
        local ok = pcall(texture.SetAtlas, texture, path)
        if ok then return end
    end
    texture:SetTexture(fallback or (UMC.atlasFallbacks and UMC.atlasFallbacks[path]) or path or "Interface\\AddOns\\UltimateMouseCursor\\media\\Reticle_Dot")
end

function UMC:GetSpellCooldownCompat(spell)
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(spell)
        if info then return info end
    end
    if GetSpellCooldown then
        local startTime, duration, enabled = GetSpellCooldown(spell)
        if startTime ~= nil then
            return { startTime = startTime or 0, duration = duration or 0, isEnabled = enabled }
        end
    end
    return nil
end

function UMC:GetPlayerCastTimes(channel)
    local a1, a2, a3, a4, a5, a6 = nil, nil, nil, nil, nil, nil
    if channel then
        a1, a2, a3, a4, a5, a6 = UnitChannelInfo("player")
    else
        a1, a2, a3, a4, a5, a6 = UnitCastingInfo("player")
    end

    -- Retail/modern: name, text, texture, startMS, endMS, ...
    if type(a4) == "number" and type(a5) == "number" and a5 > a4 then
        return a4, a5
    end

    -- 3.3.5a: name, rank, displayName, icon, startMS, endMS, ...
    if type(a5) == "number" and type(a6) == "number" and a6 > a5 then
        return a5, a6
    end

    return nil, nil
end

UMC.PowerEvents335 = {
    "UNIT_MANA", "UNIT_MAXMANA",
    "UNIT_RAGE", "UNIT_MAXRAGE",
    "UNIT_ENERGY", "UNIT_MAXENERGY",
    "UNIT_FOCUS", "UNIT_MAXFOCUS",
    "UNIT_RUNIC_POWER", "UNIT_MAXRUNIC_POWER",
    "UNIT_DISPLAYPOWER",
}

function UMC:IsPowerEvent(event)
    if event == "UNIT_POWER_UPDATE" or event == "UNIT_POWER_FREQUENT" or event == "UNIT_POWER" or event == "UNIT_MAXPOWER" then
        return true
    end
    for _, powerEvent in ipairs(UMC.PowerEvents335) do
        if event == powerEvent then return true end
    end
    return false
end

function UMC:RegisterPowerEvents(frame)
    if not frame then return end
    if UMC.IS_WRATH_335 then
        for _, event in ipairs(UMC.PowerEvents335) do
            frame:RegisterEvent(event)
        end
    else
        frame:RegisterEvent("UNIT_POWER_UPDATE")
        frame:RegisterEvent("UNIT_MAXPOWER")
    end
end

function UMC:UnregisterPowerEvents(frame)
    if not frame then return end
    for _, event in ipairs(UMC.PowerEvents335) do
        frame:UnregisterEvent(event)
    end
    frame:UnregisterEvent("UNIT_POWER_UPDATE")
    frame:UnregisterEvent("UNIT_POWER_FREQUENT")
    frame:UnregisterEvent("UNIT_POWER")
    frame:UnregisterEvent("UNIT_MAXPOWER")
end

function UMC:CallWidgetMethod(widget, method, ...)
    if widget and widget[method] then
        local result = widget[method](widget, ...)
        if method == "SetSwipeTexture" or method == "SetSwipeColor" or method == "SetReverse" then
            if UMC.FixCooldownCaptureSize then UMC:FixCooldownCaptureSize(widget) end
        end
        return result
    end
end


-- 3.3.5a/ClassicAPI cooldown widgets need a real, sized parent frame.
-- ClassicAPI's SetSwipeTexture attaches the emulated swipe to the cooldown's
-- parent, not to the cooldown region itself. If the parent has a 0x0 size, its
-- rotating texcoords can become NaN and spam "TexCoord out of range" errors.
function UMC:CreateCooldownWidget(name, size, frameLevel)
    if not UMC_CursorFrame then return nil end

    size = size or 1
    local wrapperName = name and (name .. "_WRAPPER") or nil
    local wrapper = CreateFrame("Frame", wrapperName, UMC_CursorFrame)
    if wrapper.SetSize then
        wrapper:SetSize(size, size)
    else
        wrapper:SetWidth(size)
        wrapper:SetHeight(size)
    end
    wrapper:SetPoint("CENTER", UMC_CursorFrame, "CENTER")
    if wrapper.SetFrameLevel then wrapper:SetFrameLevel(frameLevel or 1) end
    wrapper:Show()

    local cooldown = CreateFrame("Cooldown", name, wrapper)
    if cooldown.SetAllPoints then
        cooldown:SetAllPoints(wrapper)
    else
        cooldown:SetPoint("CENTER", wrapper, "CENTER")
        if cooldown.SetSize then
            cooldown:SetSize(size, size)
        else
            cooldown:SetWidth(size)
            cooldown:SetHeight(size)
        end
    end
    if cooldown.SetFrameLevel then cooldown:SetFrameLevel((frameLevel or 1) + 1) end
    cooldown.UMC_Wrapper = wrapper
    cooldown.UMC_Size = size
    return cooldown
end

function UMC:SetCooldownWidgetSize(widget, size)
    if not widget then return end
    size = size or widget.UMC_Size or 1
    local wrapper = widget.UMC_Wrapper

    if wrapper then
        if wrapper.SetSize then
            wrapper:SetSize(size, size)
        else
            wrapper:SetWidth(size)
            wrapper:SetHeight(size)
        end
        wrapper:ClearAllPoints()
        wrapper:SetPoint("CENTER", UMC_CursorFrame, "CENTER")
        wrapper:Show()
        if widget.SetAllPoints then
            widget:ClearAllPoints()
            widget:SetAllPoints(wrapper)
        end
    end

    if widget.SetSize then
        widget:SetSize(size, size)
    else
        widget:SetWidth(size)
        widget:SetHeight(size)
    end
    widget.UMC_Size = size
    UMC:FixCooldownCaptureSize(widget)
end

function UMC:FixCooldownCaptureSize(widget)
    if not widget then return end
    local wrapper = widget.UMC_Wrapper or (widget.GetParent and widget:GetParent()) or widget
    local width = widget.UMC_Size or 1
    local height = width

    if wrapper and wrapper.GetWidth and wrapper.GetHeight then
        local w, h = wrapper:GetWidth(), wrapper:GetHeight()
        if type(w) == "number" and w > 0 then width = w end
        if type(h) == "number" and h > 0 then height = h end
    end
    if not height or height <= 0 then height = width end
    if not width or width <= 0 then width = height end
    if not width or width <= 0 then width = 1 end
    if not height or height <= 0 then height = 1 end

    local swipe = widget._Swipe
    if swipe then
        if swipe.SetSize then
            swipe:SetSize(width, height)
        else
            swipe:SetWidth(width)
            swipe:SetHeight(height)
        end
        swipe.Aspect = width / height
        if swipe[5] and swipe[5].Texture then
            if swipe[5].Texture.SetSize then
                swipe[5].Texture:SetSize(width, height)
            else
                swipe[5].Texture:SetWidth(width)
                swipe[5].Texture:SetHeight(height)
            end
        end
    end
end

function UMC:ShowCooldownWidget(widget)
    if not widget then return end
    if widget.UMC_Wrapper then widget.UMC_Wrapper:Show() end
    UMC:FixCooldownCaptureSize(widget)
    widget:Show()
    UMC:FixCooldownCaptureSize(widget)
end

function UMC:HideCooldownWidget(widget)
    if widget then widget:Hide() end
end

function UMC:DestroyCooldownWidget(widget)
    if not widget then return end
    widget:Hide()
    if widget.UMC_Wrapper then
        widget.UMC_Wrapper:Hide()
        widget.UMC_Wrapper:SetParent(nil)
        widget.UMC_Wrapper = nil
    else
        widget:SetParent(nil)
    end
end

-- Wrath-safe texture-atlas arc renderer for GCD/cast rings.
-- This bypasses ClassicAPI's CooldownCapture quadrant renderer for cursor rings,
-- which can show quadrant handoff jank around 50%-75% and adds a 0.2s visual
-- padding intended for normal action-button cooldowns.
UMC.WRATH_ARC_ATLAS_PATH = "Interface\\AddOns\\UltimateMouseCursor\\media\\ArcAtlas"
UMC.WRATH_ARC_ATLAS_COLS = 8
UMC.WRATH_ARC_ATLAS_ROWS = 8
UMC.WRATH_ARC_ATLAS_MAX_STEP = 63
UMC.WRATH_CAST_FINISH_HOLD = 0.045

function UMC:SetWrathArcStep(texture, step)
    if not texture then return end
    local maxStep = UMC.WRATH_ARC_ATLAS_MAX_STEP or 63
    step = math.floor((tonumber(step) or 0) + 0.5)
    if step < 0 then step = 0 end
    if step > maxStep then step = maxStep end

    local cols = UMC.WRATH_ARC_ATLAS_COLS or 8
    local rows = UMC.WRATH_ARC_ATLAS_ROWS or 8
    local col = math.mod and math.mod(step, cols) or (step % cols)
    local row = math.floor(step / cols)

    local left = col / cols
    local right = (col + 1) / cols
    local top = row / rows
    local bottom = (row + 1) / rows
    texture:SetTexCoord(left, right, top, bottom)
end

function UMC:ApplyWrathArcRotation(texture, radians)
    if not texture or not texture.CreateAnimationGroup then return end
    radians = radians or 0
    if not texture.UMC_RotationGroup then
        local group = texture:CreateAnimationGroup()
        if not group then return end
        if group.SetLooping then group:SetLooping("REPEAT") end
        local rotation = group:CreateAnimation("Rotation")
        if not rotation then return end
        if rotation.SetOrigin then rotation:SetOrigin("CENTER", 0, 0) end
        if rotation.SetDuration then rotation:SetDuration(0) end
        if rotation.SetEndDelay then rotation:SetEndDelay(60) end
        texture.UMC_RotationGroup = group
        texture.UMC_RotationAnimation = rotation
        if group.Play then group:Play() end
    end
    if texture.UMC_RotationAnimation and texture.UMC_RotationAnimation.SetDegrees then
        texture.UMC_RotationAnimation:SetDegrees(-((radians or 0) * 57.29577951308232))
    end
end

function UMC:CreateStaticRingFrame(name, parent, size, texturePath, r, g, b, a, frameLevel)
    parent = parent or UMC_CursorFrame
    if not parent then return nil end

    local frame = CreateFrame("Frame", name, parent)
    size = size or 64
    if UMC.SetRegionSize then UMC:SetRegionSize(frame, size, size) else frame:SetWidth(size); frame:SetHeight(size) end
    frame:SetPoint("CENTER", parent, "CENTER")
    if frame.SetFrameLevel then frame:SetFrameLevel(frameLevel or 2) end
    frame:EnableMouse(false)

    local texture = frame:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints(frame)
    texture:SetTexture(texturePath or "Interface\\AddOns\\UltimateMouseCursor\\media\\Ring_Main")
    texture:SetVertexColor(r or 1, g or 1, b or 1, a == nil and 1 or a)
    frame.UMC_RingTexture = texture
    frame.UMC_Size = size

    frame.SetSwipeTexture = function(self, newTexturePath)
        if self.UMC_RingTexture and newTexturePath then
            self.UMC_RingTexture:SetTexture(newTexturePath)
        end
    end
    frame.SetSwipeColor = function(self, cr, cg, cb, ca)
        if self.UMC_RingTexture then
            self.UMC_RingTexture:SetVertexColor(cr or 1, cg or 1, cb or 1, ca == nil and 1 or ca)
        end
    end
    frame.SetReverse = function(self, reverse) self.UMC_Reverse = reverse and true or false end
    frame.GetReverse = function(self) return self.UMC_Reverse end
    frame.SetRotation = function(self, radians)
        self.UMC_Rotation = radians or 0
        if self.UMC_RingTexture then UMC:ApplyWrathArcRotation(self.UMC_RingTexture, self.UMC_Rotation) end
    end
    frame.SetHideCountdownNumbers = function(self, hide) self.noCooldownCount = hide and true or nil end
    frame.SetCooldown = function(self, startTime, duration) return true end
    frame.Clear = function(self) self:Hide() end

    frame:Hide()
    return frame
end

function UMC:UpdateWrathArcCooldownFrame(frame, force)
    if not frame or not frame.UMC_ArcTexture then return end

    if frame.UMC_HideAt then
        if GetTime() >= frame.UMC_HideAt then
            frame.UMC_HideAt = nil
            frame:Clear()
        end
        return
    end

    local duration = frame.UMC_Duration or 0
    local startTime = frame.UMC_StartTime or 0
    if duration <= 0 then
        frame.UMC_ArcStep = -1
        UMC:SetWrathArcStep(frame.UMC_ArcTexture, 0)
        return
    end

    local rawProgress = (GetTime() - startTime) / duration
    if rawProgress >= 1 then
        if frame.UMC_HideOnComplete ~= false then
            frame:Clear()
            return
        end
        rawProgress = 1
    elseif rawProgress < 0 then
        rawProgress = 0
    end

    local displayProgress
    if frame.UMC_Reverse then
        displayProgress = rawProgress
    else
        displayProgress = 1 - rawProgress
    end
    if displayProgress < 0 then displayProgress = 0 end
    if displayProgress > 1 then displayProgress = 1 end

    local maxStep = UMC.WRATH_ARC_ATLAS_MAX_STEP or 63
    local step = math.floor((displayProgress * maxStep) + 0.5)
    if step < 0 then step = 0 end
    if step > maxStep then step = maxStep end

    if force or step ~= frame.UMC_ArcStep then
        UMC:SetWrathArcStep(frame.UMC_ArcTexture, step)
        frame.UMC_ArcStep = step
        if frame.UMC_ArcColorR then
            frame.UMC_ArcTexture:SetVertexColor(frame.UMC_ArcColorR, frame.UMC_ArcColorG, frame.UMC_ArcColorB, frame.UMC_ArcColorA or 1)
        end
        UMC:ApplyWrathArcRotation(frame.UMC_ArcTexture, frame.UMC_Rotation or 0)
    end
end

function UMC:CreateArcCooldownFrame(name, parent, size, role, frameLevel)
    parent = parent or UMC_CursorFrame
    if not parent then return nil end

    local frame = CreateFrame("Frame", name, parent)
    size = size or 64
    if UMC.SetRegionSize then UMC:SetRegionSize(frame, size, size) else frame:SetWidth(size); frame:SetHeight(size) end
    frame:SetPoint("CENTER", parent, "CENTER")
    if frame.SetFrameLevel then frame:SetFrameLevel(frameLevel or 4) end
    frame:EnableMouse(false)

    local texture = frame:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints(frame)
    texture:SetTexture(UMC.WRATH_ARC_ATLAS_PATH or "Interface\\AddOns\\UltimateMouseCursor\\media\\ArcAtlas")
    UMC:SetWrathArcStep(texture, 0)
    texture:SetVertexColor(1, 1, 1, 1)

    frame.UMC_IsArcCooldown = true
    frame.UMC_ArcTexture = texture
    frame.UMC_ArcStep = -1
    frame.UMC_StartTime = 0
    frame.UMC_Duration = 0
    frame.UMC_Reverse = false
    frame.UMC_Role = role
    frame.UMC_Size = size
    frame.UMC_HideOnComplete = true

    frame.SetSwipeTexture = function(self, texturePath)
        -- Active Wrath arcs intentionally use ArcAtlas as a mask.  The chosen
        -- ring texture is still honored by static/background ring frames.
        self.UMC_SwipeTexturePath = texturePath
    end
    frame.SetSwipeColor = function(self, r, g, b, a)
        self.UMC_ArcColorR = r or 1
        self.UMC_ArcColorG = g or 1
        self.UMC_ArcColorB = b or 1
        self.UMC_ArcColorA = a == nil and 1 or a
        if self.UMC_ArcTexture then
            self.UMC_ArcTexture:SetVertexColor(self.UMC_ArcColorR, self.UMC_ArcColorG, self.UMC_ArcColorB, self.UMC_ArcColorA)
        end
    end
    frame.SetReverse = function(self, reverse)
        self.UMC_Reverse = reverse and true or false
        UMC:UpdateWrathArcCooldownFrame(self, true)
    end
    frame.GetReverse = function(self) return self.UMC_Reverse end
    frame.SetRotation = function(self, radians)
        self.UMC_Rotation = radians or 0
        if self.UMC_ArcTexture then UMC:ApplyWrathArcRotation(self.UMC_ArcTexture, self.UMC_Rotation) end
    end
    frame.SetHideCountdownNumbers = function(self, hide) self.noCooldownCount = hide and true or nil end
    frame.SetDrawEdge = function(self, enabled) self.UMC_DrawEdge = enabled and true or false end
    frame.SetDrawSwipe = function(self, enabled)
        if self.UMC_ArcTexture then self.UMC_ArcTexture:SetAlpha(enabled == false and 0 or 1) end
    end
    frame.SetCooldown = function(self, startTime, duration)
        self.UMC_HideAt = nil
        self.UMC_StartTime = startTime or 0
        self.UMC_Duration = duration or 0
        self.UMC_Active = (self.UMC_Duration > 0)
        if self.UMC_Duration <= 0 then
            self:Clear()
            return true
        end
        UMC:UpdateWrathArcCooldownFrame(self, true)
        self:Show()
        return true
    end
    frame.Complete = function(self, holdSeconds)
        local maxStep = UMC.WRATH_ARC_ATLAS_MAX_STEP or 63
        local finalStep = self.UMC_Reverse and maxStep or 0
        self.UMC_Active = false
        self.UMC_Duration = 0
        self.UMC_HideAt = GetTime() + (holdSeconds or UMC.WRATH_CAST_FINISH_HOLD or 0.045)
        UMC:SetWrathArcStep(self.UMC_ArcTexture, finalStep)
        self.UMC_ArcStep = finalStep
        self:Show()
    end
    frame.Clear = function(self)
        self.UMC_Active = false
        self.UMC_Duration = 0
        self.UMC_HideAt = nil
        self.UMC_ArcStep = 0
        if self.UMC_ArcTexture then UMC:SetWrathArcStep(self.UMC_ArcTexture, 0) end
        self:Hide()
    end

    frame:SetScript("OnUpdate", function(self, elapsed)
        UMC:UpdateWrathArcCooldownFrame(self)
    end)

    frame:Hide()
    return frame
end
