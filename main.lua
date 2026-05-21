local mod = _G.mind_over_matter or {}
_G.mind_over_matter = mod

local handlers = {}

local effect = function(id) return EffectTypeId.new(id) end
local trait = function(id) return MutationBranchId.new(id) end
local body = function(id) return BodyPartTypeId.new(id or "bp_null") end
local recipe = function(id) return RecipeId.new(id) end
local spell_type = function(id) return SpellTypeId.new(id) end
local item_type = function(id) return ItypeId.new(id) end
local skill = function(id) return SkillId.new(id) end
local monster_type = function(id) return MonsterTypeId.new(id) end
local flag = function(id) return JsonFlagId.new(id) end
local vitamin = function(id) return VitaminId.new(id) end
local turns = function(n) return TimeDuration.from_turns(n) end
local seconds = function(n) return TimeDuration.from_seconds(n) end
local minutes = function(n) return TimeDuration.from_minutes(n) end
local hours = function(n) return TimeDuration.from_hours(n) end

local call = function(fn, ...)
  local ok, result = pcall(fn, ...)
  return ok and result or nil
end

local has_effect = function(creature, id) return creature and call(function() return creature:has_effect(effect(id)) end) end
local has_trait = function(creature, id) return creature and call(function() return creature:has_trait(trait(id)) end) end
local has_item_with_flag = function(character, id) return character and call(function() return character:has_item_with_flag(flag(id), false) end) end
local set_trait = function(creature, id)
  if creature then call(function() creature:set_mutation(trait(id)) end) end
end
local unset_trait = function(creature, id)
  if creature then call(function() creature:unset_mutation(trait(id)) end) end
end
local add_effect = function(creature, id, duration, intensity)
  if creature then call(function() creature:add_effect(effect(id), duration or turns(1), body(), intensity or 1) end) end
end
local remove_effect = function(creature, id)
  if creature then call(function() creature:remove_effect(effect(id), body()) end) end
end
local mod_stamina = function(creature, amount)
  if creature then call(function() creature:mod_stamina(amount) end) end
end
local mod_fatigue = function(creature, amount)
  if creature then call(function() creature:mod_fatigue(amount) end) end
end
local mod_vitamin = function(creature, id, amount)
  if creature then call(function() creature:vitamin_mod({ vitamin = vitamin(id), amount = amount, capped = false }) end) end
end
local set_vitamin = function(creature, id, amount)
  if creature then call(function() creature:vitamin_set(vitamin(id), amount) end) end
end
local consume_item = function(character, id, count)
  if character then call(function() character:use_amount(item_type(id), count or 1) end) end
end
local create_item = function(character, id, count)
  if character then call(function() character:create_item(item_type(id), count or 1) end) end
end
local target_creature = function(params)
  return params and params.target and call(function() return game.get_creature_at(params.target, false) end) or nil
end
local spawn_monster = function(id, pos, radius)
  if pos then call(function() game.place_monster_around(monster_type(id), pos, radius or 3) end) end
end
local add_msg = function(message) call(function() game.add_msg(message) end) end
local achievement = function(id) call(function() game.complete_achievement(id) end) end
local avatar = function() return call(function() return game.get_avatar() end) end
local learn_recipe = function(character, id)
  if character then call(function() character:learn_recipe(recipe(id)) end) end
end
local get_num_value = function(creature, key)
  return tonumber(creature and call(function() return creature:get_value(key) end) or "0") or 0
end
local set_num_value = function(creature, key, value)
  if creature then call(function() creature:set_value(key, tostring(value)) end) end
end
local set_spell_level = function(character, id, level)
  if not character then return nil end
  call(function()
    local magic = character:get_magic()
    local sid = spell_type(id)
    magic:learn_spell(sid, character, true)
    magic:get_spell(sid):set_level(level)
  end)
end
local advance_lifter = function(character)
  if not has_trait(character, "TELEKINETIC") then return nil end
  local current = 0
  for i = 1, 30 do
    if has_trait(character, "TELEKINETIC_LIFTER_" .. i) then current = i end
  end
  local next_level = math.min(current + 1, 30)
  for i = 1, 30 do unset_trait(character, "TELEKINETIC_LIFTER_" .. i) end
  set_trait(character, "TELEKINETIC_LIFTER_" .. next_level)
  add_msg("You meditate on your lifting field.")
end

local concentration_effects = {
  BIOKINETIC = "effect_biokin_concentration",
  CLAIRSENTIENT = "effect_clair_concentration",
  ELECTROKINETIC = "effect_electrokin_concentration",
  PHOTOKINETIC = "effect_photokin_concentration",
  PYROKINETIC = "effect_pyrokin_concentration",
  TELEKINETIC = "effect_telekin_concentration",
  TELEPATH = "effect_telepath_concentration",
  TELEPORTER = "effect_teleport_concentration",
  VITAKINETIC = "effect_vitakin_concentration",
}

local practice_spells = {
  mom_practice_biokin_armor_skin = { spell = "biokin_armor_skin", cap = 35278 },
  mom_biokin_climate_control = { spell = "biokin_climate_control", cap = 35278 },
  mom_practice_biokin_combat_dance = { spell = "biokin_combat_dance", cap = 20513 },
  mom_practice_biokin_flexibility = { spell = "biokin_flexibility", cap = 49417 },
  mom_practice_biokin_overcome_pain = { spell = "biokin_overcome_pain", cap = 49417 },
  mom_practice_biokin_physical_enhance = { spell = "biokin_physical_enhance", cap = 49417 },
  mom_practice_biokin_reflex_enhance = { spell = "biokin_reflex_enhance", cap = 35278 },
  mom_practice_biokin_sealed_system = { spell = "biokin_sealed_system", cap = 20513 },
  mom_practice_clair_clear_sight = { spell = "clair_clear_sight", cap = 20513 },
  mom_practice_clair_danger_sense = { spell = "clair_danger_sense", cap = 49417 },
  mom_practice_clair_dodge_power = { spell = "clair_dodge_power", cap = 35278 },
  mom_practice_clair_night_vision = { spell = "clair_night_vision", cap = 49417 },
  mom_practice_clair_ranged_enhance = { spell = "clair_ranged_enhance", cap = 35278 },
  mom_practice_clair_see_map = { spell = "clair_see_map", cap = 20513 },
  mom_practice_clair_speed_reading = { spell = "clair_speed_reading", cap = 49417 },
  mom_practice_clair_spot_weakness = { spell = "clair_spot_weakness", cap = 49417 },
  mom_practice_clair_voyance = { spell = "clair_voyance", cap = 35278 },
  mom_practice_pyrokinetic_aura = { spell = "pyrokinetic_aura", cap = 20513 },
  mom_practice_pyrokinetic_blast = { spell = "pyrokinetic_blast", cap = 20513 },
  mom_practice_pyrokinetic_call_flames = { spell = "pyrokinetic_call_flames", cap = 49417 },
  mom_practice_pyrokinetic_cloak = { spell = "pyrokinetic_cloak", cap = 35278 },
  mom_practice_pyrokinetic_eruption = { spell = "pyrokinetic_eruption", cap = 49417 },
  mom_practice_pyrokinetic_flamethrower = { spell = "pyrokinetic_flamethrower", cap = 35278 },
  mom_practice_pyrokinetic_flash = { spell = "pyrokinetic_flash", cap = 49417 },
  mom_practice_pyrokinetic_quell_flames = { spell = "pyrokinetic_quell_flames", cap = 49417 },
  mom_practice_telekinetic_aegis = { spell = "telekinetic_aegis", cap = 13722 },
  mom_practice_telekinetic_explosion = { spell = "telekinetic_explosion", cap = 20513 },
  mom_practice_telekinetic_hammer = { spell = "telekinetic_hammer", cap = 35278 },
  mom_practice_telekinetic_momentum = { spell = "telekinetic_momentum", cap = 49417 },
  mom_practice_telekinetic_pull = { spell = "telekinetic_pull", cap = 49417 },
  mom_practice_telekinetic_push = { spell = "telekinetic_push", cap = 49417 },
  mom_practice_telekinetic_shield = { spell = "telekinetic_shield", cap = 20513 },
  mom_practice_telekinetic_strength = { spell = "telekinetic_strength", cap = 35278 },
  mom_practice_telekinetic_vehicle_lift = { spell = "telekinetic_vehicle_lift", cap = 20513 },
  mom_practice_telekinetic_wave = { spell = "telekinetic_wave", cap = 35278 },
  mom_practice_telepathic_blast = { spell = "telepathic_blast", cap = 49417 },
  mom_practice_telepathic_concentration = { spell = "telepathic_concentration", cap = 49417 },
  mom_practice_telepathic_confusion = { spell = "telepathic_confusion", cap = 35278 },
  mom_practice_telepathic_invisibility = { spell = "telepathic_invisibility", cap = 20513 },
  mom_practice_telepathic_mind_control = { spell = "telepathic_mind_control", cap = 20513 },
  mom_practice_telepathic_morale = { spell = "telepathic_morale", cap = 49417 },
  mom_practice_telepathic_scream = { spell = "telepathic_blast_radius", cap = 20513 },
  mom_practice_telepathic_shield = { spell = "telepathic_shield", cap = 49417 },
  mom_practice_teleport_banish = { spell = "teleport_banish", cap = 20513 },
  mom_practice_teleport_blink = { spell = "teleport_blink", cap = 49417 },
  mom_practice_teleport_collapse = { spell = "teleport_collapse", cap = 35278 },
  mom_practice_teleport_farstep = { spell = "teleport_farstep", cap = 35278 },
  mom_practice_teleport_gateway = { spell = "teleport_gateway", cap = 20513 },
  mom_practice_teleport_slow = { spell = "teleport_slow", cap = 49417 },
  mom_practice_teleport_transpose = { spell = "teleport_transpose", cap = 49417 },
  mom_practice_vita_banish_illness = { spell = "practice_vita_banish_illness", cap = 16869 },
  mom_practice_vita_blood_purge = { spell = "vita_blood_purge", cap = 20513 },
  mom_practice_vita_healing_touch = { spell = "vita_health_power_ally", cap = 49417 },
  mom_practice_vita_healing_trance = { spell = "vita_healing_trance", cap = 20513 },
  mom_practice_vita_health_power = { spell = "vita_health_power", cap = 49417 },
  mom_practice_vita_hurt_touch = { spell = "vita_hurt_touch", cap = 49417 },
  mom_practice_vita_pain_split = { spell = "vita_pain_split", cap = 35278 },
  mom_practice_vita_sleeping_trance = { spell = "vita_sleeping_trance", cap = 35278 },
  mom_practice_vita_stop_bleeding = { spell = "vita_stop_bleeding", cap = 49417 },
  mom_practice_vita_stop_infection = { spell = "vita_stop_infection", cap = 35278 },
}


local skill_practice = {
  mom_prac_psionics_begin = { amount = 100, cap = 3 },
  mom_prac_psionics_inter = { amount = 100, cap = 6 },
  mom_prac_psionics_advan = { amount = 100, cap = 10 },
  mom_prac_psionics_prof_basic = { amount = 100, cap = 2 },
  mom_prac_psionics_prof_containment = { amount = 150, cap = 4 },
  mom_prac_psionics_prof_ritual = { amount = 150, cap = 5 },
  mom_prac_psionics_prof_warping = { amount = 150, cap = 6 },
  mom_prac_psionics_prof_morphic = { amount = 150, cap = 6 },
}

local practice_result_aliases = {
  practice_biokin_armor_skin = "mom_practice_biokin_armor_skin",
  practice_biokin_climate_control = "mom_practice_biokin_climate_control",
  practice_biokin_combat_dance = "mom_practice_biokin_combat_dance",
  practice_biokin_flexibility = "mom_practice_biokin_flexibility",
  practice_biokin_overcome_pain = "mom_practice_biokin_overcome_pain",
  practice_biokin_physical_enhance = "mom_practice_biokin_physical_enhance",
  practice_biokin_reflex_enhance = "mom_practice_biokin_reflex_enhance",
  practice_biokin_sealed_system = "mom_practice_biokin_sealed_system",
  practice_clair_clear_sight = "mom_practice_clair_clear_sight",
  practice_clair_danger_sense = "mom_practice_clair_danger_sense",
  practice_clair_dodge_power = "mom_practice_clair_dodge_power",
  practice_clair_night_vision = "mom_practice_clair_night_vision",
  practice_clair_ranged_enhance = "mom_practice_clair_ranged_enhance",
  practice_clair_see_map = "mom_practice_clair_see_map",
  practice_clair_speed_reading = "mom_practice_clair_speed_reading",
  practice_clair_spot_weakness = "mom_practice_clair_spot_weakness",
  practice_clair_voyance = "mom_practice_clair_voyance",
  practice_pyrokinetic_aura = "mom_practice_pyrokinetic_aura",
  practice_pyrokinetic_blast = "mom_practice_pyrokinetic_blast",
  practice_pyrokinetic_call_flames = "mom_practice_pyrokinetic_call_flames",
  practice_pyrokinetic_cloak = "mom_practice_pyrokinetic_cloak",
  practice_pyrokinetic_eruption = "mom_practice_pyrokinetic_eruption",
  practice_pyrokinetic_flamethrower = "mom_practice_pyrokinetic_flamethrower",
  practice_pyrokinetic_flash = "mom_practice_pyrokinetic_flash",
  practice_pyrokinetic_quell_flames = "mom_practice_pyrokinetic_quell_flames",
  practice_telekinetic_aegis = "mom_practice_telekinetic_aegis",
  practice_telekinetic_explosion = "mom_practice_telekinetic_explosion",
  practice_telekinetic_hammer = "mom_practice_telekinetic_hammer",
  practice_telekinetic_momentum = "mom_practice_telekinetic_momentum",
  practice_telekinetic_pull = "mom_practice_telekinetic_pull",
  practice_telekinetic_push = "mom_practice_telekinetic_push",
  practice_telekinetic_shield = "mom_practice_telekinetic_shield",
  practice_telekinetic_strength = "mom_practice_telekinetic_strength",
  practice_telekinetic_vehicle_lift = "mom_practice_telekinetic_vehicle_lift",
  practice_telekinetic_wave = "mom_practice_telekinetic_wave",
  practice_telepathic_blast = "mom_practice_telepathic_blast",
  practice_telepathic_concentration = "mom_practice_telepathic_concentration",
  practice_telepathic_confusion = "mom_practice_telepathic_confusion",
  practice_telepathic_invisibility = "mom_practice_telepathic_invisibility",
  practice_telepathic_mind_control = "mom_practice_telepathic_mind_control",
  practice_telepathic_morale = "mom_practice_telepathic_morale",
  practice_telepathic_scream = "mom_practice_telepathic_scream",
  practice_telepathic_shield = "mom_practice_telepathic_shield",
  practice_teleport_banish = "mom_practice_teleport_banish",
  practice_teleport_blink = "mom_practice_teleport_blink",
  practice_teleport_collapse = "mom_practice_teleport_collapse",
  practice_teleport_farstep = "mom_practice_teleport_farstep",
  practice_teleport_gateway = "mom_practice_teleport_gateway",
  practice_teleport_slow = "mom_practice_teleport_slow",
  practice_teleport_transpose = "mom_practice_teleport_transpose",
  practice_vita_banish_illness = "mom_practice_vita_banish_illness",
  practice_vita_blood_purge = "mom_practice_vita_blood_purge",
  practice_vita_healing_touch = "mom_practice_vita_healing_touch",
  practice_vita_healing_trance = "mom_practice_vita_healing_trance",
  practice_vita_health_power = "mom_practice_vita_health_power",
  practice_vita_hurt_touch = "mom_practice_vita_hurt_touch",
  practice_vita_pain_split = "mom_practice_vita_pain_split",
  practice_vita_sleeping_trance = "mom_practice_vita_sleeping_trance",
  practice_vita_stop_bleeding = "mom_practice_vita_stop_bleeding",
  practice_vita_stop_infection = "mom_practice_vita_stop_infection",
}

for recipe_id, result_id in pairs(practice_result_aliases) do
  if practice_spells[result_id] then
    practice_spells[recipe_id] = {
      spell = practice_spells[result_id].spell,
      cap = practice_spells[result_id].cap,
      result = result_id,
    }
  end
end

local practice_focus_cost = function(character)
  local focus = character and (character.focus_pool or 0) or 0
  local cost = focus >= 75 and 50 or focus >= 50 and 25 or focus >= 34 and 10 or focus >= 30 and 5 or 0
  if character and cost > 0 then character.focus_pool = math.max(0, focus - cost) end
  return focus
end

local practice_skill = function(character, result_id, meta)
  consume_item(character, result_id, 1)
  if character and meta then call(function() character:practice(skill("metaphysics"), meta.amount, meta.cap, false) end) end
end

local practice_spell = function(character, result_id, meta)
  consume_item(character, meta.result or result_id, 1)
  if not character or not meta then return nil end
  call(function()
    local magic = character:get_magic()
    local sid = spell_type(meta.spell)
    if not magic:knows_spell(sid) then
      add_msg("Without even a basic understanding of the power, your meditation is nothing but idle musings.")
      return nil
    end
    local sp = magic:get_spell(sid)
    if sp:get_level() < 1 then
      add_msg("Without even a basic understanding of the power, your meditation is nothing but idle musings.")
      return nil
    end
    if sp:xp() > meta.cap then
      add_msg("Your knowledge of your powers is so deep that mere contemplation is of no further use to you.")
      return nil
    end
    sp:gain_exp(practice_focus_cost(character) * 18)
    mod_vitamin(character, "vitamin_psionic_drain", math.random(0, 2))
    add_msg("You spend some time meditating and contemplating your powers and emerge with new knowledge.")
  end)
end

local matrix_spell_adjustment = function(character, spell_class)
  local flags = {
    BIOKINETIC = "MATRIX_CRYSTAL_BIOKINESIS",
    CLAIRSENTIENT = "MATRIX_CRYSTAL_CLAIRSENTIENCE",
    PYROKINETIC = "MATRIX_CRYSTAL_PYROKINESIS",
    TELEKINETIC = "MATRIX_CRYSTAL_TELEKINESIS",
    TELEPATH = "MATRIX_CRYSTAL_TELEPATHY",
    TELEPORTER = "MATRIX_CRYSTAL_TELEPORTATION",
    VITAKINETIC = "MATRIX_CRYSTAL_VITAKINESIS",
  }
  local adjust = flags[spell_class] and has_item_with_flag(character, flags[spell_class]) and 4 or 0
  return has_effect(character, "effect_noetic_resilience_comedown") and adjust - 3 or adjust
end

local effective_spell_level = function(caster, params)
  return math.max(0, (params and params.level or 0) + matrix_spell_adjustment(caster, params and params.spell_class))
end

local clear_clair_night_traits = function(character)
  for i = 1, 8 do unset_trait(character, "CLAIR_NIGHT_EYES_" .. i) end
end

local apply_clair_night_eyes = function(character, params)
  local tier = math.min(8, math.max(1, math.floor((effective_spell_level(character, params) or 0) / 3) + 1))
  clear_clair_night_traits(character)
  set_trait(character, "CLAIR_NIGHT_EYES_" .. tier)
  add_effect(character, "effect_clair_night_eyes_" .. tier, minutes(10))
  add_effect(character, "effect_clair_night_eyes", minutes(10))
end

local spell_success_effects = {
  pyrokinetic_flashlight = "effect_pyrokinetic_light",
  photokinetic_invisibility = "effect_photokin_invisibility",
  telepath_mesmerism = "effect_telepath_mesmerize_tracker",
  clairvoyant_astral_projection = "effect_clair_astral_projection",
  teleport_ephemeral_walk = "effect_teleport_ephemeral_walk",
  vitakinetic_healing_trance = "effect_vitakin_healing_trance",
}

local note_recipes
local teach_note_recipes

local lua_spell_effects = {
  EOC_VITAKIN_RETURN_FROM_DEATH_INITIATE = function(caster) add_effect(caster, "effect_vita_return_from_death", minutes(30)) end,
  EOC_MOM_SCEN_HEART_OF_FIRE_ON_CHANNELING_END = function(caster) add_effect(caster, "effect_scenario_heart_of_fire_channeled_power_protector", minutes(30)) end,
  EOC_CAUSE_PSIONIC_DRAIN = function(caster)
    add_msg("You feel a sudden fatigue as your powers are unleashed.")
    mod_vitamin(caster, "vitamin_psionic_drain", has_effect(caster, "effect_noetic_resilience") and math.random(0, 3) or math.random(1, 5))
  end,
  electrokinetic_recharge_vehicle = function(caster) add_msg("Electric charge arcs over nearby machinery.") end,
  MoM_AEA_APPLIANCE_RECHARGE = function(caster) add_msg("The appliance hums as noetic charge gathers.") end,
}

handlers.on_craft_completed = function(params)
  local character = params and params.character
  if not character then return nil end
  if has_effect(character, "effect_clair_craft_bonus_blindness") then remove_effect(character, "effect_clair_craft_bonus_blindness") end
  if has_effect(character, "effect_clair_craft_bonus") then achievement("mom_clair_crafting_insight") end
  local recipe_id = params.recipe_id
  if recipe_id == "mom_recipe_no_result" or recipe_id == "psi_centering_meditation_drain_reduce" then
    consume_item(character, "mom_recipe_no_result", params.batch_size or 1)
    mod_vitamin(character, "vitamin_psionic_drain", -1 * (params.batch_size or 1))
  elseif recipe_id == "matrix_crystal_drained_dust" or recipe_id == "psi_matrix_channeling_drain_reduce" then
    set_vitamin(character, "vitamin_psionic_drain", 0)
    add_msg("You channel the unnatural fatigue into the drained matrix crystal until it shatters into dust.")
  elseif recipe_id == "mom_telekinetic_lifting_field_training" or recipe_id == "improve_telekinesis_lifting_field" then
    consume_item(character, "mom_telekinetic_lifting_field_training", params.batch_size or 1)
    advance_lifter(character)
  elseif practice_spells[recipe_id] then
    practice_spell(character, recipe_id, practice_spells[recipe_id])
  elseif skill_practice[recipe_id] then
    practice_skill(character, recipe_id, skill_practice[recipe_id])
  end
  return nil
end

handlers.on_book_skill_read = function(params)
  local learner = params and params.learner
  if not learner or not has_trait(learner, "CLAIR_SPEED_READ") then return nil end
  local bonus = math.max(params.min_experience or 1, params.max_experience or 1)
  call(function() learner:practice(skill(params.skill_id), bonus, params.book_level or 10, false) end)
  return nil
end

handlers.on_game_started = function(params)
  local character = avatar()
  if has_trait(character, "BIOKINETIC") then teach_note_recipes(character, note_recipes.MOM_IUSE_BIOKIN_RECIPE_NOTE) end
  if has_trait(character, "CLAIRSENTIENT") then teach_note_recipes(character, note_recipes.MOM_IUSE_CLAIR_RECIPE_NOTE) end
  if has_trait(character, "PYROKINETIC") then teach_note_recipes(character, note_recipes.MOM_IUSE_PYROKIN_RECIPE_NOTE) end
  if has_trait(character, "TELEKINETIC") then teach_note_recipes(character, note_recipes.MOM_IUSE_TELEKIN_RECIPE_NOTE) end
  if has_trait(character, "TELEPATH") then teach_note_recipes(character, note_recipes.MOM_IUSE_TELEPATH_RECIPE_NOTE) end
  if has_trait(character, "TELEPORTER") then teach_note_recipes(character, note_recipes.MOM_IUSE_TELEPORT_RECIPE_NOTE) end
  if has_trait(character, "VITAKINETIC") then teach_note_recipes(character, note_recipes.MOM_IUSE_VITAKIN_RECIPE_NOTE) end
  if has_trait(character, "SCEN_HEART_OF_FIRE") then
    set_spell_level(character, "pyrokinetic_eruption_knack", 8)
    set_spell_level(character, "pyrokinetic_call_flames_knack", 7)
    set_spell_level(character, "pyrokinetic_flamethrower_knack", 6)
    set_spell_level(character, "pyrokinetic_aura_knack", 5)
    set_spell_level(character, "pyrokinetic_blast_knack", 5)
    learn_recipe(character, "psi_centering_meditation_drain_reduce_heart_of_fire")
  end
  return nil
end

handlers.on_creature_damaged = function(params)
  local source = params and params.source
  local target = params and params.target
  if has_effect(source, "effect_photokin_invisibility") then remove_effect(source, "effect_photokin_invisibility") end
  if has_effect(target, "effect_photokin_invisibility") then remove_effect(target, "effect_photokin_invisibility") end
  if has_effect(source, "effect_mom_artifact_electrical_zap_attack") then add_effect(target, "stunned", turns(1)) end
  if has_effect(target, "effect_vita_return_from_death") then add_effect(target, "effect_vita_return_from_death_damage_tracker", minutes(1)) end
  if params and params.damage and params.damage > 0 then
    if params.damage_type == "psi_telekinetic_damage" then
      if math.random(5) == 1 then add_effect(target, "downed", seconds(1)) end
      if math.random(5) <= 2 then add_effect(target, "psi_dazed", seconds(2)) end
    elseif params.damage_type == "psi_telepathic_damage" then
      if math.random(20) == 1 then add_effect(target, "downed", seconds(1)) end
      if math.random(3) == 1 then add_effect(target, "stunned", seconds(1)) end
      if math.random(3) <= 2 then add_effect(target, "psi_dazed", seconds(2)) end
    elseif params.damage_type == "psi_photokinetic_damage" then
      if math.random(4) == 1 then add_effect(target, "blind", seconds(2)) end
    elseif params.damage_type == "psi_teleporter_teleporting_damage" then
      add_effect(target, "effect_portal_storm_teleport", turns(5))
    elseif params.damage_type == "psi_enervation_damage" then
      mod_stamina(target, -250)
    end
  end
  return nil
end


local matrix_awakenings
local portal_awakenings
local awaken_from_matrix

local lua_spell_semantics = {
  EOC_BIOKIN_PHYSICAL_ENHANCE_INITIATE = { effect = "effect_biokin_physical" },
  EOC_BIOKIN_PAIN_INITIATE = { effect = "effect_biokin_overcome_pain" },
  EOC_BIOKIN_BREATHE_SKIN_INITIATE = { effect = "effect_biokin_breathe_skin" },
  EOC_BIOKIN_HARDENED_SKIN_INITIATE = { effect = "effect_biokin_armor_skin" },
  EOC_BIOKIN_CLIMATE_CONTROL_INITIATE = { effect = "effect_biokin_climate_control" },
  EOC_BIOKIN_ENHANCE_MOBILITY_INITIATE = { effect = "effect_biokin_enhance_mobility" },
  EOC_BIOKIN_HAMMERHAND_INITIATE = { effect = "effect_biokin_hammerhand" },
  EOC_BIOKIN_REFLEX_ENHANCE_INITIATE = { effect = "effect_biokin_reflex" },
  EOC_BIOKIN_METABOLISM_ENHANCE_INITIATE = { effect = "effect_biokin_metabolism_enhance" },
  EOC_BIOKIN_VITAMINOSIS = { effect = "effect_biokin_vitaminosis" },
  EOC_BIOKIN_GUIDED_EVOLUTION_INITIATE = { effect = "effect_biokin_guided_evolution" },
  EOC_BIOKIN_COMBAT_DANCE_INITIATE = { effect = "effect_biokin_combat_dance" },
  EOC_BIOKIN_PERFECTED_MOTION_INITIATE = { effect = "effect_biokin_perfected_motion" },
  EOC_CLAIR_BETTER_SENSES_INITIATE = { effect = "effect_clair_better_senses" },
  EOC_CLAIR_SPEED_READING_INITIATE = { effect = "effect_clair_speed_reader", trait = "CLAIR_SPEED_READ", duration = 120 },
  EOC_CLAIR_DANGER_SENSE_INITIATE = { effect = "effect_clair_premonition" },
  EOC_CLAIR_NIGHT_EYES_INITIATE = { effect = "effect_clair_night_eyes" },
  EOC_CLAIR_SEE_AURAS_INITIATE = { effect = "effect_clair_see_auras" },
  EOC_CLAIR_DISCERN_WEAKNESS = { effect = "effect_clair_weak_point" },
  EOC_CLAIR_RAD_SENSE_SELF_REPORT = { effect = "effect_clair_sense_rads_self" },
  EOC_CLAIR_RANGED_ENHANCE_INITIATE = { effect = "effect_clair_ranged_enhance" },
  EOC_CLAIR_SENSE_HOSTILE_CREATURES_INITIATE = { effect = "effect_clair_sense_hostile_creatures" },
  EOC_CLAIR_DODGE_POWER_INITIATE = { effect = "effect_clair_dodge" },
  EOC_CLAIR_CRAFT_BONUS_INITIATE = { effect = "effect_clair_craft_bonus" },
  EOC_CLAIR_CLEAR_SIGHT_INITIATE = { effect = "effect_clair_clear_sight" },
  EOC_CLAIR_ASTRAL_PROJECTION_INITIATE = { effect = "effect_clair_astral_projection", trait = "CLAIR_ASTRAL_PROJECTION_APPEARANCE" },
  EOC_CLAIR_ASTRAL_PROJECTION_DEACTIVATE = { remove_effect = "effect_clair_astral_projection", lose_trait = "CLAIR_ASTRAL_PROJECTION_APPEARANCE" },
  EOC_CLAIR_GROUP_TACTICS_INITIATE = { effect = "effect_clair_group_tactics_self" },
  EOC_ELECTROKIN_SEE_ELECTRICITY_INITIATE = { effect = "effect_electrokin_see_electricity" },
  EOC_ELECTROKIN_ZAP_ENEMIES_INITIATE = { effect = "effect_electrokin_zap_enemies" },
  EOC_ELECTROKIN_MELEE_ATTACKS_INITIATE = { effect = "effect_electrokin_melee_attacks" },
  EOC_ELECTROKIN_HACKING_INTERFACE_INITIATE = { effect = "effect_electrokin_hacking_interface" },
  EOC_ELECTROKIN_PERSONAL_BATTERY_INITIATE = { effect = "effect_electrokin_personal_battery" },
  EOC_ELECTROKIN_PARALYSIS = { effect = "effect_electrokin_paralysis" },
  EOC_ELECTROKIN_REDUCE_PAIN_INITIATE = { effect = "effect_electrokin_reduce_pain" },
  EOC_ELECTROKIN_PAIN_IMMUNE_ON = { effect = "effect_electrokinetic_pain_immune" },
  EOC_ELECTROKIN_SPEED_BOOST_TARGET_CHECKER = { effect = "effect_electrokinetic_speed_boost" },
  EOC_ELECTROKIN_LIGHTNING_AURA_INITIATE = { effect = "effect_electrokinetic_lightning_aura" },
  EOC_PHOTOKIN_LIGHT_LOCAL_INITIATE = { effect = "effect_photokin_light_local" },
  EOC_PHOTOKIN_LIGHT_UP_ENEMY_TARGET = { effect = "effect_photokin_enemy_light" },
  EOC_PHOTOKIN_LIGHT_DODGE_INITIATE = { effect = "effect_photokin_dodge" },
  EOC_PHOTOKIN_CAMOUFLAGE_INITIATE = { effect = "effect_photokin_camouflage" },
  EOC_PHOTOKIN_RAD_IMMUNITY_INITIATE = { effect = "effect_photokin_light_barrier" },
  EOC_PHOTOKIN_HIDE_UGLY_INITIATE = { effect = "effect_photokin_hide_ugly" },
  EOC_PHOTOKIN_RADIO_INITIATE = { effect = "effect_photokinetic_radio" },
  EOC_PHOTOKINETIC_STERILIZE_FOODS = { effect = "effect_photokin_sterilization" },
  EOC_PHOTOKIN_INVISIBILITY_INITIATE = { effect = "effect_photokin_invisibility" },
  EOC_PHOTOKIN_BLINDING_GLARE_INITIATE = { effect = "effect_photokin_blinding_glare" },
  EOC_PHOTOKIN_LIGHT_ARMY_INITIATE = { effect = "effect_photokin_light_army" },
  EOC_PYROKIN_CALL_FLAME_INITIATE = { effect = "effect_pyrokinetic_fire_tool" },
  EOC_PYROKIN_WARMTH_CLOAK_INITIATE = { effect = "effect_pyrokinetic_cloak" },
  EOC_PYROKIN_TORCH_WELD_INITIATE = { effect = "effect_pyrokinetic_torch_weld" },
  EOC_PYROKIN_BLAZING_AURA_INITIATE = { effect = "effect_pyrokinetic_aura" },
  EOC_PYROKIN_FLAME_IMMUNITY_INITIATE = { effect = "effect_pyrokinetic_flame_immunity" },
  EOC_TELEKIN_MOMENTUM_INITIATE = { effect = "effect_telekinetic_momentum" },
  EOC_TELEKIN_WATER_WALKING = { effect = "effect_telekinetic_water_walking" },
  EOC_TELEKIN_LIFTING_FIELD_INITIATE = { effect = "effect_telekinetic_lifting_field" },
  EOC_TELEKIN_STRENGTH_INITIATE = { effect = "effect_telekinetic_strength" },
  EOC_TELEKIN_SHIELD_INITIATE = { effect = "effect_telekinetic_armor" },
  EOC_TELEKIN_LEVITATION_INITIATE = { effect = "effect_telekinetic_levitation" },
  EOC_TELEPATH_CONCENTRATION_INITIATE = { effect = "effect_telepathic_learning_bonus" },
  EOC_TELEPATH_SHIELD_INITIATE = { effect = "effect_telepathic_psi_armor" },
  EOC_TELEPATH_SENSE_MINDS_INITIATE = { effect = "effect_telepath_sense_minds" },
  EOC_TELEPATH_MORALE_INITIATE = { effect = "effect_telepathic_morale" },
  EOC_TELEPATH_PRIMAL_TERROR = { effect = "effect_telepathic_primal_terror" },
  EOC_TELEPATH_NETWORK_ALLY_CHECK = { effect = "effect_telepath_network_effect" },
  EOC_TELEPORT_STRIDE_INITIATE = { effect = "effect_teleport_stride" },
  EOC_TELEPORT_REACTIVE_DISPLACEMENT_INITIATE = { effect = "effect_teleport_reactive_displacement" },
  EOC_TELEPORT_WARPED_STRIKES_INITIATE = { effect = "effect_teleport_warped_strikes" },
  EOC_TELEPORT_EPHEMERAL_WALK_INITIATE = { effect = "effect_teleport_ephemeral_walk" },
  EOC_TELEPORT_LOCI_ESTABLISHMENT_INITIATE = { effect = "effect_teleport_loci_establishment" },
  EOC_TELEPORT_WARPER_COMBAT_INITIATE = { effect = "effect_teleport_warper_combat" },
  EOC_VITAKIN_HEALTH_POWER_INITIATE = { effect = "effect_vita_health" },
  EOC_VITAKIN_SLOW_BLEEDING_INITIATE = { effect = "effect_vitakin_slow_bleeding" },
  EOC_VITAKIN_CONCENTRATED_HEALING_INITIATE = { effect = "effect_vita_concentrated_healing" },
  EOC_VITAKIN_CURE_DISEASE_INITIATE = { effect = "effect_vita_cure_disease" },
  EOC_VITAKIN_HEALING_TRANCE = { effect = "effect_vitakin_healing_trance" },
  EOC_VITAKIN_RAD_PURGE = { effect = "effect_vitakin_purge_rads" },
  EOC_VITAKIN_NO_NEED_FOR_SLEEP = { effect = "effect_vitakin_no_need_for_sleep" },
  EOC_VITAKIN_SUPER_HEAL_INITIATE = { effect = "effect_vita_super_heal" },
  EOC_VITAKIN_DEGENERATING_TOUCH = { effect = "effect_vita_degenerating_touch" },
}

local apply_lua_spell_semantics = function(caster, params)
  local key = params and (params.effect_id or params.spell_id)
  local spell_id = params and params.spell_id
  if key == "EOC_CLAIR_NIGHT_EYES_INITIATE" or key == "EOC_CLAIR_NIGHT_EYES" or (key and key:match("^effect_clair_night_eyes_%d$")) then
    apply_clair_night_eyes(caster, params)
    return true
  end
  if key == "EOC_TELEKIN_SUMMON_JACKING_TOOL_INITIATE" then
    create_item(caster, "telekin_lifting_jack_" .. math.max(1, math.min(20, effective_spell_level(caster, params) or 1)), 1)
    return true
  end
  if key == "EOC_PYROKIN_CALL_FLAME_INITIATE" then
    consume_item(caster, "pyrokinetic_fire_tool", 1)
    create_item(caster, "pyrokinetic_fire_tool", 1)
    add_effect(caster, "effect_pyrokinetic_fire_tool", minutes(effective_spell_level(caster, params) >= 5 and 90 or 10))
    mod_vitamin(caster, "vitamin_psionic_drain", effective_spell_level(caster, params) >= 5 and math.random(2, 5) or math.random(0, 1))
    add_msg("Flames begin dancing in the air above your hand")
    return true
  end
  if key == "EOC_TELEKINETIC_LIFTER" then advance_lifter(caster); return true end
  if key == "EOC_TELEKIN_STRENGTH_INITIATE" then
    consume_item(caster, "telekin_ritual_summon_strength_item", 1)
    create_item(caster, "telekin_ritual_summon_strength_item", 1)
    add_effect(caster, "effect_telekinetic_strength", minutes(10))
    return true
  end
  if key == "EOC_END_PSI_POWERS_MAINTAINED" or key == "EOC_END_PSI_POWERS_SPECIFIC" then
    for _, id in pairs(concentration_effects) do remove_effect(caster, id) end
    return true
  end
  if key == "EOC_TELEKINETIC_FAR_HAND_SELECTOR" then add_effect(target_creature(params), "psi_dazed", turns(2)); add_msg("A telekinetic pull yanks the target toward you."); return true end
  if key == "EOC_TELEKINETIC_FORCE_SHOVE_SELECTOR" then add_effect(target_creature(params), "downed", turns(1)); add_msg("Telekinetic force shoves the target away."); return true end
  if key == "EOC_TELEKIN_WAVE_TARGETS" then add_effect(target_creature(params), "psi_dazed", turns(2)); add_effect(target_creature(params), "downed", turns(1)); return true end
  if key == "EOC_TELEKIN_REMOVE_ENHANCE_STRENGTH" then remove_effect(caster, "effect_telekinetic_strength"); consume_item(caster, "telekin_ritual_summon_strength_item", 1); return true end
  if key == "EOC_TELEPORT_BLINK_INITIATE" then call(function() game.teleport_creature_random(caster, { min_distance = 2, max_distance = 12, safe = true }) end); return true end
  if key == "EOC_TELEPORT_FARSTEP_INITIATE" then call(function() game.teleport_creature_random(caster, { min_distance = 12, max_distance = 80, safe = true }) end); return true end
  if key == "EOC_TELEPORT_SPACIAL_VORTEX" then add_effect(target_creature(params), "stunned", turns(2)); add_msg("Space twists violently around the target."); return true end
  if key == "EOC_TELEPORTER_OUBLIETTE_HANDLING" then add_effect(target_creature(params), "effect_psi_neutralized", minutes(5)); add_msg("Space folds around the target and tries to cast it away."); return true end
  if key == "EOC_TELEPORT_GATEWAY_SELECTOR" then add_msg("A controlled gateway opens for a moment."); return true end
  if key == "EOC_VITAKIN_STOP_BLEEDING_EOC" then remove_effect(caster, "bleed"); add_effect(caster, "effect_vitakin_slow_bleeding", minutes(10)); return true end
  if key == "EOC_VITAKIN_STOP_INFECTION_SWITCH" then remove_effect(caster, "infected"); add_effect(caster, "recover", hours(12)); return true end
  if key == "EOC_VITAKIN_BANISH_ILLNESS_SELECTOR" then remove_effect(caster, "asthma"); remove_effect(caster, "poison"); remove_effect(caster, "badpoison"); remove_effect(caster, "foodpoison"); add_effect(caster, "effect_asthma_disease_absorbed", hours(12)); return true end
  if key == "silent_one_polymorph_to_hostile" or key == "mon_nether_silent_one_aggressive" then add_msg("The silent one turns openly hostile."); return true end
  if key == "nether_banish_monster" or key == "nether_banish_monster_greater" then add_effect(target_creature(params), "effect_psi_neutralized", minutes(5)); return true end
  if key == "pigeon_aura" then add_effect(caster, "effect_telekin_concentration", minutes(5)); return true end
  if key == "GROUP_SPAWN_PSI_RAPTOR" then spawn_monster("mon_spawn_raptor_teke_push", params and params.target, 3); return true end
  if key == "telelixir_random" then call(function() game.teleport_creature_random(caster, { min_distance = 2, max_distance = 20, safe = false }) end); return true end
  if key == "mon_photokin_image" or key == "mon_photokin_army_image" then spawn_monster(key, params and params.target, 2); return true end
  if key == "mon_pyrokin_hotair_2" or key == "mon_pyrokin_hotair_3" or key == "mon_pyrokin_hotair_4" then spawn_monster(key, params and params.target, 1); return true end
  if key == "pure_translocate_power" then call(function() game.teleport_creature_random(caster, { min_distance = 6, max_distance = 60, safe = true }) end); return true end
  if key == "MoM_AEA_DIM" or key == "dim" then add_effect(caster, "blind", turns(2)); return true end
  if key == "MoM_AEA_ILLUSIONARY_ARMY" then spawn_monster("mon_photokin_army_image", params and params.target, 3); return true end
  if key == "biokin_sealed_system" then remove_effect(caster, "effect_biokin_breathe_skin"); return true end
  if key == "biokin_climate_control" then remove_effect(caster, "effect_biokin_climate_control"); return true end
  if key == "effect_telepathic_learning_bonus" then remove_effect(caster, "effect_telepathic_learning_bonus"); return true end
  if key == "EOC_VITAKIN_SLEEP" or key == "FATIGUE" then mod_fatigue(caster, -200); return true end
  if key and key:match("^fd_hot_air") then add_msg("You smother the nearby heat with focused will."); return true end
  local meta = lua_spell_semantics[key] or lua_spell_semantics[spell_id]
  if meta then
    if meta.remove_effect then remove_effect(caster, meta.remove_effect) end
    if meta.effect then add_effect(caster, meta.effect, minutes(meta.duration or 10)) end
    if meta.trait then set_trait(caster, meta.trait) end
    if meta.lose_trait then unset_trait(caster, meta.lose_trait) end
    return true
  end
  if key and key:match("_MATRIX_AWAKENING$") then
    local iuse = ({
      EOC_BIOKIN_MATRIX_AWAKENING = "MOM_IUSE_BIOKIN_MATRIX",
      EOC_CLAIR_MATRIX_AWAKENING = "MOM_IUSE_CLAIR_MATRIX",
      EOC_PYROKIN_MATRIX_AWAKENING = "MOM_IUSE_PYROKIN_MATRIX",
      EOC_TELEKIN_MATRIX_AWAKENING = "MOM_IUSE_TELEKIN_MATRIX",
      EOC_TEEP_MATRIX_AWAKENING = "MOM_IUSE_TEEP_MATRIX",
      EOC_TELEPORT_MATRIX_AWAKENING = "MOM_IUSE_TELEPORT_MATRIX",
      EOC_VITAKIN_MATRIX_AWAKENING = "MOM_IUSE_VITAKIN_MATRIX",
    })[key]
    if iuse then awaken_from_matrix(caster, matrix_awakenings[iuse]); return true end
  end
  if key == "EOC_NULL_BREAK_CONCENTRATION" then
    for _, id in pairs(concentration_effects) do remove_effect(caster, id) end
    add_msg("A nullifying pulse scatters psionic concentration.")
    return true
  end
  if key == "EOC_TELEPORTER_TRIFFID_SUMMON_ALLIES" then spawn_monster("mon_triffid_young", params and params.target, 3); return true end
  if key == "EOC_ELECTROKIN_MONSTER_PARALYSIS" then add_effect(target_creature(params), "stunned", turns(3)); return true end
  if key == "EOC_ELECTRONKINETIC_MONSTER_POWER_DRAINING" then add_effect(target_creature(params), "effect_nether_attunement_electrokinetic_power_drain", minutes(5)); return true end
  if key == "EOC_TELEPORT_OUBLIETTE_MONSTER" then add_effect(target_creature(params), "effect_psi_neutralized", minutes(5)); add_msg("Space folds around the target and tries to cast it away."); return true end
  if key == "EOC_TRIFFID_CLEAR_DISCERN_WEAKNESS" then add_effect(target_creature(params), "effect_clair_weak_point", minutes(5)); return true end
  if key == "EOC_MONSTER_APPLY_OBSCURITY" then add_effect(caster, "effect_photokin_camouflage", minutes(5)); return true end
  if key == "EOC_WHISPERING_AMALGAMATION_MINDSIGHT" then add_effect(caster, "eff_mind_seeing_bonus_20", minutes(10)); return true end
  if key == "EOC_AMALGAMATION_TELEKINETIC_SHIELDER_APPLICATION" then add_effect(target_creature(params) or caster, "effect_monster_inertial_barrier", minutes(5)); return true end
  if key == "EOC_SILENT_ONE_BUFF_SELF" then add_effect(caster, "effect_clair_clear_sight", minutes(5)); add_effect(caster, "effect_telekin_concentration", minutes(5)); return true end
  if key == "EOC_SILENT_ONE_DETECT_PSIONIC_ACTIVITY" or key == "EOC_SILENT_ONE_DETECT_PSIONIC_ACTIVITY_AGGRESSIVE" then add_effect(caster, "eff_mind_seeing_bonus_30", minutes(10)); return true end
  if key == "EOC_FERAL_BIOKINESIS_HEIGHTENED_REFLEXES_APPLIER" then add_effect(caster, "effect_feral_heightened_senses", minutes(5)); return true end
  if key == "EOC_FERAL_BIOKINESIS_HEIGHTENED_REFLEXES_ENHANCED_APPLIER" then add_effect(caster, "effect_feral_heightened_senses_2", minutes(5)); return true end
  if key == "EOC_FERAL_ELECTROKINETIC_NEURO_ACCELERATION_APPLIER" then add_effect(caster, "effect_electrokinetic_speed_boost_npc", minutes(5)); return true end
  if key == "EOC_FERAL_ELECTROKINETIC_NEURO_ACCELERATION_ENHANCED_APPLIER" then add_effect(caster, "effect_electrokinetic_speed_boost_npc", minutes(10)); return true end
  if key == "telekinetic_pull_monster" then add_effect(target_creature(params), "downed", turns(1)); return true end
  if key == "telepathic_network_monster" then add_effect(caster, "effect_telepath_network_monster_effect", minutes(5)); return true end
  if key == "EOC_MOM_AEA_ARTIFACT_CALORIE_COST" then
    if caster then call(function() caster:mod_stored_kcal(-250) end) end
    return true
  end
  if key == "EOC_MoM_AEA_NETHER_ATTUNEMENT" then add_effect(caster, "effect_nether_attunement_power_surge", minutes(10)); return true end
  if key == "EOC_MoM_AEA_AREA_PARALYSIS" then add_effect(target_creature(params), "stunned", turns(5)); return true end
  if key == "EOC_MoM_AEA_INTENSIFY_NEARBY_FLAMES" then add_effect(caster, "effect_pyrokinetic_aura_damage", minutes(5)); return true end
  if key == "EOC_NETHER_EFFECT_APPLY_TELEPORT_MISJUMP" then add_effect(caster, "effect_teleport_mishap_tindrift_warning", minutes(5)); return true end
  if key == "EOC_MOM_ABJURATION_STONE_SPELL_EFFECTS" then add_effect(target_creature(params) or caster, "effect_psi_neutralized", minutes(10)); return true end
  if key == "EOC_MoM_AEA_BLOOD_PURGE" or key == "EOC_VITAKIN_BLOOD_PURGE" then
    add_effect(caster, "effect_vitakin_purge_rads", minutes(10))
    return true
  end
  if key == "EOC_MoM_AEA_HEALTH_CHANGER" then add_effect(caster, "effect_vita_health", minutes(10)); return true end
  if key == "EOC_random_artifact_mutate" then add_msg("The artifact twists your biology for a moment."); return true end
  if key == "EOC_TELEPORT_SUMMON" or key == "GROUP_NETHER_BREACH" then
    spawn_monster("mon_hunting_horror", params and params.target, 4)
    add_msg("A breach opens and something from beyond presses close.")
    return true
  end
  if key == "EOC_TELEPORT_SUMMON_LAB_DEVOURER" then
    spawn_monster("mon_nether_eater_lab_devourer", params and params.target, 4)
    add_msg("A predatory shape tears through a momentary breach.")
    return true
  end
  if key == "EOC_EATER_DRAIN" or key == "EOC_SILENT_ONE_DRAINING_POWER" then
    mod_stamina(caster, -250)
    add_msg("Psionic force drains vitality from the air.")
    return true
  end
  if key == "biokin_dash" or key == "EOC_BIOKIN_ADRENALINE_TRIGGER" or key == "biokin_adrenaline_knack" then add_effect(caster, "adrenaline", minutes(5)); return true end
  if key == "EOC_BIOKIN_CHANGE_APPEARANCE" then add_msg("You reshape your features with biokinetic focus."); return true end
  if key == "EOC_BIOKIN_REMOVE_CLIMATE_CONTROL" then remove_effect(caster, "effect_biokin_climate_control"); return true end
  if key == "EOC_BIOKIN_REMOVE_BREATHE_SKIN" then remove_effect(caster, "effect_biokin_breathe_skin"); return true end
  if key == "EOC_CLAIR_EXAMINE_ITEM_INITIATE" or key == "clair_examine_item_knack" then add_msg("Clairvoyant impressions gather around the object."); return true end
  if key == "EOC_ELECTROKIN_ROBOT_INTERFACE" then create_item(caster, "electro_robot_interface", 1); return true end
  if key == "EOC_PHOTOKIN_CREATE_LIGHT_SWITCH" then add_effect(caster, "effect_photokin_light_local", minutes(10)); return true end
  if key == "EOC_PHOTOKIN_LIGHT_ARMY_DISAPPEAR_MONSTERS" then remove_effect(caster, "effect_photokin_light_army"); return true end
  if key == "EOC_PYROKIN_INTENSIFY_FLAMES" then add_effect(caster, "effect_pyrokinetic_aura_damage", minutes(5)); return true end
  if key == "EOC_PYROKIN_CAUTERIZE_SELECTOR" then create_item(caster, "vita_bandages", 1); return true end
  if key == "EOC_SPELL_PYROKIN_THERMOGENESIS_SELECTOR" then spawn_monster("mon_pyrokin_hotair_1", params and params.target, 1); return true end
  if key == "EOC_TELEKINETIC_MOVE_LARGE_WEIGHT_SELECTOR" then add_effect(caster, "effect_telekinetic_strength", minutes(5)); return true end
  if key == "EOC_TELEPATH_MESMERIZE" then add_effect(target_creature(params), "effect_telepath_mesmerize_tracker", minutes(5)); return true end
  if key == "EOC_TELEPORT_PHASE_INITIATE" then add_effect(caster, "effect_teleport_ephemeral_walk", minutes(5)); return true end
  if key == "EOC_TELEPORT_ITEM_APPORT" then add_msg("Nearby objects tug toward your hand through a short-lived fold."); return true end
  if key == "EOC_TELEPORT_DISPLACEMENT_CHECK" then add_effect(caster, "effect_teleport_reactive_displacement", minutes(5)); return true end
  if key == "EOC_TELEPORT_RELOCATION_PRE_CHECK" or key == "EOC_TELEPORT_LOCI_TECHNIQUE" then add_effect(caster, "effect_teleport_loci_establishment", minutes(5)); return true end
  if key == "EOC_TELEPORT_dilated_gateway_SELECTOR" or key == "EOC_TELEPORT_EXTERNAL_TELEPORT" then add_msg("A dilated gateway opens for a moment."); return true end
  if key == "EOC_REALITY_TEAR_CHECKER" then add_effect(caster, "effect_nether_attunement_raiser", minutes(5)); return true end
  if key == "EOC_VITAKIN_DEXTOXIFICATION_CHECK_1" then add_effect(caster, "effect_vitakin_purge_rads", minutes(5)); return true end
  if key == "EOC_VITAKIN_RESTORE_LIMB_SELECTOR" then add_effect(caster, "effect_vita_super_heal", minutes(10)); return true end
  if key and key:match("PYROKIN") then add_effect(caster, "effect_pyrokinetic_fire_tool", minutes(5)); return true end
  if key and key:match("TELEKIN") then add_effect(caster, "effect_telekin_concentration", minutes(5)); return true end
  if key and key:match("TELEPATH") then add_effect(caster, "effect_telepath_concentration", minutes(5)); return true end
  if key and key:match("TELEPORT") then add_effect(caster, "effect_teleport_concentration", minutes(5)); return true end
  if key and key:match("BIOKIN") then add_effect(caster, "effect_biokin_physical", minutes(5)); return true end
  if key and key:match("CLAIR") then add_effect(caster, "effect_clair_better_senses", minutes(5)); return true end
  if key and key:match("ELECTRO") then add_effect(caster, "effect_electrokin_see_electricity", minutes(5)); return true end
  if key and key:match("PHOTOKIN") then add_effect(caster, "effect_photokin_light_local", minutes(5)); return true end
  if key and (key:match("VITAKIN") or key:match("VITA_")) then add_effect(caster, "effect_vita_health", minutes(5)); return true end
  if key and (key:match("EOC_") or key:match("_knack$")) then
    add_msg("Your psionic focus takes hold.")
    return true
  end
  return false
end

handlers.on_lua_spell_effect = function(params)
  local key = params and (params.effect_id or params.spell_id)
  local fn = key and lua_spell_effects[key]
  if fn then
    fn(params.caster, params)
  else
    apply_lua_spell_semantics(params.caster, params)
  end
  return nil
end

handlers.on_spell_cast_finished = function(params)
  local caster = params and params.caster
  if not caster then return nil end
  local class = params.spell_class
  local spell_id = params.spell_id
  if params.success then
    if concentration_effects[class] then add_effect(caster, concentration_effects[class], minutes(5)) end
    if spell_success_effects[spell_id] then add_effect(caster, spell_success_effects[spell_id], minutes(10)) end
    if has_trait(caster, "SCEN_HEART_OF_FIRE") then add_effect(caster, "effect_scenario_heart_of_fire_channeled_power_protector", minutes(30)) end
  else
    add_effect(caster, "effect_psi_lost_concentration", turns(5))
  end
  if has_effect(caster, "effect_teleport_ephemeral_walk") then mod_stamina(caster, -100) end
  return nil
end

local portal_overload = function(character, meta, strength)
  add_msg(meta.overload_message)
  add_effect(character, "psionic_overload", hours(strength))
  if meta.overload then add_effect(character, meta.overload, hours(math.max(1, strength * 2))) end
  add_effect(character, "downed", turns(math.max(1, strength)))
  mod_stamina(character, -4000)
end

local portal_awaken = function(character, meta, strength)
  if not character or not meta then return nil end
  if has_trait(character, meta.trait) or has_effect(character, "psionic_awakened") then portal_overload(character, meta, strength); return nil end
  if math.random(100) <= math.max(5, 100 - strength * 8) then
    add_msg(meta.message)
    set_trait(character, meta.trait)
    if meta.passive then set_trait(character, meta.passive) end
    if meta.passive2 then set_trait(character, meta.passive2) end
    if meta.note then teach_note_recipes(character, note_recipes[meta.note]) end
    add_effect(character, "psionic_awakened", hours(strength * 2))
  else
    portal_overload(character, meta, strength)
  end
end

handlers.on_weather_updated = function(params)
  local character = avatar()
  if not character or (params and params.is_sheltered) or has_effect(character, "sleep") or has_item_with_flag(character, "PORTAL_PROOF") then return nil end
  local strength = ({ distant_portal_storm = 1, portal_storm = 5, close_portal_storm = 10 })[params and params.weather_id]
  if not strength or has_effect(character, "psionic_awakened") or math.random(100) > strength then return nil end
  local choices = { "BIOKINETIC", "CLAIRSENTIENT", "PYROKINETIC", "TELEKINETIC", "TELEPATH", "TELEPORTER", "VITAKINETIC" }
  portal_awaken(character, portal_awakenings[choices[math.random(#choices)]], strength)
  return nil
end

handlers.on_trap_triggered = function(params)
  if params and params.trap_id == "tr_mom_psionic" then add_msg("A psionic resonance passes through you.") end
  return nil
end


note_recipes = {
  MOM_IUSE_BIOKIN_RECIPE_NOTE = { "mom_practice_biokin_physical_enhance", "mom_practice_biokin_overcome_pain", "mom_practice_biokin_flexibility", "mom_practice_biokin_climate_control", "mom_practice_biokin_armor_skin", "mom_practice_biokin_reflex_enhance", "mom_practice_biokin_sealed_system", "mom_practice_biokin_combat_dance" },
  MOM_IUSE_CLAIR_RECIPE_NOTE = { "mom_practice_clair_night_vision", "mom_practice_clair_danger_sense", "mom_practice_clair_speed_reading", "mom_practice_clair_spot_weakness", "mom_practice_clair_ranged_enhance", "mom_practice_clair_voyance", "mom_practice_clair_dodge_power", "mom_practice_clair_clear_sight", "mom_practice_clair_see_map" },
  MOM_IUSE_PYROKIN_RECIPE_NOTE = { "mom_practice_pyrokinetic_flash", "mom_practice_pyrokinetic_eruption", "mom_practice_pyrokinetic_call_flames", "mom_practice_pyrokinetic_quell_flames", "mom_practice_pyrokinetic_cloak", "mom_practice_pyrokinetic_flamethrower", "mom_practice_pyrokinetic_aura", "mom_practice_pyrokinetic_blast" },
  MOM_IUSE_TELEKIN_RECIPE_NOTE = { "mom_practice_telekinetic_pull", "mom_practice_telekinetic_push", "mom_practice_telekinetic_momentum", "mom_practice_telekinetic_wave", "mom_practice_telekinetic_strength", "mom_practice_telekinetic_hammer", "mom_practice_telekinetic_vehicle_lift", "mom_practice_telekinetic_shield", "mom_practice_telekinetic_explosion", "mom_practice_telekinetic_aegis", "mom_telekinetic_lifting_field_training" },
  MOM_IUSE_TELEPATH_RECIPE_NOTE = { "mom_practice_telepathic_concentration", "mom_practice_telepathic_shield", "mom_practice_telepathic_morale", "mom_practice_telepathic_blast", "mom_practice_telepathic_confusion", "mom_practice_telepathic_invisibility", "mom_practice_telepathic_scream", "mom_practice_telepathic_mind_control" },
  MOM_IUSE_TELEPORT_RECIPE_NOTE = { "mom_practice_teleport_blink", "mom_practice_teleport_slow", "mom_practice_teleport_transpose", "mom_practice_teleport_farstep", "mom_practice_teleport_collapse", "mom_practice_teleport_gateway", "mom_practice_teleport_banish" },
  MOM_IUSE_VITAKIN_RECIPE_NOTE = { "mom_practice_vita_health_power", "mom_practice_vita_stop_bleeding", "mom_practice_vita_healing_touch", "mom_practice_vita_hurt_touch", "mom_practice_vita_sleeping_trance", "mom_practice_vita_pain_split", "mom_practice_vita_stop_infection", "mom_practice_vita_healing_trance", "mom_practice_vita_blood_purge", "mom_practice_vita_banish_illness" },
}

local potion_effects = {
  MOM_IUSE_BIOKIN_POTION = { effect = "effect_biokin_potion", comedown = "effect_biokin_potion_comedown" },
  MOM_IUSE_CLAIR_POTION = { effect = "effect_clair_potion", comedown = "effect_clair_potion_comedown" },
  MOM_IUSE_PYROKIN_POTION = { effect = "effect_pyrokin_potion", comedown = "effect_pyrokin_potion_comedown" },
  MOM_IUSE_TELEKIN_POTION = { effect = "effect_telekin_potion", comedown = "effect_telekin_potion_comedown", trait = "TELELIXIRDOWN" },
  MOM_IUSE_TELEPATH_POTION = { effect = "effect_telepath_potion", comedown = "effect_telepath_potion_comedown" },
  MOM_IUSE_TELEPORT_POTION = { effect = "effect_teleport_potion", comedown = "effect_teleport_potion_comedown" },
  MOM_IUSE_VITAKIN_POTION = { effect = "effect_vitakin_potion", comedown = "effect_vitakin_potion_comedown" },
  MOM_IUSE_DRAIN_RESIST_POTION = { effect = "effect_noetic_resilience", comedown = "effect_noetic_resilience_comedown", min_hours = 18 },
}

matrix_awakenings = {
  MOM_IUSE_BIOKIN_MATRIX = { item = "matrix_crystal_biokinesis", trait = "BIOKINETIC", passive = "BIOKIN_NEEDS", note = "MOM_IUSE_BIOKIN_RECIPE_NOTE", boost = "effect_biokin_physical", message = "You gaze into the strange crystal and the light slowly grows brighter.  As it fills your vision, you become aware of your heartbeat, blood, and breath.  Strength and power suddenly fill your body, and you know how to do it again.", failure = "You gaze into the strange crystal and the light slowly grows brighter.  A searing headache crashes through your brain, blotting out all other sensations." },
  MOM_IUSE_CLAIR_MATRIX = { item = "matrix_crystal_clairsentience", trait = "CLAIRSENTIENT", passive = "CLAIR_SENSES", note = "MOM_IUSE_CLAIR_RECIPE_NOTE", boost = "effect_clair_clear_sight", boost_duration = 1, message = "You gaze into the strange crystal and the light slowly grows brighter.  Dozens of might-have-beens and never-weres flicker through your memory.  When the last one ends, you can see forever.", failure = "You gaze into the strange crystal and see yourself as you could have been, but only for a moment before your head starts pounding." },
  MOM_IUSE_PYROKIN_MATRIX = { item = "matrix_crystal_pyrokinesis", trait = "PYROKINETIC", passive = "PYROGLOW_WEAK", passive2 = "PYROGLOW_STRONG", note = "MOM_IUSE_PYROKIN_RECIPE_NOTE", boosts = { { "effect_pyrokinetic_cloak", 5 }, { "effect_pyrokinetic_aura", 5 } }, message = "You gaze into the strange crystal and the light slowly grows brighter.  Warmth spreads down your arms and across your entire body, and sparks and flames dance on the air around you.", failure = "You gaze into the strange crystal and feel a pleasant heat in your veins, but the heat turns into searing pain before the crystal goes dark." },
  MOM_IUSE_TELEKIN_MATRIX = { item = "matrix_crystal_telekinesis", trait = "TELEKINETIC", passive = "TELEKINETIC_LIFTER_1", note = "MOM_IUSE_TELEKIN_RECIPE_NOTE", boost = "effect_telekinetic_armor", boost_duration = 1, message = "You gaze into the strange crystal and the light slowly grows brighter.  It floats, supported on nothingness, and gravity, attraction, and repulsion reveal themselves to you.", failure = "You gaze into the strange crystal and it rises into the air, then freezes and strobes, each pulse a dagger in your brain." },
  MOM_IUSE_TEEP_MATRIX = { item = "matrix_crystal_telepathy", trait = "TELEPATH", passive = "TELEPATHIC_SUGGESTION", note = "MOM_IUSE_TELEPATH_RECIPE_NOTE", boost = "effect_telepathic_learning_bonus", boost_duration = 1, message = "You gaze into the strange crystal and the light slowly grows brighter.  Time slows as you stand outside yourself observing your own thoughts, then your awareness sharpens into laser focus.", failure = "You gaze into the strange crystal, see a flare of light, and close your eyes against its intensity.  Your head pounds when the crystal goes dark." },
  MOM_IUSE_TELEPORT_MATRIX = { item = "matrix_crystal_teleportation", trait = "TELEPORTER", passive = "TELEPORTER_PROTECT", note = "MOM_IUSE_TELEPORT_RECIPE_NOTE", boost = "effect_teleport_stride", boost_duration = 1, message = "You gaze into the strange crystal and the light slowly grows brighter.  Reality grows thin, and you see glowing paths linking this place to infinite others.", failure = "You gaze into the strange crystal as images of locations and times overlap in a kaleidoscope of color and sound that makes your head throb." },
  MOM_IUSE_VITAKIN_MATRIX = { item = "matrix_crystal_vitakinesis", trait = "VITAKINETIC", passive = "VITAKINETIC_HEALTH", note = "MOM_IUSE_VITAKIN_RECIPE_NOTE", boost = "effect_vita_health", message = "You gaze into the strange crystal and the light slowly grows brighter.  You become aware of every cut and bruise, then push away the grime and strain until you feel instantly better.", failure = "You gaze into the strange crystal, see a flare of light, and close your eyes against its intensity.  Your head pounds when the crystal goes dark." },
}

portal_awakenings = {
  BIOKINETIC = { trait = "BIOKINETIC", passive = "BIOKIN_NEEDS", note = "MOM_IUSE_BIOKIN_RECIPE_NOTE", overload = "effect_biokin_overload", message = "A roar fills your mind, louder even than the screaming madness of the portal storm.  New strength and vigor suddenly fill you.  The sense of strength remains.", overload_message = "Your head pounds in time with the kaleidoscoping sky as your muscles cramp uncontrollably." },
  CLAIRSENTIENT = { trait = "CLAIRSENTIENT", passive = "CLAIR_SENSES", note = "MOM_IUSE_CLAIR_RECIPE_NOTE", overload = "blind_clair_overload", message = "A roar fills your mind, louder even than the screaming madness of the portal storm.  Light expands behind your eyelids and reveals your surroundings.  When your awareness snaps back, colors and sounds are clearer than before.", overload_message = "Your head pounds in time with the kaleidoscoping sky as your vision wavers and the world vanishes into silent darkness." },
  PYROKINETIC = { trait = "PYROKINETIC", passive = "PYROGLOW_WEAK", passive2 = "PYROGLOW_STRONG", note = "MOM_IUSE_PYROKIN_RECIPE_NOTE", overload = "effect_pyrokin_overload", message = "A roar fills your mind, louder even than the screaming madness of the portal storm.  A glow gathers around your hand and becomes flame.  The glow fades, but the sensation of heat remains.", overload_message = "Your head pounds in time with the kaleidoscoping sky as your skin prickles and the air around you grows unbearably hot." },
  TELEKINETIC = { trait = "TELEKINETIC", passive = "TELEKINETIC_LIFTER_1", note = "MOM_IUSE_TELEKIN_RECIPE_NOTE", overload = "effect_telekin_overload", message = "A roar fills your mind, louder even than the screaming madness of the portal storm.  Grass, rock, and dirt lift and swirl around you.  After you fall back to earth, one pebble hangs in the air for a moment.", overload_message = "Your head pounds in time with the kaleidoscoping sky as the very air presses down on you." },
  TELEPATH = { trait = "TELEPATH", passive = "TELEPATHIC_SUGGESTION", note = "MOM_IUSE_TELEPATH_RECIPE_NOTE", message = "A roar fills your mind, louder even than the screaming madness of the portal storm.  A babble of voices rises inside you, then quiets into a strange internal calm.", overload_message = "Your head pounds in time with the kaleidoscoping sky as whispers grow into a cacophony of voices." },
  TELEPORTER = { trait = "TELEPORTER", passive = "TELEPORTER_PROTECT", note = "MOM_IUSE_TELEPORT_RECIPE_NOTE", overload = "effect_portal_storm_teleport", message = "A roar fills your mind, louder even than the screaming madness of the portal storm.  Reality grows thin, and you see the paths you could take to slip between spaces.", overload_message = "Your head pounds in time with the kaleidoscoping sky as the world seems to grow far away, then close." },
  VITAKINETIC = { trait = "VITAKINETIC", passive = "VITAKINETIC_HEALTH", note = "MOM_IUSE_VITAKIN_RECIPE_NOTE", overload = "effect_vitakin_overload", message = "A roar fills your mind, louder even than the screaming madness of the portal storm.  For a moment, you can feel blood and breath moving through your body, and a lingering trace remains.", overload_message = "Your head pounds in time with the kaleidoscoping sky as feverish heat spreads through your body." },
}

teach_note_recipes = function(character, ids)
  for _, id in ipairs(ids or {}) do learn_recipe(character, id) end
  add_msg("You study the note and contemplate ways that you might improve your powers.")
end

local drink_matrix_potion = function(character, meta)
  add_msg("You drink the concoction.")
  remove_effect(character, meta.comedown)
  add_effect(character, meta.effect, hours(math.random(meta.min_hours or 12, 30)))
  if meta.trait then set_trait(character, meta.trait) end
end

local awakening_reducer = function(character)
  return 100 - (100 * math.exp(get_num_value(character, "mom_awakening_countup") / -3))
end

local record_awakening_success = function(character)
  set_num_value(character, "mom_awakening_countup", get_num_value(character, "mom_awakening_countup") + 1)
end

local matrix_awakening_failure = function(character, meta, source_item)
  add_msg(meta.failure or "You gaze into the strange crystal and the light slowly grows brighter.  A searing headache crashes through your brain as the crystal goes dark.")
  consume_item(character, source_item or meta.item, 1)
  create_item(character, "matrix_crystal_drained", 1)
  add_effect(character, "psionic_overload", hours(1))
  add_effect(character, "stunned", turns(5))
end

awaken_from_matrix = function(character, meta, source_item)
  if not character then return 0 end
  if has_trait(character, meta.trait) then
    add_msg("You gaze into the strange crystal and the light slowly grows brighter.  It starts pulsing, first slowly and more rapidly, and your head starts pounding in time with the light.  You tear your gaze away but the pounding in your head remains.")
    add_effect(character, "psionic_overload", hours(1))
    add_effect(character, "stunned", turns(5))
    return 100
  end
  if math.random(100) > (100 - awakening_reducer(character)) then matrix_awakening_failure(character, meta, source_item); return 100 end
  consume_item(character, source_item or meta.item, 1)
  create_item(character, "matrix_crystal_drained", 1)
  add_msg(meta.message)
  set_trait(character, meta.trait)
  if meta.passive then set_trait(character, meta.passive) end
  if meta.passive2 then set_trait(character, meta.passive2) end
  for _, boost in ipairs(meta.boosts or {}) do add_effect(character, boost[1], minutes(boost[2])) end
  if meta.boost then add_effect(character, meta.boost, minutes(meta.boost_duration or 5)) end
  if meta.note then teach_note_recipes(character, note_recipes[meta.note]) end
  record_awakening_success(character)
  return 100
end

local use_force_field_generator = function(character)
  if not character then return 0 end
  if call(function() return character:has_item_with_id(item_type("matrix_crystal_drained"), false) end) then
    consume_item(character, "matrix_crystal_drained", 1)
    if math.random(100) <= 3 then
      consume_item(character, "force_field_generator", 1)
      create_item(character, "force_field_generator_broken", 1)
      add_msg("The device makes a whining sound and there is a sharp smell of burnt plastic!")
    else
      add_effect(character, "force_field_generated", seconds(math.random(2, 12)))
      add_msg("The matrix crystal cracks into pieces as the device activates!")
    end
  else
    add_msg("Without a matrix crystal to power it, flipping the toggle does nothing.")
  end
  return 100
end

local use_zener_deck = function(character)
  add_msg(math.random(1, 5) == 1 and "You correctly sense the card before turning it over." or "The card is not the one you expected.")
  return 100
end

local use_instability_cream = function(character)
  add_msg("You rub the cream on your skin.")
  add_effect(character, "instability_remover", hours(24))
  return 100
end

local use_chaos_stone = function(character)
  add_msg("The compressed chaos shivers and the air around you tastes like a portal storm.")
  add_effect(character, "teleglow", minutes(30))
  return 100
end

local use_drained_matrix = function(character)
  add_msg("You gaze into the strange crystal and the light slowly grows brighter.  The sensation grows rapidly until your stomach feels like it will burst and every brush of clothing on your skin is like rasping sandpaper.  As the light fades from the crystal, a searing pains fills your head.")
  add_effect(character, "psionic_overload", hours(1))
  add_effect(character, "stunned", turns(5))
  return 100
end

local use_coruscating_matrix = function(character)
  local choices = { "MOM_IUSE_BIOKIN_MATRIX", "MOM_IUSE_CLAIR_MATRIX", "MOM_IUSE_PYROKIN_MATRIX", "MOM_IUSE_TELEKIN_MATRIX", "MOM_IUSE_TEEP_MATRIX", "MOM_IUSE_TELEPORT_MATRIX", "MOM_IUSE_VITAKIN_MATRIX" }
  return awaken_from_matrix(character, matrix_awakenings[choices[math.random(#choices)]], "matrix_crystal_coruscating")
end

mod.use_item_eoc = function(iuse, params)
  local character = params and params.user
  if potion_effects[iuse] then return drink_matrix_potion(character, potion_effects[iuse]) or 100 end
  if matrix_awakenings[iuse] then return awaken_from_matrix(character, matrix_awakenings[iuse]) end
  if note_recipes[iuse] then teach_note_recipes(character, note_recipes[iuse]); return 100 end
  if iuse == "MOM_IUSE_FORCE_FIELD_GENERATOR" then return use_force_field_generator(character) end
  if iuse == "MOM_IUSE_ZENER_DECK" then return use_zener_deck(character) end
  if iuse == "MOM_IUSE_INSTABILITY_CREAM" then return use_instability_cream(character) end
  if iuse == "MOM_IUSE_CHAOS_STONE" then return use_chaos_stone(character) end
  if iuse == "MOM_IUSE_DRAINED_MATRIX" then return use_drained_matrix(character) end
  if iuse == "MOM_IUSE_CORUSCATING_MATRIX" then return use_coruscating_matrix(character) end
  return 0
end

local teleport_potion_comedown = function(character)
  if has_effect(character, "effect_teleport_potion_comedown") and math.random(3) == 1 then
    add_effect(character, "effect_portal_storm_teleport", turns(20))
    add_msg("Reality suddenly warps around you and you are somewhere else!")
    call(function() game.teleport_creature_random(character, { min_distance = 2, max_distance = 12, safe = true }) end)
  end
end

local telepathic_stole_recently = function(character, value)
  if value then set_num_value(character, "mom_telepathically_stole_recently", value) end
  return get_num_value(character, "mom_telepathically_stole_recently")
end

handlers.on_character_effect_removed = function(params)
  local character = params and (params.character or params.char)
  local removed = params and params.effect and call(function() return params.effect:get_id():str() end)
  if removed == "effect_clair_speed_reader" then unset_trait(character, "CLAIR_SPEED_READ") end
  if removed and removed:match("^effect_clair_night_eyes") then clear_clair_night_traits(character) end
  for _, meta in pairs(potion_effects) do
    if removed == meta.effect then
      add_effect(character, meta.comedown, hours(math.random(24, 55)))
      if meta.trait then unset_trait(character, meta.trait); unset_trait(character, meta.trait .. "_active") end
    end
  end
  return nil
end

mod.dispatch = function(hook, params)
  local handler = handlers[hook]
  if handler then return handler(params or {}) end
  return nil
end

call(function()
  game.add_on_every_x_hook(minutes(30), function() teleport_potion_comedown(avatar()) end)
  game.add_on_every_x_hook(hours(24), function()
    local character = avatar()
    if telepathic_stole_recently(character) >= 1 then telepathic_stole_recently(character, 0) end
  end)
end)
