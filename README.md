# SimpleLua v3.2 — Подробная документация

**SimpleLua** — это упрощённая библиотека для Roblox, которая делает код короче и понятнее.  
Вместо длинных цепочек `game.Players.LocalPlayer.Character.Humanoid.WalkSpeed` можно писать `S.player.speed(50)`.

---

## Установка

1. Создай **ModuleScript** в `ReplicatedStorage`.
2. Назови его точно **SimpleLua**.
3. Вставь весь код из `SimpleLua.lua`.
4. В своём скрипте (LocalScript или Script) пиши:

```lua
local S = require(game.ReplicatedStorage.SimpleLua)
```

---

## Игрок (S.player / S.me / S.p)

### Изменение параметров

| Функция | Что делает | Пример |
|---------|------------|--------|
| `.speed(число)` | Устанавливает WalkSpeed | `S.player.speed(50)` |
| `.jump(число)` | Устанавливает JumpPower | `S.player.jump(80)` |
| `.health(число)` | Устанавливает здоровье | `S.player.health(100)` |
| `.maxhealth(число)` | Устанавливает максимум здоровья | `S.player.maxhealth(150)` |
| `.freeze(true/false)` | Замораживает персонажа | `S.player.freeze(true)` |

### Телепортация

```lua
-- По координатам
S.teleport(0, 10, 0)
S.player.pos(0, 10, 0)
S.player.goto(0, 50, 0)

-- По Vector3
S.teleport(Vector3.new(10, 20, 30))

-- По CFrame
S.teleport(CFrame.new(0, 50, 0))

-- К объекту (Part / Model / Tool)
S.teleport(workspace.Part)
S.teleportTo(workspace.SpawnLocation)

-- К другому игроку
local other = game.Players:FindFirstChild("PlayerName")
if other and other.Character then
    S.teleport(other.Character)
end
```

### Получение данных

```lua
print(S.player.name)        -- имя игрока
print(S.player.character)   -- персонаж
print(S.player.humanoid)    -- Humanoid
print(S.player.root)        -- HumanoidRootPart
```

---

## Мир (S.world)

```lua
S.world.brightness(2)           -- яркость
S.world.ambient(100, 100, 255)  -- цвет окружения (RGB или Color3)
S.world.fog(500)                -- дальность тумана
S.world.time(14)                -- время суток (0–24)
S.world.gravity(50)             -- гравитация
```

---

## Камера (S.camera / S.cam)

```lua
S.camera.fov(70)                        -- поле зрения
S.camera.look(Vector3.new(0, 10, 0))    -- посмотреть на точку
```

---

## Звуки

```lua
-- Проиграть звук (ID с Roblox)
local sound = S.playSound(12222216, 0.5, false)  -- id, громкость, зациклить

-- Остановить все звуки
S.stopSounds()
```

---

## GUI

```lua
-- Создать окно
local win = S.window("Моё меню", 400, 300)

-- Кнопка
S.button(win, "Нажми меня", function()
    S.notify("Кнопка", "Ты нажал!")
end)

-- Переключатель
S.toggle(win, "Скорость", false, function(state)
    S.player.speed(state and 50 or 16)
end)

-- Слайдер
S.slider(win, "Громкость", 0, 1, 0.5, function(value)
    print("Громкость:", value)
end)

-- Выпадающий список
S.dropdown(win, "Выбери", {"Вариант 1", "Вариант 2"}, function(choice)
    print("Выбрано:", choice)
end)

-- Секция
S.section(win, "Настройки игрока")
```

---

## Оружие

```lua
-- Есть ли оружие
if S.hasWeapon("ClassicSword") then
    print("Меч есть!")
end

-- Получить оружие
local tool = S.getWeapon("Gun")
if tool then
    tool.Parent = S.player.character  -- экипировать
end

-- Ждать появления оружия
local axe = S.waitForWeapon("Axe", 10)  -- максимум 10 секунд
```

---

## Утилиты

```lua
-- Существует ли объект
if S.exists(part) then
    print("Объект жив")
end

-- Ждать появления элемента
local item = S.waitFor(player.Backpack, "Key", 5)

-- Безопасно получить свойство
local speed = S.get(humanoid, "WalkSpeed", 16)

-- Создать часть
local part = S.part(Vector3.new(4, 1, 4), Vector3.new(0, 10, 0), Color3.new(1, 0, 0))

-- Создать сферу
local sphere = S.sphere(3, Vector3.new(0, 20, 0))

-- Уведомление
S.notify("Заголовок", "Текст уведомления", 4)

-- Ожидание
S.wait(2)
S.sleep(1)
```

---

## Maid (очистка ресурсов)

Автоматически отключает соединения и уничтожает объекты.

```lua
local maid = S.maid()

local conn = workspace.ChildAdded:Connect(function(child)
    print(child.Name)
end)
maid:give(conn)

local part = S.part(4)
maid:give(part)

-- Когда больше не нужно
maid:clean()
```

---

## Signal (свои события)

```lua
local event = S.signal()

event:connect(function(message)
    print("Получено:", message)
end)

event:fire("Привет!")

-- Ждать (только из корутины)
task.spawn(function()
    local result = event:wait()
    print("Дождались:", result)
end)
```

---

## Spring (плавные анимации)

**Работает только с числами.**

```lua
local spring = S.spring(0, 5, 0.8)  -- начальное значение, частота, демпфирование
spring:setTarget(100)

-- Анимировать свойство
local part = S.part(4)
S.springTo(part, "Transparency", 1, 4, 0.7, 2)
```

---

## Данные (DataStore)

```lua
-- Сохранить
S.saveData("PlayerData", player.UserId, {
    Coins = 100,
    Level = 5
})

-- Загрузить
local data = S.loadData("PlayerData", player.UserId, {Coins = 0, Level = 1})
print(data.Coins)
```

---

## Глобальные функции (опционально)

```lua
S.enableGlobals()

-- Теперь можно писать без S.
player.speed(50)
say("Привет")
notify("Тест", "Работает")
```

---

## Примеры использования

### Простой скрипт

```lua
local S = require(game.ReplicatedStorage.SimpleLua)

S.player.speed(30)
S.player.jump(60)
S.teleport(0, 50, 0)
S.notify("Готово", "Персонаж изменён")
```

### С меню

```lua
local S = require(game.ReplicatedStorage.SimpleLua)

local win = S.window("Панель", 380, 280)

S.button(win, "Телепорт вверх", function()
    local pos = S.player.root.Position
    S.teleport(pos.X, pos.Y + 20, pos.Z)
end)

S.toggle(win, "Быстрый бег", false, function(on)
    S.player.speed(on and 80 or 16)
end)
```

---

**SimpleLua** создан для быстрого прототипирования и удобной работы в Roblox Studio.  
Если нужна новая функция — напиши.
