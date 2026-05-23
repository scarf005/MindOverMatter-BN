local mod = {}
_G.mind_over_matter = mod
for _, hook in ipairs({ "on_character_effect_removed", "on_craft_completed", "on_creature_damaged", "on_game_started", "on_lua_spell_effect", "on_spell_cast_finished", "on_trap_triggered", "on_weather_updated" }) do
  game.add_hook(hook, function(params) return mod.dispatch(hook, params) end)
end

for _, iuse in ipairs({
  "MOM_IUSE_BIOKIN_POTION",
  "MOM_IUSE_CLAIR_POTION",
  "MOM_IUSE_PYROKIN_POTION",
  "MOM_IUSE_TELEKIN_POTION",
  "MOM_IUSE_TELEPATH_POTION",
  "MOM_IUSE_TELEPORT_POTION",
  "MOM_IUSE_VITAKIN_POTION",
  "MOM_IUSE_DRAIN_RESIST_POTION",
  "MOM_IUSE_INSTABILITY_CREAM",
  "MOM_IUSE_ZENER_DECK",
  "MOM_IUSE_FORCE_FIELD_GENERATOR",
  "MOM_IUSE_CHAOS_STONE",
  "MOM_IUSE_BIOKIN_MATRIX",
  "MOM_IUSE_CLAIR_MATRIX",
  "MOM_IUSE_PYROKIN_MATRIX",
  "MOM_IUSE_TELEKIN_MATRIX",
  "MOM_IUSE_TEEP_MATRIX",
  "MOM_IUSE_TELEPORT_MATRIX",
  "MOM_IUSE_VITAKIN_MATRIX",
  "MOM_IUSE_DRAINED_MATRIX",
  "MOM_IUSE_CORUSCATING_MATRIX",
  "MOM_IUSE_BIOKIN_RECIPE_NOTE",
  "MOM_IUSE_CLAIR_RECIPE_NOTE",
  "MOM_IUSE_PYROKIN_RECIPE_NOTE",
  "MOM_IUSE_TELEKIN_RECIPE_NOTE",
  "MOM_IUSE_TELEPATH_RECIPE_NOTE",
  "MOM_IUSE_TELEPORT_RECIPE_NOTE",
  "MOM_IUSE_VITAKIN_RECIPE_NOTE",
}) do
  game.iuse_functions[iuse] = function(params) return mod.use_item_eoc(iuse, params) end
end
