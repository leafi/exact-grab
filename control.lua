local original_inv_whitelist = {
  [defines.inventory.character_main] = true,
  [defines.inventory.character_guns] = true,
  [defines.inventory.character_ammo] = true,
  [defines.inventory.character_armor] = true,
  [defines.inventory.character_vehicle] = true,
  [defines.inventory.character_trash] = true
}

local function reinit_vars()
  global.last_hand_location = {}
  global.last_hand_sis = {}
  global.chosen_item_name = {}
  global.chosen_item_count = {}
end

local function reset_for_player(pi)
  global.last_hand_location[pi] = nil
  global.last_hand_sis[pi] = nil
  global.chosen_item_name[pi] = nil
  global.chosen_item_count[pi] = 0
end

script.on_configuration_changed(function()
  reinit_vars()
end)

script.on_init(function()
  reinit_vars()
end)

script.on_event(defines.events.on_player_joined_game, function(event)
  reset_for_player(event.player_index)
end)

script.on_event(defines.events.on_player_left_game, function(event)
  reset_for_player(event.player_index)
end)

local function conditions_ok(event, loud)
  if game.get_player(event.player_index) ~= nil then
    local player = game.get_player(event.player_index)
    if (player.cursor_stack ~= nil) and (player.cursor_stack.valid) and (player.cursor_stack.valid_for_read) then
      if player.cursor_stack.item_number == nil then
        if player.hand_location ~= nil then
          if original_inv_whitelist[player.hand_location.inventory] and player.get_inventory(player.hand_location.inventory) ~= nil then
            return true
          elseif loud then
            player.create_local_flying_text({text={"exact-grab-error-special-inventory", tostring(player.hand_location.inventory)}, create_at_cursor=true})
          end
        elseif loud then
          -- player.create_local_flying_text({text={"exact-grab-error-no-inventory"}, create_at_cursor=true})
          -- we'll just use the player inventory
          -- (this error case is too common... e.g. right-click a stack in your inventory - no source inventory for held items!)
          return true
        end
      elseif loud then
        player.create_local_flying_text({text={"exact-grab-error-special-item"}, create_at_cursor=true})
      end
    elseif loud then
      player.create_local_flying_text({text={"exact-grab-error-select-first"}, create_at_cursor=true})
    end
  end
  return false
end


local function apply_desired_grab(pi, player, no_read_cstack, quiet)
  -- put back what's already grabbed
  local oinv = player.get_inventory(
    no_read_cstack and global.last_hand_location[pi] and global.last_hand_location[pi].inventory or
    player.hand_location ~= nil and player.hand_location.inventory or
    defines.inventory.character_main
  )

  local pname = no_read_cstack and global.chosen_item_name[pi] or player.cursor_stack.name

  -- try and grab that many items from the inventory
  local available = oinv.get_item_count(pname) + ((not no_read_cstack) and player.cursor_stack.count or 0)
  local desired = global.chosen_item_count[pi] or 0

  local capped_available = false
  local capped_stack_size = false

  if available == 0 then
    player.create_local_flying_text({text={"exact-grab-error-empty"}, create_at_cursor=true})
    return false
  end

  if available < desired then
    desired = available
    capped_available = true
  end
  if game.item_prototypes[pname].stack_size < desired then
    desired = game.item_prototypes[pname].stack_size
    capped_stack_size = true
  end

  local sis = no_read_cstack and global.last_hand_sis[pi] or {
    name=pname,
    count=1,
    health=player.cursor_stack.health,
    durability=player.cursor_stack.durability
  }
  global.last_hand_sis[pi] = sis
  if not no_read_cstack then
    if player.cursor_stack.is_item_with_tags then sis.tags = player.cursor_stack.tags end
    if player.cursor_stack.prototype.get_ammo_type() ~= nil then sis.ammo = player.cursor_stack.ammo end
  end

  local old_hand_location = nil
  if no_read_cstack and global.last_hand_location[pi] then
    old_hand_location = global.last_hand_location[pi]
  elseif player.hand_location ~= nil then
    old_hand_location = {
      inventory=player.hand_location.inventory,
      slot=player.hand_location.slot
    }
  else
    -- Super-easy to end up with no original inventory... Just use the main char inv.
    old_hand_location={
      inventory=defines.inventory.character_main,
      slot=1
    }
  end

  if not player.clear_cursor() then
    player.print({"exact-grab-error-free-slot"})
    return false
  end
  global.last_hand_location[pi] = old_hand_location

  -- need to grab more!
  sis.count = desired
  local grabbed = oinv.remove(sis)

  sis.count = grabbed
  player.cursor_stack.set_stack(sis)

  -- restore hand_location
  -- (..but use a free slot, otherwise Factorio complains)
  local freeis, freeisnum = oinv.find_empty_stack(pname)
  if freeis ~= nil then
    old_hand_location.slot = freeisnum
    player.hand_location = old_hand_location
  end

  local which_str = (capped_available and capped_stack_size) and "exact-grab-grabbed-cap-stack" or
    capped_available and "exact-grab-grabbed-cap" or
    capped_stack_size and "exact-grab-grabbed-stack" or
    "exact-grab-grabbed"

  if not quiet then
    player.create_local_flying_text({text={which_str, tostring(global.chosen_item_count[pi]), tostring(grabbed)}, create_at_cursor=true})
  end
  return true
end

local function stack_numkey_pressed(num, event)
  if conditions_ok(event, true) then
    local pi = event.player_index
    local player = game.get_player(pi)

    if not player.cursor_stack.prototype.stackable then
      player.create_local_flying_text({text={"exact-grab-error-not-stackable"}, create_at_cursor=true})
      global.chosen_item_count[pi] = 0
      global.chosen_item_name[pi] = nil
      return
    end

    if global.chosen_item_count[pi] == nil or global.chosen_item_count[pi] == 0 then
      global.chosen_item_count[pi] = num
      if num == 0 then return end
      global.chosen_item_name[pi] = player.cursor_stack.name
    elseif global.chosen_item_name[pi] ~= player.cursor_stack.name or global.chosen_item_count[pi] ~= player.cursor_stack.count then
      global.chosen_item_name[pi] = nil
      global.chosen_item_count[pi] = num
      if num == 0 then return end
      global.chosen_item_name[pi] = player.cursor_stack.name
    else
      global.chosen_item_count[pi] = global.chosen_item_count[pi] * 10 + num
      if global.chosen_item_count[pi] > player.cursor_stack.prototype.stack_size then
        global.chosen_item_name[pi] = nil
        global.chosen_item_count[pi] = num
        if num == 0 then return end
        global.chosen_item_name[pi] = player.cursor_stack.name
      end
    end

    apply_desired_grab(pi, player, false, true)
  end
end

script.on_event("exact-grab-clear-key", function(event)
  local pi = event.player_index
  global.chosen_item_name[pi] = nil
  global.chosen_item_count[pi] = 0
  global.last_hand_location[pi] = nil
  global.last_hand_sis[pi] = nil

  local player = game.get_player(pi)
  player.create_local_flying_text({text={"exact-grab-cleared"}})
end)

-- Re-apply grab #
script.on_event("exact-grab-recall-key", function(event)
  local pi = event.player_index
  if global.chosen_item_count[pi] > 0 and global.last_hand_location[pi] ~= nil and global.last_hand_sis[pi] ~= nil then
    local player = game.get_player(pi)
    if player ~= nil then
      player.clear_cursor()
      apply_desired_grab(pi, player, true, true)
    end
  end
end)

-- bind numeric keys
for i=0,9 do
  script.on_event("exact-grab-num"..tostring(i).."-key", function(event)
    stack_numkey_pressed(i, event)
  end)
end

local function add_remove_pressed(delta, event)
  local pi = event.player_index
  local player = game.get_player(pi)
  if player == nil then return end

  -- hack for those who can't stop scrolling
  if (player.cursor_stack == nil) or (not player.cursor_stack.valid_for_read) then
    if delta > 0 then
      if global.chosen_item_count[pi] > 0 and global.last_hand_location[pi] ~= nil and global.last_hand_sis[pi] ~= nil then
        -- empty stack; treat e.g. "+5" as "recall 5 of last item"
        -- 1. recall at least 1
        global.chosen_item_count[pi] = 1
        if apply_desired_grab(pi, player, true, true) then
          -- 2. good? good. now grab the real number.
          if global.chosen_item_count[pi] > 1 then
            global.chosen_item_count[pi] = delta
            apply_desired_grab(pi, player, false, true)
          end
        end
      end
    end

    return
  end

  if conditions_ok(event, true) then
    if not player.cursor_stack.prototype.stackable then
      player.create_local_flying_text({text={"exact-grab-error-not-stackable"}, create_at_cursor=true})
      global.chosen_item_count[pi] = 0
      global.chosen_item_name[pi] = nil
      return
    end

    global.chosen_item_name[pi] = player.cursor_stack.name
    global.chosen_item_count[pi] = player.cursor_stack.count + delta

    if global.chosen_item_count[pi] == nil or global.chosen_item_count[pi] < 1 then
      player.clear_cursor()
      -- but leave it at 1, so you can 'scroll up' again. a bit evil!
      -- this comes from us using chosen_item_count to mean both 'what the user typed in explicitly' and 'what i want right now'
      -- maybe fix in the future? it'll make the UX better if we do(!)
      global.chosen_item_count[pi] = 1
      return
    end

    apply_desired_grab(pi, player, false, true)
  end
end

-- key increments used
-- (when updating this list, update data.lua & the locale file too!)
local increments = {1, 5, 10, 20, 50}

-- bind inc. & dec. keys
for i=1,#increments do
  script.on_event("exact-grab-inc"..tostring(increments[i]).."-key", function(event)
    add_remove_pressed(increments[i], event)
  end)
  script.on_event("exact-grab-dec"..tostring(increments[i]).."-key", function(event)
    add_remove_pressed(-increments[i], event)
  end)
end
