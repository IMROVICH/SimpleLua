-- SimpleLua v3 — Вдохновлено Rayfield, Orion, Fluent, WindUI
-- ModuleScript в ReplicatedStorage → SimpleLua

local S = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local function getPlayer() return Players.LocalPlayer end
local function getChar() local p = getPlayer() return p and p.Character end
local function getHumanoid() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end

local function safeCall(fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok then warn("[SimpleLua]", err) end
	return ok
end

-- ==================== ИГРОК ====================
local playerProxy = setmetatable({}, {
	__index = function(_, key)
		local k = string.lower(tostring(key))
		if k == "speed" or k == "walk" then
			return function(v) local h = getHumanoid() if h then h.WalkSpeed = v end return playerProxy end
		elseif k == "jump" then
			return function(v) local h = getHumanoid() if h then h.UseJumpPower = true h.JumpPower = v end return playerProxy end
		elseif k == "health" or k == "hp" then
			return function(v) local h = getHumanoid() if h then h.Health = v end return playerProxy end
		elseif k == "maxhealth" then
			return function(v)
				local h = getHumanoid()
				if h then h.MaxHealth = v end
				return playerProxy
			end
		elseif k == "pos" or k == "position" or k == "move" or k == "goto" then
			return function(x, y, z)
				return S.teleport(x, y, z)
			end
		elseif k == "freeze" then
			return function(state) local root = getRoot() if root then root.Anchored = state ~= false end return playerProxy end
		elseif k == "name" then return getPlayer() and getPlayer().Name
		elseif k == "character" then return getChar()
		elseif k == "humanoid" then return getHumanoid()
		elseif k == "root" then return getRoot() end
		local h = getHumanoid()
		if k == "speed" then return h and h.WalkSpeed end
		if k == "health" then return h and h.Health end
		return nil
	end,
	__newindex = function(_, key, value)
		local k = string.lower(tostring(key))
		local h = getHumanoid()
		local root = getRoot()
		if k == "speed" and h then h.WalkSpeed = value end
		if k == "jump" and h then h.UseJumpPower = true h.JumpPower = value end
		if k == "health" and h then h.Health = value end
		if (k == "pos" or k == "position") and root then
			root.CFrame = typeof(value) == "Vector3" and CFrame.new(value) or value
		end
	end
})

-- ==================== ТЕЛЕПОРТАЦИЯ ====================
function S.teleport(x, y, z)
	local root = getRoot()
	if not root then
		warn("[SimpleLua] Не удалось телепортировать: нет HumanoidRootPart")
		return S.player
	end

	local targetCFrame
	if typeof(x) == "Vector3" then
		targetCFrame = CFrame.new(x)
	elseif typeof(x) == "CFrame" then
		targetCFrame = x
	elseif typeof(x) == "Instance" and x:IsA("BasePart") then
		targetCFrame = x.CFrame + Vector3.new(0, 3, 0)
	elseif typeof(x) == "Instance" and x:IsA("Model") then
		local primary = x.PrimaryPart or x:FindFirstChild("HumanoidRootPart") or x:FindFirstChildWhichIsA("BasePart")
		if primary then
			targetCFrame = primary.CFrame + Vector3.new(0, 3, 0)
		end
	elseif type(x) == "number" then
		targetCFrame = CFrame.new(x or 0, y or 10, z or 0)
	end

	if targetCFrame then
		root.CFrame = targetCFrame
	else
		warn("[SimpleLua] Неверный формат координат для телепорта")
	end

	return S.player
end

-- Телепорт к объекту / игроку / части
function S.teleportTo(target)
	return S.teleport(target)
end

S.player = playerProxy
S.me = playerProxy
S.p = playerProxy

-- ==================== МИР ====================
S.world = setmetatable({}, {
	__index = function(_, key)
		local k = string.lower(tostring(key))
		if k == "brightness" or k == "bright" then return function(v) Lighting.Brightness = v return S.world end
		elseif k == "ambient" then return function(r, g, b) Lighting.Ambient = typeof(r) == "Color3" and r or Color3.fromRGB(r or 255, g or 255, b or 255) return S.world end
		elseif k == "fog" then return function(v) Lighting.FogEnd = v or 1000 return S.world end
		elseif k == "time" then return function(v) Lighting.ClockTime = v return S.world end
		elseif k == "gravity" then return function(v) Workspace.Gravity = v return S.world end end
		return Lighting[key]
	end
})

-- ==================== КАМЕРА ====================
S.camera = setmetatable({}, {
	__index = function(_, key)
		local cam = Workspace.CurrentCamera
		local k = string.lower(tostring(key))
		if k == "fov" then return function(v) if cam then cam.FieldOfView = v end return S.camera end
		elseif k == "look" then return function(pos) if cam then cam.CFrame = CFrame.new(cam.CFrame.Position, pos) end return S.camera end end
		return cam and cam[key]
	end
})
S.cam = S.camera

-- ==================== ЗВУКИ ====================
function S.playSound(id, volume, looped)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. tostring(id)
	sound.Volume = volume or 0.5
	sound.Looped = looped or false
	sound.Parent = SoundService
	sound:Play()
	if not looped then Debris:AddItem(sound, (sound.TimeLength or 5) + 1) end
	return sound
end
S.sound = { play = S.playSound }
function S.stopSounds()
	for _, s in ipairs(SoundService:GetChildren()) do
		if s:IsA("Sound") then s:Stop() end
	end
end

-- ==================== GUI (идеи из Rayfield / Orion / Fluent) ====================
function S.gui(name)
	local player = getPlayer()
	local playerGui = player and player:FindFirstChild("PlayerGui")
	if not playerGui then return nil end
	local gui = playerGui:FindFirstChild(name or "SimpleGui")
	if gui then return gui end
	gui = Instance.new("ScreenGui")
	gui.Name = name or "SimpleGui"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui
	return gui
end

function S.window(title, sizeX, sizeY)
	local screen = S.gui("SimpleWindow")
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, sizeX or 420, 0, sizeY or 320)
	frame.Position = UDim2.new(0.5, -(sizeX or 420)/2, 0.5, -(sizeY or 320)/2)
	frame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.Draggable = true
	frame.Parent = screen
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 36)
	titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = frame
	Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -40, 1, 0)
	titleLabel.Position = UDim2.new(0, 12, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title or "SimpleLua"
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 16
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 24, 0, 24)
	closeBtn.Position = UDim2.new(1, -30, 0, 6)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 14
	closeBtn.Parent = titleBar
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
	closeBtn.MouseButton1Click:Connect(function() screen:Destroy() end)

	local content = Instance.new("ScrollingFrame")
	content.Size = UDim2.new(1, -16, 1, -48)
	content.Position = UDim2.new(0, 8, 0, 42)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 4
	content.CanvasSize = UDim2.new(0, 0, 0, 0)
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = content

	return content, screen
end

function S.section(parent, text)
	local s = Instance.new("TextLabel")
	s.Size = UDim2.new(1, 0, 0, 24)
	s.BackgroundTransparency = 1
	s.Text = "▸ " .. (text or "Section")
	s.TextColor3 = Color3.fromRGB(100, 180, 255)
	s.Font = Enum.Font.GothamBold
	s.TextSize = 14
	s.TextXAlignment = Enum.TextXAlignment.Left
	s.Parent = parent
	return s
end

function S.label(parent, text)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 0, 22)
	l.BackgroundTransparency = 1
	l.Text = text or ""
	l.TextColor3 = Color3.fromRGB(220, 220, 230)
	l.Font = Enum.Font.Gotham
	l.TextSize = 14
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

function S.button(parent, text, callback)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 34)
	b.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
	b.Text = text or "Button"
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	if callback then b.MouseButton1Click:Connect(function() safeCall(callback) end) end
	return b
end

function S.toggle(parent, text, default, callback)
	local state = default or false
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, 0, 0, 34)
	holder.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
	holder.Parent = parent
	Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -50, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text or "Toggle"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = holder

	local box = Instance.new("TextButton")
	box.Size = UDim2.new(0, 28, 0, 18)
	box.Position = UDim2.new(1, -38, 0.5, -9)
	box.BackgroundColor3 = state and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(60, 60, 75)
	box.Text = ""
	box.Parent = holder
	Instance.new("UICorner", box).CornerRadius = UDim.new(1, 0)

	local function update()
		box.BackgroundColor3 = state and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(60, 60, 75)
		if callback then safeCall(callback, state) end
	end

	box.MouseButton1Click:Connect(function()
		state = not state
		update()
	end)
	update()
	return holder
end

function S.dropdown(parent, text, options, callback)
	local selected = options[1] or ""
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, 0, 0, 34)
	holder.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
	holder.Parent = parent
	Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = (text or "Select") .. ": " .. selected .. " ▼"
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 14
	btn.Parent = holder

	local list = Instance.new("Frame")
	list.Size = UDim2.new(1, 0, 0, #options * 28)
	list.Position = UDim2.new(0, 0, 1, 4)
	list.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
	list.Visible = false
	list.ZIndex = 5
	list.Parent = holder
	Instance.new("UICorner", list).CornerRadius = UDim.new(0, 6)
	local listLayout = Instance.new("UIListLayout")
	listLayout.Parent = list

	for _, opt in ipairs(options) do
		local optBtn = Instance.new("TextButton")
		optBtn.Size = UDim2.new(1, 0, 0, 28)
		optBtn.BackgroundTransparency = 1
		optBtn.Text = opt
		optBtn.TextColor3 = Color3.new(1, 1, 1)
		optBtn.Font = Enum.Font.Gotham
		optBtn.TextSize = 13
		optBtn.Parent = list
		optBtn.MouseButton1Click:Connect(function()
			selected = opt
			btn.Text = (text or "Select") .. ": " .. selected .. " ▼"
			list.Visible = false
			if callback then safeCall(callback, selected) end
		end)
	end

	btn.MouseButton1Click:Connect(function()
		list.Visible = not list.Visible
	end)
	return holder
end

function S.slider(parent, text, min, max, default, callback)
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, 0, 0, 48)
	holder.BackgroundTransparency = 1
	holder.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 18)
	label.BackgroundTransparency = 1
	label.Text = (text or "Slider") .. ": " .. (default or min)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = holder

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 8)
	bar.Position = UDim2.new(0, 0, 0, 26)
	bar.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
	bar.Parent = holder
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(((default or min) - min) / (max - min), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
	fill.Parent = bar
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local dragging = false
	bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
	UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			local val = math.floor(min + rel * (max - min) + 0.5)
			fill.Size = UDim2.new(rel, 0, 1, 0)
			label.Text = (text or "Slider") .. ": " .. val
			if callback then safeCall(callback, val) end
		end
	end)
	return holder
end

function S.close(obj) if obj then obj:Destroy() end end

-- ==================== АНИМАЦИИ / ЭФФЕКТЫ ====================
function S.animate(charOrHumanoid, animId)
	local humanoid = charOrHumanoid
	if typeof(charOrHumanoid) == "Instance" and charOrHumanoid:IsA("Model") then
		humanoid = charOrHumanoid:FindFirstChildOfClass("Humanoid")
	end
	if not humanoid then return nil end
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(animId)
	local track = humanoid:LoadAnimation(anim)
	track:Play()
	return track
end

function S.tween(obj, props, time, style)
	local info = TweenInfo.new(time or 1, style or Enum.EasingStyle.Quad)
	local tw = TweenService:Create(obj, info, props)
	tw:Play()
	return tw
end

function S.moveTo(obj, pos, time) return S.tween(obj, {Position = pos}, time or 1) end
function S.fade(obj, transparency, time)
	local props = obj:IsA("GuiObject") and {BackgroundTransparency = transparency or 1} or {Transparency = transparency or 1}
	return S.tween(obj, props, time or 0.5)
end
function S.spin(obj, time)
	return S.tween(obj, {CFrame = obj.CFrame * CFrame.Angles(0, math.rad(360), 0)}, time or 2)
end

function S.particles(parent, color, rate)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color or Color3.new(1,1,1))
	e.Rate = rate or 20
	e.Lifetime = NumberRange.new(1, 2)
	e.Speed = NumberRange.new(4, 10)
	e.Parent = parent
	return e
end

-- ==================== ВВОД ====================
function S.onKey(key, callback)
	local keyCode
	local ok, result = pcall(function()
		return Enum.KeyCode[key]
	end)
	if ok and result then
		keyCode = result
	else
		keyCode = Enum.KeyCode[string.upper(tostring(key))] or nil
	end
	if not keyCode then
		warn("[SimpleLua] Неизвестная клавиша:", key)
		return
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == keyCode then
			safeCall(callback)
		end
	end)
end

-- ==================== УТИЛИТЫ ====================
function S.wait(s) return task.wait(s or 0) end
function S.sleep(s) return task.wait(s or 0) end
function S.say(...) print(...) end
function S.log(...) print("[SimpleLua]", ...) end
function S.warn(...) warn("[SimpleLua]", ...) end

function S.notify(title, text, duration)
	safeCall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title or "Info",
			Text = text or "",
			Duration = duration or 3
		})
	end)
end

function S.find(name) return Workspace:FindFirstChild(name, true) end
function S.destroy(obj) if obj and obj.Destroy then obj:Destroy() end end
function S.clone(obj) return obj and obj:Clone() end

-- Проверка на существование элемента
function S.exists(obj)
	if obj == nil then return false end
	if typeof(obj) == "Instance" then
		return obj.Parent ~= nil
	end
	return true
end

-- Ждать появления элемента (по имени или пути)
function S.waitFor(parent, name, timeout)
	timeout = timeout or 10
	local start = tick()
	local result = parent:FindFirstChild(name)
	while not result and (tick() - start) < timeout do
		task.wait(0.1)
		result = parent:FindFirstChild(name)
	end
	return result
end

-- Безопасное получение свойства
function S.get(obj, property, default)
	if not S.exists(obj) then return default end
	local ok, value = pcall(function() return obj[property] end)
	return ok and value or default
end

-- ==================== ОРУЖИЕ ====================
-- Проверить, есть ли оружие у игрока (в рюкзаке или в руках)
function S.hasWeapon(name)
	local player = getPlayer()
	if not player then return false end

	-- В рюкзаке
	local backpack = player:FindFirstChild("Backpack")
	if backpack and backpack:FindFirstChild(name) then
		return true
	end

	-- В руках (Character)
	local char = getChar()
	if char and char:FindFirstChild(name) then
		return true
	end

	return false
end

-- Получить оружие (Tool)
function S.getWeapon(name)
	local player = getPlayer()
	if not player then return nil end

	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		local tool = backpack:FindFirstChild(name)
		if tool and tool:IsA("Tool") then return tool end
	end

	local char = getChar()
	if char then
		local tool = char:FindFirstChild(name)
		if tool and tool:IsA("Tool") then return tool end
	end

	return nil
end

-- Ждать появления оружия
function S.waitForWeapon(name, timeout)
	timeout = timeout or 10
	local start = tick()
	while not S.hasWeapon(name) and (tick() - start) < timeout do
		task.wait(0.2)
	end
	return S.getWeapon(name)
end

function S.part(size, pos, color)
	local p = Instance.new("Part")
	p.Size = typeof(size) == "Vector3" and size or Vector3.new(4,1,4)
	p.Position = typeof(pos) == "Vector3" and pos or Vector3.new(0,5,0)
	p.Anchored = true
	p.Color = typeof(color) == "Color3" and color or Color3.fromRGB(80, 140, 255)
	p.Parent = Workspace
	return p
end

function S.sphere(r, pos)
	local p = S.part(Vector3.new(r*2, r*2, r*2), pos)
	p.Shape = Enum.PartType.Ball
	return p
end

-- ==================== MAID (очистка ресурсов, идея из RbxUtil/Nevermore) ====================
function S.maid()
	local maid = {
		_tasks = {}
	}

	function maid:give(task)
		if task == nil then return end
		table.insert(self._tasks, task)
		return task
	end

	function maid:clean()
		for i = #self._tasks, 1, -1 do
			local task = self._tasks[i]
			self._tasks[i] = nil
			if typeof(task) == "RBXScriptConnection" then
				task:Disconnect()
			elseif typeof(task) == "Instance" then
				task:Destroy()
			elseif type(task) == "function" then
				pcall(task)
			elseif type(task) == "thread" then
				pcall(task.cancel, task)
			elseif type(task) == "table" and task.Destroy then
				pcall(function() task:Destroy() end)
			elseif type(task) == "table" and task.clean then
				pcall(function() task:clean() end)
			end
		end
	end

	function maid:destroy()
		self:clean()
	end

	return maid
end

-- ==================== SIGNAL (свои события, идея из RbxUtil) ====================
function S.signal()
	local signal = {
		_connections = {}
	}

	function signal:connect(fn)
		local conn = {
			Connected = true,
			_fn = fn
		}
		function conn:disconnect()
			self.Connected = false
			for i, c in ipairs(signal._connections) do
				if c == self then
					table.remove(signal._connections, i)
					break
				end
			end
		end
		table.insert(signal._connections, conn)
		return conn
	end

	function signal:fire(...)
		local args = {...}
		for _, conn in ipairs(signal._connections) do
			if conn.Connected then
				task.spawn(function()
					pcall(conn._fn, table.unpack(args))
				end)
			end
		end
	end

	function signal:wait()
		local thread = coroutine.running()
		if not thread then
			warn("[SimpleLua] signal:wait() нужно вызывать из корутины (task.spawn / coroutine)")
			return
		end
		local conn
		conn = self:connect(function(...)
			if conn then
				conn:disconnect()
				conn = nil
			end
			task.defer(thread, ...)
		end)
		return coroutine.yield()
	end

	function signal:destroy()
		for _, conn in ipairs(self._connections) do
			conn:disconnect()
		end
		self._connections = {}
	end

	return signal
end

-- ==================== SPRING (плавная анимация, идея из Otter / Nevermore) ====================
-- Поддерживает только числа (для простоты и стабильности)
function S.spring(initial, frequency, damping)
	local spring = {
		position = initial or 0,
		velocity = 0,
		target = initial or 0,
		frequency = math.max(0.1, frequency or 4),
		damping = math.clamp(damping or 1, 0, 2)
	}

	function spring:setTarget(value)
		self.target = value
	end

	function spring:step(dt)
		dt = math.clamp(dt, 0, 0.1) -- защита от больших dt
		local f = self.frequency * 2 * math.pi
		local d = self.damping
		local pos = self.position
		local vel = self.velocity
		local target = self.target

		local acc = f * f * (target - pos) - 2 * d * f * vel
		self.velocity = vel + acc * dt
		self.position = pos + self.velocity * dt
		return self.position
	end

	function spring:update(dt, callback)
		local value = self:step(dt)
		if callback then callback(value) end
		return value
	end

	return spring
end

-- Простой spring для числовых свойств объекта
function S.springTo(obj, property, target, frequency, damping, duration)
	if typeof(target) ~= "number" then
		warn("[SimpleLua] springTo поддерживает только числа")
		return
	end
	local start = obj[property]
	if typeof(start) ~= "number" then
		warn("[SimpleLua] Свойство должно быть числом")
		return
	end

	local spring = S.spring(start, frequency or 5, damping or 0.8)
	spring:setTarget(target)

	local conn
	local elapsed = 0
	local maxTime = duration or 3
	conn = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		local value = spring:step(dt)
		local success = pcall(function()
			obj[property] = value
		end)
		if not success or elapsed > maxTime or math.abs(value - target) < 0.05 then
			conn:Disconnect()
			pcall(function() obj[property] = target end)
		end
	end)
	return conn
end

-- ==================== PROMISE (простой, идея из RbxUtil) ====================
function S.promise(executor)
	local promise = {
		_status = "pending",
		_value = nil,
		_callbacks = {}
	}

	function promise:andThen(fn)
		if self._status == "resolved" then
			task.spawn(fn, self._value)
		else
			table.insert(self._callbacks, fn)
		end
		return self
	end

	function promise:catch(fn)
		-- упрощённо
		return self
	end

	local function resolve(value)
		if promise._status ~= "pending" then return end
		promise._status = "resolved"
		promise._value = value
		for _, cb in ipairs(promise._callbacks) do
			task.spawn(cb, value)
		end
	end

	local function reject(err)
		promise._status = "rejected"
		warn("[Promise]", err)
	end

	task.spawn(function()
		local ok, err = pcall(executor, resolve, reject)
		if not ok then reject(err) end
	end)

	return promise
end

-- ==================== ДАННЫЕ (простой DataStore helper) ====================
local DataStoreService = game:GetService("DataStoreService")

function S.saveData(storeName, key, data)
	key = tostring(key)
	local ok, err = pcall(function()
		local store = DataStoreService:GetDataStore(storeName)
		store:SetAsync(key, data)
	end)
	if not ok then warn("[SimpleLua] Ошибка сохранения:", err) end
	return ok
end

function S.loadData(storeName, key, default)
	key = tostring(key)
	local ok, result = pcall(function()
		local store = DataStoreService:GetDataStore(storeName)
		return store:GetAsync(key)
	end)
	if ok and result ~= nil then
		return result
	else
		if not ok then warn("[SimpleLua] Ошибка загрузки:", result) end
		return default
	end
end

function S.enableGlobals()
	_G.player = S.player
	_G.world = S.world
	_G.camera = S.camera
	_G.say = S.say
	_G.notify = S.notify
	_G.onKey = S.onKey
	_G.maid = S.maid
	_G.signal = S.signal
	print("[SimpleLua] Глобальные функции включены")
end

return S
