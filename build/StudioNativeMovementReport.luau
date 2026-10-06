assert(game.PlaceId==140221183064352)
local c=_G.BombNativeMovement
print('BOMB_NATIVE_OBSERVER_STATUS',c.done,#c.samples,#c.states)
local previous=nil
for _,s in ipairs(c.states) do
 local key=tostring(s[4])..','..tostring(s[5])
 if key~=previous then print('BOMB_NATIVE_INPUT',s[1],s[2],s[3],key);previous=key end
end
for i=2,#c.states do
 local a,b=c.states[i-1],c.states[i]
 if (a[4]~=0 or a[5]~=0) and b[4]==0 and b[5]==0 then
  local near={}
  for _,v in ipairs(c.samples) do if v[1]>=b[1]-.1 and v[1]<=b[1]+.1 then table.insert(near,{v[1]-b[1],v[2],v[3]}) end end
  print('BOMB_NATIVE_RELEASE_RENDER',game:GetService('HttpService'):JSONEncode(near))
 end
end
