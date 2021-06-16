ModUtil.RegisterMod("BarberPole")

local config = {
  ModName = "Barber Pole",
  Enabled = true
}

if ModConfigMenu then
  ModConfigMenu.Register(config)
end

local Slots = {
  "WeaponTrait",
  "SecondaryTrait",
  "RangedTrait",
  "RushTrait",
  "ShoutTrait"
}

local Gods = {
  "Aphrodite",
  "Artemis",
  "Ares",
  "Athena",
  "Demeter",
  "Dionysus",
  "Poseidon",
  "Zeus"
}

ModUtil.WrapBaseFunction("SetupMap", function(baseFunc)
  local names = {}
  for _, god in ipairs(Gods) do
    names[#names + 1] = god .. "Upgrade"
  end
  LoadPackages({ Names = names })
  return baseFunc()
end)

local function NextSlotIndex(i)
  local nextSlotIndex = i + 1
  if nextSlotIndex > #Slots then
    nextSlotIndex = 1
  end
  return nextSlotIndex
end


local function GodSlotName(god, slot)
  if slot == "RangedTrait" and
     HeroHasTrait("ShieldLoadAmmoTrait") and
     god ~= "Poseidon" and
     god ~= "Dionysus" then
    return "ShieldLoadAmmo_" .. god .. slot
  else
    return god .. slot
  end
end

local function GetTraitRarity(name)
  for _, traitData in pairs( CurrentRun.Hero.Traits ) do
    if traitData.Name == name then
      return traitData.Rarity
    end
  end
end

local function RemoveTraitForSlot(slot)
  for _, god in ipairs(Gods) do
    local name = GodSlotName(god, slot)
    while HeroHasTrait(name) do
      local level = GetTraitNameCount( CurrentRun.Hero, name )
      local rarity = GetTraitRarity( name )
      RemoveWeaponTrait( name )
      return {
        God = god,
        Level = level,
        Rarity = rarity
      }
    end
  end
end

ModUtil.WrapBaseFunction("StartRoom", function(baseFunc, currentRun, currentRoom)
  local previousBoons = {}
  -- for each slot, remove the current trait
  for _, slot in ipairs(Slots) do
    previousBoons[slot] = RemoveTraitForSlot(slot)
  end
  -- for each slot, add the new trait
  for i, slot in ipairs(Slots) do
    local previousBoon = previousBoons[Slots[NextSlotIndex(i)]]
    if previousBoon then
      local name = GodSlotName(previousBoon.God, slot)
      for i=1,previousBoon.Level do
        AddTraitToHero({
          TraitName = name,
          Rarity = previousBoon.Rarity
        })
      end
    end
  end

  return baseFunc(currentRun, currentRoom)
end)
