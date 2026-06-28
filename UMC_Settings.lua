UMC_Config = UMC_Config or {}

UltimateMouseCursor = UltimateMouseCursor or {}
local UMC = UltimateMouseCursor


function UMC:InitializeSettings()
    if not UMC_Config then
        UMC_Config = {}
    end
    
    for key, value in pairs(UMC.defaults) do
        if UMC_Config[key] == nil then
            UMC_Config[key] = value
        end
    end
end

function UMC:GetConfig()
    return UMC_Config
end

function UMC:CreateSettingsPanel()
    local panel = CreateFrame("Frame", "UMC_SettingsPanel")
    panel.name = "Ultimate Mouse Cursor"
    
    function panel.OnCommit() end
    function panel.OnDefault() end
    function panel.OnRefresh() end
    -- 3.3.5a Interface Options use these older callback names.
    panel.okay = panel.OnCommit
    panel.default = panel.OnDefault
    panel.refresh = panel.OnRefresh
    
    local scrollFrame = CreateFrame("ScrollFrame", "UMC_SettingsScrollFrame", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 3, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", -27, 4)
    
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(640, 1500)
    scrollFrame:SetScrollChild(content)
    
    local function CreateSeparator(parent, text, anchor, relativeFrame, xOffset, yOffset)
        local separator = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        separator:SetPoint(anchor, relativeFrame, "BOTTOMLEFT", xOffset, yOffset)
        separator:SetText(text)
        separator:SetTextColor(1.0, 0.82, 0, 1)
        
        local line = content:CreateTexture(nil, "ARTWORK")
        if line.SetColorTexture then
            line:SetColorTexture(0.5, 0.5, 0.5, 0.5)
        else
            line:SetTexture(0.5, 0.5, 0.5, 0.5)
        end
        line:SetHeight(1)
        line:SetPoint("LEFT", separator, "RIGHT", 5, 0)
        line:SetPoint("RIGHT", content, "RIGHT", -20, 0)
        
        return separator
    end
    
    local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Ultimate Mouse Cursor Settings")
    
    local function CreateDropdown(name, label, yOffset, defaultValue)
        local dropdown = CreateFrame("Frame", name, content, "UIDropDownMenuTemplate")
        -- We will set the point later based on the section
        
        local labelText = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        labelText:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 20, 0)
        labelText:SetText(label)
        
        UIDropDownMenu_SetWidth(dropdown, 120)
        UIDropDownMenu_SetText(dropdown, defaultValue or "")
        
        return dropdown
    end

    local function OnDropdownClick(self, dropdown, configKey)
        UMC_Config[configKey] = self.value
        UIDropDownMenu_SetText(dropdown, self.value)
        UMC:ApplySettings()
        CloseDropDownMenus()
    end
    
    -- Helper function to create color picker button
    local function CreateColorPickerButton(parent, configKey, modeKey, updateFunc)
        local button = CreateFrame("Button", nil, parent)
        button:SetSize(16, 16)
        
        local swatch = button:CreateTexture(nil, "OVERLAY")
        swatch:SetAllPoints()
        if swatch.SetColorTexture then
            swatch:SetColorTexture(1, 1, 1)
        else
            swatch:SetTexture(1, 1, 1, 1)
        end
        button.swatch = swatch
        
        local border = button:CreateTexture(nil, "BACKGROUND")
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        if border.SetColorTexture then
            border:SetColorTexture(0.5, 0.5, 0.5)
        else
            border:SetTexture(0.5, 0.5, 0.5, 1)
        end
        
        local function UpdateButtonColor()
            local c = UMC_Config[configKey]
            if c then
                swatch:SetVertexColor(c.r, c.g, c.b)
            else
                swatch:SetVertexColor(1, 1, 1)
            end
        end
        
        button:SetScript("OnClick", function()
            local r, g, b = 1, 1, 1
            if UMC_Config[configKey] then
                r, g, b = UMC_Config[configKey].r, UMC_Config[configKey].g, UMC_Config[configKey].b
            end
            
            local info = {
                r = r, g = g, b = b,
                hasOpacity = false,
                swatchFunc = function()
                    local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                    UMC_Config[configKey] = {r = newR, g = newG, b = newB}
                    UpdateButtonColor()
                    if updateFunc then updateFunc() end
                end,
                cancelFunc = function()
                    UMC_Config[configKey] = {r = r, g = g, b = b}
                    UpdateButtonColor()
                    if updateFunc then updateFunc() end
                end,
            }
            
            ColorPickerFrame:SetupColorPickerAndShow(info)
        end)
        
        UpdateButtonColor()
        button.UpdateColor = UpdateButtonColor
        
        return button
    end
    
    -- Helper function to create color mode dropdown
    local function CreateColorModeDropdown(parent, label, colorModeKey, customColorKey, anchorPoint, relativeFrame, xOffset, yOffset, updateFunc, defaultText)
        local dropdownName = "UMC_" .. tostring(colorModeKey or customColorKey or "ColorMode") .. "Dropdown"
        local dropdown = CreateFrame("Frame", dropdownName, parent, "UIDropDownMenuTemplate")
        dropdown:SetPoint(anchorPoint, relativeFrame, "BOTTOMLEFT", xOffset, yOffset)
        
        local labelText = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        labelText:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 20, 0)
        labelText:SetText(label)
        
        UIDropDownMenu_SetWidth(dropdown, 120)
        
        local colorButton = CreateColorPickerButton(content, customColorKey, colorModeKey, updateFunc)
        colorButton:SetPoint("LEFT", dropdown, "RIGHT", 10, 2)
        
        -- Show/hide color button based on mode
        local function UpdateColorButtonState()
            local mode = UMC_Config[colorModeKey] or "default"
            if mode == "custom" then
                colorButton:Show()
                colorButton:Enable()
            else
                colorButton:Hide()
            end
        end
        
        -- Use custom default text or fall back to "Default (White)"
        local defaultOptionText = defaultText or "Default (White)"
        
        UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
            local info = UIDropDownMenu_CreateInfo()
            local options = {defaultOptionText, "Class Color", "Custom Color"}
            local values = {"default", "class", "custom"}
            
            for i, option in ipairs(options) do
                info.text = option
                info.checked = (UMC_Config[colorModeKey] == values[i])
                info.func = function()
                    UMC_Config[colorModeKey] = values[i]
                    UIDropDownMenu_SetText(dropdown, option)
                    UpdateColorButtonState()
                    if updateFunc then updateFunc() end
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        
        -- Set initial text
        local currentMode = UMC_Config[colorModeKey] or "default"
        local modeText = currentMode == "default" and defaultOptionText or 
                        currentMode == "class" and "Class Color" or "Custom Color"
        UIDropDownMenu_SetText(dropdown, modeText)
        UpdateColorButtonState()
        
        return dropdown, colorButton
    end

    -- Helper function to create texture selection dropdown
    local function CreateTextureDropdown(parent, label, configKey, anchorPoint, relativeFrame, xOffset, yOffset, updateFunc)
        local dropdownName = "UMC_" .. tostring(configKey or "Texture") .. "Dropdown"
        local dropdown = CreateFrame("Frame", dropdownName, parent, "UIDropDownMenuTemplate")
        dropdown:SetPoint(anchorPoint, relativeFrame, "BOTTOMLEFT", xOffset, yOffset)
        
        local labelText = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        labelText:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 20, 0)
        labelText:SetText(label)
        
        UIDropDownMenu_SetWidth(dropdown, 120)
        
        UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
            local info = UIDropDownMenu_CreateInfo()
            for _, option in ipairs(UMC.ringTextureOptions) do
                info.text = option
                info.checked = (UMC_Config[configKey] == option)
                info.func = function()
                    UMC_Config[configKey] = option
                    UIDropDownMenu_SetText(dropdown, option)
                    if updateFunc then updateFunc() end
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        
        UIDropDownMenu_SetText(dropdown, UMC_Config[configKey] or "")
        
        return dropdown
    end

    -- 1. Ring Slot Assignment
    local ringSeparator = CreateSeparator(content, "Ring Slot Assignment", "TOPLEFT", title, 0, -20)
    
    -- Inner Ring Dropdown
    local innerDropdown = CreateDropdown("UMC_InnerRingDropdown", "Inner Ring (Small)", 0, UMC_Config.innerRing)
    innerDropdown:SetPoint("TOPLEFT", ringSeparator, "BOTTOMLEFT", 0, -25)
    
    UIDropDownMenu_Initialize(innerDropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        for _, option in ipairs(UMC.ringOptions) do
            info.text = option
            info.checked = (UMC_Config.innerRing == option)
            info.func = function()
                UMC_Config.innerRing = option
                UIDropDownMenu_SetText(innerDropdown, option)
                if UMC.ApplySettings then UMC:ApplySettings() end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Main Ring Dropdown
    local mainDropdown = CreateDropdown("UMC_MainRingDropdown", "Main Ring (Medium)", 0, UMC_Config.mainRing)
    mainDropdown:SetPoint("TOPLEFT", innerDropdown, "BOTTOMLEFT", 0, -25)
    
    UIDropDownMenu_Initialize(mainDropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        for _, option in ipairs(UMC.ringOptions) do
            info.text = option
            info.checked = (UMC_Config.mainRing == option)
            info.func = function()
                UMC_Config.mainRing = option
                UIDropDownMenu_SetText(mainDropdown, option)
                if UMC.ApplySettings then UMC:ApplySettings() end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Outer Ring Dropdown
    local outerDropdown = CreateDropdown("UMC_OuterRingDropdown", "Outer Ring (Large)", 0, UMC_Config.outerRing)
    outerDropdown:SetPoint("TOPLEFT", mainDropdown, "BOTTOMLEFT", 0, -25)
    
    UIDropDownMenu_Initialize(outerDropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        for _, option in ipairs(UMC.ringOptions) do
            info.text = option
            info.value = option
            info.func = function(self) OnDropdownClick(self, outerDropdown, "outerRing") end
            info.checked = (UMC_Config.outerRing == option)
            UIDropDownMenu_AddButton(info)
        end
    end)

    -- 2. Rings Customization
    local colorSeparator = CreateSeparator(content, "Rings Customization", "TOPLEFT", outerDropdown, 0, -40)

    -- ===================== RETICLE SUBSECTION =====================
    local reticleSubSeparator = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    reticleSubSeparator:SetPoint("TOPLEFT", colorSeparator, "BOTTOMLEFT", 10, -20)
    reticleSubSeparator:SetText("Reticle")
    
    -- Reticle Texture (Dropdown moved from Ring Slot Assignment)
    local reticleDropdown = CreateDropdown("UMC_ReticleDropdown", "Texture:", 0, UMC_Config.reticle)
    reticleDropdown:SetPoint("TOPLEFT", reticleSubSeparator, "BOTTOMLEFT", -10, -20)
    
    UIDropDownMenu_Initialize(reticleDropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        for _, option in ipairs(UMC.reticleOptions) do
            info.text = option
            info.checked = (UMC_Config.reticle == option)
            info.func = function()
                UMC_Config.reticle = option
                UIDropDownMenu_SetText(reticleDropdown, option)
                if UMC.ApplySettings then UMC:ApplySettings() end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetText(reticleDropdown, UMC_Config.reticle or "Dot")

    -- Reticle Color
    local reticleColorDropdown, reticleColorButton = CreateColorModeDropdown(
        content, "Color:", "reticleColorMode", "reticleCustomColor",
        "BOTTOMLEFT", reticleDropdown, 200, 0,
        function() UMC:UpdateReticle() end
    )
    
    -- Reticle Scale Slider
    local reticleScaleSlider = CreateFrame("Slider", "UMC_ReticleScaleSlider", content, "OptionsSliderTemplate")
    reticleScaleSlider:SetPoint("LEFT", reticleColorButton, "RIGHT", 40, 0)
    reticleScaleSlider:SetMinMaxValues(0.5, 3.0)
    reticleScaleSlider:SetValue(UMC_Config.reticleScale or 1.0)
    reticleScaleSlider:SetValueStep(0.1)
    if reticleScaleSlider.SetObeyStepOnDrag then reticleScaleSlider:SetObeyStepOnDrag(true) end
    reticleScaleSlider:SetWidth(100)
    _G[reticleScaleSlider:GetName() .. "Low"]:SetText("0.5")
    _G[reticleScaleSlider:GetName() .. "High"]:SetText("3.0")
    _G[reticleScaleSlider:GetName() .. "Text"]:SetText("Size")
    
    local reticleScaleValue = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    reticleScaleValue:SetPoint("TOP", reticleScaleSlider, "BOTTOM", 0, -5)
    reticleScaleValue:SetText(string.format("%.1f", UMC_Config.reticleScale or 1.0))
    
    reticleScaleSlider:SetScript("OnValueChanged", function(self, value)
        local rounded = math.floor(value * 10 + 0.5) / 10
        reticleScaleValue:SetText(string.format("%.1f", rounded))
        UMC_Config.reticleScale = rounded
        if UMC.UpdateReticle then UMC:UpdateReticle() end
    end)

    -- ===================== MAIN RING SUBSECTION =====================
    local mainRingSubSeparator = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    mainRingSubSeparator:SetPoint("TOPLEFT", reticleDropdown, "BOTTOMLEFT", 10, -35)
    mainRingSubSeparator:SetText("Main Ring")
    
    -- Main Ring Texture
    local mainRingTextureDropdown = CreateTextureDropdown(
        content, "Texture:", "mainRingTexture",
        "TOPLEFT", mainRingSubSeparator, -10, -20,
        function() UMC:UpdateRingTextures() end
    )

    -- Main Ring Color
    local mainRingColorDropdown, mainRingColorButton = CreateColorModeDropdown(
        content, "Color:", "mainRingColorMode", "mainRingCustomColor",
        "BOTTOMLEFT", mainRingTextureDropdown, 200, 0,
        function() UMC:UpdateRingColors() end
    )
    
    -- Combat Color Checkbox
    local combatColorCheckbox = CreateFrame("CheckButton", "UMC_CombatColorCheckbox", content, "InterfaceOptionsCheckButtonTemplate")
    combatColorCheckbox:SetPoint("TOPLEFT", mainRingTextureDropdown, "BOTTOMLEFT", 10, -10)
    _G[combatColorCheckbox:GetName() .. "Text"]:SetText("Change color when entering combat")
    combatColorCheckbox:SetChecked(UMC_Config.mainRingCombatColorEnabled or false)
    combatColorCheckbox:SetScript("OnClick", function(self)
        UMC_Config.mainRingCombatColorEnabled = self:GetChecked()
        UMC:UpdateRingColors()
    end)
    
    -- Combat Color Picker
    local combatColorButton = CreateColorPickerButton(content, "mainRingCombatColor", nil, function() UMC:UpdateRingColors() end)
    combatColorButton:SetPoint("LEFT", _G[combatColorCheckbox:GetName() .. "Text"], "RIGHT", 10, 0)
    
    -- ===================== GCD SUBSECTION =====================
    local gcdSubSeparator = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    gcdSubSeparator:SetPoint("TOPLEFT", combatColorCheckbox, "BOTTOMLEFT", 0, -20)
    gcdSubSeparator:SetText("GCD")
    
    -- GCD Texture
    local gcdTextureDropdown = CreateTextureDropdown(
        content, "Texture:", "gcdTexture",
        "TOPLEFT", gcdSubSeparator, -10, -20,
        function() UMC:UpdateRingTextures() end
    )

    -- GCD Color
    local gcdColorDropdown, gcdColorButton = CreateColorModeDropdown(
        content, "Color:", "gcdColorMode", "gcdCustomColor",
        "BOTTOMLEFT", gcdTextureDropdown, 200, 0,
        function() UMC:UpdateRingColors() end
    )
    
    -- GCD Fill/Drain Dropdown
    local gcdFillDrainDropdown = CreateFrame("Frame", "UMC_GCDFillDrainDropdown", content, "UIDropDownMenuTemplate")
    gcdFillDrainDropdown:SetPoint("TOPLEFT", gcdTextureDropdown, "BOTTOMLEFT", 0, -20)
    UIDropDownMenu_SetWidth(gcdFillDrainDropdown, 120)
    
    local gcdFillDrainLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    gcdFillDrainLabel:SetPoint("BOTTOMLEFT", gcdFillDrainDropdown, "TOPLEFT", 20, 0)
    gcdFillDrainLabel:SetText("Fill/Drain:")
    
    UIDropDownMenu_Initialize(gcdFillDrainDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        local options = {"Drain", "Fill (Default)"}
        local values = {"drain", "fill"}
        for i, option in ipairs(options) do
            info.text = option
            info.checked = (UMC_Config.gcdFillDrain == values[i])
            info.func = function()
                UMC_Config.gcdFillDrain = values[i]
                UIDropDownMenu_SetText(gcdFillDrainDropdown, option)
                UMC:ResetCooldownFrames()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetText(gcdFillDrainDropdown, (UMC_Config.gcdFillDrain == "fill") and "Fill (Default)" or "Drain")
    
    -- GCD Rotation Slider
    local gcdRotationSlider = CreateFrame("Slider", "UMC_GCDRotationSlider", content, "OptionsSliderTemplate")
    gcdRotationSlider:SetPoint("LEFT", gcdFillDrainDropdown, "LEFT", 220, 2)
    
    local gcdRotationLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    gcdRotationLabel:SetPoint("BOTTOM", gcdRotationSlider, "TOP", 0, 5)
    gcdRotationLabel:SetText("Start:")
    gcdRotationSlider:SetMinMaxValues(1, 12)
    gcdRotationSlider:SetValue(UMC_Config.gcdRotation or 12)
    gcdRotationSlider:SetValueStep(1)
    if gcdRotationSlider.SetObeyStepOnDrag then gcdRotationSlider:SetObeyStepOnDrag(true) end
    gcdRotationSlider:SetWidth(120)
    _G[gcdRotationSlider:GetName() .. "Low"]:SetText("1")
    _G[gcdRotationSlider:GetName() .. "High"]:SetText("12")
    
    local function GetClockLabel(value)
        return string.format("%d o'clock", value)
    end
    
    local gcdRotationValue = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    gcdRotationValue:SetPoint("TOP", gcdRotationSlider, "BOTTOM", 0, -5)
    gcdRotationValue:SetText(GetClockLabel(UMC_Config.gcdRotation or 12))
    
    gcdRotationSlider:SetScript("OnValueChanged", function(self, value)
        local rounded = math.floor(value + 0.5)
        gcdRotationValue:SetText(GetClockLabel(rounded))
        UMC_Config.gcdRotation = rounded
        UMC:ResetCooldownFrames()
    end)
    
    
    -- ===================== CAST SUBSECTION =====================
    local castSubSeparator = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    castSubSeparator:SetPoint("TOPLEFT", gcdFillDrainDropdown, "BOTTOMLEFT", 10, -20)
    castSubSeparator:SetText("Cast")
    
    -- Cast Texture
    local castTextureDropdown = CreateTextureDropdown(
        content, "Texture:", "castTexture",
        "TOPLEFT", castSubSeparator, -10, -20,
        function() UMC:UpdateRingTextures() end
    )
    
    -- Cast Color
    local castColorDropdown, castColorButton = CreateColorModeDropdown(
        content, "Color:", "castColorMode", "castCustomColor",
        "BOTTOMLEFT", castTextureDropdown, 200, 0,
        function() UMC:UpdateRingColors() end
    )
    
    -- Cast Fill/Drain Dropdown
    local castFillDrainDropdown = CreateFrame("Frame", "UMC_CastFillDrainDropdown", content, "UIDropDownMenuTemplate")
    castFillDrainDropdown:SetPoint("TOPLEFT", castTextureDropdown, "BOTTOMLEFT", 0, -20)
    UIDropDownMenu_SetWidth(castFillDrainDropdown, 120)
    
    local castFillDrainLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    castFillDrainLabel:SetPoint("BOTTOMLEFT", castFillDrainDropdown, "TOPLEFT", 20, 0)
    castFillDrainLabel:SetText("Fill/Drain:")
    
    UIDropDownMenu_Initialize(castFillDrainDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        local options = {"Drain", "Fill (Default)"}
        local values = {"drain", "fill"}
        for i, option in ipairs(options) do
            info.text = option
            info.checked = (UMC_Config.castFillDrain == values[i])
            info.func = function()
                UMC_Config.castFillDrain = values[i]
                UIDropDownMenu_SetText(castFillDrainDropdown, option)
                UMC:ResetCooldownFrames()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetText(castFillDrainDropdown, (UMC_Config.castFillDrain == "fill") and "Fill (Default)" or "Drain")
    
    -- Cast Rotation Slider
    local castRotationSlider = CreateFrame("Slider", "UMC_CastRotationSlider", content, "OptionsSliderTemplate")
    castRotationSlider:SetPoint("LEFT", castFillDrainDropdown, "LEFT", 220, 2)
    
    local castRotationLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    castRotationLabel:SetPoint("BOTTOM", castRotationSlider, "TOP", 0, 5)
    castRotationLabel:SetText("Start:")
    castRotationSlider:SetMinMaxValues(1, 12)
    castRotationSlider:SetValue(UMC_Config.castRotation or 12)
    castRotationSlider:SetValueStep(1)
    if castRotationSlider.SetObeyStepOnDrag then castRotationSlider:SetObeyStepOnDrag(true) end
    castRotationSlider:SetWidth(120)
    _G[castRotationSlider:GetName() .. "Low"]:SetText("1")
    _G[castRotationSlider:GetName() .. "High"]:SetText("12")
    
    local castRotationValue = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    castRotationValue:SetPoint("TOP", castRotationSlider, "BOTTOM", 0, -5)
    castRotationValue:SetText(GetClockLabel(UMC_Config.castRotation or 12))
    
    castRotationSlider:SetScript("OnValueChanged", function(self, value)
        local rounded = math.floor(value + 0.5)
        castRotationValue:SetText(GetClockLabel(rounded))
        UMC_Config.castRotation = rounded
        UMC:ResetCooldownFrames()
    end)
    
    --[[ Health Color
    local healthColorDropdown, healthColorButton = CreateColorModeDropdown(
        content, "Health Color:", "healthColorMode", "healthCustomColor",
        "TOPLEFT", castColorDropdown, 0, -25,
        function() UMC:UpdateHealthRing() end
    )
    
    -- Lock Health Color checkbox (next to health color dropdown)
    local healthColorLockCheckbox = CreateFrame("CheckButton", "UMC_HealthColorLockCheckbox", content, "InterfaceOptionsCheckButtonTemplate")
    healthColorLockCheckbox:SetPoint("LEFT", healthColorButton, "RIGHT", 40, 0)
    _G[healthColorLockCheckbox:GetName() .. "Text"]:SetText("Lock Color")
    healthColorLockCheckbox:SetChecked(UMC_Config.healthColorLock or false)
    healthColorLockCheckbox:SetScript("OnClick", function(self)
        UMC_Config.healthColorLock = self:GetChecked()
        UMC:UpdateHealthRing()
    end)
    
    -- Power Color (special dropdown with "Power Color" instead of "Class Color")
    local powerColorDropdown = CreateFrame("Frame", "UMC_PowerColorDropdown", content, "UIDropDownMenuTemplate")
    powerColorDropdown:SetPoint("TOPLEFT", healthColorDropdown, "BOTTOMLEFT", 0, -25)
    
    local powerColorLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    powerColorLabel:SetPoint("BOTTOMLEFT", powerColorDropdown, "TOPLEFT", 20, 0)
    powerColorLabel:SetText("Power Ring Color:")
    
    UIDropDownMenu_SetWidth(powerColorDropdown, 120)
    
    local powerColorButton = CreateColorPickerButton(content, "powerCustomColor", "powerColorMode", function() UMC:UpdatePowerRing() end)
    powerColorButton:SetPoint("LEFT", powerColorDropdown, "RIGHT", 10, 2)
    
    -- Enable/disable color button based on mode
    local function UpdatePowerColorButtonState()
        local mode = UMC_Config.powerColorMode or "default"
        if mode == "custom" then
            powerColorButton:Enable()
            powerColorButton:SetAlpha(1.0)
        else
            powerColorButton:Disable()
            powerColorButton:SetAlpha(0.5)
        end
    end
    
    UIDropDownMenu_Initialize(powerColorDropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        local options = {"Default (Blue)", "Power Color", "Custom Color"}
        local values = {"default", "power", "custom"}
        
        for i, option in ipairs(options) do
            info.text = option
            info.checked = (UMC_Config.powerColorMode == values[i])
            info.func = function()
                UMC_Config.powerColorMode = values[i]
                UIDropDownMenu_SetText(powerColorDropdown, option)
                UpdatePowerColorButtonState()
                UMC:UpdatePowerRing()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Set initial text
    local currentMode = UMC_Config.powerColorMode or "default"
    local modeText = currentMode == "default" and "Default (Blue)" or 
                    currentMode == "power" and "Power Color" or "Custom Color"
    UIDropDownMenu_SetText(powerColorDropdown, modeText)
    UpdatePowerColorButtonState()
    ]]--
    
    -- ===================== HC OUTER RING SUBSECTION =====================
    local hcOuterSubSeparator = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    hcOuterSubSeparator:SetPoint("TOPLEFT", castFillDrainDropdown, "BOTTOMLEFT", 10, -20)
    hcOuterSubSeparator:SetText("High Contrast Outer Ring")

    -- HC Outer Texture
    local hcOuterTextureDropdown = CreateTextureDropdown(
        content, "Texture:", "hcOuterTexture",
        "TOPLEFT", hcOuterSubSeparator, -10, -20,
        function() UMC:UpdateRingTextures() end
    )

    -- High Contrast Outer Ring Color
    local hcOuterColorDropdown, hcOuterColorButton = CreateColorModeDropdown(
        content, "Color:", "highContrastOuterColorMode", "highContrastOuterColor",
        "BOTTOMLEFT", hcOuterTextureDropdown, 200, 0,
        function() 
            if UMC.CreateHighContrastRing then
                local slots = {{config=UMC_Config.innerRing, size=50}, {config=UMC_Config.mainRing, size=70}, {config=UMC_Config.outerRing, size=90}}
                for _, slot in ipairs(slots) do if slot.config == "High Contrast Ring" then UMC:CreateHighContrastRing(slot.size) end end
            end
        end,
        "Default (Black)"
    )
    
    -- Outer Thickness Slider
    local hcOuterThicknessSlider = CreateFrame("Slider", "UMC_HCOuterThicknessSlider", content, "OptionsSliderTemplate")
    hcOuterThicknessSlider:SetPoint("LEFT", hcOuterColorButton, "RIGHT", 40, 0)
    hcOuterThicknessSlider:SetMinMaxValues(-5, 5)
    hcOuterThicknessSlider:SetValue((UMC_Config.highContrastOuterThickness or 2) - 2)
    hcOuterThicknessSlider:SetValueStep(1)
    if hcOuterThicknessSlider.SetObeyStepOnDrag then hcOuterThicknessSlider:SetObeyStepOnDrag(true) end
    hcOuterThicknessSlider:SetWidth(100)
    _G[hcOuterThicknessSlider:GetName() .. "Low"]:SetText("-5")
    _G[hcOuterThicknessSlider:GetName() .. "High"]:SetText("+5")
    _G[hcOuterThicknessSlider:GetName() .. "Text"]:SetText("Size")
    
    local hcOuterThicknessValue = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    hcOuterThicknessValue:SetPoint("TOP", hcOuterThicknessSlider, "BOTTOM", 0, -5)
    local outerDisplayValue = (UMC_Config.highContrastOuterThickness or 2) - 2
    hcOuterThicknessValue:SetText(string.format("%+d", outerDisplayValue))
    
    hcOuterThicknessSlider:SetScript("OnValueChanged", function(self, value)
        local rounded = math.floor(value + 0.5)
        hcOuterThicknessValue:SetText(string.format("%+d", rounded))
        UMC_Config.highContrastOuterThickness = rounded + 2
        if UMC.CreateHighContrastRing then
            local slots = {{config=UMC_Config.innerRing, size=50}, {config=UMC_Config.mainRing, size=70}, {config=UMC_Config.outerRing, size=90}}
            for _, slot in ipairs(slots) do if slot.config == "High Contrast Ring" then UMC:CreateHighContrastRing(slot.size) end end
        end
    end)


    -- ===================== HC INNER RING SUBSECTION =====================
    local hcInnerSubSeparator = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    hcInnerSubSeparator:SetPoint("TOPLEFT", hcOuterTextureDropdown, "BOTTOMLEFT", 10, -35)
    hcInnerSubSeparator:SetText("High Contrast Inner Ring")

    -- HC Inner Texture
    local hcInnerTextureDropdown = CreateTextureDropdown(
        content, "Texture:", "hcInnerTexture",
        "TOPLEFT", hcInnerSubSeparator, -10, -20,
        function() UMC:UpdateRingTextures() end
    )
    
    -- High Contrast Inner Ring Color
    local hcInnerColorDropdown, hcInnerColorButton = CreateColorModeDropdown(
        content, "Color:", "highContrastInnerColorMode", "highContrastInnerColor",
        "BOTTOMLEFT", hcInnerTextureDropdown, 200, 0,
        function()
            if UMC.CreateHighContrastRing then
                local slots = {{config=UMC_Config.innerRing, size=50}, {config=UMC_Config.mainRing, size=70}, {config=UMC_Config.outerRing, size=90}}
                for _, slot in ipairs(slots) do if slot.config == "High Contrast Ring" then UMC:CreateHighContrastRing(slot.size) end end
            end
        end
    )
    
    -- Inner Thickness Slider
    local hcInnerThicknessSlider = CreateFrame("Slider", "UMC_HCInnerThicknessSlider", content, "OptionsSliderTemplate")
    hcInnerThicknessSlider:SetPoint("LEFT", hcInnerColorButton, "RIGHT", 40, 0)
    hcInnerThicknessSlider:SetMinMaxValues(-5, 5)
    hcInnerThicknessSlider:SetValue((UMC_Config.highContrastInnerThickness or -4) + 4)
    hcInnerThicknessSlider:SetValueStep(1)
    if hcInnerThicknessSlider.SetObeyStepOnDrag then hcInnerThicknessSlider:SetObeyStepOnDrag(true) end
    hcInnerThicknessSlider:SetWidth(100)
    _G[hcInnerThicknessSlider:GetName() .. "Low"]:SetText("-5")
    _G[hcInnerThicknessSlider:GetName() .. "High"]:SetText("+5")
    _G[hcInnerThicknessSlider:GetName() .. "Text"]:SetText("Size")
    
    local hcInnerThicknessValue = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    hcInnerThicknessValue:SetPoint("TOP", hcInnerThicknessSlider, "BOTTOM", 0, -5)
    local innerDisplayValue = (UMC_Config.highContrastInnerThickness or -4) + 4
    hcInnerThicknessValue:SetText(string.format("%+d", innerDisplayValue))
    
    hcInnerThicknessSlider:SetScript("OnValueChanged", function(self, value)
        local rounded = math.floor(value + 0.5)
        hcInnerThicknessValue:SetText(string.format("%+d", rounded))
        UMC_Config.highContrastInnerThickness = rounded - 4
        if UMC.CreateHighContrastRing then
            local slots = {{config=UMC_Config.innerRing, size=50}, {config=UMC_Config.mainRing, size=70}, {config=UMC_Config.outerRing, size=90}}
            for _, slot in ipairs(slots) do if slot.config == "High Contrast Ring" then UMC:CreateHighContrastRing(slot.size) end end
        end
    end)
    
    
    -- 4. Cursor Trail
    local trailSeparator = CreateSeparator(content, "Cursor Trail", "TOPLEFT", hcInnerTextureDropdown, 0, -25)

    
    local enableTrailCheckbox = CreateFrame("CheckButton", "UMC_EnableTrailCheckbox", content, "InterfaceOptionsCheckButtonTemplate")
    enableTrailCheckbox:SetPoint("TOPLEFT", trailSeparator, "BOTTOMLEFT", 20, -15)
    _G[enableTrailCheckbox:GetName() .. "Text"]:SetText("Enable trail")
    enableTrailCheckbox:SetChecked(UMC_Config.enableTrail)
    enableTrailCheckbox:SetScript("OnClick", function(self)
        UMC_Config.enableTrail = self:GetChecked()
    end)
    
    local trailClassColorCheckbox = CreateFrame("CheckButton", "UMC_TrailClassColorCheckbox", content, "InterfaceOptionsCheckButtonTemplate")
    trailClassColorCheckbox:SetPoint("TOPLEFT", enableTrailCheckbox, "BOTTOMLEFT", 0, -5)
    _G[trailClassColorCheckbox:GetName() .. "Text"]:SetText("Use Class Color for Trail")
    trailClassColorCheckbox:SetChecked(UMC_Config.trailUseClassColor)
    trailClassColorCheckbox:SetScript("OnClick", function(self)
        UMC_Config.trailUseClassColor = self:GetChecked()
    end)
    trailClassColorCheckbox:Hide() -- Hide old checkbox
    
    -- Cursor Trail Color (custom dropdown with Seasonal Effect option)
    local trailColorDropdown = CreateFrame("Frame", "UMC_TrailColorDropdown", content, "UIDropDownMenuTemplate")
    trailColorDropdown:SetPoint("BOTTOMLEFT", enableTrailCheckbox, 80, -5)
    UIDropDownMenu_SetWidth(trailColorDropdown, 120)
    
    local trailColorButton = CreateColorPickerButton(content, "trailCustomColor", "trailColorMode", function() end)
    trailColorButton:SetPoint("LEFT", trailColorDropdown, "RIGHT", 10, 2)
    
    -- Seasonal Effect Style Dropdown (to the right of trail color, initially hidden)
    local seasonalStyleDropdown = CreateFrame("Frame", "UMC_SeasonalStyleDropdown", content, "UIDropDownMenuTemplate")
    seasonalStyleDropdown:SetPoint("LEFT", trailColorDropdown, "RIGHT", 10, 0)
    UIDropDownMenu_SetWidth(seasonalStyleDropdown, 130)
    seasonalStyleDropdown:Hide()
    
    -- Particle Type Dropdown (to the right of style dropdown, initially hidden)
    local seasonalParticleDropdown = CreateFrame("Frame", "UMC_SeasonalParticleDropdown", content, "UIDropDownMenuTemplate")
    seasonalParticleDropdown:SetPoint("LEFT", seasonalStyleDropdown, "RIGHT", 10, 0)
    UIDropDownMenu_SetWidth(seasonalParticleDropdown, 110)
    seasonalParticleDropdown:Hide()
    
    -- Function to update visibility of seasonal controls
    local function UpdateSeasonalControlsVisibility()
        local mode = UMC_Config.trailColorMode or "default"
        if mode == "seasonal" then
            trailColorButton:Hide()
            seasonalStyleDropdown:Show()
            seasonalParticleDropdown:Show()
        else
            seasonalStyleDropdown:Hide()
            seasonalParticleDropdown:Hide()
            if mode == "custom" then
                trailColorButton:Show()
                trailColorButton:Enable()
            else
                trailColorButton:Hide()
            end
        end
    end
    
    -- Initialize Trail Color Dropdown
    UIDropDownMenu_Initialize(trailColorDropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        local options = {"Default (White)", "Class Color", "Custom Color", "Winter Veil"}
        local values = {"default", "class", "custom", "seasonal"}
        
        for i, option in ipairs(options) do
            info.text = option
            info.checked = (UMC_Config.trailColorMode == values[i])
            info.func = function()
                UMC_Config.trailColorMode = values[i]
                UIDropDownMenu_SetText(trailColorDropdown, option)
                UpdateSeasonalControlsVisibility()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Set initial trail color text
    local currentTrailMode = UMC_Config.trailColorMode or "default"
    local trailModeText = currentTrailMode == "default" and "Default (White)" or 
                         currentTrailMode == "class" and "Class Color" or 
                         currentTrailMode == "custom" and "Custom Color" or "Winter Veil"
    UIDropDownMenu_SetText(trailColorDropdown, trailModeText)
    
    -- Initialize Seasonal Style Dropdown (only Candy Cane and Christmas Lights)
    UIDropDownMenu_Initialize(seasonalStyleDropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        local styles = {"Candy Cane", "Christmas Lights", "None"}
        
        for _, style in ipairs(styles) do
            info.text = style
            info.checked = (UMC_Config.seasonalEffectStyle == style)
            info.func = function()
                UMC_Config.seasonalEffectStyle = style
                UIDropDownMenu_SetText(seasonalStyleDropdown, style)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetText(seasonalStyleDropdown, UMC_Config.seasonalEffectStyle or "Candy Cane")
    
    -- Initialize Particle Type Dropdown
    UIDropDownMenu_Initialize(seasonalParticleDropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        local particleTypes = {"Snowflakes", "Sparkles", "Both", "None"}
        
        for _, particleType in ipairs(particleTypes) do
            info.text = particleType
            info.checked = (UMC_Config.seasonalParticleType == particleType)
            info.func = function()
                UMC_Config.seasonalParticleType = particleType
                UIDropDownMenu_SetText(seasonalParticleDropdown, particleType)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetText(seasonalParticleDropdown, UMC_Config.seasonalParticleType or "Snowflakes")
    
    -- Set initial visibility
    UpdateSeasonalControlsVisibility()
    
    local trailDurationLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    trailDurationLabel:SetPoint("TOPLEFT", enableTrailCheckbox, "BOTTOMLEFT", 0, -25)
    trailDurationLabel:SetText("Trail Duration:")

    local trailDurationSlider = CreateFrame("Slider", "UMC_TrailDurationSlider", content, "OptionsSliderTemplate")
    trailDurationSlider:SetPoint("LEFT", trailDurationLabel, "RIGHT", 20, 0)
    trailDurationSlider:SetMinMaxValues(0.2, 1.0)
    trailDurationSlider:SetValue(UMC_Config.trailDuration or 0.4)
    trailDurationSlider:SetValueStep(0.05)
    if trailDurationSlider.SetObeyStepOnDrag then trailDurationSlider:SetObeyStepOnDrag(true) end
    trailDurationSlider:SetWidth(150)
    _G[trailDurationSlider:GetName() .. "Low"]:SetText("0.2s")
    _G[trailDurationSlider:GetName() .. "High"]:SetText("1.0s")
    
    local trailDurationValue = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    trailDurationValue:SetPoint("TOP", trailDurationSlider, "BOTTOM", 0, -5)
    trailDurationValue:SetText(string.format("%.2fs", UMC_Config.trailDuration or 0.4))
    
    trailDurationSlider:SetScript("OnValueChanged", function(self, value)
        UMC_Config.trailDuration = value
        trailDurationValue:SetText(string.format("%.2fs", value))
    end)
    
    local trailDensityLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    trailDensityLabel:SetPoint("TOPLEFT", trailDurationLabel, "BOTTOMLEFT", 0, -35)
    trailDensityLabel:SetText("Trail Density:")
    
    local trailDensitySlider = CreateFrame("Slider", "UMC_TrailDensitySlider", content, "OptionsSliderTemplate")
    trailDensitySlider:SetPoint("LEFT", trailDensityLabel, "RIGHT", 25, 0)
    trailDensitySlider:SetMinMaxValues(0.004, 0.02)
    trailDensitySlider:SetValue(UMC_Config.trailDensity or 0.008)
    trailDensitySlider:SetValueStep(0.001)
    if trailDensitySlider.SetObeyStepOnDrag then trailDensitySlider:SetObeyStepOnDrag(true) end
    trailDensitySlider:SetWidth(150)
    _G[trailDensitySlider:GetName() .. "Low"]:SetText("Dense")
    _G[trailDensitySlider:GetName() .. "High"]:SetText("Sparse")
    
    local trailDensityValue = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    trailDensityValue:SetPoint("TOP", trailDensitySlider, "BOTTOM", 0, -5)
    trailDensityValue:SetText(string.format("%.3fs", UMC_Config.trailDensity or 0.008))
    
    trailDensitySlider:SetScript("OnValueChanged", function(self, value)
        UMC_Config.trailDensity = value
        trailDensityValue:SetText(string.format("%.3fs", value))
    end)
    
    local trailScaleLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    trailScaleLabel:SetPoint("TOPLEFT", trailDensityLabel, "BOTTOMLEFT", 0, -35)
    trailScaleLabel:SetText("Trail Scale:")
    
    local trailScaleSlider = CreateFrame("Slider", "UMC_TrailScaleSlider", content, "OptionsSliderTemplate")
    trailScaleSlider:SetPoint("LEFT", trailScaleLabel, "RIGHT", 35, 0)
    trailScaleSlider:SetMinMaxValues(0.5, 2.0)
    trailScaleSlider:SetValue(UMC_Config.trailScale or 1.0)
    trailScaleSlider:SetValueStep(0.1)
    if trailScaleSlider.SetObeyStepOnDrag then trailScaleSlider:SetObeyStepOnDrag(true) end
    trailScaleSlider:SetWidth(150)
    _G[trailScaleSlider:GetName() .. "Low"]:SetText("0.5x")
    _G[trailScaleSlider:GetName() .. "High"]:SetText("2.0x")
    
    local trailScaleValue = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    trailScaleValue:SetPoint("TOP", trailScaleSlider, "BOTTOM", 0, -5)
    trailScaleValue:SetText(string.format("%.1fx", UMC_Config.trailScale or 1.0))
    
    trailScaleSlider:SetScript("OnValueChanged", function(self, value)
        UMC_Config.trailScale = value
        trailScaleValue:SetText(string.format("%.1fx", value))
    end)

    -- 4. Visibility
    local combatSeparator = CreateSeparator(content, "Visibility", "TOPLEFT", trailScaleLabel, -20, -40)

    -- Position Dropdown
    local positionDropdown = CreateFrame("Frame", "UMC_PositionDropdown", content, "UIDropDownMenuTemplate")
    positionDropdown:SetPoint("TOPLEFT", combatSeparator, "BOTTOMLEFT", 0, -35)
    UIDropDownMenu_SetWidth(positionDropdown, 160)
    
    local positionLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    positionLabel:SetPoint("BOTTOMLEFT", positionDropdown, "TOPLEFT", 20, 0)
    positionLabel:SetText("Position:")
    
    -- X Slider
    local posXSlider = CreateFrame("Slider", "UMC_PosXSlider", content, "OptionsSliderTemplate")
    posXSlider:SetPoint("LEFT", positionDropdown, "RIGHT", 10, 2)
    posXSlider:SetMinMaxValues(-1000, 1000)
    posXSlider:SetValue(UMC_Config.positionX or 0)
    posXSlider:SetValueStep(1)
    if posXSlider.SetObeyStepOnDrag then posXSlider:SetObeyStepOnDrag(true) end
    posXSlider:SetWidth(100)
    _G[posXSlider:GetName() .. "Low"]:SetText("-1000")
    _G[posXSlider:GetName() .. "High"]:SetText("1000")
    
    local posXValue = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    posXValue:SetPoint("BOTTOM", posXSlider, "TOP", 0, 5)
    posXValue:SetText("X Offset: " .. (UMC_Config.positionX or 0))
    
    posXSlider:SetScript("OnValueChanged", function(self, value)
        local rounded = math.floor(value + 0.5)
        posXValue:SetText("X Offset: " .. rounded)
        UMC_Config.positionX = rounded
        UMC:ApplySettings()
    end)
    
    -- Y Slider
    local posYSlider = CreateFrame("Slider", "UMC_PosYSlider", content, "OptionsSliderTemplate")
    posYSlider:SetPoint("LEFT", posXSlider, "RIGHT", 30, 0)
    posYSlider:SetMinMaxValues(-1000, 1000)
    posYSlider:SetValue(UMC_Config.positionY or 0)
    posYSlider:SetValueStep(1)
    if posYSlider.SetObeyStepOnDrag then posYSlider:SetObeyStepOnDrag(true) end
    posYSlider:SetWidth(100)
    _G[posYSlider:GetName() .. "Low"]:SetText("-1000")
    _G[posYSlider:GetName() .. "High"]:SetText("1000")
    
    local posYValue = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    posYValue:SetPoint("BOTTOM", posYSlider, "TOP", 0, 5)
    posYValue:SetText("Y Offset: " .. (UMC_Config.positionY or 0))
    
    posYSlider:SetScript("OnValueChanged", function(self, value)
        local rounded = math.floor(value + 0.5)
        posYValue:SetText("Y Offset: " .. rounded)
        UMC_Config.positionY = rounded
        UMC:ApplySettings()
    end)
    
    -- Reset Position Button
    local resetPosButton = CreateFrame("Button", "UMC_ResetPosButton", content, "UIPanelButtonTemplate")
    resetPosButton:SetSize(80, 25)
    resetPosButton:SetPoint("LEFT", posYSlider, "RIGHT", 30, 0)
    resetPosButton:SetText("Reset")
    resetPosButton:SetScript("OnClick", function(self)
        UMC_Config.positionX = 0
        UMC_Config.positionY = 0
        posXSlider:SetValue(0)
        posYSlider:SetValue(0)
        UMC:ApplySettings()
    end)
    
    local function UpdatePositionControls()
        if UMC_Config.positionMode == "fixed" or UMC_Config.positionMode == "dragonriding" then
            posXSlider:Show()
            posYSlider:Show()
            resetPosButton:Show()
            posXValue:Show()
            posYValue:Show()
        else
            posXSlider:Hide()
            posYSlider:Hide()
            resetPosButton:Hide()
            posXValue:Hide()
            posYValue:Hide()
        end
    end
    
    UIDropDownMenu_Initialize(positionDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        info.text = "Attached to Cursor (Default)"
        info.checked = (UMC_Config.positionMode ~= "fixed")
        info.func = function()
            UMC_Config.positionMode = "cursor"
            UIDropDownMenu_SetText(positionDropdown, "Attached to Cursor (Default)")
            UpdatePositionControls()
            UMC:ApplySettings()
        end
        UIDropDownMenu_AddButton(info)
        
        info.text = "Fixed Position"
        info.checked = (UMC_Config.positionMode == "fixed")
        info.func = function()
            UMC_Config.positionMode = "fixed"
            UIDropDownMenu_SetText(positionDropdown, "Fixed Position")
            UpdatePositionControls()
            UMC:ApplySettings()
        end
        UIDropDownMenu_AddButton(info)
        
        info.text = "Fixed while mounted/flying"
        info.checked = (UMC_Config.positionMode == "dragonriding")
        info.func = function()
            UMC_Config.positionMode = "dragonriding"
            UIDropDownMenu_SetText(positionDropdown, "Fixed while mounted/flying")
            UpdatePositionControls()
            UMC:ApplySettings()
        end
        UIDropDownMenu_AddButton(info)
    end)
    
    local posText = "Attached to Cursor (Default)"
    if UMC_Config.positionMode == "fixed" then posText = "Fixed Position" end
    if UMC_Config.positionMode == "dragonriding" then posText = "Fixed while mounted/flying" end
    UIDropDownMenu_SetText(positionDropdown, posText)
    UpdatePositionControls()

    -- Combat Visibility Dropdown
    local combatDropdown = CreateFrame("Frame", "UMC_CombatDropdown", content, "UIDropDownMenuTemplate")
    combatDropdown:SetPoint("TOPLEFT", positionDropdown, "BOTTOMLEFT", 0, -20)
    UIDropDownMenu_SetWidth(combatDropdown, 160)
    
    local combatLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    combatLabel:SetPoint("BOTTOMLEFT", combatDropdown, "TOPLEFT", 20, 0)
    combatLabel:SetText("Show:")
    
    UIDropDownMenu_Initialize(combatDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        -- Option 1: Always (Default)
        info.text = "Always"
        info.checked = (not UMC_Config.showOnlyInCombat)
        info.func = function()
            UMC_Config.showOnlyInCombat = false
            UIDropDownMenu_SetText(combatDropdown, "Always")
            UMC:ApplySettings()
        end
        UIDropDownMenu_AddButton(info)
        
        -- Option 2: In combat
        info.text = "In combat"
        info.checked = (UMC_Config.showOnlyInCombat)
        info.func = function()
            UMC_Config.showOnlyInCombat = true
            UIDropDownMenu_SetText(combatDropdown, "In combat")
            UMC:ApplySettings()
        end
        UIDropDownMenu_AddButton(info)
    end)
    
    -- Set initial text
    UIDropDownMenu_SetText(combatDropdown, UMC_Config.showOnlyInCombat and "In combat" or "Always")
    
    -- Modifier Actions
    local shiftDropdown = CreateDropdown("UMC_ShiftDropdown", "When Shift is pressed:", 0, UMC_Config.shiftAction)
    shiftDropdown:SetPoint("TOPLEFT", combatDropdown, "BOTTOMLEFT", 0, -20)
    UIDropDownMenu_SetWidth(shiftDropdown, 160)
    
    UIDropDownMenu_Initialize(shiftDropdown, function(self, level)
        for _, option in ipairs(UMC.modifierOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option
            info.value = option
            info.func = function(self) OnDropdownClick(self, shiftDropdown, "shiftAction") end
            info.checked = (UMC_Config.shiftAction == option)
            UIDropDownMenu_AddButton(info)
        end
    end)

    local ctrlDropdown = CreateDropdown("UMC_CtrlDropdown", "When Ctrl is pressed:", 0, UMC_Config.ctrlAction)
    ctrlDropdown:SetPoint("TOPLEFT", shiftDropdown, "BOTTOMLEFT", 0, -20)
    UIDropDownMenu_SetWidth(ctrlDropdown, 160)
    
    UIDropDownMenu_Initialize(ctrlDropdown, function(self, level)
        for _, option in ipairs(UMC.modifierOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option
            info.value = option
            info.func = function(self) OnDropdownClick(self, ctrlDropdown, "ctrlAction") end
            info.checked = (UMC_Config.ctrlAction == option)
            UIDropDownMenu_AddButton(info)
        end
    end)

    local altDropdown = CreateDropdown("UMC_AltDropdown", "When Alt is pressed:", 0, UMC_Config.altAction)
    altDropdown:SetPoint("TOPLEFT", ctrlDropdown, "BOTTOMLEFT", 0, -20)
    UIDropDownMenu_SetWidth(altDropdown, 160)
    
    UIDropDownMenu_Initialize(altDropdown, function(self, level)
        for _, option in ipairs(UMC.modifierOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option
            info.value = option
            info.func = function(self) OnDropdownClick(self, altDropdown, "altAction") end
            info.checked = (UMC_Config.altAction == option)
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Transparency Slider
    local transparencyLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    transparencyLabel:SetPoint("TOPLEFT", altDropdown, "BOTTOMLEFT", 0, -20)
    transparencyLabel:SetText("Transparency:")
    
    local transparencySlider = CreateFrame("Slider", "UMC_TransparencySlider", content, "OptionsSliderTemplate")
    transparencySlider:SetPoint("LEFT", transparencyLabel, "RIGHT", 10, 0)
    transparencySlider:SetMinMaxValues(0.1, 1.0)
    transparencySlider:SetValue(UMC_Config.transparency or 1.0)
    transparencySlider:SetValueStep(0.05)
    if transparencySlider.SetObeyStepOnDrag then transparencySlider:SetObeyStepOnDrag(true) end
    transparencySlider:SetWidth(150)
    _G[transparencySlider:GetName() .. "Low"]:SetText("10%")
    _G[transparencySlider:GetName() .. "High"]:SetText("100%")
    
    local transparencyValue = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    transparencyValue:SetPoint("TOP", transparencySlider, "BOTTOM", 0, -5)
    transparencyValue:SetText(string.format("%.0f%%", (UMC_Config.transparency or 1.0) * 100))
    
    transparencySlider:SetScript("OnValueChanged", function(self, value)
        UMC_Config.transparency = value
        transparencyValue:SetText(string.format("%.0f%%", value * 100))
        UMC:ApplySettings()
    end)

    -- 5. Scale
    local scaleLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    scaleLabel:SetPoint("TOPLEFT", transparencyLabel, "BOTTOMLEFT", 0, -40)
    scaleLabel:SetText("Scale:")

    local scaleSlider = CreateFrame("Slider", "UMC_ScaleSlider", content, "OptionsSliderTemplate")
    scaleSlider:SetPoint("LEFT", scaleLabel, "RIGHT", 55, 0)
    scaleSlider:SetMinMaxValues(0.5, 4.0)
    scaleSlider:SetValueStep(0.1)
    if scaleSlider.SetObeyStepOnDrag then scaleSlider:SetObeyStepOnDrag(true) end
    scaleSlider:SetValue(UMC_Config.scale)
    scaleSlider:SetWidth(150)
    --_G["UMC_ScaleSliderText"]:SetText("Cursor Ring Scale")
    _G["UMC_ScaleSliderLow"]:SetText("0.5")
    _G["UMC_ScaleSliderHigh"]:SetText("4.0")
    
    local scaleValue = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    scaleValue:SetPoint("TOP", scaleSlider, "BOTTOM", 0, -5)
    scaleValue:SetText(string.format("%.1f", UMC_Config.scale))
    
    scaleSlider:SetScript("OnValueChanged", function(self, value)
        local rounded = math.floor(value * 10 + 0.5) / 10
        scaleValue:SetText(string.format("%.1f", rounded))
        UMC_Config.scale = rounded
        UMC:ApplySettings()
    end)

    -- 6. Reset
    local resetSeparator = CreateSeparator(content, "Reset to default values", "TOPLEFT", scaleLabel, -16, -40)
    
    local resetButton = CreateFrame("Button", "UMC_ResetButton", content, "UIPanelButtonTemplate")
    resetButton:SetSize(160, 25)
    resetButton:SetPoint("TOPLEFT", resetSeparator, "BOTTOMLEFT", 0, -10)
    resetButton:SetText("Reset to Default Values")
    resetButton:SetScript("OnClick", function(self)
        for key, value in pairs(UMC.defaults) do
            UMC_Config[key] = value
        end
        scaleSlider:SetValue(UMC_Config.scale)
        scaleValue:SetText(string.format("%.1f", UMC_Config.scale))
        UIDropDownMenu_SetText(innerDropdown, UMC_Config.innerRing)
        UIDropDownMenu_SetText(mainDropdown, UMC_Config.mainRing)
        UIDropDownMenu_SetText(outerDropdown, UMC_Config.outerRing)
        
        -- Update color dropdowns
        local reticleMode = UMC_Config.reticleColorMode or "default"
        local reticleModeText = reticleMode == "default" and "Default (White)" or 
                               reticleMode == "class" and "Class Color" or "Custom Color"
        UIDropDownMenu_SetText(reticleColorDropdown, reticleModeText)
        reticleColorButton:UpdateColor()
        reticleColorButton:Hide()
        
        local mainRingMode = UMC_Config.mainRingColorMode or "default"
        local mainRingModeText = mainRingMode == "default" and "Default (White)" or 
                                mainRingMode == "class" and "Class Color" or "Custom Color"
        UIDropDownMenu_SetText(mainRingColorDropdown, mainRingModeText)
        mainRingColorButton:UpdateColor()
        mainRingColorButton:Hide()
        combatColorCheckbox:SetChecked(UMC_Config.mainRingCombatColorEnabled or false)
        
        local gcdMode = UMC_Config.gcdColorMode or "default"
        local gcdModeText = gcdMode == "default" and "Default (White)" or 
                           gcdMode == "class" and "Class Color" or "Custom Color"
        UIDropDownMenu_SetText(gcdColorDropdown, gcdModeText)
        gcdColorButton:UpdateColor()
        gcdColorButton:Hide()
        
        local castMode = UMC_Config.castColorMode or "default"
        local castModeText = castMode == "default" and "Default (White)" or 
                            castMode == "class" and "Class Color" or "Custom Color"
        UIDropDownMenu_SetText(castColorDropdown, castModeText)
        castColorButton:UpdateColor()
        castColorButton:Hide()
        
        -- Health and Power color sections were removed/commented out from UMC_Settings.lua
        
        
        local trailMode = UMC_Config.trailColorMode or "default"
        local trailModeText = trailMode == "default" and "Default (White)" or 
                             trailMode == "class" and "Class Color" or 
                             trailMode == "custom" and "Custom Color" or "Winter Veil"
        UIDropDownMenu_SetText(trailColorDropdown, trailModeText)
        trailColorButton:UpdateColor()
        
        -- Update seasonal controls
        UIDropDownMenu_SetText(seasonalStyleDropdown, UMC_Config.seasonalEffectStyle or "Candy Cane")
        UIDropDownMenu_SetText(seasonalParticleDropdown, UMC_Config.seasonalParticleType or "Snowflakes")
        UpdateSeasonalControlsVisibility()
        
        enableTrailCheckbox:SetChecked(UMC_Config.enableTrail)
        trailDurationSlider:SetValue(UMC_Config.trailDuration)
        trailDurationValue:SetText(string.format("%.2fs", UMC_Config.trailDuration))
        trailDensitySlider:SetValue(UMC_Config.trailDensity)
        trailDensityValue:SetText(string.format("%.3fs", UMC_Config.trailDensity))
        trailScaleSlider:SetValue(UMC_Config.trailScale)
        trailScaleValue:SetText(string.format("%.1fx", UMC_Config.trailScale))
        UIDropDownMenu_SetText(combatDropdown, UMC_Config.showOnlyInCombat and "In combat" or "Always")
        UIDropDownMenu_SetText(positionDropdown, "Attached to Cursor (Default)")
        posXSlider:SetValue(0)
        posYSlider:SetValue(0)
        UpdatePositionControls()
        UIDropDownMenu_SetText(shiftDropdown, UMC_Config.shiftAction)
        UIDropDownMenu_SetText(ctrlDropdown, UMC_Config.ctrlAction)
        UIDropDownMenu_SetText(altDropdown, UMC_Config.altAction)
        UIDropDownMenu_SetText(reticleDropdown, UMC_Config.reticle or "Dot")
        reticleScaleSlider:SetValue(UMC_Config.reticleScale)
        reticleScaleValue:SetText(string.format("%.1f", UMC_Config.reticleScale))
        transparencySlider:SetValue(UMC_Config.transparency)
        transparencyValue:SetText(string.format("%.0f%%", UMC_Config.transparency * 100))
        
        -- Update High Contrast Ring settings
        hcOuterThicknessSlider:SetValue((UMC_Config.highContrastOuterThickness or 2) - 2)
        local outerDisplayValue = (UMC_Config.highContrastOuterThickness or 2) - 2
        hcOuterThicknessValue:SetText(string.format("%+d", outerDisplayValue))
        hcInnerThicknessSlider:SetValue((UMC_Config.highContrastInnerThickness or -4) + 4)
        local innerDisplayValue = (UMC_Config.highContrastInnerThickness or -4) + 4
        hcInnerThicknessValue:SetText(string.format("%+d", innerDisplayValue))
        
        -- Update High Contrast color dropdowns
        local hcOuterMode = UMC_Config.highContrastOuterColorMode or "default"
        local hcOuterModeText = hcOuterMode == "default" and "Default (Black)" or 
                                hcOuterMode == "class" and "Class Color" or "Custom Color"
        UIDropDownMenu_SetText(hcOuterColorDropdown, hcOuterModeText)
        hcOuterColorButton:UpdateColor()
        hcOuterColorButton:Hide()
        
        local hcInnerMode = UMC_Config.highContrastInnerColorMode or "default"
        local hcInnerModeText = hcInnerMode == "default" and "Default (White)" or 
                                hcInnerMode == "class" and "Class Color" or "Custom Color"
        UIDropDownMenu_SetText(hcInnerColorDropdown, hcInnerModeText)
        hcInnerColorButton:UpdateColor()
        hcInnerColorButton:Hide()
        
        -- Update Cast/GCD Animation settings
        UIDropDownMenu_SetText(gcdFillDrainDropdown, (UMC_Config.gcdFillDrain == "fill") and "Fill (Default)" or "Drain")
        UIDropDownMenu_SetText(castFillDrainDropdown, (UMC_Config.castFillDrain == "fill") and "Fill (Default)" or "Drain")
        gcdRotationSlider:SetValue(UMC_Config.gcdRotation or 12)
        gcdRotationValue:SetText(GetClockLabel(UMC_Config.gcdRotation or 12))
        castRotationSlider:SetValue(UMC_Config.castRotation or 12)
        castRotationValue:SetText(GetClockLabel(UMC_Config.castRotation or 12))
        
        UIDropDownMenu_SetText(mainRingTextureDropdown, UMC_Config.mainRingTexture)
        UIDropDownMenu_SetText(gcdTextureDropdown, UMC_Config.gcdTexture)
        UIDropDownMenu_SetText(castTextureDropdown, UMC_Config.castTexture)
        UIDropDownMenu_SetText(hcOuterTextureDropdown, UMC_Config.hcOuterTexture)
        UIDropDownMenu_SetText(hcInnerTextureDropdown, UMC_Config.hcInnerTexture)
        
        UMC:UpdateRingTextures()
        UMC:ResetCooldownFrames()
        UMC:ApplySettings()
        print("|cff00ff00UMC:|r Settings reset to defaults.")
    end)


    
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category, layout = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        layout:AddAnchorPoint("TOPLEFT", 0, 0)
        layout:AddAnchorPoint("BOTTOMRIGHT", 0, 0)
        Settings.RegisterAddOnCategory(category)
        UMC.settingsCategory = category
    else
        InterfaceOptions_AddCategory(panel)
    end
    
    UMC.settingsPanel = panel
    return panel
end


function UMC:ApplySettings()
    if UMC.BindXMLFrames then UMC:BindXMLFrames() end

    if UMC_Config.scale then
        UMC:SetGroupScale(UMC_Config.scale)
    end
    
    if UMC_CursorFrame then
        local transparency = UMC_Config.transparency or 1.0
        UMC_CursorFrame:SetAlpha(transparency)
        
        if UMC_Config.positionMode == "fixed" then
            UMC_CursorFrame:ClearAllPoints()
            UMC_CursorFrame:SetPoint("CENTER", UIParent, "CENTER", (UMC_Config.positionX or 0) / UMC.currentGroupScale, (UMC_Config.positionY or 0) / UMC.currentGroupScale)
        end
    end
    
    if UMC.GCDCooldownFrame then UMC:HideCooldownWidget(UMC.GCDCooldownFrame) end
    if UMC.GCDBackgroundFrame then UMC:HideCooldownWidget(UMC.GCDBackgroundFrame) end
    if UMC.CastFrame then UMC:HideCooldownWidget(UMC.CastFrame) end
    if UMC.CastBackgroundFrame then UMC:HideCooldownWidget(UMC.CastBackgroundFrame) end
    if UMC.HealthFrame then UMC:HideCooldownWidget(UMC.HealthFrame) end
    if UMC.HealthBackgroundFrame then UMC.HealthBackgroundFrame:Hide() end
    if UMC.PowerFrame then UMC:HideCooldownWidget(UMC.PowerFrame) end
    if UMC_CursorFrame and UMC_CursorFrame.MainRing then UMC_CursorFrame.MainRing:Hide() end
    
    -- Hide all High Contrast Rings (both old and new versions)
    if UMC.HighContrastRings then
        for _, ring in pairs(UMC.HighContrastRings) do
            -- New version (outer/inner halves)
            if ring.outerHalf then ring.outerHalf:Hide() end
            if ring.innerHalf then ring.innerHalf:Hide() end
            -- Old version (sandwich layers)
            if ring.outerBorder then ring.outerBorder:Hide() end
            if ring.centerRing then ring.centerRing:Hide() end
            if ring.innerBorder then ring.innerBorder:Hide() end
        end
    end
    
    UMC.enableGCD = false
    UMC.enableCast = false
    local trackHealth = false
    local trackPower = false
    
    local slots = {
        {config = UMC_Config.innerRing, size = 50},
        {config = UMC_Config.mainRing, size = 70},
        {config = UMC_Config.outerRing, size = 90},
    }
    
    for _, slot in ipairs(slots) do
        local ringType = slot.config
        local size = slot.size
        
        if ringType == "Main Ring" then
            if UMC_CursorFrame and UMC_CursorFrame.MainRing then
                UMC_CursorFrame.MainRing:SetSize(size, size)
                UMC_CursorFrame.MainRing:Show()
            end
            
        elseif ringType == "GCD" then
            if UMC.GCDCooldownFrame then
                UMC:SetCooldownWidgetSize(UMC.GCDCooldownFrame, size)
                UMC:ShowCooldownWidget(UMC.GCDCooldownFrame)
                UMC.enableGCD = true
            end
            if size == 70 and UMC.GCDBackgroundFrame then
                UMC:SetCooldownWidgetSize(UMC.GCDBackgroundFrame, size)
                UMC:ShowCooldownWidget(UMC.GCDBackgroundFrame)
            end
            
        elseif ringType == "Cast" then
            if UMC.CastFrame then
                UMC:SetCooldownWidgetSize(UMC.CastFrame, size)
                UMC:ShowCooldownWidget(UMC.CastFrame)
                UMC.enableCast = true
            end
            if size == 70 and UMC.CastBackgroundFrame then
                UMC:SetCooldownWidgetSize(UMC.CastBackgroundFrame, size)
                UMC:ShowCooldownWidget(UMC.CastBackgroundFrame)
            end
            
        elseif ringType == "Health" then
            if UMC.HealthFrame then
                UMC:SetCooldownWidgetSize(UMC.HealthFrame, size)
                UMC:ShowCooldownWidget(UMC.HealthFrame)
                trackHealth = true
            end
            if UMC.HealthBackgroundFrame then
                UMC.HealthBackgroundFrame:SetSize(size, size)
                UMC.HealthBackgroundFrame:Show()
            end
            
        elseif ringType == "Power" then
            if UMC.PowerFrame then
                UMC:SetCooldownWidgetSize(UMC.PowerFrame, size)
                UMC:ShowCooldownWidget(UMC.PowerFrame)
                trackPower = true
            end
            
        elseif ringType == "Health and Power" then
            if UMC.HealthFrame then
                UMC:SetCooldownWidgetSize(UMC.HealthFrame, size)
                UMC:ShowCooldownWidget(UMC.HealthFrame)
                trackHealth = true
            end
            if UMC.HealthBackgroundFrame then
                UMC.HealthBackgroundFrame:SetSize(size, size)
                UMC.HealthBackgroundFrame:Show()
            end
            if UMC.PowerFrame then
                UMC:SetCooldownWidgetSize(UMC.PowerFrame, size + 10)
                UMC:ShowCooldownWidget(UMC.PowerFrame)
                trackPower = true
            end
            
        elseif ringType == "Main Ring + GCD" then
            if UMC_CursorFrame and UMC_CursorFrame.MainRing then
                UMC_CursorFrame.MainRing:SetSize(size, size)
                UMC_CursorFrame.MainRing:Show()
            end
            if UMC.GCDCooldownFrame then
                UMC:SetCooldownWidgetSize(UMC.GCDCooldownFrame, size)
                UMC:ShowCooldownWidget(UMC.GCDCooldownFrame)
                UMC.enableGCD = true
            end
            if UMC.GCDBackgroundFrame then
                UMC:SetCooldownWidgetSize(UMC.GCDBackgroundFrame, size)
                UMC:ShowCooldownWidget(UMC.GCDBackgroundFrame)
            end
            
        elseif ringType == "Main Ring + Cast" then
            if UMC_CursorFrame and UMC_CursorFrame.MainRing then
                UMC_CursorFrame.MainRing:SetSize(size, size)
                UMC_CursorFrame.MainRing:Show()
            end
            if UMC.CastFrame then
                UMC:SetCooldownWidgetSize(UMC.CastFrame, size)
                UMC:ShowCooldownWidget(UMC.CastFrame)
                UMC.enableCast = true
            end
            if UMC.CastBackgroundFrame then
                UMC:SetCooldownWidgetSize(UMC.CastBackgroundFrame, size)
                UMC:ShowCooldownWidget(UMC.CastBackgroundFrame)
            end
            
        elseif ringType == "High Contrast Ring" then
            -- Create High Contrast Ring with dual-stroke effect
            UMC:CreateHighContrastRing(size)
        end
    end
    
    if UMC.TrackerFrame then
        if UMC.enableGCD then
            UMC.TrackerFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
            UMC.TrackerFrame:RegisterEvent("UNIT_SPELLCAST_START")
            UMC.TrackerFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
            UMC.TrackerFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
            UMC.TrackerFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
        else
            UMC.TrackerFrame:UnregisterEvent("UNIT_SPELLCAST_SENT")
            UMC.TrackerFrame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
            UMC.TrackerFrame:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
            if not UMC.enableCast then
                UMC.TrackerFrame:UnregisterEvent("UNIT_SPELLCAST_START")
                UMC.TrackerFrame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
            end
        end
        
        if UMC.enableCast then
            UMC.TrackerFrame:RegisterEvent("UNIT_SPELLCAST_START")
            UMC.TrackerFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
            UMC.TrackerFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
            UMC.TrackerFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
            UMC.TrackerFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
            UMC.TrackerFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
        else
            if not UMC.enableGCD then
                UMC.TrackerFrame:UnregisterEvent("UNIT_SPELLCAST_START")
                UMC.TrackerFrame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
            end
            UMC.TrackerFrame:UnregisterEvent("UNIT_SPELLCAST_STOP")
            UMC.TrackerFrame:UnregisterEvent("UNIT_SPELLCAST_FAILED")
            UMC.TrackerFrame:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
            UMC.TrackerFrame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
        end
        
        if trackHealth then
            UMC.TrackerFrame:RegisterEvent("UNIT_HEALTH")
            UMC.TrackerFrame:RegisterEvent("UNIT_MAXHEALTH")
            if UMC.HealthFrame and UMC.HealthFrame:IsShown() then
                UMC:UpdateHealthRing()
            end
        else
            UMC.TrackerFrame:UnregisterEvent("UNIT_HEALTH")
            UMC.TrackerFrame:UnregisterEvent("UNIT_MAXHEALTH")
        end
        
        if trackPower then
            if UMC.RegisterPowerEvents then
                UMC:RegisterPowerEvents(UMC.TrackerFrame)
            else
                UMC.TrackerFrame:RegisterEvent("UNIT_POWER_UPDATE")
                UMC.TrackerFrame:RegisterEvent("UNIT_MAXPOWER")
            end
            if UMC.PowerFrame and UMC.PowerFrame:IsShown() then
                UMC:UpdatePowerRing()
            end
        else
            if UMC.UnregisterPowerEvents then
                UMC:UnregisterPowerEvents(UMC.TrackerFrame)
            else
                UMC.TrackerFrame:UnregisterEvent("UNIT_POWER_UPDATE")
                UMC.TrackerFrame:UnregisterEvent("UNIT_MAXPOWER")
            end
        end
    end
    
    UMC:UpdateRingColors()
    UMC:UpdateVisibility()
    UMC:UpdateReticle()
end

SLASH_ULTIMATEMOUSECURSOR1 = "/ultimate"
SLASH_ULTIMATEMOUSECURSOR2 = "/umc"
SlashCmdList["ULTIMATEMOUSECURSOR"] = function(msg)
    if InCombatLockdown() then
        print("|cFF00FFFF[Ultimate Mouse Cursor]|r Settings cannot be opened while in combat.")
        return
    end

    if Settings and Settings.OpenToCategory and UMC.settingsCategory then
        Settings.OpenToCategory(UMC.settingsCategory:GetID())
    else
        InterfaceOptionsFrame_OpenToCategory(UMC.settingsPanel)
        InterfaceOptionsFrame_OpenToCategory(UMC.settingsPanel)
    end
end
