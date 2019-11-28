pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

house_types = {
  {states = {default = {33}, destroyed = {53}}, width = 2, height = 2},
  {states = {default = {35}, destroyed = {55}}, width = 2, height = 2},
  {states = {default = {8}, destroyed = {15}}, width = 1, height = 3},
  {states = {default = {80}, destroyed = {112}}, width = 4, height = 2},
  {states = {default = {84}, destroyed = {100}}, width = 2, height = 1},
  {states = {default = {116}, destroyed = {117}}, width = 1, height = 1},
  {states = {default = {105}, destroyed = {106}}, width = 1, height = 2}
}

effect_types = {
  hoho = {states = {default = {20}}, width = 1, height = 1, vy = -1, vx = 0},
  gold_rings = {states = {default = {31}}, width = 1, height = 1, vy = -1.5, vx = 0},
  sprinkle = {states={default={70,70,71,71,72,72,73,73}}, width = 1, height = 1, vy = 1.5, vx = 0},
  bauble = {states={default={21}}, width = 1, height = 1, vy = 1.5, vx = 0}
}

level_defs = {
  {
    house_selector = {1,1,2,3},
    target = 10,
    multiplier = 10,
    meteor_rate = 30,
    map_offset = 0
  },
  {
    house_selector = {1,1,2,2,3,5,6},
    target = 20,
    multiplier = 20,
    meteor_rate = 30,
    map_offset = 17
  },
  {
    house_selector = {1,1,2,2,3,4,5,5,6,6},
    target = 50,
    multiplier = 30,
    meteor_rate = 15,
    map_offset = 33
  },
  {
    house_selector = {1,1,2,2,3,4,5,5,6,6,7,7},
    target = 100,
    multiplier = 40,
    meteor_rate = 10,
    map_offset = 49
  }
}


present_colors = {
  function() pal(1,1) pal(2,2) pal(3,3) end,
  function() pal(1,3) pal(2,11) pal(3,8) end,
  function() pal(1,9) pal(2,10) pal(3,14) end
}

function make_santa()
  local s = {}
  s.states = {default = {4}, dying = {64,64,64,66,66,66,68,68,68}}
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
  s.health = 5
  s.score = 0
  s.rings = 0
  return s
end

function calc_score()
  local multiplier
  if current_level > #level_defs then
    multiplier = level_defs[#level_defs].multiplier
  else
    multiplier = level_defs[current_level].multiplier
  end
  local present_score = (santa.presents_delivered / santa.presents_thrown) * (santa.presents_delivered * multiplier)
  local ring_score = santa.rings * multiplier
  return ceil(present_score + ring_score)
end

function make_meteor()
  local m = {}
  m.states = {default = {37,37,37,38,38,38,39,39,39}}
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

function make_explosion(source)
  local e = {}
  e.x = source.x
  e.y = source.y
  e.width = 2
  e.height = 2
  e.state = {9,9,9,11,11,11,13,13,13,41,41,41,43,43,43,45,45,45}
  e.tick = 1
  return e
end

function hit_house(house)
  house.height = 1
  house.y = 112
  house.state = house.states.destroyed
end

function hit_santa()
  if santa.presents_delivered >= level_defs[current_level].target then return end
  santa.health -= 1
  santa.do_blink = true
  if santa.health == 0 then
    santa.state = santa.states.dying
  end
end

function kill_santa()
  santa.vy = min(santa.vy + santa.acc, santa.max_v)
  if santa.y > 120 then santa.dead = true end
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
  local meteor_hit = has_hit_meteor(p)
  if meteor_hit != false then
    p.v = 0 - p.v
    add(effects, make_effect(p, effect_types.gold_rings))
    add(effects, make_effect(p, effect_types.sprinkle))
    sfx(2)
    santa.rings += 1
    del(meteor_state.meteors, meteor_hit)
  end
end

function update_house(house)
  house.x = house.x - house_state.speed
  if house.x < 0 - (house.width * 8) then del(house_state.houses, house) end
end

function update_houses()
  local last_house_width = 0
  if #house_state.houses > 0 then last_house_width = house_state.houses[#house_state.houses].width end
  house_state.since_last += 1
  foreach(house_state.houses, update_house)
  local make_new = rnd(100) > 95
  if make_new and house_state.since_last * house_state.speed > (last_house_width * 8) then
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
    local house_hit = has_hit_chimney(meteor)
    if house_hit != false then
      hit_house(house_hit)
      add(explosions, make_explosion(meteor))
      sfx(1)
      del(meteor_state.meteors, meteor)
    end
    if has_hit_santa(meteor) then
      hit_santa()
      del(meteor_state.meteors, meteor)
      add(explosions, make_explosion(meteor))
      sfx(1)
    end
  end
  local make_new = rnd(100) > 90
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

function update_explosion(e)
  e.x -= house_state.speed
  if e.tick > #e.state then
    del(explosions, e)
  end
end

function update_santa(l, r, u, d, f)
  local max_y = 88
  santa.throttle = max(santa.throttle - 1, 0)
  if santa.state == santa.states.dying then
    kill_santa()
    max_y = 122
  else
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
      sfx(3)
    end
  end
  santa.x = santa.x + santa.v
  santa.y = santa.y + santa.vy
  if santa.x <= -15 then santa.x = -14 end
  if santa.x >= 113 then santa.x = 112 end
  if santa.y >= max_y then santa.y = max_y-1 end
  if santa.y <= -2 then santa.y = -1 end
end

function make_snow_line()
  local q = flr(rnd(4))
  local row = {}
  for i = 1, q do
    row[i] = {rnd(128), 1 - rnd(2)}
  end
  return row
end

function has_hit_chimney(thing)
  for house in all(house_state.houses) do
    if house.state != house.states.destroyed then
      if thing.x > house.x - 4 and thing.x < house.x + (8 * house.width) - 4 then
        if thing.y > house.y - 8 and thing.y < house.y + 10 then
          return house
        end
      end
    end
  end
  return false
end

function has_hit_meteor(thing)
  for meteor in all(meteor_state.meteors) do
    if thing.x >= meteor.x - 4 and thing.x <= meteor.x + 4 then
      if thing.y >= meteor.y and thing.y < meteor.y + 8 then
        return meteor
      end
    end
  end
  return false
end

function has_hit_santa(meteor)
  if santa.x >= meteor.x - 8 and santa.x <= meteor.x + 8 then
      if santa.y >= meteor.y - 4 and santa.y < meteor.y + 8 then
        return true
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
  pprint("score: "..tostr(santa.score), 1,1)
  pprint("gifts: "..tostr(santa.presents_delivered).."/"..tostr(santa.presents_thrown), 71, 0)
  for h = 1, santa.health do
    spr(47, 32 + (h * 8), 8)
  end
  spr(31, 0, 9)
  pprint(santa.rings, 10, 12)
end

function flash_white()
  for i = 1,15 do
    pal(i, 7)
  end
end

function _init()
  _draw = draw_game
  _update = update_game
  button_thottle = 30
  high_score = 0
  house_state = {speed=1}
  title_screen()
end

function init_game()
  santa = make_santa()
  snow = {}
  current_level = 1
  init_level()
  music(0)
end

function change_level()
  current_level += 1
  if current_level > #level_defs then
    end_game(true)
    return  
  end
  santa.score = santa.score + calc_score()
  santa.presents_delivered = 0
  santa.presents_thrown = 0
  santa.rings = 0
  init_level()
end

function init_level()
  presents = {}
  effects = {}
  explosions = {}
  meteor_state = {meteors = {}, since_last = 0, rate = level_defs[current_level].meteor_rate}
  house_state = {houses = {}, since_last = 0, speed = 1, selector = level_defs[current_level].house_selector}
  target_deliveries = level_defs[current_level].target
  start_countdown = 45
  button_thottle = -1
  map_offset = level_defs[current_level].map_offset
end

function draw_game()
  cls()
  map(map_offset,0,0,0,16,16)
  camera(0,0)
  draw_entity(santa)
  foreach(presents, draw_entity)
  foreach(house_state.houses, draw_entity)
  foreach(meteor_state.meteors, draw_entity)
  foreach(explosions, draw_entity)
  foreach(effects, draw_entity)
  draw_snow()
  hud()
  if santa.dead then pprint("uh-oh!", 32, 32) end
  if santa.presents_delivered >= target_deliveries then pprint("level complete! merry christmas!", 4, 48) end
  if start_countdown > 0 then pprint("level "..tostr(current_level).." - deliver "..tostr(level_defs[current_level].target).." presents!", 0, 64 ) end
end

function update_game()
  start_countdown = max(0, start_countdown -1)
  if santa.dead != true and santa.presents_delivered <= target_deliveries then
    update_santa(btn(0), btn(1), btn(2), btn(3), btn(4))
  end
  if santa.dead then
    if btn(4) then end_game(false) end
  end
  if santa.presents_delivered >= target_deliveries then
    if button_thottle == -1 then button_thottle = 45 end
    button_thottle = max(0, button_thottle - 1)
    if btn(4) and button_thottle == 0 then change_level() end
  end
  update_houses()
  update_meteors()
  foreach(presents, update_present)
  foreach(effects, update_effect)
  foreach(explosions, update_explosion)
  update_snow()
end

function title_screen()
  local title_x = 0
  local title_effects = {}
  local trees = {}
  local tree_spacer = 0
  music(8)
  repeat
    flip()
    if #title_effects < 40 then
      if rnd(10) >=5 then
        if rnd(10) >=5 then
          add(title_effects, make_effect({x = rnd(120), y = 0}, effect_types.bauble))
        else
          add(title_effects, make_effect({x = rnd(120), y = 0}, effect_types.sprinkle))
        end
      else
        add(title_effects, make_effect({x = rnd(120), y = 128}, effect_types.gold_rings))
      end
    else
      del(title_effects, title_effects[1])
    end
    if tree_spacer == 0 then
      add(trees, make_house(house_types[7]))
      tree_spacer = 30
    end
    if trees[1].x < -8 then del(trees, trees[1]) end
    tree_spacer -= 1
    title_x = min(128, title_x + 0.5)
    if (title_x == 128) then title_x = 0 end
    button_thottle = max(button_thottle -1, 0)
    cls()
    foreach(title_effects, update_effect)
    foreach(title_effects, draw_entity)
    foreach(trees, update_house)
    foreach(trees, draw_entity)
    spr(0, title_x - 32, 16, 4, 2)
    spr(0, 128 - title_x, 88, 4, 2, true)
    pprint("last christmas", 32, 48, 7, 3)
    pprint("high score: "..tostr(high_score), 32, 64, 7, 8)
    pprint("press fire to start", 24, 72, 7, 3)
  until btn(4) and button_thottle == 0
  init_game()
end

function end_game(complete)
  if complete then
    pprint("you did it!", 32, 48, 7, 8)
    pprint("you saved the last christmas", 8, 56, 7, 3)
  else
    pprint("last christmas...", 32, 48)
    pprint("and you blew it, santa!", 8, 56)
  end
  for i = 0,120 do
    flip()
  end
  santa.score = santa.score + calc_score()
  high_score = max(high_score, santa.score)
  --_update = update_title_screen
  --_draw = draw_title_screen
  button_thottle = 30
  title_screen()
end

function pprint(str, x, y, col, back)
  back = back or 0
  col = col or 7
  for ix = -1, 1 do
    for iy = -1, 1 do
      print(str, x + ix, y + iy, back)
    end
  end
  print(str, x, y, col)
end

__gfx__
00000000000000000770000000000000000000007780000000000011110000007766667700000000000000000000000000000000000008800000000000000000
0000000000000000077880070000000000002000081f000000001666666100005555555500000000000000000000000000000000000008099988880005000000
00000000004400000088888800000000000442008ff77000001666666666610005445450000000000000000000800000088000000890889aaaa8888005000050
0000000004400000000888f00000000000444444887770900166666555666610054454500000000000000000008888800880080000899999a7a9aa9005405450
00004444444200000078fdf000000000492444428888800906666551556666600544545000000000000000000889808888898800088aaaaa7aaaaa9006445460
00000444444420000008fff700000000922222228888888916651655665666610555555000000000000000000989999889888900088aaa77aaaa799006556560
009994444444442008888f770000000049999999999999906655555565655666055444500000000000008000090aaa9009a09000089aaa77aaaaa99076666667
099244444444444008888f77770009900555555555555500665556566656566605544450000080000800000089aaaaaaa9aa9980009a97777770a98877777777
0924444444444442888888777700999000000000000aa000666566666665666605544450000008800000000099aaaa7a7aaa09000999aaa777aaa8800009a000
994444444244444288888870000090996060676000133100666666666656666605555550000088890088000099aaaa777aaa0980089999979aa9088004900940
994444442444424288888888800000097770707013d88431666566566666666605445450009a998980990000899a97777aa99900089a7797aa77900009000090
092424424244442288888888888000996060676058889745166655666666666105445450008aaaaaaaa98800898aaa7777a9998808888889a9798808a0000009
09922222222222228888888888880990000000003888898306666566666666600544545008099aaaaaaaa8000999aaa7aaa9990009888879880088009000000a
0099999999999999999999999999990060606760588888850166655666666610055555500089aaa77aaaa8000899aaa779aa9900009889708808800009000090
000555555555555555555555555550007770707013d88d31001666556666610005544450090aaaaaaa9988000989977799988800000000700000000004900940
00000555555555555555555555550000606067600013310000001666666100000554445000898980808a000000899980999890900000008800000000000a9000
0030030000666000000000000000000110000000022229000929892008a980000554445000000880009900000000000500000000000000050050050007000700
00033000005550077000000000000006600000002889a5902288a99089aaa980055555500080080808889880008000000000550000000000050000007e707e70
0122221000555664466000000000000660000000299a551a099a5519aaaa5590054454500800809aaaaa8088a9000050050000000008050a05000000e8e7e8e0
022222200056644444466000000000066000000028a5555a98a5555a99a5555905445450000989999aaaa090a8505555950999000008000a00009800888e8880
022222200064444444444600000000066000000095a5555725a555579aa55557064454600880a9a97aaa7a988000000550005599000000000000889028888820
022222200644444444444460000007777770000091555567995555678955556706556560080a97aa777a709900000000550995a90000000000008a0002888200
0222222005555555555555500006777777776000a7556677895566770955667a766666670889907777a7a7a9000a0000000000a9000005555000000000282000
0122221005111555555aaa5000677777777776000a76777000767770087677a077777777008977077aa709090000aa055000088905550000050500a000020000
7777777706111555555aaa5006777777777777600000000000000000000000000000000009a9aa7a70aa07aa558000a05000000000005055500555a000000000
77777777016665555557775007777777777777700000000000000000010000000000000089a99a07777a997a5589aaa7987aa500009a00055500005000000000
77777777055555566555555017777776677777710505000000005500060070006707600009990a0a7788099a509a0a00880005aa008500005500000000000000
77777777066555d11d5555506777777117777776006550000055550007007700077700000990000a07088999089aa900500009a9050000055000000000000000
7676767601111511115111507777776116777777010005100150005017007760067700010800900a0080808898aa900000050899000aa0005009980000000000
666666660566651111566650777776111167777705666510005666506767761001676006099000007808808099a990800005055900890005500aa09000000000
6c6c6c6c655555111155555677777611116777776555551011555556777776111167716700899000000000080aa9980000000889058900000000a00000000000
cccccccc777777666677777766666666666666667777776666777777666666666666666600800008000000000a80080000000000050000000000000000000000
000000007780050000000000778005050000000077800005000000e0e20002e7e000000002000200000000000000000000000000000000000000000000000000
00000000081f000500000000081f000000000000081f005020002e7e0000000e2000200000000e00000000000000000000000000000000000000000000000000
000008008ff47050000000008ff44005008008808ff64500000000e0000200020000e0000002e7e2000000000000000000000000000000000000000000000000
00000a00887770900000080088777090089089808877759000200020000e0000002e7e2000000e00000000000000000000000000000000000000000000000000
8008a7808888800908080a088888800909788a988888800900e0000002e7e2000000e00002000200000000000000000000000000000000000000000000000000
9a7a77a2888888890a8a87828888888989779982888888892e7e2000000e0000200020000e000000000000000000000000000000000000000000000000000000
497977999999999049a7a7a999999990997777a99999999000e0000000020002e0000000e7e20002000000000000000000000000000000000000000000000000
055555555555550005555555555555009555555555555500002000200000000e7e20002e0e000000000000000000000000000000000000000000000000000000
07070700000000000000000000707070000222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01050100000070000007000000105010022222222222210000000000000000000000000000000000000000000000000000000000000000000000000000000000
015551000007570000757000001555102ee111ee11eee11000000000000000000000000000000000000000000000000000000000000000000000000000000000
015a51000075557777555700001515102ee212ee11eee21100000000000000001111111100000000000000000000000000000000000000000000000000000000
015a51000755555555555570001565102eeeeeeeeeeeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000
01555100055555555555555000155510233333333333333300000000000000000000000000000000000000000000000000000000000000000000000000000000
0155517775551555555a5557771555102e55eeeeeeee55e200000000000000000000000000000000000000000000000000000000000000000000000000000000
0151515555511555555aa5555515a510005500000000550000000000000000001111111100000000000000000000000000000000000000000000000000000000
0156515115566555555aa5511515a51000000000000000000000000011111111222222220000a000000500000000000000000000000000000000000000000000
01555156655555555555555665155510000000000000000000000000000000001111111100097900000050000000000000000000000000000000000000000000
01555155555555555555555555155510000000000000000000000000000000001111111100a777a0000040000000000000000000000000000000000000000000
01515155555555566555555555151510000000000000000000000000111111112222222200097900000040000000000000000000000000000000000000000000
0156515115555561165555511515651000000000000000001111111122222222888888880003a000000540000000000000000000000000000000000000000000
01555156655555111155555665155510233330333030033300000000111111112222222200333300000440000000000000000000000000000000000000000000
015551555555551111555555551555102e55eeeeeeee55e20000000011111111222222220a03a0a0005445000000000000000000000000000000000000000000
77777777777777666677777777777777005500000000550000000000111111112222222200333300567667650000000000000000000000000000000000000000
00000000000000000000000000000000040000000000000000000000111111112222222203a3a330000000000000000000000000000000000000000000000000
00000000000050000000000600050000040000000000000011111111222222228888888880033008000000000000000000000000000000000000000000000000
00000050505050000000055550055000044444400000000000000000111111112222222200333300000000000000000000000000000000000000000000000000
01505050555550000000055555150500041144400000000000000000111111112222222203a33a30000000000000000000000000000000000000000000000000
01565150055555000000055000156500041144400000000011111111222222228888888833333333000000000000000000000000000000000000000000000000
015551566555550000555556651555000444454000404000000000001111111122222222e004400e000000000000000000000000000000000000000000000000
01555155555555000055555555155510044445400444404011111111222222228888888800044000000000000000000000000000000000000000000000000000
77777777777777666677777777777777777777777777777711111111222222228888888856777765000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000607000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000001617000000000000000000000607000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000001617000000000000000000000006070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000016170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000161700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000058585858585858585858585858585858000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000666666666666666666666666666666666767676767676767676767676767676768686868686868686868686868686868000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000767676767676767676767676767676767777777777777777777777777777777778787878787878787878787878787878000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100003b5503c5503b5603a560395503755034550305502c55028550235501e5501c5501a5501a5501b5501c5501e5501f5502155023550265502a5503055034550395503b5503e5503f5503f5503e5503d550
00030000306502d6501d650106501c6501c6501d6501d6501d6501d6501d6501e6501f650126501465016650186501b6501e65025650106500a65005650016500165001650016500163001030046100361003600
00070000395503e550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000011500215005150091500b150000002600026000000002600027000260000000000000260002a0002900026000220002200022000260002100026000260002a000270002600027000260002700000000
0110000018751000001975218751000000000000000000001875200000197521875200000000000000000000187520000019752187520000000000000000000018752000001b7521875200000000000000000000
011000000075200752007520075200752007520075200752007520075200752007520075200752007520075200752007520075200752007520075200752007520375203752037520375203752037520375203752
011000003075230752307523175200000307520000000000307523075230752317520000030752000000000030752307523075231752000003075200000000003175231752317523075200000317520000000000
011000001875200000197521875200000000000000030752307523075231752000003075200000000000000018752000001975218752000000000000000317523375233752337520000031752000000000000000
011000002443200000244320000024432000000000000000244320000024432000002443200000000000000024432000002443200000244320000024432244320000000000256320000025632000000000000000
011000001c732000001c732000001c7320000000000000001c732000001c732000001c7320000000000000001c7321f732187321c7321a732000001c732000001c732000001c732000001c732000000000000000
011000001d732000001d732000001d732000001d7321d7321d732000001c732000001c732000001c7321c7321c732000001a732000001a732000001c732000001a732000001f7321f7321f7321f7321f7321f732
011000000273202732027320273202732027320273202732027320273202732027320273202732027320273203732037320373203732037320373203732037320273202732027320273202732027320273202732
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 04054040
00 04054040
00 06054040
00 06054040
00 07054040
00 07054040
00 07054040
02 08054040
01 090b4040
02 0a0b4040
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000

