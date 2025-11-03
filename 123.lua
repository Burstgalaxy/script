--[[
	Универсальная библиотека ESP (Extra Sensory Perception)
	Версия: 1.3 (Интегрирована профессиональная логика трассировщиков через Drawing.new("Line"))
	Автор: Gemini
]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Проверка, поддерживает ли эксплойт Drawing API
if not Drawing then
	warn("ESP Library: Drawing API не найдено. 2D-визуалы (Tracer, Box) не будут работать.")
	return
end

local ESP = {}
ESP.__index = ESP

-- /////////////////////////////////////////////////////////////////////////////
-- // Утилиты (без изменений)
-- /////////////////////////////////////////////////////////////////////////////
local Bin = {}
Bin.__index = Bin
function Bin.new() return setmetatable({}, Bin) end
function Bin:add(item) local node = { item = item }; if not self.head then self.head = node end; if self.tail then self.tail.next = node end; self.tail = node; return item end
function Bin:destroy() local head = self.head; while head do local item = head.item; if type(item) == "function" then pcall(item) elseif typeof(item) == "RBXScriptConnection" then item:Disconnect() elseif type(item) == "thread" then task.cancel(item) elseif item and typeof(item) == "Instance" then item:Destroy() elseif type(item) == "table" and item.Destroy then pcall(item.Destroy, item) elseif type(item) == "table" and item.destroy then pcall(item.destroy, item) elseif type(item) == "table" and item.Remove then pcall(item.Remove, item) end; head = head.next end; self.head = nil; self.tail = nil end

-- /////////////////////////////////////////////////////////////////////////////
-- // Основной объект ESP
-- /////////////////////////////////////////////////////////////////////////////

local ESP_OBJECT_COUNTER = 0
local function resolveValue(value, ...) if type(value) == "function" then return value(...) end; return value end

function ESP.new(target, options)
	if not target or not target.Parent then return nil end
	local self = setmetatable({}, ESP); self.Id = ESP_OBJECT_COUNTER; ESP_OBJECT_COUNTER += 1; self.target = target; self.options = options or {}; self.bin = Bin.new(); self.isEnabled = false; self.visuals = {}; self.bin:add(target.AncestryChanged:Connect(function(_, parent) if not parent then self:Destroy() end end)); self:_createVisuals(); self:SetEnabled(resolveValue(self.options.Enabled, self.target) or true); return self
end

function ESP:_createVisuals()
	-- Highlight (без изменений)
	if self.options.Highlight then local config = self.options.Highlight; if resolveValue(config.Enabled, self.target) then local highlight = Instance.new("Highlight"); highlight.Name = "ESP_Highlight_"..self.Id; highlight.Adornee = self.target; highlight.DepthMode = resolveValue(config.DepthMode, self.target) or Enum.HighlightDepthMode.AlwaysOnTop; highlight.Parent = self.target; self.visuals.Highlight = highlight; self.bin:add(highlight) end end
	
	-- Billboard (Label) (без изменений)
	if self.options.Label then local billboardContainer = Instance.new("BillboardGui"); billboardContainer.Name = "ESP_Container_"..self.Id; billboardContainer.AlwaysOnTop = true; billboardContainer.LightInfluence = 0; billboardContainer.Size = UDim2.fromOffset(0, 0); billboardContainer.ResetOnSpawn = false; self.visuals.Billboard = billboardContainer; self.bin:add(billboardContainer); local config = self.options.Label; if resolveValue(config.Enabled, self.target) then local textLabel = Instance.new("TextLabel"); textLabel.Name = "ESP_Label"; textLabel.BackgroundTransparency = 1; textLabel.Font = resolveValue(config.Font, self.target) or Enum.Font.SourceSans; textLabel.TextSize = resolveValue(config.Size, self.target) or 16; textLabel.TextStrokeTransparency = resolveValue(config.StrokeTransparency, self.target) or 0.5; textLabel.Size = UDim2.new(10, 0, 2, 0); textLabel.TextXAlignment = Enum.TextXAlignment.Center; textLabel.TextYAlignment = Enum.TextYAlignment.Center; textLabel.Parent = billboardContainer; self.visuals.Label = textLabel end end
	
	-- [[ ИЗМЕНЕНО ]] Tracer теперь использует Drawing.new("Line")
	if self.options.Tracer then
		local config = self.options.Tracer
		if resolveValue(config.Enabled, self.target) then
			local tracerLine = Drawing.new("Line")
			self.visuals.Tracer = tracerLine
			self.bin:add(tracerLine) -- Bin автоматически вызовет :Remove() при уничтожении
		end
	end
end

function ESP:SetEnabled(enabled)
	if self.isEnabled == enabled then return end; self.isEnabled = enabled
	if enabled then if self.updateConnection then return end; self.updateConnection = RunService.RenderStepped:Connect(function() self:_update() end); self.bin:add(function() if self.updateConnection then self.updateConnection:Disconnect(); self.updateConnection = nil end end) else for _, visual in pairs(self.visuals) do if visual and visual.Visible then visual.Visible = false end end; if self.visuals.Billboard then self.visuals.Billboard.Parent = nil end; if self.updateConnection then self.updateConnection:Disconnect(); self.updateConnection = nil end end
end

function ESP:_update()
	if not self.target or not self.target.Parent then self:Destroy(); return end
	local camera = Workspace.CurrentCamera; if not camera then return end
	local primaryPart = self.target:IsA("Model") and (self.target.PrimaryPart or self.target:FindFirstChild("HumanoidRootPart") or self.target:FindFirstChild("Head")) or (self.target:IsA("BasePart") and self.target);
	if not primaryPart then self:Destroy(); return end
	
	local worldPos, onScreen = camera:WorldToViewportPoint(primaryPart.Position);
	
	-- Highlight (без изменений)
	local highlight = self.visuals.Highlight; if highlight then local config = self.options.Highlight; highlight.Enabled = onScreen and (resolveValue(config.Enabled, self.target) or true); if highlight.Enabled then highlight.FillColor = resolveValue(config.Color, self.target) or Color3.new(1,1,1); highlight.FillTransparency = resolveValue(config.FillTransparency, self.target) or 0.8; highlight.OutlineColor = resolveValue(config.OutlineColor, self.target) or Color3.new(1,1,1); highlight.OutlineTransparency = resolveValue(config.OutlineTransparency, self.target) or 0 end end
	
	-- Label (без изменений)
	local label = self.visuals.Label; if label then local billboard = self.visuals.Billboard; if onScreen then billboard.Adornee = primaryPart; billboard.Parent = self.target else billboard.Parent = nil end; if billboard.Parent then local config = self.options.Label; label.Visible = resolveValue(config.Enabled, self.target) or true; if label.Visible then label.TextColor3 = resolveValue(config.Color, self.target) or Color3.new(1,1,1); label.Text = resolveValue(config.Text, self.target) or self.target.Name; local offset = resolveValue(config.Offset, self.target) or Vector3.new(0, primaryPart.Size.Y / 2 + 1.5, 0); billboard.StudsOffset = offset end end end

	-- [[ ИЗМЕНЕНО ]] Логика обновления Tracer полностью заменена на логику из твоего примера
	local tracer = self.visuals.Tracer
	if tracer then
		local config = self.options.Tracer
		local isVisible = resolveValue(config.Enabled, self.target) or false
		
		if not isVisible then
			tracer.Visible = false
			return
		end

		local targetPosition
		local targetType = resolveValue(config.Target, self.target) or "Head"
		
		if targetType == "Head" and self.target:FindFirstChild("Head") then
			targetPosition = self.target.Head.Position
		elseif targetType == "Torso" and self.target:FindFirstChild("HumanoidRootPart") then
			targetPosition = self.target.HumanoidRootPart.Position
		elseif targetType == "Feet" and self.target:FindFirstChild("HumanoidRootPart") then
			local hrp = self.target.HumanoidRootPart
			targetPosition = (hrp.CFrame * CFrame.new(0, -hrp.Size.Y / 2, 0)).Position
		else
			targetPosition = primaryPart.Position -- Запасной вариант
		end

		if not targetPosition then
			tracer.Visible = false
			return
		end

		local vector, onScreenTarget = camera:WorldToViewportPoint(targetPosition)
		tracer.Visible = onScreenTarget
		
		if onScreenTarget then
			tracer.Color = resolveValue(config.Color, self.target) or Color3.new(1,1,1)
			tracer.Thickness = resolveValue(config.Thickness, self.target) or 1
			tracer.Transparency = resolveValue(config.Transparency, self.target) or 0
			tracer.To = Vector2.new(vector.X, vector.Y)

			local fromType = resolveValue(config.From, self.target) or "Center"
			if fromType == "Mouse" then
				tracer.From = game:GetService("UserInputService"):GetMouseLocation()
			elseif fromType == "Bottom" then
				tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
			else -- Center
				tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
			end
		end
	end
end

function ESP:Destroy() if self.isDestroyed then return end; self.isDestroyed = true; self:SetEnabled(false); self.bin:destroy(); self.visuals = {}; self.target = nil end

-- /////////////////////////////////////////////////////////////////////////////
-- // Контроллер отслеживания (без изменений)
-- /////////////////////////////////////////////////////////////////////////////
local Tracker = {}
Tracker.__index = Tracker
function ESP.track(criteria, optionsFunc) local self = setmetatable({}, Tracker); self.criteria = criteria or {}; self.optionsFunc = optionsFunc; self.trackedObjects = {}; self.bin = Bin.new(); self:_scan(Workspace); self.bin:add(Workspace.ChildAdded:Connect(function(child) self:_scan(child) end)); self.bin:add(Workspace.DescendantRemoving:Connect(function(descendant) if self.trackedObjects[descendant] then self.trackedObjects[descendant]:Destroy(); self.trackedObjects[descendant] = nil end end)); return self end
function Tracker:_checkAndAdd(instance) if self.trackedObjects[instance] then return end; local match = true; if self.criteria.ClassName and not instance:IsA(self.criteria.ClassName) then match = false end; if self.criteria.Name and instance.Name ~= self.criteria.Name then match = false end; if self.criteria.Attribute then if not instance:GetAttribute(self.criteria.Attribute) then match = false end end; if self.criteria.Predicate and not self.criteria.Predicate(instance) then match = false end; if match then local options = self.optionsFunc(instance); if options and type(options) == "table" then local espObj = ESP.new(instance, options); if espObj then self.trackedObjects[instance] = espObj end end end end
function Tracker:_scan(parent) self:_checkAndAdd(parent); for _, child in ipairs(parent:GetChildren()) do self:_scan(child) end end
function Tracker:Destroy() self.bin:destroy(); for _, espObj in pairs(self.trackedObjects) do espObj:Destroy() end; self.trackedObjects = {} end

return ESP
