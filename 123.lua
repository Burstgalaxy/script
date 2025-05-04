local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Custom Hub",
   Icon = 0,
   LoadingTitle = "Rayfield Interface Suite",
   LoadingSubtitle = "by Sirius",
   Theme = "Default",
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "CustomHub"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false,
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided",
      FileName = "Key",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"Hello"}
   }
})

-- Создание вкладки
local MainTab = Window:CreateTab("Main", 0)

-- Функция для покупки предмета
local function purchaseItem(item)
    local purchaseItemRemote = item:WaitForChild("PurchaseItem")
    if purchaseItemRemote then
        purchaseItemRemote:InvokeServer()
    end
end

-- Секция для отображения предметов
local BuySection = MainTab:CreateSection("Auto Purchase Items")

-- Функция для получения цены из TextLabel внутри PurchaseableUI
local function getItemPrice(item)
    local purchaseableUI = item:FindFirstChild("PurchaseableUI")
    if purchaseableUI then
        local imageLabel = purchaseableUI:FindFirstChild("ImageLabel")
        if imageLabel then
            local priceLabel = imageLabel:FindFirstChild("TextLabel")
            if priceLabel then
                return priceLabel.Text -- Возвращаем текст с ценой
            end
        end
    end
    return "N/A" -- Если цена не найдена
end

-- Функция для отображения предметов в меню
local function displayItems()
    -- Проходим по всем предметам в Workspace.BuyableItems
    for _, item in pairs(workspace:WaitForChild("BuyableItems"):GetChildren()) do
        if item:FindFirstChild("PurchaseItem") then
            -- Получаем название предмета
            local itemName = item.Name
            -- Получаем цену с помощью функции getItemPrice
            local itemPrice = getItemPrice(item)
            
            -- Добавляем кнопку для покупки предмета
            MainTab:CreateButton({
                Name = itemName .. " - " .. itemPrice,
                Callback = function()
                    print("Attempting to buy: " .. itemName)
                    purchaseItem(item) -- Покупаем предмет
                end
            })
        end
    end
end

-- Вызываем функцию для отображения всех предметов
displayItems()

-- Загрузка сохранённых настроек
Rayfield:LoadConfiguration()
