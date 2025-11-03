--[[
	Универсальная библиотека ESP (Extra Sensory Perception)
	Версия: 1.0
	Автор: Gemini

	Эта библиотека предоставляет универсальную систему для создания и управления ESP для любого объекта в Roblox.

	-- Краткое руководство --

	1.  -- Создание ESP для одного объекта:
		local esp = require(путь.к.библиотеке.ESP)
		local part = workspace.MyPart
		
		local partESP = esp.new(part, {
			Enabled = true,
			Label = {
				Enabled = true,
				Text = "Это важная деталь",
				Color = Color3.new(1, 1, 0)
			},
			Highlight = {
				Enabled = true,
				Color = Color3.fromRGB(255, 255, 0),
				FillTransparency = 0.5
			}
		})

		-- Вы можете отключить его позже
		-- partESP:SetEnabled(false)

		-- И уничтожить, когда он больше не нужен
		-- partESP:Destroy()

	2.  -- Автоматическое отслеживание нескольких объектов:
		local esp = require(путь.к.библиотеке.ESP)

		-- Отслеживать все модели с атрибутом "IsEnemy"
		local enemyTracker = esp.track({ Attribute = "IsEnemy" }, function(target)
			-- Эта функция вызывается для каждого найденного врага.
			-- Она должна возвращать таблицу конфигурации.
			local humanoid = target:FindFirstChildOfClass("Humanoid")
			
			return {
				Enabled = true,
				Tracer = {
					Enabled = true,
					Color = Color3.fromRGB(255, 0, 0)
				},
				Label = {
					Enabled = true,
					-- Текст может быть функцией для динамического обновления
					Text = function()
						if humanoid then
							return target.Name .. string.format(" [%.0f HP]", humanoid.Health)
						end
						return target.Name
					end,
					Color = Color3.fromRGB(255, 255, 255)
				},
				Box = {
					Enabled = true,
					Color = function()
						-- Цвет также может быть динамическим
						if humanoid and humanoid.Health < 50 then
							return Color3.new(1, 0.5, 0) -- Оранжевый, если здоровье низкое
						end
						return Color3.new(1, 0, 0) -- Красный в остальных случаях
					end
				}
			}
		end)

		-- Чтобы остановить отслеживание и очистить все ESP
		-- enemyTracker:Destroy()
]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ESP = {}
ESP.__index = ESP

-- /////////////////////////////////////////////////////////////////////////////
-- // Утилиты
-- /////////////////////////////////////////////////////////////////////////////

-- Класс Bin для управления памятью (из первого скрипта)
local Bin = {}
Bin.__index = Bin
function Bin.new()
	return setmetatable({}, Bin)
end
function Bin:add(item)
	local node = { item = item }
	if not self.head then
		self.head = node
	end
	if self.tail then
		self.tail.next = node
	end
	self.tail = node
	return item
end
function Bin:destroy()
	local head = self.head
	while head do
		local item = head.item
		if type(item) == "function" then
			pcall(item)
		elseif typeof(item) == "RBXScriptConnection" then
			item:Disconnect()
		elseif type(item) == "thread" then
			task.cancel(item)
		elseif item and typeof(item) == "Instance" then
			item:Destroy()
        elseif type(item) == "table" and item.Destroy then
            item:Destroy()
		elseif type(item) == "table" and item.destroy then
			item:destroy()
		end
		head = head.next
	end
	self.head = nil
	self.tail = nil
end

-- /////////////////////////////////////////////////////////////////////////////
-- // Основной объект ESP
-- /////////////////////////////////////////////////////////////////////////////

local ESP_OBJECT_COUNTER = 0
local SCREEN_GUI = (function()
	pcall(function()
		if gethui then
			return gethui()
		end
	end)
	
	local coreGui = game:GetService("CoreGui")
	if coreGui then
		local existing = coreGui:FindFirstChild("ESPLibraryScreenGui")
		if existing then return existing end
		
		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "ESPLibraryScreenGui"
		screenGui.ResetOnSpawn = false
		screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screenGui.Parent = coreGui
		return screenGui
	end
	return nil
end)()


local function resolveValue(value, ...)
	if type(value) == "function" then
		return value(...)
	end
	return value
end

function ESP.new(target, options)
	if not target or not target.Parent or not SCREEN_GUI then
		return nil
	end

	local self = setmetatable({}, ESP)
	self.Id = ESP_OBJECT_COUNTER
	ESP_OBJECT_COUNTER += 1

	self.target = target
	self.options = options or {}
	self.bin = Bin.new()
	self.isEnabled = false
	self.visuals = {}

	self.bin:add(target.AncestryChanged:Connect(function(_, parent)
		if not parent then
			self:Destroy()
		end
	end))

	self:_createVisuals()
	self:SetEnabled(resolveValue(self.options.Enabled, self.target) or true)
	
	return self
end

function ESP:_createVisuals()
	-- Highlight
	if self.options.Highlight then
		local config = self.options.Highlight
		if resolveValue(config.Enabled, self.target) then
			local highlight = Instance.new("Highlight")
			highlight.Name = "ESP_Highlight_" .. self.Id
			highlight.Adornee = self.target
			highlight.DepthMode = resolveValue(config.DepthMode, self.target) or Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Parent = self.target
			self.visuals.Highlight = highlight
			self.bin:add(highlight)
		end
	end

	-- Контейнер для 2D элементов
	local billboardContainer = Instance.new("BillboardGui")
	billboardContainer.Name = "ESP_Container_" .. self.Id
	billboardContainer.AlwaysOnTop = true
	billboardContainer.LightInfluence = 0
	billboardContainer.Size = UDim2.fromOffset(0, 0) -- Размер управляется элементами
	billboardContainer.ResetOnSpawn = false
	self.visuals.Billboard = billboardContainer
	self.bin:add(billboardContainer)
	
	-- Label
	if self.options.Label then
		local config = self.options.Label
		if resolveValue(config.Enabled, self.target) then
			local textLabel = Instance.new("TextLabel")
			textLabel.Name = "ESP_Label"
			textLabel.BackgroundTransparency = 1
			textLabel.Font = resolveValue(config.Font, self.target) or Enum.Font.SourceSans
			textLabel.TextSize = resolveValue(config.Size, self.target) or 16
			textLabel.TextStrokeTransparency = resolveValue(config.StrokeTransparency, self.target) or 0.5
			textLabel.Size = UDim2.new(10, 0, 2, 0) -- Широкий размер для предотвращения переноса
			textLabel.TextXAlignment = Enum.TextXAlignment.Center
			textLabel.TextYAlignment = Enum.TextYAlignment.Center
			textLabel.Parent = billboardContainer
			self.visuals.Label = textLabel
		end
	end
	
	-- Box
	if self.options.Box then
		local config = self.options.Box
		if resolveValue(config.Enabled, self.target) then
			local boxFrame = Instance.new("Frame")
			boxFrame.Name = "ESP_Box"
			boxFrame.BackgroundTransparency = 1
			boxFrame.BorderSizePixel = resolveValue(config.Thickness, self.target) or 2
			boxFrame.Parent = SCREEN_GUI
			self.visuals.Box = boxFrame
			self.bin:add(boxFrame)
		end
	end

	-- Tracer
	if self.options.Tracer then
		local config = self.options.Tracer
		if resolveValue(config.Enabled, self.target) then
			local tracerFrame = Instance.new("Frame")
			tracerFrame.Name = "ESP_Tracer"
			tracerFrame.AnchorPoint = Vector2.new(0.5, 1)
			tracerFrame.BorderSizePixel = 0
			self.visuals.Tracer = tracerFrame
			tracerFrame.Parent = SCREEN_GUI
			self.bin:add(tracerFrame)
		end
	end
end


function ESP:SetEnabled(enabled)
	if self.isEnabled == enabled then return end
	self.isEnabled = enabled

	if enabled then
		if self.updateConnection then return end
		self.updateConnection = RunService.RenderStepped:Connect(function() self:_update() end)
		self.bin:add(function()
			if self.updateConnection then
				self.updateConnection:Disconnect()
				self.updateConnection = nil
			end
		end)
	else
		for _, visual in pairs(self.visuals) do
			visual.Visible = false
		end
		if self.visuals.Billboard then
			self.visuals.Billboard.Parent = nil
		end
		if self.updateConnection then
			self.updateConnection:Disconnect()
			self.updateConnection = nil
		end
	end
end

function ESP:_update()
	if not self.target or not self.target.Parent then
		self:Destroy()
		return
	end

	local camera = Workspace.CurrentCamera
	if not camera then return end

	local primaryPart = self.target:IsA("Model") and self.target.PrimaryPart or (self.target:IsA("BasePart") and self.target)
	if not primaryPart then
		self:Destroy()
		return
	end
	
	-- Общая позиция на экране
	local worldPos = primaryPart.Position
	local posVector, onScreen = camera:WorldToViewportPoint(worldPos)
	local screenPos = Vector2.new(posVector.X, posVector.Y)
	
	-- Обновление Highlight
	local highlight = self.visuals.Highlight
	if highlight then
		local config = self.options.Highlight
		highlight.Enabled = onScreen and (resolveValue(config.Enabled, self.target) or true)
		if highlight.Enabled then
			highlight.FillColor = resolveValue(config.Color, self.target) or Color3.new(1,1,1)
			highlight.FillTransparency = resolveValue(config.FillTransparency, self.target) or 0.8
			highlight.OutlineColor = resolveValue(config.OutlineColor, self.target) or Color3.new(1,1,1)
			highlight.OutlineTransparency = resolveValue(config.OutlineTransparency, self.target) or 0
		end
	end

	-- Обновление Billboard
	local billboard = self.visuals.Billboard
	if billboard then
		if onScreen and (self.visuals.Label) then
			billboard.Adornee = primaryPart
			billboard.Parent = self.target
		else
			billboard.Parent = nil
		end
	end
	
	-- Обновление Label
	local label = self.visuals.Label
	if label and billboard.Parent then
		local config = self.options.Label
		label.Visible = resolveValue(config.Enabled, self.target) or true
		if label.Visible then
			label.TextColor3 = resolveValue(config.Color, self.target) or Color3.new(1,1,1)
			label.Text = resolveValue(config.Text, self.target) or self.target.Name
			local offset = resolveValue(config.Offset, self.target) or Vector3.new(0, primaryPart.Size.Y / 2 + 1.5, 0)
			billboard.StudsOffset = offset
		end
	end

	-- Обновление Box
	local box = self.visuals.Box
	if box then
		local config = self.options.Box
		box.Visible = onScreen and (resolveValue(config.Enabled, self.target) or false)
		if box.Visible then
			local cf, size = self.target:GetBoundingBox()
			local corners = {
				cf * Vector3.new(size.X/2, size.Y/2, size.Z/2),
				cf * Vector3.new(size.X/2, -size.Y/2, size.Z/2),
				cf * Vector3.new(-size.X/2, size.Y/2, size.Z/2),
				cf * Vector3.new(-size.X/2, -size.Y/2, size.Z/2),
				cf * Vector3.new(size.X/2, size.Y/2, -size.Z/2),
				cf * Vector3.new(size.X/2, -size.Y/2, -size.Z/2),
				cf * Vector3.new(-size.X/2, size.Y/2, -size.Z/2),
				cf * Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
			}
			
			local minX, minY = math.huge, math.huge
			local maxX, maxY = -math.huge, -math.huge

			for _, corner in ipairs(corners) do
				local cornerVec, cornerOnScreen = camera:WorldToViewportPoint(corner)
				if cornerOnScreen then
					minX = math.min(minX, cornerVec.X)
					minY = math.min(minY, cornerVec.Y)
					maxX = math.max(maxX, cornerVec.X)
					maxY = math.max(maxY, cornerVec.Y)
				end
			end
			
			if maxX > minX then
				box.Position = UDim2.fromOffset(minX, minY)
				box.Size = UDim2.fromOffset(maxX - minX, maxY - minY)
				box.BorderColor3 = resolveValue(config.Color, self.target) or Color3.new(1,1,1)
			else
				box.Visible = false
			end
		end
	end
	
	-- Обновление Tracer
	local tracer = self.visuals.Tracer
	if tracer then
		local config = self.options.Tracer
		tracer.Visible = onScreen and (resolveValue(config.Enabled, self.target) or false)
		if tracer.Visible then
			local fromPoint = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
			local fromType = resolveValue(config.From, self.target)
			if fromType == "Mouse" then
				fromPoint = game:GetService("UserInputService"):GetMouseLocation()
			elseif fromType == "Center" then
				fromPoint = camera.ViewportSize / 2
			end

			local delta = screenPos - fromPoint
			local distance = delta.Magnitude
			
			tracer.Size = UDim2.fromOffset(resolveValue(config.Thickness, self.target) or 1, distance)
			tracer.Position = UDim2.fromOffset(fromPoint.X + delta.X / 2, fromPoint.Y + delta.Y / 2)
			tracer.Rotation = math.deg(math.atan2(delta.X, -delta.Y))
			tracer.BackgroundColor3 = resolveValue(config.Color, self.target) or Color3.new(1,1,1)
		end
	end
end

function ESP:Destroy()
    if self.isDestroyed then return end
    self.isDestroyed = true
	self:SetEnabled(false)
	self.bin:destroy()
	self.visuals = {}
	self.target = nil
end

-- /////////////////////////////////////////////////////////////////////////////
-- // Контроллер отслеживания
-- /////////////////////////////////////////////////////////////////////////////

local Tracker = {}
Tracker.__index = Tracker

function ESP.track(criteria, optionsFunc)
	local self = setmetatable({}, Tracker)
	
	self.criteria = criteria or {}
	self.optionsFunc = optionsFunc
	self.trackedObjects = {} -- [Instance] = ESP_Object
	self.bin = Bin.new()

	self:_scan(Workspace)

	self.bin:add(Workspace.ChildAdded:Connect(function(child)
		self:_scan(child)
	end))

	-- AncestryChanged более надежен для отслеживания удаления
	self.bin:add(Workspace.DescendantRemoving:Connect(function(descendant)
		if self.trackedObjects[descendant] then
			self.trackedObjects[descendant]:Destroy()
			self.trackedObjects[descendant] = nil
		end
	end))

	return self
end

function Tracker:_checkAndAdd(instance)
	if self.trackedObjects[instance] then return end
	
	local match = true
	if self.criteria.ClassName and not instance:IsA(self.criteria.ClassName) then match = false end
	if self.criteria.Name and instance.Name ~= self.criteria.Name then match = false end
	if self.criteria.Attribute then
		if not instance:GetAttribute(self.criteria.Attribute) then match = false end
	end
	if self.criteria.Predicate and not self.criteria.Predicate(instance) then match = false end

	if match then
		local options = self.optionsFunc(instance)
		if options and type(options) == "table" then
			local espObj = ESP.new(instance, options)
			if espObj then
				self.trackedObjects[instance] = espObj
			end
		end
	end
end

function Tracker:_scan(parent)
	self:_checkAndAdd(parent)
	for _, child in ipairs(parent:GetChildren()) do
		self:_scan(child)
	end
end

function Tracker:Destroy()
	self.bin:destroy()
	for _, espObj in pairs(self.trackedObjects) do
		espObj:Destroy()
	end
	self.trackedObjects = {}
end

return ESP
