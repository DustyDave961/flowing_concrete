--Register wet concrete nodes
for _, state in pairs({"flowing", "source"}) do
	minetest.register_node("flowing_concrete:concrete_"..state, {
		description = (state == "source" and "Concrete Source" or "Flowing Concrete"),
		drawtype = (state == "source" and "liquid" or "flowingliquid"),
		tiles = {{
			name = "flowing_concrete_block.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 3.0,
			},
		}},
		special_tiles = {
			{
				name = "flowing_concrete_block.png",
				backface_culling = false,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 3.0,
				},
			},
			{
				name = "flowing_concrete_block.png",
				backface_culling = true,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 3.0,
				},
			},
		},
		use_texture_alpha = "blend",
		paramtype = "light",
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

local function concrete_stairs()
	stairs.register_stair_and_slab(
		"concrete",
		"flowing_concrete:concrete_block",
		{cracky = 1, dig_stone = 1, pickaxey = 5},
		{"flowing_concrete_block.png"},
		"Concrete Stair",
		"Concrete Slab",
		default.node_sound_stone_defaults(),
		true,
		"Inner Concrete Stair",
		"Outer Concrete Stair"
	)
end

--Copy items so we don't need basic_materials.
if minetest.get_modpath("basic_materials") then
	minetest.register_alias("flowing_concrete:concrete_block", "basic_materials:concrete_block")
	
	if minetest.get_modpath("stairsplus_legacy") then
		minetest.register_alias("flowing_concrete:slab_concrete", "basic_materials:slab_concrete_8")
	else
		concrete_stairs()
	end
	minetest.register_alias("flowing_concrete:wet_cement", "basic_materials:wet_cement")
else
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
	minetest.register_alias("basic_materials:concrete_block", "flowing_concrete:concrete_block")
	minetest.register_alias("basic_materials:wet_cement", "flowing_concrete:wet_cement")
	
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
	concrete_stairs()
end

--Bucket of concrete
minetest.register_craft({
	output = "flowing_concrete:bucket_concrete",
	recipe = {
		{"group:sand", "flowing_concrete:wet_cement", "default:gravel"},
		{"default:steel_ingot", "flowing_concrete:wet_cement" ,"bucket:bucket_empty"},
		{"default:gravel", "flowing_concrete:wet_cement", "group:sand"},
	},
})

bucket.register_liquid(
	"flowing_concrete:concrete_source",
	"flowing_concrete:concrete_flowing",
	"flowing_concrete:bucket_concrete",
	"#c4bdb5",
	"Concrete Bucket",
	{tool = 1}
)

minetest.register_alias("flowing_concrete:slab_concrete", "stairs:slab_concrete")

--Solidify the concrete over time.
local function harden_concrete(concrete)
	local concrete = concrete
	
	local nodenames_slab = {"flowing_concrete:concrete_flowing"}
	local nodenames_block = {"flowing_concrete:concrete_source"}
	
	if minetest.get_modpath("liquid_physics") then
		nodenames_slab = {}
		nodenames_block = {}
		local id_concrete_liquid = liquid_physics.get_liquid_id("flowing_concrete:concrete_source")
		local node_names = liquid_physics.get_liquid_node_names(id_concrete_liquid)
		-- Up to half height
		for i = 1, 4 do
			table.insert(nodenames_slab, node_names[i])
		end
		-- Half height up to full height
		for i = 5, 8 do
			table.insert(nodenames_block, node_names[i])
		end
	end
	
	minetest.register_abm({
		label = "Harden: Flowing concrete",
		nodenames = nodenames_slab,
		interval = 30,
		chance = 1,
		action = function(pos, node)
			minetest.set_node(pos, {name = concrete})
		end,
	})	
	minetest.register_abm({
		label = "Harden: concrete Source",
		nodenames = nodenames_block,
		neighbors = {concrete},
		interval = 40,
		chance = 1,
		action = function(pos, node)
			minetest.set_node(pos, {name = "flowing_concrete:concrete_block"})
		end,
	})
end

if minetest.get_modpath("liquid_physics") then
	liquid_physics.register_liquid("flowing_concrete", "concrete_source", "concrete_flowing")
end

if minetest.settings:get_bool("flowing_concrete_slabs") then
	harden_concrete("flowing_concrete:slab_concrete")
else
	harden_concrete("flowing_concrete:concrete_block")
end

--Register concrete bucket as dungeon loot
if minetest.global_exists("dungeon_loot") then
	dungeon_loot.register({
		{name = "flowing_concrete:bucket_concrete", chance = 0.45},

	})
end
