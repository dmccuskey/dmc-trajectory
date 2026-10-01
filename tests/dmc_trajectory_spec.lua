--====================================================================--
-- tests/dmc_trajectory_spec.lua
--
-- Unit tests for dmc-trajectory, using Luna Test.
-- Run with tests/run_unit.sh
--
-- Solar2D's Runtime is a stand-in here; frame() sends an enterFrame
-- event to its listeners
--====================================================================--


module(..., package.seeall)



--====================================================================--
--== Setup


local MODULE = 'dmc_corona.dmc_trajectory'

-- stand-ins for the Solar2D globals the module uses
package.preload.json = function() return require 'dkjson' end

_G.system = {
	ResourceDirectory=newproxy(),
	pathForFile=function( name ) return './'..name end,
}

local function newRuntime()
	local rt = { listeners={} }
	function rt:addEventListener( name, f )
		self.listeners[ name ] = self.listeners[ name ] or {}
		table.insert( self.listeners[ name ], f )
	end
	function rt:removeEventListener( name, f )
		for i, g in ipairs( self.listeners[ name ] or {} ) do
			if g == f then table.remove( self.listeners[ name ], i ) return end
		end
	end
	function rt:countListeners( name )
		return #( self.listeners[ name ] or {} )
	end
	return rt
end

-- frame()
-- sends one enterFrame event, at time ms
--
local function frame( time )
	local fs = {}
	for i, f in ipairs( Runtime.listeners.enterFrame or {} ) do fs[i] = f end
	for _, f in ipairs( fs ) do f( { name='enterFrame', time=time } ) end
end

-- a display object: removeSelf() takes its parent away and keeps
-- its methods, as in Solar2D
local function newObject()
	local o = { x=0, y=0, rotation=0, parent={} }
	function o:removeSelf() self.parent = nil end
	return o
end

local function load()
	package.loaded[ MODULE ] = nil
	package.loaded[ 'dmc_corona_boot' ] = nil
	_G.Runtime = newRuntime()
	return require( MODULE )
end

local function near( a, b ) return math.abs( a - b ) < 1e-6 end

-- errorOf()
-- the error f raises
--
local function errorOf( f )
	local ok, err = pcall( f )
	assert_false( ok, 'no error' )
	return err
end

local B, E = { 80, 120 }, { 240, 240 }



--====================================================================--
--== Tests


function test_module()
	local Trajectory = load()
	assert_equal( '1.2.0', Trajectory.VERSION )
end

function test_no_globals()
	-- master's leaked by an earlier test's load
	rawset( _G, '_extend', nil )
	local before = {}
	for k in pairs( _G ) do before[ k ] = true end
	local Trajectory = load()
	Trajectory.move( newObject(), { time=100, pBegin=B, pEnd=E, height=30, rotate=true } )
	frame( 1 ) ; frame( 50 ) ; frame( 200 )
	for k in pairs( _G ) do
		if not before[ k ] and k ~= '__dmc_corona' then
			fail( 'new global: '..tostring( k ) )
		end
	end
end

function test_calculate_reaches_the_end_point()
	local Trajectory = load()
	for _, case in ipairs( {
		{ B, E, 30 }, { E, B, 30 }, { { 0, 100 }, { 300, 100 }, 50 },
		{ { 0, 100 }, { -300, 0 }, 10 }, { { 0, 0 }, { 50, 200 }, 0 },
	} ) do
		local pB, pE, h = case[1], case[2], case[3]
		local r = Trajectory.calculate( { pBegin=pB, pEnd=pE, height=h } )
		assert_gt( 0, r.time )
		-- y is up in the math, down on screen
		assert_true( near( pE[1] - pB[1], Trajectory.x_Given_vx_t( r.Vx, r.time ) ) )
		assert_true( near( pB[2] - pE[2], Trajectory.y_Given_vy_t( r.Vy, r.time ) ) )
	end
end

function test_calculate_height_from_the_highest_point()
	local Trajectory = load()
	-- the top is height above the higher point, at Vy = 0
	for _, case in ipairs( { { B, E }, { E, B } } ) do
		local pB, pE = case[1], case[2]
		local r = Trajectory.calculate( { pBegin=pB, pEnd=pE, height=30 } )
		local tTop = r.Vy / 9.8
		local top = pB[2] - Trajectory.y_Given_vy_t( r.Vy, tTop )
		assert_true( near( math.min( pB[2], pE[2] ) - 30, top ) )
	end
end

function test_calculate_angle()
	local Trajectory = load()
	-- going right and up: rotated counterclockwise, a negative angle
	local r = Trajectory.calculate( { pBegin=B, pEnd=E, height=30 } )
	assert_true( near( -math.deg( math.atan( r.Vy / r.Vx ) ), r.angle ) )
	assert_lt( 0, r.angle )
	-- going left, facing right: turned around
	r = Trajectory.calculate( { pBegin=E, pEnd=B, height=30 } )
	assert_gt( 90, r.angle )
	-- going left, facing left
	r = Trajectory.calculate( { pBegin=E, pEnd=B, height=30, direction='left' } )
	assert_gt( 0, r.angle ) ; assert_lt( 90, r.angle )
end

function test_move()
	local Trajectory = load()
	local o, done = newObject(), 0
	Trajectory.move( o, { time=1000, pBegin=B, pEnd=E, height=30,
		onComplete=function() done = done + 1 end } )
	assert_equal( 1, Runtime:countListeners( 'enterFrame' ) )
	frame( 5000 ) -- the first frame starts the clock
	assert_equal( B[1], o.x ) ; assert_equal( B[2], o.y )
	frame( 5500 )
	assert_gt( B[1], o.x ) ; assert_lt( E[1], o.x )
	assert_equal( 0, o.rotation ) -- rotate is off
	frame( 6000 )
	assert_equal( E[1], o.x ) ; assert_equal( E[2], o.y )
	assert_equal( 1, done )
	assert_equal( 0, Runtime:countListeners( 'enterFrame' ) )
end

function test_move_highest_point()
	local Trajectory = load()
	local o, top = newObject(), math.huge
	Trajectory.move( o, { time=1000, pBegin=B, pEnd=E, height=30 } )
	for t = 0, 1000, 5 do
		frame( 1 + t )
		top = math.min( top, o.y )
	end
	assert_lt( 0.5, math.abs( top - ( B[2] - 30 ) ) )
end

function test_move_rotate()
	local Trajectory = load()
	local o, angles = newObject(), {}
	Trajectory.move( o, { time=1000, pBegin=B, pEnd=E, height=30, rotate=true } )
	for t = 0, 1000, 100 do
		frame( 1 + t )
		table.insert( angles, o.rotation )
	end
	-- up and right at the start, down and right at the end
	assert_lt( 0, angles[1] )
	assert_gt( 0, angles[ #angles ] ) ; assert_lt( 90, angles[ #angles ] )
	for i = 2, #angles do assert_gte( angles[i-1], angles[i] ) end
end

function test_move_rotate_no_movement_keeps_angle()
	local Trajectory = load()
	local o = newObject()
	Trajectory.move( o, { time=1000, pBegin=B, pEnd=E, height=30, rotate=true } )
	frame( 1 ) ; frame( 100 )
	local a = o.rotation
	frame( 100 ) -- same time, same place
	assert_equal( a, o.rotation )
end

function test_move_vertical()
	local Trajectory = load()
	local o, done = newObject(), false
	Trajectory.move( o, { time=500, pBegin={ 100, 300 }, pEnd={ 100, 100 }, height=20,
		rotate=true, onComplete=function() done = true end } )
	for t = 0, 500, 50 do frame( 1 + t ) end
	assert_true( done )
	assert_equal( 100, o.x ) ; assert_equal( 100, o.y )
end

function test_move_removed_object_stops()
	local Trajectory = load()
	local o, done = newObject(), false
	Trajectory.move( o, { time=1000, pBegin=B, pEnd=E, height=30,
		onComplete=function() done = true end } )
	frame( 1 ) ; frame( 300 )
	o:removeSelf()
	local x = o.x
	frame( 600 ) ; frame( 2000 )
	assert_equal( 0, Runtime:countListeners( 'enterFrame' ) )
	assert_equal( x, o.x )
	assert_false( done )
end

function test_move_zero_time()
	local Trajectory = load()
	local o, done = newObject(), false
	Trajectory.move( o, { time=0, pBegin=B, pEnd=E, height=30,
		onComplete=function() done = true end } )
	frame( 1 )
	assert_true( done )
	assert_equal( E[1], o.x ) ; assert_equal( E[2], o.y )
end

function test_bad_params()
	local Trajectory = load()
	local o = newObject()
	local function check( pat, f )
		local err = errorOf( f )
		assert_match( pat, err )
		-- reported at the caller's line, in this file
		assert_match( 'dmc_trajectory_spec', err )
	end
	check( 'params must be a table', function() Trajectory.calculate() end )
	check( 'pBegin must be', function() Trajectory.calculate( { pEnd=E, height=1 } ) end )
	check( 'pEnd must be', function() Trajectory.calculate( { pBegin=B, pEnd={ 1 }, height=1 } ) end )
	check( 'height must be', function() Trajectory.calculate( { pBegin=B, pEnd=E } ) end )
	check( 'height must be', function() Trajectory.calculate( { pBegin=B, pEnd=E, height=-1 } ) end )
	check( 'same height', function()
		Trajectory.calculate( { pBegin={ 0, 10 }, pEnd={ 50, 10 }, height=0 } ) end )
	check( 'obj must be', function() Trajectory.move( nil, { pBegin=B, pEnd=E, height=1, time=1 } ) end )
	check( 'pBegin must be', function() Trajectory.move( o, { pEnd=E, height=1, time=1 } ) end )
	check( 'time must be', function() Trajectory.move( o, { pBegin=B, pEnd=E, height=1 } ) end )
	assert_equal( 0, Runtime:countListeners( 'enterFrame' ) )
end

function test_move_vertical_rotate_points_along_the_path()
	local Trajectory = load()
	-- facing right: up is -90, down is 90; facing left: up is 90, down is 270
	for _, case in ipairs( { { 'right', -90, 90 }, { 'left', 90, 270 } } ) do
		local o, angles = newObject(), {}
		Trajectory.move( o, { time=1000, pBegin={ 100, 300 }, pEnd={ 100, 300 }, height=100,
			rotate=true, direction=case[1] } )
		for t = 0, 900, 100 do
			frame( 1 + t )
			table.insert( angles, o.rotation )
		end
		assert_equal( case[2], angles[1] )
		assert_equal( case[2], angles[3] )
		assert_equal( case[3], angles[ #angles ] )
		frame( 2000 )
	end
end

-- a table that isn't in the scene (no parent) still moves
function test_move_plain_table()
	local Trajectory = load()
	local o, done = { x=0, y=0, rotation=0 }, false
	Trajectory.move( o, { time=100, pBegin=B, pEnd=E, height=30,
		onComplete=function() done = true end } )
	frame( 1 ) ; frame( 50 ) ; frame( 200 )
	assert_true( done )
	assert_equal( E[1], o.x )
end
