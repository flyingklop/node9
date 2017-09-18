--
-- mount remote namespace of wmii
--
--[[
include "sys.m";
  sys: Sys;
include "draw.m";
include "keyring.m";
include "security.m";
include "factotum.m";
include "styxconv.m";
include "styxpersist.m";
include "arg.m";
include "sh.m";
--]]


verbose = false
doauth = true
do9 = false
oldstyx = false
persist = false
showstyx = false
quiet = false
flags = 0

alg = "none"
keyfile = nil
spec = nil
addr = nil

usage = "mount [-a|-b] [-coA9] [-C cryptoalg] [-k keyfile] [-q] net!addr|file|{command} mountpoint [spec]"


function split(s,re)
    local res = {}
    local t_insert = table.insert
    re = '[^'..re..']+'
    for k in s:gmatch(re) do t_insert(res,k) end
    return res
end


function fail(status, msg)
  sys.fprint(sys.fildes(2), "mount: %s\n", msg);
  error("fail:" .. status)
end

function nomod(mod)
  fail("load", sys.sprint("can't load %s: %r", mod));
end

function netmkaddr(addr, net, svc)
  if not net then net = "net" end

  local adr = split(addr, "!")

  if #adr <= 1 then
    if not svc then return string.format("%s!%s", net, addr) end
    return string.format("%s!%s!%s", net, addr, svc)
  end

  if not svc or #adr > 2 then return addr end
  return string.format("%s!%s", addr, svc)
end

function connect(dest)
  --if dest ~= nil and dest:sub(1,1) == '{' and dest:sub(#dest) == '}' then
    --if(persist)
      --fail("usage", "cannot persistently mount a command");
    --doauth = false;
    --return popen(ctxt, dest :: nil);
  --end
  local dst = split(dest, "!")
  if #dst == 1 then
    fd = sys.open(dest, sys.ORDWR)
    if fd then
      --if(persist)
        --fail("usage", "cannot persistently mount a file");
      return fd
        end
    if dest:sub(1,1) == '/' then
      fail("open failed", string.format("can't open %s: %s", dest, sys.errstr()))
        end
  end

  local svc = "styx"
  if do9 then svc = "9fs" end

  local ndest = netmkaddr(dest, "net", svc)

  ok, c = sys.dial(ndest, nil)

  if ok < 0 then
        fail("dial failed",  string.format("can't dial %s: %s", ndest, sys.errstr()))
    end

  return c.dfd;
end

function user()
  local fd = sys.open("/dev/user", sys.OREAD)

  if not fd then return "" end

  local buf = buffers.new(sys.NAMEMAX)

  n = sys.read(fd, buf, buf.len)

  if n < 0 then return "" end

    return buf.tostring()
end

function authcvt(fd)
  local err,nfd
  if doauth then
        fail("not implemented","authentication is not currently implemented")
  end
  --if oldstyx then return cvstyx(fd) end
  return fd, nil
end


function nomod(mod)
    fail("load", string.format("can't load %s: %s", mod, sys.errstr()))
end

function init(argv)
    sys = import("sys")
    buffers = import("buffers")

    local fd = connect("tcp!172.17.0.1!5555")

    local ok = sys.mount(fd, nil, "/wmii", flags, spec)

    if ok < 0 and not quiet then
        error("mount failed: " .. ok)
    end
end
