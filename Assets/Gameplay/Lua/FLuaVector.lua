------------------------------------------------------------------------------
--	Copyright (c) 2009 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
function Vector2( i, j )       return { x = i, y = j }; end
function Vector3( i, j, k )    return { x = i, y = j, z = k }; end
function Vector4( i, j, k, l ) return { x = i, y = j, z = k, w = l }; end
function Color( r, g, b, a )   return Vector4( r, g, b, a ); end

function VecAdd( v1, v2 ) 
    temp = {};
    if( v1.x ~= nil and v2.x ~= nil ) then temp.x = v1.x + v2.x; end
    if( v1.y ~= nil and v2.y ~= nil ) then temp.y = v1.y + v2.y; end
    if( v1.z ~= nil and v2.z ~= nil ) then temp.z = v1.z + v2.z; end
    if( v1.w ~= nil and v2.w ~= nil ) then temp.w = v1.w + v2.w; end
    return temp;
end

function VecSubtract( v1, v2 ) 
    temp = {};
    if( v1.x ~= nil and v2.x ~= nil ) then temp.x = v1.x - v2.x; end
    if( v1.y ~= nil and v2.y ~= nil ) then temp.y = v1.y - v2.y; end
    if( v1.z ~= nil and v2.z ~= nil ) then temp.z = v1.z - v2.z; end
    if( v1.w ~= nil and v2.w ~= nil ) then temp.w = v1.w - v2.w; end
    return temp;
end