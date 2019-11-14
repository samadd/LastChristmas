pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

house_types = {
  {states = {default = {33}}, width = 2, height = 2},
  {states = {default = {35}}, width = 2, height = 2},
  {states = {default = {8}}, width = 1, height = 3}
}

effect_types = {
  hoho = {states = {default = {20}}, width = 1, height = 1, vy = -1, vx = 0}
}

house_selector = {
  {1,1,2,3}
}

present_colors = {
  function() pal(1,1) pal(2,2) pal(3,3) end,
  function() pal(1,3) pal(2,11) pal(3,8) end,
  function() pal(1,9) pal(2,10) pal(3,14) end
}

function make_santa()
  local s = {}
  s.states = {default = {4}}
  s.state = s.states.default
  s.x = 0
  s.y = 32
  s.max_v = 2
  s.acc = 0.25
  s.inertia = 0.125
  s.v = 0
  s.vy = 0
  s.tick = 1
  s.width = 2
  s.height = 1
  s.throttle = 10
  s.throttle_limit = 10
  s.presents_thrown = 0
  s.presents_delivered = 0
  return s
end

function make_meteor()
  local m = {}
  m.states = {default = {37,37,37,37,38,38,38,38}}
  m.state = m.states.default
  m.x = rnd(32)
  m.y = 0
  m.vy = 0.5 + rnd(2)
  m.vx = 2.5 - m.vy
  m.width = 1
  m.height = 1
  m.tick = 1
  return m
end

function make_present(s)
  local p = {}
  p.x = s.x + 8
  p.y = s.y + 4
  p.v = -2
  p.max_v = 3
  p.acc = 0.1
  p.states = {default = {32}}
  p.state = p.states.default
  p.tick = 1
  p.width = 1
  p.height = 1
  p.colour = present_colors[ceil(rnd(#present_colors))]
  return p
end

function make_effect(source, type)
  local e = {}
  e.x = source.x
  e.y = source.y
  e.vy = type.vy
  e.vx = type.vx
  e.states = type.states
  e.state = e.states.default
  e.width = type.width
  e.height = type.height
  e.tick = 1
  return e
end

function make_house(template)
  local h = {}
  h.x = 128
  h.y = 120 - (template.height * 8)
  h.states = template.states
  h.state = h.states.default
  h.tick = 1
  h.width = template.width
  h.height = template.height
  return h
end

function update_present(p)
  p.v = min(p.v + p.acc, p.max_v)
  p.y = p.y + p.v
  if p.y > 124 then
    del(presents, p)
    return  
  end
  local house_hit = has_hit_chimney(p)
  if house_hit != false then
    del(presents, p)
    santa.presents_delivered += 1
    sfx(0)
    add(effects, make_effect(p, effect_types.hoho))
    house_hit.do_blink = true
  end
end

function update_houses()
  house_state.since_last += 1
  for house in all(house_state.houses) do
    house.x = house.x - house_state.speed
    if house.x < 0 - (house.width * 8) then del(house_state.houses, house) end
  end
  local make_new = rnd(100) > 95
  if make_new and house_state.since_last * house_state.speed > 16 then
    local htype = house_state.selector[ceil(rnd(#house_state.selector))]
    add(house_state.houses, make_house(house_types[htype]))
    house_state.since_last = 0
  end
end

function update_meteors()
  meteor_state.since_last += 1
  for meteor in all(meteor_state.meteors) do
    meteor.x += meteor.vx
    meteor.y += meteor.vy
    if meteor.x > 128 or meteor.y > 120 then del(meteor_state.meteors, meteor) end 
  end
  local make_new = rnd(100) > 95
  if make_new and meteor_state.since_last > meteor_state.rate then
    add(meteor_state.meteors, make_meteor())
    meteor_state.since_last = 0
  end
end

function update_effect(e)
  e.y = e.y + e.vy
  e.x = e.x + e.vx
  if e.y < -8 or e.y > 128 or e.x < -8 or e.y > 128 then del(effects, e) end
end

function update_santa(l, r, u, d, f)
  santa.throttle = max(santa.throttle - 1, 0)
  if santa.v != 0 then
    santa.v = santa.v + (((0 - santa.v) / abs(santa.v)) * santa.inertia)
  end
  if santa.vy != 0 then
    santa.vy = santa.vy + (((0 - santa.vy) / abs(santa.vy)) * santa.inertia)
  end
  if l then
    santa.v = santa.v - santa.acc
    if santa.v < 0 - santa.max_v then santa.v = 0 - santa.max_v end
  end
  if r then
    santa.v = santa.v + santa.acc
    if santa.v > santa.max_v then santa.v = santa.max_v end
  end
  if u then
    santa.vy = santa.vy - santa.acc
    if santa.vy < 0 - santa.max_v then santa.vy = 0 - santa.max_v end
  end
  if d then
    santa.vy = santa.vy + santa.acc
    if santa.vy > santa.max_v then santa.vy = santa.max_v end
  end
  if f and santa.throttle == 0 then
    add(presents, make_present(santa))
    santa.throttle = santa.throttle_limit
    santa.presents_thrown += 1
  end
  santa.x = santa.x + santa.v
  santa.y = santa.y + santa.vy
end

function make_snow_line()
  local q = flr(rnd(4))
  local row = {}
  for i = 1, q do
    row[i] = {rnd(128), 1 - rnd(2)}
  end
  return row
end

function has_hit_chimney(present)
  for house in all(house_state.houses) do
    if present.x > house.x - 4 and present.x < house.x + (8 * house.width) - 4 then
      if present.y > house.y - 8 and present.y < house.y + 10 then
        return house
      end
    end
  end
  return false
end

function update_snow()
  if #snow == 120 then del(snow, snow[1]) end
  local newsnow = make_snow_line()
  add(snow, newsnow)
end

function draw_snow()
  local l = #snow
  for i = l, 1, -1 do
    for flake in all(snow[i]) do
       flake[1] = flake[1] + flake[2]
       pset(flake[1], l - i, 7)
    end
  end
end

function draw_entity(e)
  if e.tick > #e.state then e.tick = 1 end
  if e.colour != nil then e.colour() end
  if e.do_blink == true then flash_white() e.do_blink = false end
  spr(e.state[e.tick], e.x, e.y, e.width, e.height)
  pal()
  e.tick += 1
end

function hud()
  print("thrown: "..tostr(santa.presents_thrown))
  print("delivered: "..tostr(santa.presents_delivered), 64, 0)
end

function flash_white()
  for i = 1,15 do
    pal(i, 7)
  end
end

function _init()
  santa = make_santa()
  snow = {}
  presents = {}
  effects = {}
  meteor_state = {meteors = {}, since_last = 0, rate = 30}
  house_state = {houses = {}, since_last = 0, speed = 1, selector = house_selector[1]}
  _draw = draw_game
  _update = update_game
end

function draw_game()
  cls()
  map(0,0,0,0,16,16)
  camera(0,0)
  draw_entity(santa)
  foreach(presents, draw_entity)
  foreach(house_state.houses, draw_entity)
  foreach(meteor_state.meteors, draw_entity)
  foreach(effects, draw_entity)
  draw_snow()
  hud()
end

function update_game()
  update_santa(btn(0), btn(1), btn(2), btn(3), btn(4))
  update_houses()
  update_meteors()
  foreach(presents, update_present)
  foreach(effects, update_effect)
  update_snow()
end
__gfx__
00000000000000000770000000000000000000007780000000000011110000007766667700000000000000000000000000000000000008800000000000000000
0000000000000000077880070000000000002000081f000000001666666100005555555500000000000000000000000000000000000008099988880000000000
00000000004400000088888800000000000442008ff77000001666666666610005445450000000000000000000800000088000000890889aaaa8888000000000
0000000004400000000888f00000000000444444887770900166666555666610054454500000000000000000008888800880080000899999a7a9aa9000000000
00004444444200000078fdf000000000492444428888800906666551556666600544545000000000000000000889808888898800088aaaaa7aaaaa9000000000
00000444444420000008fff700000000922222228888888916651655665666610555555000000000000000000989999889888900088aaa77aaaa799000000000
009994444444442008888f770000000049999999999999906655555565655666055444500000000000008000090aaa9009a09000089aaa77aaaaa99000000000
099244444444444008888f77770009900555555555555500665556566656566605544450000080000800000089aaaaaaa9aa9980009a97777770a98800000000
092444444444444288888877770099900000000000000000666566666665666605544450000008800000000099aaaa7a7aaa09000999aaa777aaa88000000000
994444444244444288888870000090996060676000000000666666666656666605555550000088890088000099aaaa777aaa0980089999979aa9088000000000
994444442444424288888888800000097770707000000000666566566666666605445450009a998980990000899a97777aa99900089a7797aa77900000000000
092424424244442288888888888000996060676000000000166655666666666105445450008aaaaaaaa98800898aaa7777a9998808888889a979880800000000
09922222222222228888888888880990000000000000000006666566666666600544545008099aaaaaaaa8000999aaa7aaa99900098888798800880000000000
0099999999999999999999999999990060606760000000000166655666666610055555500089aaa77aaaa8000899aaa779aa9900009889708808800000000000
000555555555555555555555555550007770707000000000001666556666610005544450090aaaaaaa9988000989977799988800000000700000000000000000
00000555555555555555555555550000606067600000000000001666666100000554445000898980808a00000089998099989090000000880000000000000000
00300300006660000000000000000001100000000288990008997780000000000554445000000880009900000000000500000000000000050050050000000000
00033000005550077000000000000006600000002002559020025590000000000555555000800808088898800080000000005500000000000500000000000000
01222210005556644660000000000006600000008255665a8855665700000000054454500800809aaaaa8088a9000050050000000008050a0500000000000000
02222220005664444446600000000006600000008856655aa256655a0000000005445450000989999aaaa090a8505555950999000008000a0000980000000000
022222200064444444444600000000066000000095665657a566565700000000064454600880a9a97aaa7a988000000550005599000000000000889000000000
0222222006444444444444600000077777700000965665577656655a0000000006556560080a97aa777a709900000000550995a90000000000008a0000000000
0222222005555555555555500006777777776000a55555a7955555a000000000766666670889907777a7a7a9000a0000000000a9000005555000000000000000
0122221005000555555aaa5000677777777776000a77777000a7aa000000000077777777008977077aa709090000aa055000088905550000050500a000000000
7777777706000555555aaa5006777777777777600000000000000000000000000000000009a9aa7a70aa07aa558000a05000000000005055500555a000000000
77777777016665555557775007777777777777700000000000000000000000000000000089a99a07777a997a5589aaa7987aa500009a00055500005000000000
77777777055555566555555017777776677777710000000000000000000000000000000009990a0a7788099a509a0a00880005aa008500005500000000000000
77777777066555d11d5555506777777117777776000000000000000000000000000000000990000a07088999089aa900500009a9050000055000000000000000
7676767601000511115000507777776116777777000000000000000000000000000000000800900a0080808898aa900000050899000aa0005009980000000000
666666660566651111566650777776111167777700000000000000000000000000000000099000007808808099a990800005055900890005500aa09000000000
6c6c6c6c655555111155555677777611116777770000000000000000000000000000000000899000000000080aa9980000000889058900000000a00000000000
cccccccc777777666677777766666666666666660000000000000000000000000000000000800008000000000a80080000000000050000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000607000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000001617000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100003b5503c5503b5603a560395503755034550305502c55028550235501e5501c5501a5501a5501b5501c5501e5501f5502155023550265502a5503055034550395503b5503e5503f5503f5503e5503d550
