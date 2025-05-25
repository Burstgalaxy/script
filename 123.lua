pcall(function()
   if getgenv().RayfieldLoaded then
      Rayfield:Destroy()
   end
end)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
getgenv().RayfieldLoaded = true

local Window = Rayfield:CreateWindow({
   Name = "Dark GUI",
   LoadingTitle = "Loading...",
   LoadingSubtitle = "Hold on...",
   Theme = {
      TextColor = Color3.fromRGB(240, 240, 240),
      Background = Color3.fromRGB(10, 10, 10),
      Topbar = Color3.fromRGB(20, 20, 20),
      Shadow = Color3.fromRGB(0, 0, 0),
      NotificationBackground = Color3.fromRGB(15, 15, 15),
      NotificationActionsBackground = Color3.fromRGB(30, 30, 30),
      TabBackground = Color3.fromRGB(20, 20, 20),
      TabStroke = Color3.fromRGB(40, 40, 40),
      TabBackgroundSelected = Color3.fromRGB(50, 50, 50),
      TabTextColor = Color3.fromRGB(200, 200, 200),
      SelectedTabTextColor = Color3.fromRGB(255, 255, 255),
      ElementBackground = Color3.fromRGB(20, 20, 20),
      ElementBackgroundHover = Color3.fromRGB(30, 30, 30),
      SecondaryElementBackground = Color3.fromRGB(15, 15, 15),
      ElementStroke = Color3.fromRGB(50, 50, 50),
      SecondaryElementStroke = Color3.fromRGB(40, 40, 40),
      SliderBackground = Color3.fromRGB(60, 60, 60),
      SliderProgress = Color3.fromRGB(90, 90, 90),
      SliderStroke = Color3.fromRGB(100, 100, 100),
      ToggleBackground = Color3.fromRGB(30, 30, 30),
      ToggleEnabled = Color3.fromRGB(0, 150, 200),
      ToggleDisabled = Color3.fromRGB(80, 80, 80),
      ToggleEnabledStroke = Color3.fromRGB(0, 170, 255),
      ToggleDisabledStroke = Color3.fromRGB(100, 100, 100),
      ToggleEnabledOuterStroke = Color3.fromRGB(60, 60, 60),
      ToggleDisabledOuterStroke = Color3.fromRGB(40, 40, 40),
      DropdownSelected = Color3.fromRGB(40, 40, 40),
      DropdownUnselected = Color3.fromRGB(30, 30, 30),
      InputBackground = Color3.fromRGB(25, 25, 25),
      InputStroke = Color3.fromRGB(55, 55, 55),
      PlaceholderColor = Color3.fromRGB(150, 150, 150)
   },
   ConfigurationSaving = {
      Enabled = false
   }
})

local Tab = Window:CreateTab("TP")

local function tpTo(x, y, z)
   local plr = game.Players.LocalPlayer
   local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
   if hrp then
      hrp.CFrame = CFrame.new(x, y, z)
   end
end

local locations = {
   {name="Slatetown", x=65, y=31, z=177},
   {name="Stonewood", x=1170, y=38, z=935},
   {name="Ashenpeak", x=-565, y=28, z=1326},
   {name="Frostspire Island", x=1943, y=93, z=-1019},
   {name="Crystal Cavern", x=2212, y=-698, z=-989},
   {name="Soul Island", x=28, y=23, z=-851},
   {name="Ancient Cave", x=6, y=-119, z=-804},
   {name="Observatory", x=1777, y=34, z=348},
   {name="Old Atoll", x=546, y=28, z=1553},
   {name="Mossgrove", x=-1906, y=41, z=-621},
   {name="Living Cavern", x=-1695, y=-105, z=-856},
   {name="The Undergrove", x=-2178, y=-5158, z=-918}
}

for _, loc in ipairs(locations) do
   Tab:CreateButton({
      Name = loc.name,
      Callback = function()
         tpTo(loc.x, loc.y, loc.z)
         Rayfield:Notify({
            Title = "Teleported!",
            Content = "You are now at " .. loc.name,
            Duration = 3
         })
      end
   })
end

local MisicTab = Window:CreateTab("Misic")

local idealCritEnabled = false
local old
old = hookmetamethod(game, "__namecall", function(self, ...)
   if idealCritEnabled and not checkcaller() and getnamecallmethod() == "InvokeServer" then
      local args = {...}
      if typeof(args[1]) == "Instance" and typeof(args[2]) == "number" then
         args[2] = 1
      end
      return old(self, unpack(args))
   end
   return old(self, ...)
end)

MisicTab:CreateToggle({
   Name = "Ideal Crit",
   CurrentValue = false,
   Callback = function(Value)
      idealCritEnabled = Value
   end
})

local ShopTab = Window:CreateTab("Shop")

local function getItemPrice(item)
   local purchaseableUI = item:FindFirstChild("PurchaseableUI")
   if purchaseableUI then
      local imageLabel = purchaseableUI:FindFirstChild("ImageLabel")
      if imageLabel then
         local priceLabel = imageLabel:FindFirstChild("TextLabel")
         if priceLabel then
            return priceLabel.Text
         end
      end
   end
   return "N/A"
end

local function purchaseItem(item)
   local purchaseItemRemote = item:WaitForChild("PurchaseItem")
   if purchaseItemRemote then
      purchaseItemRemote:InvokeServer()
   end
end

local function displayBuyableItems(tab)
   for _, item in pairs(workspace:WaitForChild("BuyableItems"):GetChildren()) do
      if item:FindFirstChild("PurchaseItem") then
         local itemName = item.Name
         local itemPrice = getItemPrice(item)

         tab:CreateButton({
            Name = itemName .. " - " .. itemPrice,
            Callback = function()
               print("Attempting to buy: " .. itemName)
               purchaseItem(item)
            end
         })
      end
   end
end

displayBuyableItems(ShopTab)
