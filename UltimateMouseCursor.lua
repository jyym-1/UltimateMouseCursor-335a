UltimateMouseCursor = UltimateMouseCursor or {}
local UMC = UltimateMouseCursor 

local TrackerFrame = CreateFrame("Frame", "UMC_TrackerFrame", UIParent)
local LoaderFrame = CreateFrame("Frame")

local GCD_DURATION = 1.5
local GCD_SPELL_ID = 61304 
local _, _, _, interfaceVersion = GetBuildInfo()
local CURRENT_API = interfaceVersion or 0
UMC.interfaceVersion = CURRENT_API
UMC.IS_WRATH_335 = (CURRENT_API > 0 and CURRENT_API <= 30300)
UMC.GCDCooldownFrame = nil
UMC.GCDBackgroundFrame = nil
UMC.CastFrame = nil
UMC.CastBackgroundFrame = nil
UMC.HealthFrame = nil
UMC.HealthBackgroundFrame = nil
UMC.PowerFrame = nil

UMC.currentGroupScale = 1.0 
UMC.lastGCDTime = 0 
UMC.isGCDAnimating = false 
UMC.isCasting = false
UMC.lastHealthPercent = 1.0
UMC.lastPowerPercent = 1.0

UMC.trailElements = {}
UMC.trailActive = {}
UMC.trailTimer = 0
UMC.trailLastX = 0
UMC.trailLastY = 0

UMC.lastShiftState = false
UMC.lastCtrlState = false
UMC.lastAltState = false

UMC.pingTimer = 0
UMC.isPingAnimating = false
UMC.pingDuration = 0.5
UMC.pingStartSize = 250
UMC.pingEndSize = 70

UMC.crosshairTimer = 0
UMC.isCrosshairAnimating = false
UMC.crosshairDuration = 1.5
UMC.crosshairGap = 35 -- Radius of the ring (70/2)

UMC.defaults = {
    scale = 1.0,
    positionMode = "cursor",
    positionX = 0,
    positionY = 0,
    innerRing = "GCD",
    mainRing = "Main Ring",
    outerRing = "Cast",
    usePowerColors = false,
    
    -- Color modes: "default", "class", or "custom"
    reticleColorMode = "default",
    reticleCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    mainRingColorMode = "default",
    mainRingCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    mainRingCombatColorEnabled = false,
    mainRingCombatColor = {r = 1.0, g = 0.0, b = 0.0},
    gcdColorMode = "default",
    gcdCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    castColorMode = "default",
    castCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    healthColorMode = "default",
    healthCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    healthColorLock = false,  
    trailColorMode = "default",
    trailCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    powerColorMode = "default",
    powerCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    
    -- Legacy fields (kept for backwards compatibility)
    useMainRingClassColor = false,
    useGCDClassColor = false,
    useCastClassColor = false,
    useReticleClassColor = false,
    
    enableTrail = false,
    trailUseClassColor = false,
    trailDuration = 0.5,
    trailDensity = 0.005,
    trailScale = 1.0,
    trailMinMovement = 0.5,
    showOnlyInCombat = false,
    shiftAction = "None",
    ctrlAction = "None",
    altAction = "None",
    reticle = "Dot",
    reticleScale = 1.5,
    transparency = 1.0,
    
    -- High Contrast Ring settings
    highContrastOuterThickness = 2,
    highContrastOuterColor = {r = 0.0, g = 0.0, b = 0.0},
    highContrastOuterColorMode = "default",
    highContrastInnerThickness = -4,
    highContrastInnerColor = {r = 1.0, g = 1.0, b = 1.0},
    highContrastInnerColorMode = "default",
    
    -- Seasonal Effect settings
    seasonalEffectStyle = "Candy Cane",
    seasonalParticleType = "Snowflakes",
    
    -- Cast/GCD Animation settings
    gcdFillDrain = "fill",               -- "drain" or "fill"
    castFillDrain = "fill",              -- "drain" or "fill"
    gcdRotation = 12,                    -- 1-12 (clock position, 12 = 12 o'clock)
    castRotation = 12,                   -- 1-12 (clock position)
    
    -- Textures
    mainRingTexture = "Main (Default)",
    gcdTexture = "Main (Default)",
    castTexture = "Main (Default)",
    hcOuterTexture = "Main (Default)",
    hcInnerTexture = "Main (Default)",
}

UMC.ringTextureOptions = {
    "Main (Default)",
    "Main (Thick)",
    "Dark",
    "Dark (Large)",
    "Glass",
    "Glass (Thick)",
    "Rune"
}

UMC.ringTextureFiles = {
    ["Main (Default)"] = "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main",
    ["Main (Thick)"] = "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main_Thick",
    ["Dark"] = "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Dark",
    ["Dark (Large)"] = "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Dark_L",
    ["Glass"] = "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Glass",
    ["Glass (Thick)"] = "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Glass_Thick",
    ["Rune"] = "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Rune"
}

UMC.ringOptions = {
    "None",
    "Main Ring",
    "Main Ring + GCD",
    "Main Ring + Cast",
    "Cast",
    "GCD",
    -- "Health and Power",
    -- "Health",
    -- "Power",
    "High Contrast Ring",
}

UMC.modifierOptions = {
    "None",
    "Show Rings",
    "Ping with ring",
    "Ping with area",
    "Ping with crosshair",
    "Show Crosshair",
}

UMC.reticleOptions = {
    "Dot",
    "Chevron",
    "Crosshair",
    "Diamond",
    "Flatline",
    "Star",
    "Ring",
    "Tech Arrow",
    "X",
    "No Reticle",
}

UMC.reticleTextures = {
    ["Dot"] = { path = "Interface\\Addons\\UltimateMouseCursor\\media\\Reticle_Dot", scale = 0.5 },
    ["Chevron"] = { path = "uitools-icon-chevron-down", fallback = "Interface\\AddOns\\UltimateMouseCursor\\media\\Reticle_Dot", scale = 1.0, isAtlas = true },
    ["Crosshair"] = { path = "uitools-icon-plus", fallback = "Interface\\AddOns\\UltimateMouseCursor\\media\\Reticle_Circle", scale = 1.0, isAtlas = true },
    ["Diamond"] = { path = "UF-SoulShard-FX-FrameGlow", fallback = "Interface\\AddOns\\UltimateMouseCursor\\media\\Reticle_Circle", scale = 1.0, isAtlas = true },
    ["Flatline"] = { path = "uitools-icon-minus", fallback = "Interface\\AddOns\\UltimateMouseCursor\\media\\Reticle_Dot", scale = 1.0, isAtlas = true },
    ["Star"] = { path = "AftLevelup-WhiteStarBurst", fallback = "Interface\\AddOns\\UltimateMouseCursor\\media\\Reticle_Dot", scale = 2.0, isAtlas = true },
    ["Ring"] = { path = "Interface\\Addons\\UltimateMouseCursor\\media\\Reticle_Circle", scale = 1.0 },
    ["Tech Arrow"] = { path = "ProgLan-w-4", fallback = "Interface\\AddOns\\UltimateMouseCursor\\media\\Reticle_Dot", scale = 1.0, isAtlas = true },
    ["X"] = { path = "uitools-icon-close", fallback = "Interface\\AddOns\\UltimateMouseCursor\\media\\Reticle_Circle", scale = 1.0, isAtlas = true },
    ["No Reticle"] = { path = nil, scale = 1.0 },
}

function UMC:BindXMLFrames()
    if not UMC_CursorFrame then return end

    UMC_CursorFrame.Reticle = UMC_CursorFrame.Reticle or _G["UMC_CursorFrame_Reticle"] or _G["UMC_CursorFrameReticle"]
    UMC_CursorFrame.MainRing = UMC_CursorFrame.MainRing or _G["UMC_CursorFrame_MainRing"] or _G["UMC_CursorFrameMainRing"]
end

function UMC:GetClassColor(ringType)
    local colorMode = "default"
    local customColor = nil
    
    if ringType == "main" then
        colorMode = UMC_Config.mainRingColorMode or "default"
        customColor = UMC_Config.mainRingCustomColor
        
        if UMC_Config.mainRingCombatColorEnabled and (InCombatLockdown() or UMC.isPlayerInCombat) then
            colorMode = "custom"
            customColor = UMC_Config.mainRingCombatColor or {r = 1.0, g = 0.0, b = 0.0}
        end
    elseif ringType == "gcd" then
        colorMode = UMC_Config.gcdColorMode or "default"
        customColor = UMC_Config.gcdCustomColor
    elseif ringType == "cast" then
        colorMode = UMC_Config.castColorMode or "default"
        customColor = UMC_Config.castCustomColor
    elseif ringType == "reticle" then
        colorMode = UMC_Config.reticleColorMode or "default"
        customColor = UMC_Config.reticleCustomColor
    elseif ringType == "trail" then
        colorMode = UMC_Config.trailColorMode or "default"
        customColor = UMC_Config.trailCustomColor
    elseif ringType == "power" then
        colorMode = UMC_Config.powerColorMode or "default"
        customColor = UMC_Config.powerCustomColor
    end
    
    -- Return custom color if mode is custom
    if colorMode == "custom" and customColor then
        return customColor.r or 1.0, customColor.g or 1.0, customColor.b or 1.0
    end
    
    -- Return power type color if mode is "power" (special case for power ring)
    if colorMode == "power" and ringType == "power" then
        -- This will be handled by UpdatePowerRing function
        return nil, nil, nil
    end
    
    -- Return class color if mode is class
    if colorMode == "class" then
        local _, class = UnitClass("player")
        local classColor = nil
        if C_ClassColor and C_ClassColor.GetClassColor then
            classColor = C_ClassColor.GetClassColor(class)
        end
        if not classColor and RAID_CLASS_COLORS then
            classColor = RAID_CLASS_COLORS[class]
        end
        if classColor then
            return classColor.r, classColor.g, classColor.b
        end
    end

    -- Return default color
    -- Power ring default is cyan blue (original color), others are white
    if ringType == "power" then
        return 0.0, 0.5, 1.0  -- Cyan blue for power (original default)
    else
        return 1.0, 1.0, 1.0  -- White for others
    end
end

function UMC:ClockToRadians(clockPosition)
    -- Convert clock position (1-12) to radians for SetRotation
    -- 12 = 12 o'clock (top), 3 = 3 o'clock (right), 6 = 6 o'clock (bottom), 9 = 9 o'clock (left)
    -- WoW rotation: 0 radians = 12 o'clock
    local position = (clockPosition == 12) and 0 or clockPosition
    return (position * math.pi / 6) -- Each hour = 30 degrees = π/6 radians
end

function UMC:UpdateRingTextures()
    if not UMC_CursorFrame then return end
    UMC:BindXMLFrames()
    
    local function GetTexture(name)
        return UMC.ringTextureFiles[name] or UMC.ringTextureFiles["Main (Default)"]
    end
    
    if UMC_CursorFrame.MainRing then
        UMC_CursorFrame.MainRing:SetTexture(GetTexture(UMC_Config.mainRingTexture))
    end
    
    if UMC.GCDBackgroundFrame then
        UMC:CallWidgetMethod(UMC.GCDBackgroundFrame, "SetSwipeTexture", GetTexture(UMC_Config.gcdTexture))
    end
    if UMC.GCDCooldownFrame then
        UMC:CallWidgetMethod(UMC.GCDCooldownFrame, "SetSwipeTexture", GetTexture(UMC_Config.gcdTexture))
    end
    
    if UMC.CastBackgroundFrame then
        UMC:CallWidgetMethod(UMC.CastBackgroundFrame, "SetSwipeTexture", GetTexture(UMC_Config.castTexture))
    end
    if UMC.CastFrame then
        UMC:CallWidgetMethod(UMC.CastFrame, "SetSwipeTexture", GetTexture(UMC_Config.castTexture))
    end
    
    if UMC.HighContrastRings then
        for _, ring in pairs(UMC.HighContrastRings) do
            if ring.outerHalf then
                ring.outerHalf:SetTexture(GetTexture(UMC_Config.hcOuterTexture))
            end
            if ring.innerHalf then
                ring.innerHalf:SetTexture(GetTexture(UMC_Config.hcInnerTexture))
            end
        end
    end
end

function UMC:UpdateRingColors()
    UMC:BindXMLFrames()
    -- Check which configurations are selected
    local hasMainRingPlusGCD = false
    local hasMainRingPlusCast = false
    
    local slots = {
        {config = UMC_Config.innerRing},
        {config = UMC_Config.mainRing},
        {config = UMC_Config.outerRing},
    }
    
    for _, slot in ipairs(slots) do
        if slot.config == "Main Ring + GCD" then
            hasMainRingPlusGCD = true
        end
        if slot.config == "Main Ring + Cast" then
            hasMainRingPlusCast = true
        end
    end
    
    -- GCD: Use gray if "Main Ring + GCD" is selected without class colors
    -- GCD: Use gray if "Main Ring + GCD" is selected AND mode is "default"
    if UMC.GCDCooldownFrame then
        local gcdMode = UMC_Config.gcdColorMode or "default"
        if hasMainRingPlusGCD and gcdMode == "default" then
            -- Gray for contrast with white Main Ring
            UMC:CallWidgetMethod(UMC.GCDCooldownFrame, "SetSwipeColor", 0.4, 0.4, 0.4, 1.0)
        else
            -- Use class color (white or class color or custom)
            local r, g, b = UMC:GetClassColor("gcd")
            UMC:CallWidgetMethod(UMC.GCDCooldownFrame, "SetSwipeColor", r, g, b, 1.0)
        end
    end

    -- Cast: Use gray if "Main Ring + Cast" is selected AND mode is "default"
    if UMC.CastFrame then
        local castMode = UMC_Config.castColorMode or "default"
        if hasMainRingPlusCast and castMode == "default" then
            -- Gray for contrast with white Main Ring
            UMC:CallWidgetMethod(UMC.CastFrame, "SetSwipeColor", 0.4, 0.4, 0.4, 1.0)
        else
            -- Use class color (white or class color or custom)
            local r, g, b = UMC:GetClassColor("cast")
            UMC:CallWidgetMethod(UMC.CastFrame, "SetSwipeColor", r, g, b, 1.0)
        end
    end

    -- Main Ring: Always use class color (white or class color)
    if UMC_CursorFrame and UMC_CursorFrame.MainRing then
        local r, g, b = UMC:GetClassColor("main")
        UMC_CursorFrame.MainRing:SetVertexColor(r, g, b, 1.0)
    end
end

function UMC:UpdateReticle()
    UMC:BindXMLFrames()
    if not UMC_CursorFrame or not UMC_CursorFrame.Reticle then return end
    
    local reticleName = UMC_Config.reticle or "Dot"
    local reticleInfo = UMC.reticleTextures[reticleName]
    
    if not reticleInfo or not reticleInfo.path then
        -- No Reticle or invalid
        UMC_CursorFrame.Reticle:Hide()
    else
        UMC_CursorFrame.Reticle:Show()
        
        if reticleInfo.isAtlas and UMC.SetTextureOrAtlas then
            UMC:SetTextureOrAtlas(UMC_CursorFrame.Reticle, reticleInfo.path, reticleInfo.fallback)
        else
            UMC_CursorFrame.Reticle:SetTexture(reticleInfo.path)
        end
        
        -- Apply scale. 3.3.5a textures do not expose Texture:SetScale(),
        -- so resize the region directly instead.
        local globalScale = UMC_Config.reticleScale or 1.0
        local reticleSize = 10 * (reticleInfo.scale or 1.0) * globalScale
        if UMC.SetRegionSize then
            UMC:SetRegionSize(UMC_CursorFrame.Reticle, reticleSize, reticleSize)
        else
            UMC_CursorFrame.Reticle:SetSize(reticleSize, reticleSize)
        end
        
        -- Apply color using GetClassColor
        local r, g, b = UMC:GetClassColor("reticle")
        UMC_CursorFrame.Reticle:SetVertexColor(r, g, b, 1.0)
    end
end

function UMC:SetGroupScale(scale)
    if type(scale) == "number" and scale > 0 then
        UMC.currentGroupScale = scale
        if UMC_CursorFrame then
            UMC_CursorFrame:SetScale(scale)
        end
    end
end

function UMC:CreateHighContrastRing(size)
    -- Initialize High Contrast Ring frames if they don't exist
    if not UMC.HighContrastRings then
        UMC.HighContrastRings = {}
    end
    
    -- Create or reuse ring for this size
    local ringKey = "ring_" .. size
    local ring = UMC.HighContrastRings[ringKey]
    
    if not ring then
        -- Create the two-ring structure
        ring = {}
        
        -- Outer Half: Larger ring (for visibility on light backgrounds)
        local outerHalf = UMC_CursorFrame:CreateTexture(nil, "ARTWORK")
        outerHalf:SetTexture(UMC.ringTextureFiles[UMC_Config.hcOuterTexture] or "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
        outerHalf:SetPoint("CENTER", UMC_CursorFrame, "CENTER")
        outerHalf:SetDrawLayer("ARTWORK", 1)
        ring.outerHalf = outerHalf
        
        -- Inner Half: Smaller ring (for visibility on dark backgrounds)
        local innerHalf = UMC_CursorFrame:CreateTexture(nil, "ARTWORK")
        innerHalf:SetTexture(UMC.ringTextureFiles[UMC_Config.hcInnerTexture] or "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
        innerHalf:SetPoint("CENTER", UMC_CursorFrame, "CENTER")
        innerHalf:SetDrawLayer("ARTWORK", 2)
        ring.innerHalf = innerHalf
        
        UMC.HighContrastRings[ringKey] = ring
    end
    
    -- Get colors based on color mode
    local function GetHighContrastColor(colorMode, customColor, defaultColor)
        if colorMode == "class" then
            local _, class = UnitClass("player")
            if class then
                local classColor = RAID_CLASS_COLORS[class]
                if classColor then
                    return classColor.r, classColor.g, classColor.b
                end
            end
        elseif colorMode == "custom" then
            return customColor.r, customColor.g, customColor.b
        end
        -- default mode
        return defaultColor.r, defaultColor.g, defaultColor.b
    end
    
    -- Apply colors and thickness from config
    local outerColorMode = UMC_Config.highContrastOuterColorMode or "default"
    local outerCustomColor = UMC_Config.highContrastOuterColor or {r = 0.0, g = 0.0, b = 0.0}
    local outerDefaultColor = {r = 0.0, g = 0.0, b = 0.0}  -- Black
    local outerThickness = UMC_Config.highContrastOuterThickness or 2
    
    local innerColorMode = UMC_Config.highContrastInnerColorMode or "default"
    local innerCustomColor = UMC_Config.highContrastInnerColor or {r = 1.0, g = 1.0, b = 1.0}
    local innerDefaultColor = {r = 1.0, g = 1.0, b = 1.0}  -- White
    local innerThickness = UMC_Config.highContrastInnerThickness or -4
    
    -- Calculate sizes
    -- Outer half is the base size plus outer thickness
    local outerSize = size + (outerThickness * 2)
    -- Inner half also grows with thickness (same direction as outer)
    local innerSize = size + (innerThickness * 2)
    
    -- Apply sizes
    ring.outerHalf:SetSize(outerSize, outerSize)
    ring.innerHalf:SetSize(innerSize, innerSize)
    
    -- Apply colors using color mode system
    local outerR, outerG, outerB = GetHighContrastColor(outerColorMode, outerCustomColor, outerDefaultColor)
    local innerR, innerG, innerB = GetHighContrastColor(innerColorMode, innerCustomColor, innerDefaultColor)
    
    ring.outerHalf:SetVertexColor(outerR, outerG, outerB, 1.0)
    ring.innerHalf:SetVertexColor(innerR, innerG, innerB, 1.0)
    
    -- Show the ring
    ring.outerHalf:Show()
    ring.innerHalf:Show()
    
    -- Hide other rings of different sizes
    for key, otherRing in pairs(UMC.HighContrastRings) do
        if key ~= ringKey then
            if otherRing.outerHalf then otherRing.outerHalf:Hide() end
            if otherRing.innerHalf then otherRing.innerHalf:Hide() end
            -- Hide old sandwich layers if they exist
            if otherRing.outerBorder then otherRing.outerBorder:Hide() end
            if otherRing.centerRing then otherRing.centerRing:Hide() end
            if otherRing.innerBorder then otherRing.innerBorder:Hide() end
        end
    end
end

function UMC:InitializeTrail()
    if UMC.trailInitialized then return end
    UMC.trailInitialized = true

    local trailFrame = CreateFrame("Frame", "UMC_TrailFrame", UIParent)
    trailFrame:SetAllPoints(UIParent)
    trailFrame:SetFrameStrata("HIGH")
    if trailFrame.SetFrameLevel then trailFrame:SetFrameLevel(0) end
    UMC.TrailFrame = trailFrame

    for i = 1, 300 do
        local texture = trailFrame:CreateTexture(nil, "OVERLAY")
        texture:SetTexture("Interface\\Addons\\UltimateMouseCursor\\media\\Reticle_Dot")
        texture:SetBlendMode("ADD")
        texture:Hide()
        UMC.trailElements[i] = texture
    end
end

-- Seasonal Particle System
UMC.particlePool = {}
UMC.activeParticles = {}
UMC.maxParticles = 100
UMC.particleTimer = 0

function UMC:InitializeSeasonalParticles()
    -- Pre-create particle pool
    for i = 1, UMC.maxParticles do
        local particle = UIParent:CreateTexture(nil, "ARTWORK")
        particle:SetBlendMode("ADD")
        particle:Hide()
        table.insert(UMC.particlePool, particle)
    end
end

function UMC:GetParticleAtlasForStyle(style)
    -- Particle types: Snowflakes (drift down), Sparkles (burst out), Both, None
    local configs = {}
    local particleType = UMC_Config.seasonalParticleType or "Snowflakes"
    
    if particleType == "None" then
        -- No particles
        return configs
    elseif particleType == "Snowflakes" then
        -- Snowflakes: drift down gently (increased lifetime for continuity)
        table.insert(configs, {atlas = "Adventures-Buff-Heal-Burst", fallback = "Interface\\AddOns\\UltimateMouseCursor\\media\\Reticle_Dot", tint = {1.0, 1.0, 1.0}, size = 24, lifetime = 2.5, drift = true})
    elseif particleType == "Sparkles" then
        -- Sparkles: burst outward (increased lifetime for continuity)
        table.insert(configs, {atlas = "Adventures-Buff-Heal-Burst", fallback = "Interface\\AddOns\\UltimateMouseCursor\\media\\Reticle_Dot", tint = {1.0, 1.0, 1.0}, size = 20, lifetime = 1.5, burst = true})
    elseif particleType == "Both" then
        -- Both: mix of snowflakes and sparkles
        table.insert(configs, {atlas = "Adventures-Buff-Heal-Burst", fallback = "Interface\\AddOns\\UltimateMouseCursor\\media\\Reticle_Dot", tint = {1.0, 1.0, 1.0}, size = 24, lifetime = 2.5, drift = true})
        table.insert(configs, {atlas = "Adventures-Buff-Heal-Burst", fallback = "Interface\\AddOns\\UltimateMouseCursor\\media\\Reticle_Dot", tint = {1.0, 1.0, 1.0}, size = 20, lifetime = 1.5, burst = true})
    end
    
    return configs
end

function UMC:GetTrailColorForStyle(style)
    -- Returns color for trail based on style
    -- Candy Cane: alternates between red and white
    -- Christmas Lights: cycles through red, green, gold
    -- None: default white
    
    if style == "None" then
        -- Default white
        return 1.0, 1.0, 1.0
    elseif style == "Candy Cane" then
        -- Alternate between red and white
        UMC.candyCaneToggle = not UMC.candyCaneToggle
        if UMC.candyCaneToggle then
            return 1.0, 0.0, 0.0 -- Red
        else
            return 1.0, 1.0, 1.0 -- White
        end
    elseif style == "Christmas Lights" then
        -- Cycle through colors: red, green, gold, white, blue
        UMC.lightsIndex = (UMC.lightsIndex or 0) + 1
        if UMC.lightsIndex > 5 then UMC.lightsIndex = 1 end
        
        if UMC.lightsIndex == 1 then
            return 1.0, 0.0, 0.0 -- Red
        elseif UMC.lightsIndex == 2 then
            return 0.0, 1.0, 0.0 -- Green
        elseif UMC.lightsIndex == 3 then
            return 1.0, 0.84, 0.0 -- Gold
        elseif UMC.lightsIndex == 4 then
            return 1.0, 1.0, 1.0 -- White
        else
            return 0.3, 0.7, 1.0 -- Blue
        end
    end
    
    -- Default white
    return 1.0, 1.0, 1.0
end

function UMC:CreateSeasonalParticle(x, y)
    if #UMC.particlePool == 0 then return end
    if #UMC.activeParticles >= UMC.maxParticles then return end
    
    local style = UMC_Config.seasonalEffectStyle or "Candy Cane"
    local particleConfigs = UMC:GetParticleAtlasForStyle(style)
    
    -- If no particle configs (None selected), don't create particles
    if #particleConfigs == 0 then return end
    
    -- Select random particle config from available options
    local selectedConfig = particleConfigs[math.random(#particleConfigs)]
    
    local particle = table.remove(UMC.particlePool)
    table.insert(UMC.activeParticles, particle)
    
    -- Set atlas texture, with a 3.3.5a-safe fallback when atlases are unavailable
    if UMC.SetTextureOrAtlas then
        UMC:SetTextureOrAtlas(particle, selectedConfig.atlas, selectedConfig.fallback)
    else
        particle:SetTexture("Interface\\AddOns\\UltimateMouseCursor\\media\\Reticle_Dot")
    end
    
    -- Set color
    local tint = selectedConfig.tint
    particle:SetVertexColor(tint[1], tint[2], tint[3], 1.0)
    
    -- Set size with random variation
    local sizeVariation = 0.7 + (math.random() * 0.6) -- 0.7 to 1.3
    local size = selectedConfig.size * sizeVariation
    particle:SetSize(size, size)
    
    -- Position
    local uiScale = UIParent:GetEffectiveScale()
    particle.x = x / uiScale
    particle.y = y / uiScale
    particle:SetPoint("CENTER", UIParent, "BOTTOMLEFT", particle.x, particle.y)
    
    -- Lifetime
    particle.lifetime = selectedConfig.lifetime
    particle.maxLifetime = selectedConfig.lifetime
    
    -- Movement properties
    if selectedConfig.drift then
        -- Snowflake: gentle downward drift with wobble
        particle.vx = (math.random() - 0.5) * 20 -- Horizontal wobble
        particle.vy = -30 - (math.random() * 20) -- Downward drift
        particle.rotation = math.random() * 360
        particle.rotationSpeed = (math.random() - 0.5) * 90 -- degrees per second
    elseif selectedConfig.burst then
        -- Sparkle: slight outward burst
        local angle = math.random() * math.pi * 2
        local speed = 10 + (math.random() * 20)
        particle.vx = math.cos(angle) * speed
        particle.vy = math.sin(angle) * speed
        particle.rotation = math.random() * 360
        particle.rotationSpeed = (math.random() - 0.5) * 180
    elseif selectedConfig.rotate then
        -- Candy cane: rotating in place
        particle.vx = 0
        particle.vy = -10 -- Slight downward
        particle.rotation = math.random() * 360
        particle.rotationSpeed = 180 + (math.random() * 180)
    elseif selectedConfig.pulse then
        -- Christmas lights: pulsing
        particle.vx = 0
        particle.vy = 0
        particle.rotation = 0
        particle.rotationSpeed = 0
        particle.pulsePhase = math.random() * math.pi * 2
    else
        particle.vx = 0
        particle.vy = 0
        particle.rotation = 0
        particle.rotationSpeed = 0
    end
    
    particle.config = selectedConfig
    particle:SetAlpha(1.0)
    particle:Show()
end

function UMC:UpdateSeasonalParticles(elapsed)
    -- Update existing particles
    for i = #UMC.activeParticles, 1, -1 do
        local particle = UMC.activeParticles[i]
        particle.lifetime = particle.lifetime - elapsed
        
        if particle.lifetime <= 0 then
            -- Return to pool
            particle:Hide()
            table.insert(UMC.particlePool, table.remove(UMC.activeParticles, i))
        else
            -- Update position
            particle.x = particle.x + (particle.vx * elapsed)
            particle.y = particle.y + (particle.vy * elapsed)
            particle:SetPoint("CENTER", UIParent, "BOTTOMLEFT", particle.x, particle.y)
            
            -- Update rotation
            if particle.rotationSpeed and particle.rotationSpeed ~= 0 then
                particle.rotation = particle.rotation + (particle.rotationSpeed * elapsed)
                -- Note: WoW textures don't have SetRotation, so we'll skip actual rotation
                -- The visual variety comes from movement and fading
            end
            
            -- Update alpha (fade out)
            local progress = particle.lifetime / particle.maxLifetime
            local alpha = progress
            
            -- Pulsing effect for Christmas lights
            if particle.config.pulse then
                particle.pulsePhase = particle.pulsePhase + (elapsed * 3)
                local pulseAlpha = 0.6 + (math.sin(particle.pulsePhase) * 0.4)
                alpha = alpha * pulseAlpha
            end
            
            particle:SetAlpha(alpha)
        end
    end
end

function UMC:UpdateTrail(elapsed)
    -- Check if trail should be visible based on cursor visibility
    local shouldShowTrail = UMC_Config.enableTrail and UMC_CursorFrame and UMC_CursorFrame:IsShown()
    
    if shouldShowTrail then
        local cursorX, cursorY = GetCursorPosition()
        local uiScale = UIParent:GetEffectiveScale()

        local x = cursorX - UMC.trailLastX
        local y = cursorY - UMC.trailLastY
        local movement = math.sqrt(x * x + y * y)

        local minMovement = UMC_Config.trailMinMovement or 0.5
        local density = UMC_Config.trailDensity or 0.008

        UMC.trailTimer = UMC.trailTimer + elapsed

        if UMC.trailTimer >= density and movement >= minMovement and #UMC.trailElements > 0 then
            UMC.trailTimer = 0

            -- Check if we should use seasonal effects
            local trailColorMode = UMC_Config.trailColorMode or "default"
            
            if trailColorMode == "seasonal" then
                local style = UMC_Config.seasonalEffectStyle or "Candy Cane"
                
                -- Spawn more particles for continuous effect (3-5 instead of 1-2)
                local particleCount = math.random(3, 5)
                for i = 1, particleCount do
                    UMC:CreateSeasonalParticle(cursorX, cursorY)
                end
                
                -- Only show colored trail if style is NOT None
                if style ~= "None" then
                    local element = table.remove(UMC.trailElements)
                    table.insert(UMC.trailActive, element)

                    element.duration = UMC_Config.trailDuration or 0.4
                    element.x = cursorX / uiScale
                    element.y = cursorY / uiScale

                    -- Get color based on style
                    local r, g, b = UMC:GetTrailColorForStyle(style)

                    element:SetVertexColor(r, g, b, 1.0)
                    local baseSize = 50 * (UMC_Config.trailScale or 1.0)
                    element:SetSize(baseSize, baseSize)
                    element:SetPoint("CENTER", UIParent, "BOTTOMLEFT", element.x, element.y)
                    element:SetAlpha(0.5)  -- Start at 50% alpha so colors are more visible
                    element:Show()
                end
            else
                -- Regular trail behavior
                local element = table.remove(UMC.trailElements)
                table.insert(UMC.trailActive, element)

                element.duration = UMC_Config.trailDuration or 0.4
                element.x = cursorX / uiScale
                element.y = cursorY / uiScale

                -- Use GetClassColor for trail color
                local r, g, b = UMC:GetClassColor("trail")

                element:SetVertexColor(r, g, b, 1.0)
                local baseSize = 50 * (UMC_Config.trailScale or 1.0)
                element:SetSize(baseSize, baseSize)
                element:SetPoint("CENTER", UIParent, "BOTTOMLEFT", element.x, element.y)
                element:SetAlpha(1.0)
                element:Show()
            end

            UMC.trailLastX = cursorX
            UMC.trailLastY = cursorY
        end
        
        -- Update seasonal particles
        UMC:UpdateSeasonalParticles(elapsed)
    else
        for i = #UMC.trailActive, 1, -1 do
            local element = UMC.trailActive[i]
            element:Hide()
            table.insert(UMC.trailElements, table.remove(UMC.trailActive, i))
        end
        
        -- Hide all seasonal particles when trail is disabled
        for i = #UMC.activeParticles, 1, -1 do
            local particle = UMC.activeParticles[i]
            particle:Hide()
            table.insert(UMC.particlePool, table.remove(UMC.activeParticles, i))
        end
    end

    for i = #UMC.trailActive, 1, -1 do
        local element = UMC.trailActive[i]
        element.duration = element.duration - elapsed

        if element.duration <= 0 then
            element:Hide()
            table.insert(UMC.trailElements, table.remove(UMC.trailActive, i))
        else
            local progress = element.duration / (UMC_Config.trailDuration or 0.4)
            progress = math.min(1.0, math.max(0.0, progress))
            local baseSize = 50 * (UMC_Config.trailScale or 1.0)
            local size = math.max(5, baseSize * progress)
            element:SetSize(size, size)
            element:SetAlpha(progress)
            element:SetPoint("CENTER", UIParent, "BOTTOMLEFT", element.x, element.y)
        end
    end
end

function UMC:IsDragonriding()
    if not IsMounted or not GetShapeshiftFormID then return false end
    if not IsMounted() then
        local form = GetShapeshiftFormID()
        if form ~= 27 and form ~= 29 then 
            return false 
        end
    end
    
    if HasBonusActionBar and GetActionBarPage and HasBonusActionBar() and GetActionBarPage() == 5 then
        return true
    end

    if C_PlayerInfo and C_PlayerInfo.GetGlidingInfo then
        local isGliding, canGlide = C_PlayerInfo.GetGlidingInfo()
        if isGliding or canGlide then
            return true
        end
    end
    
    if IsFlying and IsFlying() then
        return true
    end
    
    return false
end

function UMC:OnUpdate(elapsed)
    if not UMC_CursorFrame then return end
    UMC:BindXMLFrames()

    local uiScale = UIParent:GetScale()
    local groupScale = UMC.currentGroupScale

    local isFixed = (UMC_Config.positionMode == "fixed")
    if UMC_Config.positionMode == "dragonriding" then
        isFixed = UMC:IsDragonriding()
    end

    if not isFixed then
        local cursorX, cursorY = GetCursorPosition()
        local correctedX = (cursorX / uiScale) / groupScale
        local correctedY = (cursorY / uiScale) / groupScale

        UMC_CursorFrame:ClearAllPoints()
        UMC_CursorFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", correctedX, correctedY)
        UMC.wasFixed = false
    else
        UMC_CursorFrame:ClearAllPoints()
        UMC_CursorFrame:SetPoint("CENTER", UIParent, "CENTER", (UMC_Config.positionX or 0) / UMC.currentGroupScale, (UMC_Config.positionY or 0) / UMC.currentGroupScale)
        UMC.wasFixed = true
    end

    UMC:UpdateTrail(elapsed)

    if UMC.pendingGCDUntil then
        if UMC:TryStartGCDAnimation(UMC.pendingGCDSpell, false) then
            UMC.pendingGCDUntil = nil
            UMC.pendingGCDSpell = nil
        elseif GetTime() > UMC.pendingGCDUntil then
            -- Last-resort fallback only after the client had a few frames and
            -- ACTIONBAR_UPDATE_COOLDOWN chances to expose the real GCD.
            -- This keeps haste/reduced-GCD durations accurate whenever the
            -- 61304 dummy cooldown or the fired spell's short cooldown exists.
            UMC:TryStartGCDAnimation(UMC.pendingGCDSpell, true)
            UMC.pendingGCDUntil = nil
            UMC.pendingGCDSpell = nil
        end
    end

    if UMC.pendingCastUntil then
        local startTime, endTime = UMC:GetPlayerCastTimes(UMC.pendingCastChannel)
        if startTime and endTime then
            local duration = (endTime - startTime) / 1000
            if duration > 0.1 then
                UMC:StartCastAnimation(startTime / 1000, duration)
            end
            UMC.pendingCastUntil = nil
            UMC.pendingCastChannel = nil
        elseif GetTime() > UMC.pendingCastUntil then
            UMC.pendingCastUntil = nil
            UMC.pendingCastChannel = nil
        end
    end

    -- Modifier Key Logic
    local shiftDown = IsShiftKeyDown()
    local ctrlDown = IsControlKeyDown()
    local altDown = IsAltKeyDown()

    -- Check for Ping/Crosshair triggers (OnPress)
    if shiftDown and not UMC.lastShiftState then
        if UMC_Config.shiftAction == "Ping with ring" then UMC:PlayPingAnimation("Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
        elseif UMC_Config.shiftAction == "Ping with area" then UMC:PlayPingAnimation("Interface\\Addons\\UltimateMouseCursor\\media\\Reticle_Dot")
        elseif UMC_Config.shiftAction == "Ping with crosshair" then UMC:PlayCrosshairAnimation() end
    end
    if ctrlDown and not UMC.lastCtrlState then
        if UMC_Config.ctrlAction == "Ping with ring" then UMC:PlayPingAnimation("Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
        elseif UMC_Config.ctrlAction == "Ping with area" then UMC:PlayPingAnimation("Interface\\Addons\\UltimateMouseCursor\\media\\Reticle_Dot")
        elseif UMC_Config.ctrlAction == "Ping with crosshair" then UMC:PlayCrosshairAnimation() end
    end
    if altDown and not UMC.lastAltState then
        if UMC_Config.altAction == "Ping with ring" then UMC:PlayPingAnimation("Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
        elseif UMC_Config.altAction == "Ping with area" then UMC:PlayPingAnimation("Interface\\Addons\\UltimateMouseCursor\\media\\Reticle_Dot")
        elseif UMC_Config.altAction == "Ping with crosshair" then UMC:PlayCrosshairAnimation() end
    end

    -- Check for "Show Crosshair" (OnHold)
    local showCrosshair = (shiftDown and UMC_Config.shiftAction == "Show Crosshair") or
                          (ctrlDown and UMC_Config.ctrlAction == "Show Crosshair") or
                          (altDown and UMC_Config.altAction == "Show Crosshair")

    if showCrosshair and UMC.CrosshairFrame then
        UMC.isCrosshairAnimating = false -- Stop animation if it was running
        UMC.CrosshairFrame:Show()
        UMC.CrosshairFrame:SetAlpha(1.0)
        UMC:UpdateCrosshairPosition()
    elseif (not shiftDown and UMC.lastShiftState and UMC_Config.shiftAction == "Show Crosshair") or
           (not ctrlDown and UMC.lastCtrlState and UMC_Config.ctrlAction == "Show Crosshair") or
           (not altDown and UMC.lastAltState and UMC_Config.altAction == "Show Crosshair") then
        -- Just released "Show Crosshair", trigger fade out
        UMC:PlayCrosshairAnimation()
    end

    -- Check for Visibility triggers (OnHold)
    local showRings = false
    if shiftDown and UMC_Config.shiftAction == "Show Rings" then showRings = true end
    if ctrlDown and UMC_Config.ctrlAction == "Show Rings" then showRings = true end
    if altDown and UMC_Config.altAction == "Show Rings" then showRings = true end

    if showRings then
        UMC:UpdateVisibility(true)
    elseif (not shiftDown and UMC.lastShiftState and UMC_Config.shiftAction == "Show Rings") or
           (not ctrlDown and UMC.lastCtrlState and UMC_Config.ctrlAction == "Show Rings") or
           (not altDown and UMC.lastAltState and UMC_Config.altAction == "Show Rings") then
         -- Just released a "Show Rings" key, revert to normal visibility
         UMC:UpdateVisibility()
    end

    UMC.lastShiftState = shiftDown
    UMC.lastCtrlState = ctrlDown
    UMC.lastAltState = altDown

    -- Ping Animation Update
    if UMC.isPingAnimating and UMC.PingFrame then
        UMC.pingTimer = UMC.pingTimer + elapsed
        if UMC.pingTimer >= UMC.pingDuration then
            UMC.isPingAnimating = false
            UMC.PingFrame:Hide()
        else
            local progress = UMC.pingTimer / UMC.pingDuration
            local size = UMC.pingStartSize - ((UMC.pingStartSize - UMC.pingEndSize) * progress)
            local alpha = 1.0 - progress
            
            UMC.PingFrame:SetSize(size, size)
            UMC.PingFrame:SetAlpha(alpha)
            UMC.PingFrame:SetPoint("CENTER", UMC_CursorFrame, "CENTER") 
        end
    end

    -- Crosshair Animation Update
    if UMC.isCrosshairAnimating and UMC.CrosshairFrame then
        UMC.crosshairTimer = UMC.crosshairTimer + elapsed
        if UMC.crosshairTimer >= UMC.crosshairDuration then
            UMC.isCrosshairAnimating = false
            UMC.CrosshairFrame:Hide()
        else
            local progress = UMC.crosshairTimer / UMC.crosshairDuration
            local alpha = 1.0
            if progress > 0.7 then -- Fade out in last 30%
                alpha = 1.0 - ((progress - 0.7) / 0.3)
            end
            
            UMC.CrosshairFrame:SetAlpha(alpha)
            
            UMC:UpdateCrosshairPosition()
        end
    end
end

function UMC:UpdateCrosshairPosition()
    if not UMC.CrosshairFrame then return end
    
    local gap = UMC.crosshairGap * UMC.currentGroupScale
    local cx, cy = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    cx = cx / scale
    cy = cy / scale
    
    -- Top Line
    UMC.CrosshairFrame.Top:ClearAllPoints()
    UMC.CrosshairFrame.Top:SetPoint("TOP", UIParent, "TOPLEFT", cx, 0)
    UMC.CrosshairFrame.Top:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", cx, cy + gap)
    
    -- Bottom Line
    UMC.CrosshairFrame.Bottom:ClearAllPoints()
    UMC.CrosshairFrame.Bottom:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", cx, 0)
    UMC.CrosshairFrame.Bottom:SetPoint("TOP", UIParent, "BOTTOMLEFT", cx, cy - gap)
    
    -- Left Line
    UMC.CrosshairFrame.Left:ClearAllPoints()
    UMC.CrosshairFrame.Left:SetPoint("LEFT", UIParent, "BOTTOMLEFT", 0, cy)
    UMC.CrosshairFrame.Left:SetPoint("RIGHT", UIParent, "BOTTOMLEFT", cx - gap, cy)
    
    -- Right Line
    UMC.CrosshairFrame.Right:ClearAllPoints()
    UMC.CrosshairFrame.Right:SetPoint("RIGHT", UIParent, "BOTTOMRIGHT", 0, cy)
    UMC.CrosshairFrame.Right:SetPoint("LEFT", UIParent, "BOTTOMLEFT", cx + gap, cy)
end

function UMC:PlayPingAnimation(texturePath)
    if not UMC.PingFrame then return end
    if texturePath then
        UMC.PingFrame:SetTexture(texturePath)
    end
    UMC.isPingAnimating = true
    UMC.pingTimer = 0
    UMC.PingFrame:SetSize(UMC.pingStartSize, UMC.pingStartSize)
    UMC.PingFrame:SetAlpha(1.0)
    UMC.PingFrame:Show()
end

function UMC:PlayCrosshairAnimation()
    if not UMC.CrosshairFrame then return end
    UMC.isCrosshairAnimating = true
    UMC.crosshairTimer = 0
    UMC.CrosshairFrame:SetAlpha(1.0)
    UMC.CrosshairFrame:Show()
end







function UMC:UpdateHealthRing()
    if CURRENT_API >= 120000 then return end
    local healthFrame = UMC.HealthFrame
    if not healthFrame then return end

    local currentHealth = UnitHealth("player")
    local maxHealth = UnitHealthMax("player")

    if maxHealth == 0 then return end

    local healthPercent = currentHealth / maxHealth
    local missingHealthPercent = 1 - healthPercent

    local r, g, b
    
    -- Check if health color is locked (always use selected color)
    local healthColorLock = UMC_Config.healthColorLock or false
    
    if healthColorLock or healthPercent > 0.70 then
        -- Use configured health color when locked or when health is high
        local healthColorMode = UMC_Config.healthColorMode or "default"
        if healthColorMode == "class" then
            local _, class = UnitClass("player")
            if class then
                local classColor = RAID_CLASS_COLORS[class]
                if classColor then
                    r, g, b = classColor.r, classColor.g, classColor.b
                else
                    r, g, b = 1.0, 1.0, 1.0  -- Fallback to white
                end
            else
                r, g, b = 1.0, 1.0, 1.0  -- Fallback to white
            end
        elseif healthColorMode == "custom" then
            local customColor = UMC_Config.healthCustomColor or {r = 1.0, g = 1.0, b = 1.0}
            r, g, b = customColor.r, customColor.g, customColor.b
        else
            -- default mode
            r, g, b = 1.0, 1.0, 1.0  -- White
        end
    elseif healthPercent > 0.50 then
        r, g, b = 1.0, 0.788, 0.302
    elseif healthPercent > 0.35 then
        r, g, b = 1.0, 0.451, 0.184
    else
        r, g, b = 0.8, 0.0, 0.02
    end

    UMC:CallWidgetMethod(healthFrame, "SetSwipeColor", r, g, b, 0.8)

    -- Clear previous cooldown state before setting new one
    healthFrame:SetCooldown(0, 0)
    UMC:CallWidgetMethod(healthFrame, "Clear")
    local hugeDuration = 86400
    local elapsed = missingHealthPercent * hugeDuration
    UMC:FixCooldownCaptureSize(healthFrame)
    healthFrame:SetCooldown(GetTime() - elapsed, hugeDuration)
    UMC:ShowCooldownWidget(healthFrame)

    UMC.lastHealthPercent = healthPercent
end

function UMC:HealthEventHandler(self, event, unit)
    if unit and unit ~= "player" then return end

    UMC:UpdateHealthRing()
end

function UMC:UpdatePowerRing()
    if CURRENT_API >= 120000 then return end
    local powerFrame = UMC.PowerFrame
    if not powerFrame then return end

    local currentPower = UnitPower("player")
    local maxPower = UnitPowerMax("player")

    if maxPower == 0 then return end

    local powerPercent = currentPower / maxPower
    local missingPowerPercent = 1 - powerPercent

    -- Get color using GetClassColor system
    local r, g, b = UMC:GetClassColor("power")
    
    -- If GetClassColor returned nil (power mode), use power type colors
    if not r then
        local powerType, powerToken = UnitPowerType("player")
        
        if powerType == 0 then
            r, g, b = 0.00, 0.00, 1.00  -- Mana
        elseif powerType == 1 then
            r, g, b = 1.00, 0.00, 0.00  -- Rage
        elseif powerType == 2 then
            r, g, b = 1.00, 0.50, 0.25  -- Focus
        elseif powerType == 3 then
            r, g, b = 1.00, 1.00, 0.00  -- Energy
        elseif powerType == 4 then
            r, g, b = 1.00, 0.96, 0.41  -- Combo Points
        elseif powerType == 5 then
            r, g, b = 0.50, 0.50, 0.50  -- Runes
        elseif powerType == 6 then
            r, g, b = 0.00, 0.82, 1.00  -- Runic Power
        elseif powerType == 7 then
            r, g, b = 0.50, 0.32, 0.55  -- Soul Shards
        elseif powerType == 8 then
            r, g, b = 0.30, 0.52, 0.90  -- Lunar Power
        elseif powerType == 9 then
            r, g, b = 0.95, 0.90, 0.60  -- Holy Power
        elseif powerType == 11 then
            r, g, b = 0.00, 0.50, 1.00  -- Maelstrom
        elseif powerType == 13 then
            r, g, b = 0.40, 0.00, 0.80  -- Insanity
        elseif powerType == 12 then
            r, g, b = 0.71, 1.00, 0.92  -- Chi
        elseif powerType == 16 then
            r, g, b = 0.10, 0.10, 0.98  -- Arcane Charges
        elseif powerType == 17 then
            r, g, b = 0.788, 0.259, 0.992  -- Fury
        elseif powerType == 18 then
            r, g, b = 1.00, 0.61, 0.00  -- Pain
        else
            r, g, b = 0.00, 0.00, 1.00  -- Default to mana blue
        end
    end

    UMC:CallWidgetMethod(powerFrame, "SetSwipeColor", r, g, b, 0.8)

    local hugeDuration = 86400
    local elapsed = missingPowerPercent * hugeDuration
    UMC:FixCooldownCaptureSize(powerFrame)
    powerFrame:SetCooldown(GetTime() - elapsed, hugeDuration)
    UMC:ShowCooldownWidget(powerFrame)

    UMC.lastPowerPercent = powerPercent
end

function UMC:PowerEventHandler(self, event, unit)
    if unit and unit ~= "player" then return end

    UMC:UpdatePowerRing()
end

function UMC:StartGCDAnimation(startTime, duration)
    if not UMC.GCDCooldownFrame then return end
    if not UMC.enableGCD then return end
    
    UMC.isGCDAnimating = true
    
    -- Simple fill/drain control
    local fillDrain = UMC_Config.gcdFillDrain or "drain"
    UMC:CallWidgetMethod(UMC.GCDCooldownFrame, "SetReverse", fillDrain == "fill")

    local visualDuration = duration or 0
    -- ClassicAPI's cooldown capture adds a small 0.2s padding for normal
    -- action-button bling.  The custom Wrath arc renderer does not, but keep
    -- this compensation for any fallback Cooldown widgets.
    if UMC.IS_WRATH_335 and not UMC.GCDCooldownFrame.UMC_IsArcCooldown and visualDuration > 0.25 then
        visualDuration = visualDuration - 0.20
    end
    
    UMC:FixCooldownCaptureSize(UMC.GCDCooldownFrame)
    UMC.GCDCooldownFrame:SetCooldown(startTime, visualDuration)
    UMC:ShowCooldownWidget(UMC.GCDCooldownFrame)
end











function UMC:StartCastAnimation(startTime, duration)
    if not UMC.CastFrame then return end
    if not UMC.enableCast then return end
    
    UMC.isCasting = true
    
    -- Detect if this is a channel or regular cast
    local isChanneling = UnitChannelInfo("player") ~= nil
    
    -- For channels, automatically reverse the fill/drain behavior
    local fillDrain = UMC_Config.castFillDrain or "fill"
    local shouldReverse = (fillDrain == "fill")
    
    -- Invert for channels to create the opposite visual effect
    if isChanneling then
        shouldReverse = not shouldReverse
    end
    
    UMC:CallWidgetMethod(UMC.CastFrame, "SetReverse", shouldReverse)

    local visualDuration = duration or 0
    -- ClassicAPI pads CooldownCapture by roughly 0.2s.  That makes cast rings
    -- get hidden by UNIT_SPELLCAST_STOP before the swipe reaches the end.
    -- The custom arc renderer uses exact timing; this only affects fallback
    -- ClassicAPI cooldown widgets.
    if UMC.IS_WRATH_335 and not UMC.CastFrame.UMC_IsArcCooldown and visualDuration > 0.25 then
        visualDuration = visualDuration - 0.20
    end
    
    UMC:FixCooldownCaptureSize(UMC.CastFrame)
    UMC.CastFrame:SetCooldown(startTime, visualDuration)
    UMC:ShowCooldownWidget(UMC.CastFrame)
end




function UMC:StopCastAnimation(success)
    if not UMC.CastFrame then return end

    -- A failed/interrupted cast can be followed by a STOP event on some 3.3.5a
    -- cores.  Do not play a completion frame after we already hid it.
    if success and not UMC.isCasting then return end
    
    UMC.isCasting = false

    -- With the custom arc renderer, show the final arc state for a tiny fraction
    -- of a second so the circle does not appear to disappear just before it
    -- reaches completion at low frame rates.
    if success and UMC.CastFrame.Complete then
        UMC.CastFrame:Complete(UMC.WRATH_CAST_FINISH_HOLD or 0.045)
        return
    end

    UMC:CallWidgetMethod(UMC.CastFrame, "Clear")
    UMC:HideCooldownWidget(UMC.CastFrame)
end

function UMC:TryStartGCDAnimation(spellName, allowFallback)
    if not UMC.enableGCD then return false end

    local GCDInfo = UMC.GetSpellCooldownCompat and UMC:GetSpellCooldownCompat(GCD_SPELL_ID) or nil

    -- Some 3.3.5a cores do not expose spell 61304 to the UI.  Fall back to
    -- the spell that fired the event, but only accept short cooldowns that look
    -- like the global cooldown rather than a real ability cooldown.
    if (not GCDInfo or not GCDInfo.duration or GCDInfo.duration <= 0) and spellName and UMC.GetSpellCooldownCompat then
        local spellInfo = UMC:GetSpellCooldownCompat(spellName)
        if spellInfo and spellInfo.duration and spellInfo.duration > 0 and spellInfo.duration <= (GCD_DURATION + 0.5) then
            GCDInfo = spellInfo
        end
    end

    if GCDInfo and GCDInfo.duration and GCDInfo.duration > 0 then
        if GetTime() - UMC.lastGCDTime < 0.05 then return true end
        UMC.lastGCDTime = GetTime()
        UMC:StartGCDAnimation(GCDInfo.startTime or 0, GCDInfo.duration)
        return true
    end

    if allowFallback then
        if GetTime() - UMC.lastGCDTime < 0.05 then return true end
        UMC.lastGCDTime = GetTime()
        UMC:StartGCDAnimation(GetTime(), GCD_DURATION)
        return true
    end

    return false
end

function UMC:GCDCastHandler(self, event, unit, spellName, spellId)
    --if CURRENT_API >= 120000 then return end
    if event ~= "ACTIONBAR_UPDATE_COOLDOWN" and unit and unit ~= "player" then return end

    -- Do not use the static 1.5s fallback immediately on spellcast events.
    -- GetSpellCooldown(61304) is often populated a frame or two later, and
    -- that real duration is what carries haste, presence/stance, and other
    -- reduced-GCD effects. ACTIONBAR_UPDATE_COOLDOWN is registered below as
    -- an additional "cooldowns are now refreshed" signal.
    if UMC:TryStartGCDAnimation(spellName, false) then
        UMC.pendingGCDUntil = nil
        UMC.pendingGCDSpell = nil
        return
    end

    if event == "ACTIONBAR_UPDATE_COOLDOWN" then
        -- Only use this as a follow-up to a player spellcast; otherwise normal
        -- cooldown refreshes could create a fake GCD after the retry expires.
        return
    end

    if event == "UNIT_SPELLCAST_SENT"
       or event == "UNIT_SPELLCAST_SUCCEEDED"
       or event == "UNIT_SPELLCAST_CHANNEL_START" then
        UMC.pendingGCDUntil = GetTime() + 0.35
        if spellName then UMC.pendingGCDSpell = spellName end
    end
end

function UMC:CastEventHandler(self, event, unit) 
    if unit and unit ~= "player" then return end

    local startTime, endTime, infoValid = nil, nil, false

    if event == "UNIT_SPELLCAST_START" then
        if UMC.GetPlayerCastTimes then
            startTime, endTime = UMC:GetPlayerCastTimes(false)
        end
        infoValid = true

    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        if UMC.GetPlayerCastTimes then
            startTime, endTime = UMC:GetPlayerCastTimes(true)
        end
        infoValid = true
    end

    if infoValid and startTime and endTime then
        local duration = (endTime - startTime) / 1000 

        if duration > 0.1 then 
            UMC:StartCastAnimation(startTime / 1000, duration)
        end

    elseif infoValid then
        -- 3.3.5a can fire the spellcast event one frame before UnitCastingInfo
        -- is populated, especially immediately after login/reload.
        UMC.pendingCastUntil = GetTime() + 0.20
        UMC.pendingCastChannel = (event == "UNIT_SPELLCAST_CHANNEL_START")

    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        UMC.pendingCastUntil = nil
        UMC.pendingCastChannel = nil
        UMC:StopCastAnimation(true)

    elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        UMC.pendingCastUntil = nil
        UMC.pendingCastChannel = nil
        UMC:StopCastAnimation(false)
    end
end

function UMC:UpdateVisibility(forceState)
    if not UMC_CursorFrame then return end

    -- Check Modifiers first (Override - Always Show)
    local shiftDown = IsShiftKeyDown()
    local ctrlDown = IsControlKeyDown()
    local altDown = IsAltKeyDown()
    
    local modifierShow = (shiftDown and UMC_Config.shiftAction == "Show Rings") or
                         (ctrlDown and UMC_Config.ctrlAction == "Show Rings") or
                         (altDown and UMC_Config.altAction == "Show Rings")

    if modifierShow then
        UMC_CursorFrame:Show()
        return
    end

    -- Check Combat State
    local inCombat = forceState
    if inCombat == nil then
        inCombat = InCombatLockdown()
    end

    -- Determine Base Visibility
    if UMC_Config.showOnlyInCombat then
        if inCombat then
            UMC_CursorFrame:Show()
        else
            UMC_CursorFrame:Hide()
        end
    else
        -- Show Only In Combat is FALSE (Normally Always Visible)
        -- BUT, if any key is configured to "Show Rings", we want to hide it by default
        -- so that the key press actually does something (Push-to-Show).
        
        local isAnyShowRingsConfigured = (UMC_Config.shiftAction == "Show Rings") or
                                         (UMC_Config.ctrlAction == "Show Rings") or
                                         (UMC_Config.altAction == "Show Rings")
                                         
        if isAnyShowRingsConfigured then
            UMC_CursorFrame:Hide()
        else
            UMC_CursorFrame:Show()
        end
    end
end

function UMC:ResetCooldownFrames()
    -- Stop any running animations
    UMC.isGCDAnimating = false
    UMC.isCasting = false
    UMC.gcdCompletionTime = nil
    UMC.castCompletionTime = nil
    
    -- Destroy old GCD frames
    if UMC.GCDCooldownFrame then
        UMC:DestroyCooldownWidget(UMC.GCDCooldownFrame)
        UMC.GCDCooldownFrame = nil
    end
    if UMC.GCDBackgroundFrame then
        UMC:DestroyCooldownWidget(UMC.GCDBackgroundFrame)
        UMC.GCDBackgroundFrame = nil
    end
    
    -- Destroy old Cast frames
    if UMC.CastFrame then
        UMC:DestroyCooldownWidget(UMC.CastFrame)
        UMC.CastFrame = nil
    end
    if UMC.CastBackgroundFrame then
        UMC:DestroyCooldownWidget(UMC.CastBackgroundFrame)
        UMC.CastBackgroundFrame = nil
    end
    
    local timestamp = GetTime()
    
    -- Recreate GCD Background Frame
    local gcdBgFrame = UMC:CreateStaticRingFrame(nil, UMC_CursorFrame, 70, "Interface\\AddOns\\UltimateMouseCursor\\media\\Ring_Main", 0.5, 0.5, 0.5, 0.7, 2)
    UMC.GCDBackgroundFrame = gcdBgFrame
    UMC:CallWidgetMethod(gcdBgFrame, "SetSwipeTexture", "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    UMC:CallWidgetMethod(gcdBgFrame, "SetSwipeColor", 0.5, 0.5, 0.5, 0.7)
    UMC:CallWidgetMethod(gcdBgFrame, "SetReverse", false)
    UMC:CallWidgetMethod(gcdBgFrame, "SetHideCountdownNumbers", true)
    -- Set a cooldown that already finished to show as a static full circle
    UMC:FixCooldownCaptureSize(gcdBgFrame)
    gcdBgFrame:SetCooldown(GetTime() - 1, 0.01)
    gcdBgFrame:Hide()

    -- Recreate GCD Cooldown Frame
    local cooldownFrame = UMC:CreateArcCooldownFrame(nil, UMC_CursorFrame, 50, "gcd", 4)
    UMC.GCDCooldownFrame = cooldownFrame
    UMC:CallWidgetMethod(cooldownFrame, "SetSwipeTexture", "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    local r, g, b = UMC:GetClassColor("gcd")
    UMC:CallWidgetMethod(cooldownFrame, "SetSwipeColor", r, g, b, 1.0)
    UMC:CallWidgetMethod(cooldownFrame, "SetHideCountdownNumbers", true)
    
    -- Apply rotation from clock position and direction
    local gcdRotation = UMC_Config.gcdRotation or 12
    local gcdDirection = UMC_Config.gcdDirection or "clockwise"
    local gcdFillDrain = UMC_Config.gcdFillDrain or "drain"
    UMC:CallWidgetMethod(cooldownFrame, "SetRotation", UMC:ClockToRadians(gcdRotation, gcdDirection, gcdFillDrain))
    
    cooldownFrame:Hide()

    -- Recreate Cast Background Frame
    local castBgFrame = UMC:CreateStaticRingFrame(nil, UMC_CursorFrame, 70, "Interface\\AddOns\\UltimateMouseCursor\\media\\Ring_Main", 0.5, 0.5, 0.5, 0.7, 2)
    UMC.CastBackgroundFrame = castBgFrame
    UMC:CallWidgetMethod(castBgFrame, "SetSwipeTexture", "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    UMC:CallWidgetMethod(castBgFrame, "SetSwipeColor", 0.5, 0.5, 0.5, 0.7)
    UMC:CallWidgetMethod(castBgFrame, "SetReverse", false)
    UMC:CallWidgetMethod(castBgFrame, "SetHideCountdownNumbers", true)
    -- Set a cooldown that already finished to show as a static full circle
    UMC:FixCooldownCaptureSize(castBgFrame)
    castBgFrame:SetCooldown(GetTime() - 1, 0.01)
    castBgFrame:Hide()

    -- Recreate Cast Frame
    local castFrame = UMC:CreateArcCooldownFrame(nil, UMC_CursorFrame, 90, "cast", 4)
    UMC.CastFrame = castFrame
    UMC:CallWidgetMethod(castFrame, "SetSwipeTexture", "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    r, g, b = UMC:GetClassColor("cast")
    UMC:CallWidgetMethod(castFrame, "SetSwipeColor", r, g, b, 1.0)
    UMC:CallWidgetMethod(castFrame, "SetHideCountdownNumbers", true)
    
    -- Apply rotation from clock position and direction
    local castRotation = UMC_Config.castRotation or 12
    local castDirection = UMC_Config.castDirection or "clockwise"
    local castFillDrain = UMC_Config.castFillDrain or "drain"
    UMC:CallWidgetMethod(castFrame, "SetRotation", UMC:ClockToRadians(castRotation))
    
    castFrame:Hide()
    UMC:UpdateRingTextures()
    
    -- Reapply settings to ensure correct ring sizes (e.g., Main Ring + Cast)
    if UMC.ApplySettings then
        UMC:ApplySettings()
    end
end

function UMC:SetupUI()

    UMC:BindXMLFrames()

    if not UMC_CursorFrame then return end

    local transparency = UMC_Config.transparency or 1.0
    UMC_CursorFrame:SetAlpha(transparency)
    
    if UMC_Config.positionMode == "fixed" then
        UMC_CursorFrame:ClearAllPoints()
        -- We anchor relative to CENTER since 'Reset to Center' uses mostly 0,0 offset
        UMC_CursorFrame:SetPoint("CENTER", UIParent, "CENTER", (UMC_Config.positionX or 0) / UMC.currentGroupScale, (UMC_Config.positionY or 0) / UMC.currentGroupScale)
    end
    UMC_CursorFrame:SetFrameStrata("HIGH")
    UMC_CursorFrame:SetToplevel(false)
    UMC_CursorFrame:Show()
    UMC:SetGroupScale(UMC.currentGroupScale)
    if UMC_CursorFrame.MainRing then
        UMC_CursorFrame.MainRing:Show()
    end
    
    UMC:UpdateReticle()

    local gcdBgFrame = UMC:CreateStaticRingFrame("UMC_GCD_BG_COOLDOWN", UMC_CursorFrame, 70, "Interface\\AddOns\\UltimateMouseCursor\\media\\Ring_Main", 0.5, 0.5, 0.5, 0.7, 2)
    UMC.GCDBackgroundFrame = gcdBgFrame
    UMC:CallWidgetMethod(gcdBgFrame, "SetSwipeTexture", "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    UMC:CallWidgetMethod(gcdBgFrame, "SetSwipeColor", 0.5, 0.5, 0.5, 0.7)
    UMC:CallWidgetMethod(gcdBgFrame, "SetReverse", false)
    UMC:CallWidgetMethod(gcdBgFrame, "SetHideCountdownNumbers", true)
    -- Set a cooldown that already finished to show as a static full circle
    UMC:FixCooldownCaptureSize(gcdBgFrame)
    gcdBgFrame:SetCooldown(GetTime() - 1, 0.01)
    gcdBgFrame:Hide()

    local cooldownFrame = UMC:CreateArcCooldownFrame("UMC_GCD_COOLDOWN", UMC_CursorFrame, 50, "gcd", 4)
    UMC.GCDCooldownFrame = cooldownFrame
    UMC:CallWidgetMethod(cooldownFrame, "SetSwipeTexture", "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    local r, g, b = UMC:GetClassColor("gcd")
    UMC:CallWidgetMethod(cooldownFrame, "SetSwipeColor", r, g, b, 1.0)
    UMC:CallWidgetMethod(cooldownFrame, "SetHideCountdownNumbers", true)
    
    -- Apply rotation from clock position and direction
    local gcdRotation = UMC_Config.gcdRotation or 12
    local gcdDirection = UMC_Config.gcdDirection or "clockwise"
    local gcdFillDrain = UMC_Config.gcdFillDrain or "drain"
    UMC:CallWidgetMethod(cooldownFrame, "SetRotation", UMC:ClockToRadians(gcdRotation, gcdDirection, gcdFillDrain))
    
    cooldownFrame:Hide()

    local castBgFrame = UMC:CreateStaticRingFrame("UMC_CAST_BG_COOLDOWN", UMC_CursorFrame, 70, "Interface\\AddOns\\UltimateMouseCursor\\media\\Ring_Main", 0.5, 0.5, 0.5, 0.7, 2)
    UMC.CastBackgroundFrame = castBgFrame
    UMC:CallWidgetMethod(castBgFrame, "SetSwipeTexture", "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    UMC:CallWidgetMethod(castBgFrame, "SetSwipeColor", 0.5, 0.5, 0.5, 0.7)
    UMC:CallWidgetMethod(castBgFrame, "SetReverse", false)
    UMC:CallWidgetMethod(castBgFrame, "SetHideCountdownNumbers", true)
    -- Set a cooldown that already finished to show as a static full circle
    UMC:FixCooldownCaptureSize(castBgFrame)
    castBgFrame:SetCooldown(GetTime() - 1, 0.01)
    castBgFrame:Hide()

    local castFrame = UMC:CreateArcCooldownFrame("UMC_CAST_COOLDOWN", UMC_CursorFrame, 90, "cast", 4)
    UMC.CastFrame = castFrame
    UMC:CallWidgetMethod(castFrame, "SetSwipeTexture", "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    r, g, b = UMC:GetClassColor("cast")
    UMC:CallWidgetMethod(castFrame, "SetSwipeColor", r, g, b, 1.0)
    UMC:CallWidgetMethod(castFrame, "SetHideCountdownNumbers", true)
    
    -- Apply rotation from clock position and direction
    local castRotation = UMC_Config.castRotation or 12
    local castDirection = UMC_Config.castDirection or "clockwise"
    local castFillDrain = UMC_Config.castFillDrain or "drain"
    UMC:CallWidgetMethod(castFrame, "SetRotation", UMC:ClockToRadians(castRotation, castDirection, castFillDrain))
    
    castFrame:Hide()

    -- Health Background - use Texture instead of Cooldown since it's always full
    local healthBgFrame = UMC_CursorFrame:CreateTexture(nil, "ARTWORK")
    healthBgFrame:SetSize(70, 70)
    healthBgFrame:SetPoint("CENTER", UMC_CursorFrame, "CENTER")
    healthBgFrame:SetTexture("Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    healthBgFrame:SetVertexColor(0.5, 0.5, 0.5, 0.7)
    UMC.HealthBackgroundFrame = healthBgFrame
    healthBgFrame:Hide()

    local healthFrame = UMC:CreateCooldownWidget("UMC_HEALTH_COOLDOWN", 70, 3)
    UMC.HealthFrame = healthFrame
    UMC:CallWidgetMethod(healthFrame, "SetSwipeTexture", "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    UMC:CallWidgetMethod(healthFrame, "SetSwipeColor", 1.0, 0.0, 0.0, 0.8)
    UMC:CallWidgetMethod(healthFrame, "SetReverse", false)
    UMC:CallWidgetMethod(healthFrame, "SetHideCountdownNumbers", true)
    healthFrame:Hide()

    local powerFrame = UMC:CreateCooldownWidget("UMC_POWER_COOLDOWN", 80, 1)
    UMC.PowerFrame = powerFrame
    UMC:CallWidgetMethod(powerFrame, "SetSwipeTexture", "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    UMC:CallWidgetMethod(powerFrame, "SetSwipeColor", 0.0, 0.5, 1.0, 0.8)
    UMC:CallWidgetMethod(powerFrame, "SetReverse", false)
    UMC:CallWidgetMethod(powerFrame, "SetHideCountdownNumbers", true)
    UMC:CallWidgetMethod(powerFrame, "SetHideCountdownNumbers", true)
    powerFrame:Hide()

    local pingFrame = UMC_CursorFrame:CreateTexture(nil, "OVERLAY")
    pingFrame:SetTexture("Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    pingFrame:SetBlendMode("ADD")
    pingFrame:SetVertexColor(1.0, 1.0, 1.0, 0.5)
    pingFrame:Hide()
    UMC.PingFrame = pingFrame

    -- Crosshair Frame
    local crosshairFrame = CreateFrame("Frame", "UMC_CrosshairFrame", UIParent)
    crosshairFrame:SetFrameStrata("BACKGROUND")
    crosshairFrame:SetAllPoints()
    crosshairFrame:EnableMouse(false)
    crosshairFrame:Hide()
    UMC.CrosshairFrame = crosshairFrame

    local function CreateLine(name)
        local line = crosshairFrame:CreateTexture(nil, "OVERLAY")
        if line.SetColorTexture then
            line:SetColorTexture(1, 1, 1, 0.5)
        else
            line:SetTexture(1, 1, 1, 0.5)
        end
        line:SetWidth(2) -- Thickness
        return line
    end

    crosshairFrame.Top = CreateLine("Top")
    crosshairFrame.Bottom = CreateLine("Bottom")
    crosshairFrame.Left = CreateLine("Left")
    crosshairFrame.Right = CreateLine("Right")
    
    -- Adjust line thickness for horizontal lines (height instead of width)
    crosshairFrame.Left:SetWidth(0) -- Reset width
    crosshairFrame.Left:SetHeight(2)
    crosshairFrame.Right:SetWidth(0)
    crosshairFrame.Right:SetHeight(2)



    UMC:UpdateHealthRing()
    UMC:UpdatePowerRing()

    UMC:InitializeTrail()
    UMC:InitializeSeasonalParticles()
    
    UMC:UpdateRingTextures()

    if UMC.ApplySettings then
        UMC:ApplySettings()
    end

    TrackerFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function UMC:OnInitialize()
    UMC.TrackerFrame = TrackerFrame

    TrackerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    TrackerFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    TrackerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")


    TrackerFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            if UMC_CursorFrame then
                UMC:SetupUI()
            end

        elseif event:match("UNIT_SPELLCAST_") then 
            UMC:GCDCastHandler(self, event, ...)
            UMC:CastEventHandler(self, event, ...) 

        elseif event == "ACTIONBAR_UPDATE_COOLDOWN" then
            UMC:GCDCastHandler(self, event, ...)

        elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
            UMC:HealthEventHandler(self, event, ...)

        elseif UMC.IsPowerEvent and UMC:IsPowerEvent(event) then
            UMC:PowerEventHandler(self, event, ...)

        elseif event == "PLAYER_REGEN_DISABLED" then
            UMC.isPlayerInCombat = true
            UMC:UpdateVisibility(true)
            UMC:UpdateRingColors()
        elseif event == "PLAYER_REGEN_ENABLED" then
            UMC.isPlayerInCombat = false
            UMC:UpdateVisibility(false)
            UMC:UpdateRingColors()
        end
    end)

    TrackerFrame:SetScript("OnUpdate", UMC.OnUpdate)
    TrackerFrame:Show()
end

LoaderFrame:SetScript("OnEvent", function(self, event, addon)
    if event == "ADDON_LOADED" and addon == "UltimateMouseCursor" then
        UMC:InitializeSettings()
        UMC:OnInitialize()
        UMC:CreateSettingsPanel()
        self:UnregisterAllEvents()
    end
end)
LoaderFrame:RegisterEvent("ADDON_LOADED")
