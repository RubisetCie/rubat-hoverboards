
function PANEL:Init( )

	--self.AttributePoints = 5
	self.Attributes = {}

	self.BoardSelect = vgui.Create( "PropSelect", self )
	self.BoardSelect:SetConVar( "hoverboard_model" )
	self.BoardSelect:Dock( TOP )
	self.BoardSelect.Label:SetText( "Select Model" )

	--[[self.PointsText = vgui.Create( "DLabel", self )
	self.PointsText:SetText( "Attribute Points: 0" )
	self.PointsText:SetDark( true )
	self.PointsText:SizeToContents()]]

	self:AddAttribute( "Speed", 1, 16 )
	self:AddAttribute( "Jump", 0, 16 )
	self:AddAttribute( "Turn", 1, 64 )
	self:AddAttribute( "Flip", 1, 16 )
	self:AddAttribute( "Twist", 1, 16 )

end

function PANEL:PerformLayout( )

	self:SizeToChildren( false, true )

	--self:UpdatePoints()

end

function PANEL:Think()

	if ( self.HoverboardTable ) then

		local selected = GetConVarString( self.BoardSelect:ConVar() )
		if ( selected != self.LastSelectedBoard ) then

			self.LastSelectedBoard = selected

			for name, panel in pairs( self.Attributes ) do

				panel:SetText( name )
				panel.Label:SetTextColor( panel.OldFontColor )

			end

		end

	end

end

function PANEL:PopulateBoards( tbl )

	for _, board in pairs( tbl ) do

		self.BoardSelect:AddModel( board[ "model" ] )

		self.BoardSelect.Controls[ #self.BoardSelect.Controls ]:SetTooltip( board[ "name" ] or "Unknown" )

	end

	self.HoverboardTable = tbl

end

function PANEL:GetUsedPoints( ignore )

	local count = 0

	return count

end

function PANEL:AddAttribute( name, min, max )

	local panel = vgui.Create( "DNumSlider", self )
	panel:SetText( name )
	panel:SetMin( min or 0 )
	panel:SetMax( max or 16 )
	panel:Dock( TOP )
	panel:SetDark( true )
	panel:SetDecimals( 0 )
	--panel.Attribute = name:lower()

	local cvarName = ( "hoverboard_%s" ):format( name:lower() )
	panel:SetConVar( cvarName )

	local cvar = GetConVar( cvarName )
	if ( cvar ) then
		panel:SetDefaultValue( cvar:GetDefault() )
	end

	panel.OnValueChanged = function( slider, val )

		val = math.Clamp( tonumber( val ), slider:GetMin(), slider:GetMax() )
		slider:SetValue( val )

	end

	panel.OldFontColor = panel.Label:GetTextColor()

	self.Attributes[ name ] = panel

end
