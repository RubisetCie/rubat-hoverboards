
local plasma = Material( "effects/strider_muzzle" )
local refract = Material( "sprites/heatwave" )

local UnPredictedCurTime = UnPredictedCurTime
local math = math
local render = render
local color_blue = Color( 128, 200, 255, 255 )
local color_cyan1 = Color( 0, 255, 255, 255 )
local color_cyan2 = Color( 0, 255, 255, 0)
local color_white = color_white

function EFFECT:Init( pos, normal, scale )

	self.Position = pos
	self.Scale = scale
	self.Normal = normal:Angle()

	self.Emitter = ParticleEmitter( self.Board:GetPos() )

end

function EFFECT:ShouldRender( )

	if ( self.Board:IsGrinding() or self.Board:GetUp().z < 0.33 or self.Board:WaterLevel() > 0 ) then return false end

	return true

end

function EFFECT:Think( )

end

function EFFECT:Render( )

	if ( !self:ShouldRender() ) then return end

	local anchor = self.Board:LocalToWorld( self.Position )

	local normal = self.Board:LocalToWorldAngles( self.Normal ):Forward()
	anchor = anchor + normal * 2.5

	render.SetMaterial( refract )
	render.DrawSprite( anchor, 4 * math.Rand( 1, 1.5 ), 4 * math.Rand( 1, 1.5 ), color_blue )

	local scroll = UnPredictedCurTime() * -20

	render.SetMaterial( plasma )

	scroll = scroll * 0.9
	render.StartBeam( 3 )
		render.AddBeam( anchor, 3, scroll, color_cyan1 )
		render.AddBeam( anchor + normal * 8, 3, scroll + 0.01, color_white )
		render.AddBeam( anchor + normal * 12, 3, scroll + 0.02, color_cyan2 )
	render.EndBeam()

	scroll = scroll * 0.9
	render.StartBeam( 3 )
		render.AddBeam( anchor, 3, scroll, color_cyan1 )
		render.AddBeam( anchor + normal * 3, 3, scroll + 0.01, color_white )
		render.AddBeam( anchor + normal * 6, 3, scroll + 0.02, color_cyan2 )
	render.EndBeam()

	scroll = scroll * 0.9
	render.StartBeam( 3 )
		render.AddBeam( anchor, 3, scroll, color_cyan1 )
		render.AddBeam( anchor + normal * 3, 3, scroll + 0.01, color_white )
		render.AddBeam( anchor + normal * 6, 3, scroll + 0.02, color_cyan2 )
	render.EndBeam()

end
