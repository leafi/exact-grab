local clear_key = {
  type="custom-input",
  name="exact-grab-clear-key",
  key_sequence="CONTROL + MINUS",
  alternative_key_sequence="SHIFT + KP_ENTER",
  consuming="none"
}

local recall_key = {
  type="custom-input",
  name="exact-grab-recall-key",
  key_sequence="CONTROL + R",
  alternative_key_sequence="KP_ENTER",
  consuming="game-only"
}

local num_keys = {}

for i=0,9 do
  num_keys[i+1] = {
    type="custom-input",
    name="exact-grab-num"..tostring(i).."-key",
    key_sequence="CONTROL + " .. tostring(i),
    alternative_key_sequence="KP_" .. tostring(i),
    consuming="game-only",
    enabled_while_spectating=false,
    enabled_while_in_cutscene=false
  }
end

-- If modifying this, don't forget to modify control.lua & the locale file, too
local increments = {1, 5, 10, 20, 50}
local inc_keys = {}
local dec_keys = {}

for i=1,#increments do
  inc_keys[i] = {
    type="custom-input",
    name="exact-grab-inc"..tostring(increments[i]).."-key",
    key_sequence="",
    enabled_while_spectating=false,
    enabled_while_in_cutscene=false
  }
  dec_keys[i] = {
    type="custom-input",
    name="exact-grab-dec"..tostring(increments[i]).."-key",
    key_sequence="",
    enabled_while_spectating=false,
    enabled_while_in_cutscene=false
  }
end
inc_keys[1].key_sequence="CONTROL + EQUALS"
inc_keys[1].alternative_key_sequence = "CONTROL + mouse-wheel-up"
dec_keys[1].key_sequence="CONTROL + MINUS"
dec_keys[1].alternative_key_sequence = "CONTROL + mouse-wheel-down"

local extended_data = {
  clear_key,
  recall_key
}
for i=1,#num_keys do extended_data[#extended_data+1]=num_keys[i] end
for i=1,#increments do extended_data[#extended_data+1]=inc_keys[i] end
for i=1,#increments do extended_data[#extended_data+1]=dec_keys[i] end

data:extend(extended_data)

