--Register wet concrete nodes
for _, state in pairs({"flowing", "source"}) do
	minetest.register_node("flowing_concrete:concrete_"..state, {
		description = (state == "source" and "Concrete Source" or "Flowing Concrete"),
		drawtype = (state == "source" and "liquid" or "flowingliquid"),
		tiles = {"flowing_concrete_block.png"},
		special_tiles = {
			{
				name = "flowing_concrete_block.png",
				backface_culling = false,
			},
			{
				name = "flowing_concrete_block.png",
				backface_culling = true,
			},
		},
		paramtype2 = (state == "flowing" and "flowingliquid" or nil),
		walkable = false,
		pointable = false,
		diggable = false,
		buildable_to = true,
		drop = "",
		drowning = 1,
		liquidtype = state,
		liquid_alternative_flowing = "flowing_concrete:concrete_flowing",
		liquid_alternative_source = "flowing_concrete:concrete_source",
		liquid_viscosity = 7, -- like lava
		liquid_renewable = false,
		post_effect_color = {a=192, r=188, g=185, b=174},
		groups = {
			liquid = 2,
			not_in_creative_inventory = (state == "flowing" and 1 or nil),
			rad_resistance = 10,
		},
	})
end

--Register bucket of concrete
bucket.register_liquid(
	"flowing_concrete:concrete_source",
	"flowing_concrete:concrete_flowing",
	"flowing_concrete:bucket_concrete",
	"flowing_concrete_bucket.png",
	"Concrete Bucket",
	{tool = 1}
)

--Register items and aliases so we don't need basic_materials.
if minetest.get_modpath("basic_materials") then
	minetest.register_alias("flowing_concrete:concrete_block", "basic_materials:concrete_block")
	minetest.register_alias("flowing_concrete:wet_cement", "basic_materials:wet_cement")
else
	minetest.register_alias("basic_materials:concrete_block", "flowing_concrete:concrete_block")
	minetest.register_alias("basic_materials:wet_cement", "flowing_concrete:wet_cement")
	
	minetest.register_node("flowing_concrete:concrete_block", {
		description = ("Concrete Block"),
		tiles = {"flowing_concrete_block.png"},
		is_ground_content = false,
		groups = {cracky = 1, concrete = 1, dig_stone = 1, pickaxey = 5, rad_resistance = 10},
		_mcl_hardness=1.6,
		sounds = default.node_sound_stone_defaults(),
	})
	
	minetest.register_craftitem("flowing_concrete:wet_cement", {
		description = ("Wet Cement"),
		inventory_image = "flowing_concrete_wet_cement.png",
	})
	
	minetest.register_craft({
		type = "shapeless",
		output = "flowing_concrete:wet_cement 3",
		recipe = {
			"default:dirt",
			"dye:dark_grey",
			"dye:dark_grey",
			"dye:dark_grey",
			"group:water_bucket"
		},
		replacements = {{"group:water_bucket", "bucket:bucket_empty"}},
	})
	
	stairs.register_slab(
			"concrete",
			"flowing_concrete:concrete_block",
			{cracky = 1, dig_stone = 1, pickaxey = 5},
			{"flowing_concrete_block.png"},
			"Concrete Slab",
			default.node_sound_stone_defaults(),
			true
		)
end

--Slab aliases
minetest.register_alias("flowing_concrete:slab_concrete", "stairs:slab_concrete")
minetest.register_alias("flowing_concrete:slab_concrete", "basic_materials:slab_concrete_8")

--Concrete bucket recipe
minetest.register_craft({
	output = "flowing_concrete:bucket_concrete",
	recipe = {
		{"group:sand", "flowing_concrete:wet_cement", "default:gravel"},
		{"default:steel_ingot", "bucket:bucket_empty", "flowing_concrete:wet_cement"},
		{"default:gravel", "flowing_concrete:wet_cement", "group:sand"},
	}
})

--Solidify the concrete over time.
local function harden_concrete(concrete)
	local concrete = concrete
	minetest.register_abm({
		label = "Harden concrete",
		nodenames = {"flowing_concrete:concrete_flowing"},
		interval = 30,
		chance = 1,
		action = function(pos, node)
			minetest.set_node(pos, {name = concrete})
		end,
	})
end

if minetest.settings:get_bool("flowing_concrete_slabs") then
	harden_concrete("flowing_concrete:slab_concrete")
else
	harden_concrete("flowing_concrete:concrete_block")
end

minetest.register_abm({
	label = "Harden concrete",
	nodenames = {"flowing_concrete:concrete_source"},
	neighbors = {"flowing_concrete:concrete_block"},
	interval = 40,
	chance = 1,
	action = function(pos, node)
		minetest.set_node(pos, {name = "flowing_concrete:concrete_block"})
	end,
})

--Register concrete bucket as dungeon loot
if minetest.global_exists("dungeon_loot") then
	dungeon_loot.register({
		{name = "flowing_concrete:bucket_concrete", chance = 0.45},

	})
end
