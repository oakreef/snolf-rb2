hud.add(function(v, player, camera)
	if player.mo.skin == "snolf" then
		v.drawString(16, 164, "SHOTS", V_YELLOWMAP)
		v.drawString(64, 164, player.snolf.shots)

		if player.snolf.state == 1 then
			local patch = v.getSpritePatch(SPR_RING)
			v.drawScaled(
				FRACUNIT*(160+player.snolf.hdrive),
				FRACUNIT*150,
				FRACUNIT/4, patch)
		elseif player.snolf.state == 2 then
			local patch = v.getSpritePatch(SPR_RING)
			v.drawScaled(
				FRACUNIT*160,
				FRACUNIT*(150-player.snolf.vdrive),
				FRACUNIT/4, patch)
		end

	end


end, "game")

addHook("PreThinkFrame", function()
	
	for player in players.iterate do
		if player.mo.skin ~= "snolf" then
			continue
		end

		if player.snolf == nil then
			player.snolf = { shots = 0 }
		end

		--check if the jump button was just tapped
		if not (player.cmd.buttons & BT_JUMP) then
			player.snolf.jumptapready = true
			player.snolf.jumptapping = false
		elseif player.snolf.jumptapready then
			player.snolf.jumptapping = true
			player.snolf.jumptapready = false
		else
			player.snolf.jumptapping = false
		end
		
		--check if the ability button is being held
		if player.snolf.spinheld != nil and (player.cmd.buttons & BT_USE) then
			player.snolf.spinheld = $1 + 1
		else
			player.snolf.spinheld = 0
		end

		--swallow player input
		player.cmd.forwardmove = 0
		player.cmd.sidemove = 0
		player.cmd.buttons = $1 & !BT_JUMP
	end
	
end)



addHook("ThinkFrame", function()
	for player in players.iterate do
		if player.mo.skin ~= "snolf" then
			continue
		end

		player.mo.state = S_PLAY_ROLL --force rolling animation

		if player.snolf.spinheld > 60 and player.snolf.mull then

			P_TeleportMove(player.mo,
				player.snolf.mull.x,
				player.snolf.mull.y,
				player.snolf.mull.z)
			P_InstaThrust(player.mo, 0, 0)
			P_SetObjectMomZ(player.mo, 0)
			player.snolf.spinheld = 0
			S_StartSound(player.mo, sfx_mixup)
		end


		if P_IsObjectOnGround(player.mo) then
			player.pflags = $1 | PF_SPINNING --force spinning flag

			if player.speed == 0 then --player is stationary
				player.snolf.mull = { --set mulligan spot
					x = player.mo.x,
					y = player.mo.y,
					z = player.mo.z
				}
			end
		end

		-- snolfstate
		-- 0 ready to snolf
		-- 1 snolfing horizontal
		-- 2 snolfing vertical
		-- 3 snolf'd

		player.snolf.max_hrz = 50
		player.snolf.max_vrt = 50
		
		if player.snolf.state == 0 then
			if player.snolf.jumptapping then
				player.snolf.state = 1
				player.snolf.hdrive = 0
				player.snolf.vdrive = 0
				player.snolf.increment = 1
				player.snolf.timer = 0
				S_StartSoundAtVolume(player.mo, sfx_spndsh, 64)
			end
		elseif player.snolf.state == 1 then
			if player.snolf.jumptapping then
				player.snolf.state = 2
				player.snolf.increment = 1
				S_StartSoundAtVolume(player.mo, sfx_spndsh, 100)
			else
				player.snolf.timer = $1 + 1
				
				if player.snolf.hdrive >= player.snolf.max_hrz then
					player.snolf.increment = -1
				elseif player.snolf.hdrive <= 0 then
					player.snolf.increment = 1
				end
			
				if player.snolf.timer % 2 == 0 then
					player.snolf.hdrive = $1 + player.snolf.increment
				end
			end
		elseif player.snolf.state == 2 then
			if player.snolf.jumptapping then
				player.snolf.shots = $1 + 1
				player.snolf.state = 3
				P_InstaThrust(player.mo, player.mo.angle, player.snolf.hdrive*FRACUNIT)
				P_SetObjectMomZ(player.mo, player.snolf.vdrive*FRACUNIT)
				player.pflags = $1 | PF_JUMPED --force jumped flag
				S_StartSound(player.mo, sfx_zoom)
			else
				player.snolf.timer = $1 + 1
				
				if player.snolf.vdrive >= player.snolf.max_vrt then
					player.snolf.increment = -1
				elseif player.snolf.vdrive <= 0 then
					player.snolf.increment = 1
				end
				
				if player.snolf.timer % 2 == 0 then
					player.snolf.vdrive = $1 + player.snolf.increment
				end
			end
		elseif player.snolf.state == 3 then
			if P_IsObjectOnGround(player.mo) and player.speed == 0 then
				player.snolf.state = 0
			end
		elseif player.snolf.state == nil then
			player.snolf.state = 0
		end
	end
end)
