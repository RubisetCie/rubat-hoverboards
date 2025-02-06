
TOOL.Category = "Fun"
TOOL.Name = "#tool.hoverboard.name"

TOOL.ClientConVar[ "model" ] = "models/dav0r/hoverboard/hoverboard.mdl"
TOOL.ClientConVar[ "lights" ] = 1
TOOL.ClientConVar[ "mousecontrol" ] = 1
TOOL.ClientConVar[ "boostshake" ] = 1
TOOL.ClientConVar[ "height" ] = 72
TOOL.ClientConVar[ "viewdist" ] = 172
TOOL.ClientConVar[ "trail_size" ] = 5
TOOL.ClientConVar[ "trail_r" ] = 128
TOOL.ClientConVar[ "trail_g" ] = 128
TOOL.ClientConVar[ "trail_b" ] = 255
TOOL.ClientConVar[ "boost_r" ] = 128
TOOL.ClientConVar[ "boost_g" ] = 255
TOOL.ClientConVar[ "boost_b" ] = 128
TOOL.ClientConVar[ "recharge_r" ] = 255
TOOL.ClientConVar[ "recharge_g" ] = 128
TOOL.ClientConVar[ "recharge_b" ] = 128
TOOL.ClientConVar[ "speed" ] = 10
TOOL.ClientConVar[ "jump" ] = 4
TOOL.ClientConVar[ "turn" ] = 24
TOOL.ClientConVar[ "flip" ] = 10
TOOL.ClientConVar[ "twist" ] = 5

TOOL.Information = {
	{ name = "left" },
	{ name = "right" }
}

-- TO ADD NEW HOVERBOARDS, CHECK OUT THE AUTORUN FILE

AddCSLuaFile( "vgui/hoverboard_gui.lua" )

cleanup.Register( "hoverboards" )

for _, hbt in pairs( HoverboardTypes ) do

	list.Set( "HoverboardModels", hbt.model, {} )
	util.PrecacheModel( hbt.model )

	--[[if ( SERVER and GetConVarNumber( "rb655_force_downloads" ) > 0 ) then

		resource.AddFile( hbt.model )

		-- Materials and stuff
		if ( hbt.files ) then

			for __, f in pairs( hbt.files ) do resource.AddFile( f ) end

		end

	end]]

end

function TOOL:LeftClick( trace )

	local result, hoverboard = self:CreateBoard( trace )
	return result

end

function TOOL:RightClick( trace )

	local result, hoverboard = self:CreateBoard( trace )

	if ( CLIENT ) then return result end

	if ( IsValid( hoverboard ) ) then

		local pl = self:GetOwner()

		local dist = ( hoverboard:GetPos() - pl:GetPos() ):Length()
		if ( dist <= 512 ) then

			timer.Simple( 0.25, function()

				if ( IsValid( hoverboard ) and IsValid( pl ) ) then hoverboard:SetDriver( pl ) end

			end )

		end

	end

	return result

end

function TOOL:CreateBoard( trace )

	if ( CLIENT ) then return true end

	-- Stuff is clamped in MakeHoverboard

	local pl = self:GetOwner()
	if ( GetConVarNumber( "sv_hoverboard_adminonly" ) > 0 and !( pl:IsAdmin() or pl:IsSuperAdmin() ) ) then return false end

	local model = self:GetClientInfo( "model" )
	local mcontrol = self:GetClientNumber( "mousecontrol" )
	local shake = self:GetClientNumber( "boostshake" )
	local trailsize = self:GetClientNumber( "trail_size" )
	local height = self:GetClientNumber( "height" )
	local viewdist = self:GetClientNumber( "viewdist" )
	local trail = Vector( self:GetClientNumber( "trail_r" ), self:GetClientNumber( "trail_g" ), self:GetClientNumber( "trail_b" ) )
	local boost = Vector( self:GetClientNumber( "boost_r" ), self:GetClientNumber( "boost_g" ), self:GetClientNumber( "boost_b" ) )
	local recharge = Vector( self:GetClientNumber( "recharge_r" ), self:GetClientNumber( "recharge_g" ), self:GetClientNumber( "recharge_b" ) )

	local attributes = {
		speed = self:GetClientNumber( "speed" ),
		jump = self:GetClientNumber( "jump" ),
		turn = self:GetClientNumber( "turn" ),
		flip = self:GetClientNumber( "flip" ),
		twist = self:GetClientNumber( "twist" )
	}

	local ang = pl:GetAngles()
	ang.p = 0
	ang.y = ang.y + 180

	local pos = trace.HitPos + trace.HitNormal * 32

	local hoverboard = MakeHoverboard( pl, model, ang, pos, mcontrol, shake, height, viewdist, trailsize, trail, boost, recharge, attributes )
	if ( !IsValid( hoverboard ) ) then return false end

	undo.Create( "Hoverboard" )
		undo.AddEntity( hoverboard )
		undo.SetPlayer( pl )
	undo.Finish()

	return true, hoverboard

end

if ( SERVER ) then

	function MakeHoverboard( pl, model, ang, pos, mcontrol, shake, height, viewdist, trailsize, trail, boost, recharge, attributes )

		if ( IsValid( pl ) and !pl:CheckLimit( "hoverboards" ) ) then return false end

		local hoverboard = ents.Create( "modulus_hoverboard" )
		if ( !IsValid( hoverboard ) ) then return false end

		-- Get the board info
		local boardinfo
		for _, board in pairs( HoverboardTypes ) do

			if ( board.model:lower() == model:lower() ) then

				boardinfo = board
				break

			end

		end
		if ( !boardinfo ) then return false end

		util.PrecacheModel( model )

		hoverboard:SetModel( model )
		hoverboard:SetAngles( ang )
		hoverboard:SetPos( pos )

		hoverboard:SetBoardRotation( 0 )

		if ( boardinfo.rotation ) then

			local rot = tonumber( boardinfo.rotation )

			hoverboard:SetBoardRotation( tonumber( boardinfo.rotation ) )

			ang.y = ang.y - rot
			hoverboard:SetAngles( ang )

		end

		hoverboard:Spawn()
		hoverboard:Activate()

		hoverboard:SetAvatarPosition( vector_origin )

		if ( boardinfo.driver ) then
			hoverboard:SetAvatarPosition( boardinfo.driver )
		end

		for k, v in pairs( boardinfo ) do

			if ( k:sub( 1, 7 ):lower() == "effect_" and type( boardinfo[ k ] ) == "table" ) then

				local effect = boardinfo[ k ]

				hoverboard:AddEffect( effect.effect or "trail", effect.position, effect.normal, effect.scale or 1 )

			end

		end

		local height = math.Clamp( height, 10, 200 )
		hoverboard:SetControls( tonumber( mcontrol ) != 0 )
		hoverboard:SetBoostShake( tonumber( shake ) != 0 )
		hoverboard:SetHoverHeight( math.Clamp( tonumber( height ), 36, 100 ) )
		hoverboard:SetViewDistance( math.Clamp( tonumber( viewdist ), 64, 256 ) )
		hoverboard:SetSpring( 0.21 * ( ( 72 / height ) * ( 72 / height ) ) )

		hoverboard:SetTrailScale( math.Clamp( trailsize, 0, 10 ) * 0.3 )
		hoverboard:SetTrailColor( trail )
		hoverboard:SetTrailBoostColor( boost )
		hoverboard:SetTrailRechargeColor( recharge )

		-- Clamp the attribs, this should match the UI
		attributes.speed = math.Clamp( attributes.speed, 1, 16 )
		attributes.jump = math.Clamp( attributes.jump, 0, 16 )
		attributes.turn = math.Clamp( attributes.turn, 1, 64 )
		attributes.flip = math.Clamp( attributes.flip, 1, 16 )
		attributes.twist = math.Clamp( attributes.twist, 1, 16 )

		-- Set the attributes
		hoverboard:SetSpeed( ( attributes.speed * 0.1 ) * 20 )
		hoverboard:SetJumpPower( ( attributes.jump * 0.1 ) * 250 ) -- It seems to me that this should be 2500
		hoverboard:SetTurnSpeed( ( attributes.turn * 0.1 ) * 25 )

		local flip = ( attributes.flip * 0.1 ) * 25
		local twist = ( attributes.twist * 0.1 ) * 25
		hoverboard:SetPitchSpeed( flip )
		hoverboard:SetYawSpeed( twist )
		hoverboard:SetRollSpeed( ( ( flip + twist * 0.5 ) / 50 ) * 22 )

		DoPropSpawnedEffect( hoverboard )

		if ( IsValid( pl ) ) then
			pl:AddCount( "hoverboards", hoverboard )
			pl:AddCleanup( "hoverboards", hoverboard )
			hoverboard.Creator = pl:UniqueID()
		end

		return hoverboard

	end

	return
end

language.Add( "tool.hoverboard.name", "Hoverboards" )
language.Add( "tool.hoverboard.desc", "Spawn customized hoverboards" )
language.Add( "tool.hoverboard.left", "Spawn a hoverboard" )
language.Add( "tool.hoverboard.right", "Spawn a hoverboard and mount onto it (if within 512 units)" )

language.Add( "tool.hoverboard.height", "Hover Height" )
language.Add( "tool.hoverboard.mouse_control", "Mouse Control" )
language.Add( "tool.hoverboard.boost_shake", "Boost Shake" )
language.Add( "tool.hoverboard.boost_color", "Boost Color" )
language.Add( "tool.hoverboard.trail_size", "Trail Size" )
language.Add( "tool.hoverboard.trail_color", "Trail Color" )
language.Add( "tool.hoverboard.recharge_color", "Recharge Color" )
language.Add( "tool.hoverboard.view_dist", "View Distance" )
language.Add( "tool.hoverboard.lights", "Trail Lights" )
language.Add( "tool.hoverboard.lights.help", "The following commands are ONLY accessible to the server host on a LISTEN SERVER!" )

language.Add( "Undone_hoverboard", "Undone Hoverboard" )
language.Add( "SBoxLimit_hoverboards", "You've reached the Hoverboard limit!" )
language.Add( "max_hoverboards", "Max Hoverboards:" )

local hbpanel = vgui.RegisterFile( "vgui/hoverboard_gui.lua" )

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel( cp )

	local presets = vgui.Create( "ControlPresets", cp )
	presets:SetPreset( "hoverboard" )
	presets:AddOption( "#preset.default", ConVarsDefault )
	for k, v in pairs( table.GetKeys( ConVarsDefault ) ) do
		presets:AddConVar( v )
	end
	cp:AddPanel( presets )

	local panel = vgui.CreateFromTable( hbpanel )
	panel:PopulateBoards( HoverboardTypes )
	panel:PerformLayout( )
	cp:AddPanel( panel )

	cp:NumSlider( "#tool.hoverboard.height", "hoverboard_height", 36, 100, 0 ):GetParent():DockPadding( 10, 0, 10, 0 )
	cp:CheckBox( "#tool.hoverboard.mouse_control", "hoverboard_mousecontrol" )
	cp:CheckBox( "#tool.hoverboard.boost_shake", "hoverboard_boostshake" )

	local trailColor = vgui.Create( "CtrlColor", cp )
	trailColor:SetLabel( "#tool.hoverboard.trail_color" )
	trailColor:SetConVarR( "hoverboard_trail_r" )
	trailColor:SetConVarG( "hoverboard_trail_g" )
	trailColor:SetConVarB( "hoverboard_trail_b" )
	cp:AddPanel( trailColor )
	local boostColor = vgui.Create( "CtrlColor", cp )
	boostColor:SetLabel( "#tool.hoverboard.boost_color" )
	boostColor:SetConVarR( "hoverboard_boost_r" )
	boostColor:SetConVarG( "hoverboard_boost_g" )
	boostColor:SetConVarB( "hoverboard_boost_b" )
	cp:AddPanel( boostColor )
	local rechargeColor = vgui.Create( "CtrlColor", cp )
	rechargeColor:SetLabel( "#tool.hoverboard.recharge_color" )
	rechargeColor:SetConVarR( "hoverboard_recharge_r" )
	rechargeColor:SetConVarG( "hoverboard_recharge_g" )
	rechargeColor:SetConVarB( "hoverboard_recharge_b" )
	cp:AddPanel( rechargeColor )

	cp:NumSlider( "#tool.hoverboard.trail_size", "hoverboard_trail_size", 0, 10, 0 )
	cp:NumSlider( "#tool.hoverboard.view_dist", "hoverboard_viewdist", 64, 256, 0 ):GetParent():DockPadding( 10, 0, 10, 0 )

	cp:CheckBox( "#tool.hoverboard.lights", "hoverboard_lights" )

	cp:ControlHelp( "#tool.hoverboard.lights.help" )
	cp:CheckBox( "Fall from Hoverboard", "sv_hoverboard_canfall" )
	cp:CheckBox( "Jump on Water", "sv_hoverboard_water_jump" )
	cp:CheckBox( "Hoverboards can Deal Damage", "sv_hoverboard_allow_damage" )
	cp:CheckBox( "Hoverboard Sharing", "sv_hoverboard_canshare" )
	cp:CheckBox( "Hoverboard Stealing", "sv_hoverboard_cansteal" )
	cp:CheckBox( "Admin Only", "sv_hoverboard_adminonly" )
	cp:NumSlider( "Max Hoverboards Per Player", "sbox_maxhoverboards", 1, 10, 0 )

end
