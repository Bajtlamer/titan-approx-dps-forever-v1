local _,ns=...
local J={};ns.Json=J
local escapes={['"']='\\"',['\\']='\\\\',['\n']='\\n',['\r']='\\r',['\t']='\\t'}
local function quote(s)return '"'..s:gsub('[%z\1-\31\\"]',function(c)return escapes[c] or string.format('\\u%04x',c:byte())end)..'"'end
function J.Encode(v)
 local function encode(x,depth)
  assert(depth<=32,'JSON nesting limit')
  if type(x)=='string'then return quote(x)elseif type(x)=='number'then assert(x==x and math.abs(x)<math.huge,'Invalid number');return tostring(x)elseif type(x)=='boolean'then return tostring(x)elseif x==nil then return 'null' end
  assert(type(x)=='table','Unsupported JSON value')
  local keys={};for k in pairs(x)do keys[#keys+1]=k end
  local array=#keys>0 and #keys==#x
  if array then for _,k in ipairs(keys)do if type(k)~='number' or k<1 or k>#keys or k%1~=0 then array=false end end end
  local out={}
  if array then for i=1,#x do out[i]=encode(x[i],depth+1)end;return '['..table.concat(out,',')..']' end
  table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
  for _,k in ipairs(keys)do assert(type(k)=='string' or (type(k)=='number' and ns.Number(k)), 'Invalid object key');out[#out+1]=quote(tostring(k))..':'..encode(x[k],depth+1)end
  return '{'..table.concat(out,',')..'}'
 end
 return encode(v,0)
end
function J.Decode(text)
 if type(text)~='string' or #text>16*1024*1024 then return nil,'Payload limit' end
 local ok,result=pcall(function()
  local i,entries=1,0
  local function space()local _,e=text:find('^%s*',i);i=(e or i-1)+1 end
  local function str()
   assert(text:sub(i,i)=='"','Expected string');i=i+1;local out={}
   while i<=#text do
    local c=text:sub(i,i);i=i+1
    if c=='"'then return table.concat(out)end
    if c=='\\'then
     local e=text:sub(i,i);i=i+1;local map={['"']='"',['\\']='\\',['/']='/',b='\b',f='\f',n='\n',r='\r',t='\t'}
     if e=='u'then
      local hex=text:sub(i,i+3);assert(hex:match('^%x%x%x%x$'),'Bad Unicode escape');local n=tonumber(hex,16);i=i+4
      assert(n<0xD800 or n>0xDFFF,'Surrogate escapes unsupported')
      c=n<128 and string.char(n) or n<2048 and string.char(192+math.floor(n/64),128+n%64) or string.char(224+math.floor(n/4096),128+math.floor(n/64)%64,128+n%64)
     else c=assert(map[e],'Invalid escape')end
    else assert(c:byte()>=32,'Control in string')end
    out[#out+1]=c
   end
   error('Unterminated string')
  end
  local value
  value=function(depth)
   assert(depth<=32,'Nesting limit');space();local c=text:sub(i,i)
   if c=='"' then return str() end
   if c=='{' or c=='[' then
    local object=c=='{';local close=object and '}' or ']';local t={};local keys={};i=i+1;space()
    if text:sub(i,i)==close then i=i+1;return t end
    while true do
     local key
     if object then space();key=str();assert(not keys[key],'Duplicate key');keys[key]=true;space();assert(text:sub(i,i)==':','Expected colon');i=i+1 else key=#t+1 end
     entries=entries+1;assert(entries<=100000,'Entry limit');local v=value(depth+1);assert(v~=nil,'Null values unsupported in statistics');t[key]=v;space()
     c=text:sub(i,i);i=i+1;if c==close then return t end;assert(c==',','Expected separator')
    end
   end
   for literal,v in pairs({['true']=true,['false']=false})do if text:sub(i,i+#literal-1)==literal then i=i+#literal;return v end end
   local token=text:sub(i):match('^-?%d+%.?%d*[eE]?[+-]?%d*');assert(token and #token>0,'Invalid token')
   assert(not token:match('^%-?0%d'),'Leading zero');local mantissa,exponent=token:match('^(.-)[eE](.*)$');mantissa=mantissa or token;assert(mantissa:match('^-?%d+$') or mantissa:match('^-?%d+%.%d+$'),'Invalid mantissa');if exponent then assert(exponent:match('^[+-]?%d+$'),'Invalid exponent')end
   local num=tonumber(token);assert(num and num==num and math.abs(num)<math.huge,'Invalid number');i=i+#token;return num
  end
  local v=value(0);space();assert(i>#text,'Trailing input');return v
 end)
 if not ok then return nil,'Invalid or unsupported JSON: '..tostring(result)end
 return result
end
