--------------------------------------------------------
-- Minetest :: WieldView II Mod (wieldview)
--
-- See README.txt for licensing and other information.
-- Copyright (c) 2020, Leslie E. Krause
--
-- ./games/minetest_game/mods/wieldview/init.lua
--------------------------------------------------------

plugins.require( "minetest.include" )
plugins.require( "Timekeeper" )

local config = minetest.load_config( )

local transforms = minetest.include( "transforms.lua" )
local wielded_items = { }

------------

local function TileReader( def )
	return {
		get_front_texture = function ( )
			local texture = def.tiles[ 6 ] or def.tiles[ 3 ] or def.tiles[ 1 ]
			return texture.name or texture
		end,
		get_left_texture = function ( )
			local texture = def.tiles[ 3 ] or def.tiles[ 1 ]
			return texture.name or texture
		end,
		get_top_texture = function ( )
			return def.tiles[ 1 ].name or def.tiles[ 1 ]
		end,
	}
end

local function get_item_texture( item_name )
	local item_def = minetest.registered_items[ item_name ]
	local texture	

	if not item_def then
		texture = "unknown_item.png"

	elseif item_def.inventory_image ~= "" then
		if transforms[ item_name ] then
			texture = item_def.inventory_image .. "^[transform" .. transforms[ item_name ]
		else
			texture = item_def.inventory_image
		end

	elseif item_def.wield_image ~= "" then
		if transforms[ item_name ] then
			texture = item_def.wield_image .. "^[transform" .. transforms[ item_name ]
		else
			texture = item_def.wield_image
		end

	elseif item_def.tiles and item_def.drawtype ~= "mesh" and item_def.drawtype ~= "nodebox" then
		local tiles = TileReader( item_def )

		if config.tile_projection == "side" then
			texture = tiles.get_front_texture( )
		elseif config.tile_projection == "top" then
			texture = tiles.get_top_texture( )
		elseif config.tile_projection == "cube" then
			texture = minetest.inventorycube(
				tiles.get_top_texture( ),
				tiles.get_left_texture( ),
				tiles.get_front_texture( )
			)
		end
		texture = texture .. "^[transform" .. config.tile_transform

	else
		texture = "blank.png"

	end

	return texture
end

local function update_wielded_item( player )
	local item_name =  player:get_wielded_item( ):get_name( )
	local player_name = player:get_player_name( )

	if wielded_items[ player_name ] == item_name then return end

	armor.textures[ player_name ].wielditem =
		item_name ~= "" and get_item_texture( item_name ) or "blank.png"
	armor:update_player_visuals( player )

	wielded_items[ player_name ] = item_name
end

------------

local globaltimer = Timekeeper( { } )

minetest.register_globalstep( function ( dtime )
	globaltimer.on_step( dtime )
end )

minetest.register_on_joinplayer( function( player )
	wielded_items[ player:get_player_name( ) ] = ""
end )

minetest.register_on_leaveplayer( function( player )
	wielded_items[ player:get_player_name( ) ] = nil
end )

globaltimer.start( config.timer_period, "update_wielded_item", function ( )
	for name, data in pairs( registry.connected_players ) do
		update_wielded_item( data.obj )
	end
end, config.timer_delay )
