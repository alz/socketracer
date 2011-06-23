# Socket Racer
# This is an (unfinished) proof of concept demonstrating the SocketStream framework

window.sr = 
  user: null
  infocus: true
  canvas: false
  cars: {}
  mycar: null
  lkd: 0
  lku: 0
  kpt: null
  running: false
  debugmode: false
  eps: 0.000001
  chatmode: false
  msgmax: 100000
  mrecv : 0
  cartiles: {}
  hbsnd: null
  hornsnd: null
  bestlap: 0
  currentlap: 0
  startx: 0
  starty: 0
  collisions: true
  
# This method is called automatically when the websocket connection is established. Do not rename/delete
exports.init = ->
  if SS.client.browser.isSupported()
    loadSession()
  else
    SS.client.browser.showIncompatibleMessage()

loadSession = ->
  SS.server.app.init (user) ->
    displaySignInForm()

touchEvent = (e, type, val) ->
  sr.mycar.set(type, val)
  e.preventDefault()
  broadcastCarData(sr.mycar)
  
bindEvents = ->
  $('#reset').click (e) ->
    if sr.mycar 
      sr.mycar.xpos = sr.startx
      sr.mycar.ypos = sr.starty
      broadcastCarData(sr.mycar, true)
      return true
  $('#carcoll').click (e) ->
    if (sr.collisions)
      $('#carcoll').html('Enable collisions')
      sr.collisions = false
    else
      $('#carcoll').html('Disable collisions')
      sr.collisions = true
    return true
    
  $('#controls').click (e) ->
    $('#controlsbutton').toggle()
    $('#controlsdetails').toggle()
    return false
  $('#changecol').click (e) ->
      col = sr.mycar.getColour() + 1;
      if (col > 7)
        col = 0
      sr.mycar.setColour(col)
      broadcastCarData(sr.mycar, true)
      e.preventDefault()
      return false
  $('#debug').click (e) ->
    sr.debugmode = !sr.debugmode
    
    if sr.debugmode
      $('#cardebug').show()
      $('#debug').html("Hide debug")
    else
      $('#cardebug').hide()
      $('#debug').html("Show debug")
      
    e.preventDefault()
    return false
    
  document.onorientationchange = (e) ->
    window.scrollTo(0, 1)
    e.preventDefault()
   
  # iOS Device Motion detection (disabled currently)  
  #if navigator.userAgent.match(/iPhone/i) or navigator.userAgent.match(/iPod/i) or navigator.userAgent.match(/iPad/i)
  #    window.ondevicemotion = (e) ->
  #      sr.mycar.set("st_speed", e.accelerationIncludingGravity.x)
  #      arate = e.accelerationIncludingGravity.y
  #      if arate > 0
  #        sr.mycar.set("decel", false)
  #        sr.mycar.set("accel", true)
  #      else if arate < 0
  #        sr.mycar.set("accel", false)
  #        sr.mycar.set("decel", true)
  #        
  #      sr.mycar.set("accel_rate", arate)
  #      e.preventDefault()

  document.getElementById('control-left').ontouchstart = (e) -> touchEvent(e, "tl", true)
  document.getElementById('control-left').ontouchend = (e) -> touchEvent(e, "tl", false)
  document.getElementById('control-right').ontouchstart = (e) -> touchEvent(e, "tr", true)
  document.getElementById('control-right').ontouchend = (e) -> touchEvent(e, "tr", false)
    
  document.getElementById('control-up').ontouchstart = (e) -> touchEvent(e, "accel", true)
  document.getElementById('control-up').ontouchend = (e) -> touchEvent(e, "accel", false)
  document.getElementById('control-down').ontouchstart = (e) -> touchEvent(e, "decel", true)
  document.getElementById('control-down').ontouchend = (e) -> touchEvent(e, "decel", false)
  
  $(document).keydown (e) ->
    opt = ""
    if sr.chatmode is true and e.keyCode != 13
      return true
      
    if e.keyCode is 13 # Enter
      if sr.chatmode is true
        $('#chatentry').hide()
        msg = $('#chatentry').val()
        if msg.length > 0
          send = {name: sr.mycar.name, msg: $('#chatentry').val()}
          $('#chatentry').val('')
          SS.server.app.chatMsg(send, true) 
        sr.chatmode = false
      else
        $('#chatentry').show().focus()
        sr.chatmode = true
        sr.mycar.set('accel', false)
        sr.mycar.set('decel', false)
        sr.mycar.set('tr', false)
        sr.mycar.set('tl', false)
        sr.mycar.set('hbrake', false)
                              
      e.preventDefault()
      return true
    else if e.keyCode is 38 # Up
      opt = "accel"
    else if e.keyCode is 40 # Down
      opt = "decel"
    else if e.keyCode is 37 # Left
      opt = "tl"
    else if e.keyCode is 39 # Right
      opt = "tr"
    else if e.keyCode is 72 # h
      hornsnd = $('audio#horn')
      if hornsnd[0] and sr.hornsnd is null
        hornsnd.currentTime = 0
        hornsnd[0].play()
        sr.hornsnd = hornsnd
    else if e.keyCode is 32 # Space
      opt = "hbrake"
      hbsnd = $('audio#hbaudio')
      if hbsnd[0] and sr.hbsnd is null
        hbsnd.currentTime = 0
        hbsnd[0].play()
        sr.hbsnd = hbsnd
    else
      return true

    if opt.length > 0
      sr.mycar.enable(opt)
      e.preventDefault()
      
    # Only broadcast if the key hasn't been repeated
    if sr.mycar != false and sr.lkd != e.keyCode and sr.kpt is false
        broadcastCarData(sr.mycar)
        
    sr.lkd = e.keyCode
    sr.kpt = true
    return false
  $(document).keyup (e) ->
    
    if sr.chatmode is true
      return true
      
    opt = ""
    if e.keyCode is 38 # Up
      opt = "accel"
    else if e.keyCode is 40 # Down
      opt = "decel"
    else if e.keyCode is 37 # Left
      opt = "tl"
    else if e.keyCode is 39 # Rght
      opt = "tr"
    else if e.keyCode is 72 # h
      if sr.hornsnd
        sr.hornsnd[0].pause()
        sr.hornsnd = null
    else if e.keyCode is 32 # Space
      opt = "hbrake"
      if sr.hbsnd
        sr.hbsnd[0].pause()
        sr.hbsnd = null
    else
      return false
      
    if opt.length > 0
      sr.mycar.disable(opt)
      e.preventDefault()
    
    # Only broadcast if the key hasn't been repeated
    if sr.mycar != false and sr.lku != e.keyCode and sr.kpt is true
      broadcastCarData(sr.mycar)
      
    sr.lku = e.keyCode
    sr.kpt = false
    return false
            
signUserIn = (data) ->
  sr.infocus = true
  $('#main').show()
  loadImages()
  drawCanvas()
  bindEvents()
  runGame()

initCar = (car, local) ->
  t = $('#' + car.id)
  if t
    for tc in sr.cars
      if tc.id = car.id
        return tc
  
  if sr.mycar and sr.mycar.id is car.id
    return sr.mycar    
  
  if $('#' + car.id)
    # Destroy existing element
    $('#' + car.id).remove()
  
  elem = document.createElement('div')
  ielem = document.createElement('div')
  car_elem = $(elem).addClass("car")
  img_elem = $(ielem).addClass("img")
  car_elem.attr({'id': car.id})
  img_elem.html('<p>' + car.name.substring(0,4).toLowerCase() + '</p>')
  car_elem.append(img_elem)

  radid = '_rad-' + car.id
  if $('#' + radid)
    $('#' + radid).remove()
    
  rad = document.createElement('div')
  radcar = $(rad).addClass("car")
  radcar.attr({'id': radid})
  
  if car.name is sr.user
    radcar.addClass("me")
    
  pcl = (car.xpos / sr.viewportw) * 100
  pct = (car.ypos / sr.viewporth) * 100
  radcar.css({'left': pcl + '%', 'top': pct + '%'})
  $('#radar').append(radcar)
  
  sr.viewport.append(car_elem)
  newcar = new Car(car.colour, car.name, local, car_elem, img_elem)
  $.each(car, (k, v) ->
    newcar[k] = v
  )
  return newcar
  
initMyCar = (car) ->
  sr.mycar = initCar(car, true)
  
loadImages = ->
  sr.viewportw = 5120
  sr.viewporth = 5120
  sr.viewportx = 0
  sr.viewporty = 0
  tiles = new Image
  tiles.src = SS.config.map.sprite
  sr.tilesprite = $(tiles)
  
  img = new Image
  img.src = '/images/minis.png'
  sr.carsprite = $(img)
  sr.cars = {}
    
runGame = () ->
  sr.running = true
  every 33, () -> #33
    redraw()
  every 150, () -> #200
    broadcastCarData(sr.mycar)
    
drawCanvas = ->
  #sr.canvas = $('#canvas')[0]
  sr.canvas = $('#canvas')
  canvas = sr.canvas
  sr.viewport = canvas.find('#viewport')
  sr.tiles = canvas.find('#tiles')
  
  canvas.width window.innerWidth
  canvas.height window.innerHeight - 96
  #canvas.css({'width': 1200, 'height': 800})
  canvas.css({'width': canvas.width(), 'height': canvas.height()})
  
  #ctx = canvas.getContext('2d');
  img = new Image
  img.src = '/images/minis.png'
  sr.carimg = img
  #sr.mycar = new Car(0, sr.user.u, true)
  drawTiles(canvas)
  if sr.debugmode
    $('#cardebug').show()
  
  if navigator.userAgent.match(/iPhone/i) or navigator.userAgent.match(/iPod/i) or navigator.userAgent.match(/iPad/i)
    $('#buttons-left').find(".control").css({display: 'inline-block'})
    $('#buttons-right').find("div").show()
    window.scrollTo(0, 1)
  
  return true
       
redraw = ->
  canvas = sr.canvas

  sr.cartiles = {}
  if sr.mycar is null
    # Can't do anything here
    return true
    
  # Move viewport?
  cx = sr.mycar.xpos
  cy = sr.mycar.ypos
  pos = canvas.position()
  cwidth = sr.canvas.width()
  cheight = sr.canvas.height()

  nx = 0
  ny = 0
  if cx > (cwidth / 2)
   nx = Math.round(cx - (cwidth/2))
   if nx + cwidth > sr.viewportw
     nx = Math.round(sr.viewportw - cwidth)
  if cy > (cheight / 2)
   ny = Math.round(cy - (cheight/2))
   if ny + cheight > sr.viewporth
     ny = Math.round(sr.viewporth - cheight)
  
  if nx != sr.viewportx or ny != sr.viewporty
   sr.viewport.css({"left": -nx, "top": -ny})
  
  sr.viewportx = nx
  sr.viewporty = ny

  # Draw cars
  $.each(sr.cars, (k, v) ->
    sr.cars[k].draw()
  )

  # Draw my car
  sr.mycar.draw()
  checkMyCollisions()
  
  if sr.debugmode
    sr.mycar.updateDebug()

  if sr.currentlap != 0
    
    time = new Date().getTime()
    diff = Number(time - sr.currentlap)
    mins = Math.floor((diff / 1000) % 3600 / 60)
    secs = Math.floor(diff / 1000 % 60)
    ms = Math.round((diff % 1000) / 10)
    if mins < 10
      mins = "0" + mins
    if secs < 10
      secs = "0" + secs
    if ms < 10
      ms = "0" + ms
    current = mins + ":" + secs + ":" + ms
  else
    current = "00:00:00"
    
  if sr.bestlap !=0 
    mins = Math.floor((sr.bestlap / 1000) % 3600 / 60)
    secs = Math.floor(sr.bestlap / 1000 % 60)
    ms = Math.round((sr.bestlap % 1000) / 10)
    if mins < 10
      mins = "0" + mins
    if secs < 10
      secs = "0" + secs
    if ms < 10
      ms = "0" + ms
    best = mins + ":" + secs + ":" + ms
  else
    best = "00:00:00"
    
  $('#clap').html('Current: ' + current)
  $('#blap').html('Best lap: ' + best)
  
drawTiles = () ->
  tmap = new TileMap
  
  tmap.tw = SS.config.map.tile_width
  tmap.th = SS.config.map.tile_height
  
  py = 0
  ry = 0
  for row in SS.config.map.tiles
    px = 0
    rx = 0
    for tile in row
      el = document.createElement('span')
      offset = '0px -' + (tile[0] * tmap.th) + 'px'
      newdiv = $(el).css({'left': px, 'top': py, 'background-image': 'url(' + SS.config.map.sprite + '?' + Number(new Date) + ')', 'background-position': offset}).addClass('tile')
      
      tmap.addTile(rx, ry, tile)
      if rx is 9
        newdiv.addClass('tileend')
        
      rx++
      sr.tiles.append(newdiv)
      px += tmap.tw
      
    py += tmap.th
    ry++
    
  sr.tilemap = tmap
  
drawTilesOld = () ->
  tw = 512
  th = 512
  nx = sr.viewportw / tw
  ny = sr.viewporty / th

  # Draw div element
  col1 = '#efe'
  col2 = '#eef'
  col = false
  for ry in [0..10]
    for rx in [0..10]
      if col
        fcol = col1
        col = false
      else
        fcol = col2
        col = true
      px = rx*tw
      py = ry*th
      
      el = document.createElement('span')
      newdiv = $(el).css({'left': px, 'top': py, 'background-color': fcol}).addClass('tile')
      
      if rx is 100
        newdiv.addClass('tileend')
        
      sr.tiles.append(newdiv)
      
checkMyCollisions = ->
  tx = sr.mycar.tx
  ty = sr.mycar.ty
  
  sr.mycar.checkTileCollision()
  
  if sr.collisions
    if sr.cartiles[tx]
      if sr.cartiles[tx][ty]
        for car in sr.cartiles[tx][ty]
          sr.mycar.checkCarCollision(sr.cars[car])
        
 
displaySignInForm = ->
  $('#signIn').show().submit => 
    sr.user = $('#signIn').find('input[type="text"]').val()
    SS.server.app.signIn $('#signIn').find('input[type="text"]').val(), (response) ->
      $('#signInError').remove()
      if response.error is true
        $('#signIn').find('input[type="text"]').val('')
        $('#signIn').append("<p id='signInError'>" + response.error_msg + "</p>")

      else
        $('#signIn').fadeOut 230
        signUserIn response

translateStyles = (x, y) ->
  string = "translate(#{x}px, #{y}px)"
  return cssTransform(string)
  
rotateStyles = (rot) ->
  string = "rotate(#{rot}deg)"
  return cssTransform(string)
  
transformOrigin = (x, y) ->
  string = "#{x}% #{y}%"
  return {"-webkit-transform-origin": string, "-moz-transform-origin": string, "-o-transform-origin": string, "-ms-transform-origin": string, "transform-origin": string}
          
cssTransform = (string) ->
  return {"-webkit-transform": string, "-moz-transform": string, "-o-transform": string, "-ms-transform": string, "transform": string}
  
broadcastCarData = (car, force = false) ->
  return false if car is null
  transmit = ['id', 'reverse', 'hbrake', 'brakes', 
              'colour', 'ypos', 'xpos', 'speed', 'st_speed', 
              'accel', 'decel', 'angle', 'tr', 'tl', 'name', 'spritey', 
              'accel_rate', 'velX', 'velY', 'velAng', 'speedDecay', 'turnSpeed']

  out = {}
  for key, value of car
    out[key] = value if transmit.include(key)
  SS.server.app.updateCar(out) if car.velX != 0 or car.velY != 0 or force

class TileMap
  tw: 0
  th: 0
  # Tile types:
  # Top, Right, Bottom, Left
  # True indicates wall position
  "0": [true, true, true, true]
  "1": [true, true, true, true]
  "2": [true, false, false, true]
  "3": [true, true, false, false]
  "4": [false, true, false, true]
  "5": [true, false, true, false]
  "6": [false, true, true, false]
  "7": [false, false, true, true]
  "8": [true, false, true, false]
  "9": [false, true, false, true]
  "10": [true, true, false, false]
  "11": [true, false, false, true]
  "12": [false, false, true, true]
  "13": [false, true, true, false]
  
  map: {}
  
  addTile: (x, y, tile) ->
    if !@map[x]
      @map[x] = {}
    
    @map[x][y] = tile 

  getTile: (x, y) ->
    if !@map[x]
      return null
    if !@map[x][y]
      return null
    return @map[x][y]
  
  getTileLimits: (x, y) ->
    # Calculate pixel limits for tile
    tile = @getTile(x, y)
    if tile is null
      return null
    
    tlimit = @[tile[0]]
    
    minx = x * @tw
    maxx = minx + @tw
    
    miny = y * @th
    maxy = miny + @th
    
    output = []
    
    if tlimit[0]
      output[0] = miny
    else
      output[0] = null
    
    if tlimit[1]
      output[1] = maxx
    else
      output[1] = null
      
    if tlimit[2]
      output[2] = maxy
    else
      output[2] = null
    
    if tlimit[3]
      output[3] = minx
    else
      output[3] = null
    
    return output
    
class Point
  x: null
  y: null
  constructor: (x, y) ->
    @x = x
    @y = y

class Car
  element: null
  imgelement: null
  local: false
  width: 70
  height: 128
  reverse: false
  hbrake: false
  brakes: false
  colour: 0
  ypos: 100
  xpos: 100
  speed: 0
  st_speed: 0
  maxspeed: 7
  maxstspeed: 3
  accel: false
  decel: false
  accel_rate: 0.4
  s_accel_rate: 0.5
  st_drag: 0.6
  velX: 0
  velY: 0
  drag: 0.7
  angle: 0
  velAng: 0.0
  dragAng: 0.5
  speed: 0
  speedDecay: 0.9
  turnSpeed: 3
  
  tx: 0
  ty: 0
  tile: 0
  
  tr: false
  tl: false
  name: ''
  spritey: 0
  id: null
  cbox: null
  ctimeout: null
  
  colliding_car: false
  colliding_tile: false
  completed_tiles: 0
  last_tile: 1
  current_tile: 1
  
  constructor: (colour, name, local, element, img) ->
    @setColour(colour)
    @name = name
    @local = local
    @spritey = Math.round(@colour * 128.375)
    @element = element
    @imgelement = img
  setColour: (col) -> 
    @colour = col
    @spritey = Math.round(@colour * 128.375)
  getColour: () -> return @colour
  toggle: (prop) -> @[prop] = !@[prop]
  enable: (prop) -> @[prop] = true
  disable: (prop) -> @[prop] = false
  set: (k, v) -> @[k] = v
  
  # This will be used to get corners of car (not there yet)
  getPoints: () ->
    pos = @imgelement.position()
    p1 = new Point(pos.left, pos.top)
    p2 = new Point(pos.left, pos.top)
    return [p1, p2]
    
  getSpriteX: () ->
    if @brakes is true
      return -70
    if @reverse is true
      return -140
    else 
      return 0
  getSpriteY: () ->
    return @spritey
  moveCar: () ->
    
    # Drag
    if !@accel and !@decel
      @speed *= @speedDecay
          
    if @speed >= -0.1 and @speed <= 0.1
      @speed = 0
    
    if @st_speed >= -0.1 and @st_speed <= 0.1
      @st_speed = 0
      
    # Steering drag
    if !@tl and !@tr
      @st_speed *= @st_drag
      
    # Accelerate
    if @accel is true
      if @speed < 0
        @speed += @accel_rate * 2
      if @speed < @maxspeed
        if @local
          @speed += @accel_rate
        else
          @speed += @accel_rate / 2
          
    # Brake
    if @decel is true
      if @speed > 0
        @speed *= @drag
      if @speed > -(@maxspeed/2)
        @speed -= @accel_rate
          
    # Steering
    if @tr is true and @speed != 0
      if @st_speed <= 0
        @st_speed = 0
      if @st_speed < @maxstspeed
        @st_speed += @s_accel_rate
    if @tl is true and @speed != 0
      if @st_speed > 0
        @st_speed = 0
      if @st_speed > (0 - @maxstspeed)
        @st_speed -= @s_accel_rate
        
    # Handbrake
    if @hbrake is true
      if @speed > 0
        @speed -= @accel_rate * 2
        if @speed < 0
          @speed = 0
      if @speed < 0
        @speed += @accel_rate * 3
        if @speed > 0
          @speed = 0
          
    # Check brake lights
    if @decel and @speed > 0
      @enable("brakes")
    else
      @disable("brakes")
    
    # Check handbrake
    if @hbrake
      @enable("brakes")
    
    # Check reverse lights
    if @speed < 0 
      @enable("reverse")
    else
      @disable("reverse")
      
    if @speed > @maxspeed
      @speed = @maxspeed
      
    # Update speed and positions
    @speed = Math.round(@speed * 100) / 100
    @st_speed = Math.round(@st_speed * 100) / 100
    @xpos += @velX
    @ypos += @velY
    @angle += @velAng
    
    if @hbrake
      @velX *= 0.8
      @velY *= 0.8
      @velAng *= 0.6
    else
      if @tile >= 10 and @tile <= 13
        # Special water tiles
        @velX *= 0.75
        @velY *= 0.75
        @velAng *= 0.7
      else
        @velX *= @drag
        @velY *= @drag
        @velAng *= @dragAng
      
    @xpos = Math.round(@xpos * 100) / 100
    @ypos = Math.round(@ypos * 100) / 100
      
    if @velX > -0.1 and @velX < 0.1
      @velX = 0
    if @velY > -0.1 and @velY < 0.1
      @velY = 0
    if @velAng > -0.1 and @velAng < 0.1
      @velAng = 0
      
    @velX += Math.cos(@angle * Math.PI / 180) * @speed
    @velY += Math.sin(@angle * Math.PI / 180) * @speed
      
    # Perform turn
    if @hbrake is true
      @velAng += @st_speed * 2 * (@speed/@maxspeed)
    else
      @velAng += @st_speed * (@speed/@maxspeed)
    
    @angle = Math.round(@angle)
    
    if @angle > 360
      @angle -= 360
    if @angle < 0
      @angle += 360

    # Keep inside viewport
    if @xpos < 0
      @xpos = 0
    if @ypos < 0
      @ypos = 0
    if @xpos > sr.viewportw
      @xpos = sr.viewportw
    if @ypos > sr.viewporth
      @ypos = sr.viewporth
      
    # Calculate which tile the car is on
    @tx = Math.floor(@xpos / SS.config.map.tile_width)
    @ty = Math.floor(@ypos / SS.config.map.tile_height)
    if SS.config.map.tiles[@ty]
      if SS.config.map.tiles[@ty][@tx]
        @tile = SS.config.map.tiles[@ty][@tx][0]
        newtile = SS.config.map.tiles[@ty][@tx][1]
        if newtile > @current_tile
          $('#wrongway').hide()
        else if newtile < @current_tile and newtile != 1
          $('#wrongway').show()
          
        @current_tile = newtile
      else
        @tile = null
        @current_tile = 0
    else
      @tile = null
      @current_tile = 0
    
    # Only add remote cars to cartile map
    if @local is false
      if !sr.cartiles[@tx]
        sr.cartiles[@tx] = {}
        
      if sr.cartiles[@tx][@ty]
        sr.cartiles[@tx][@ty].push(@name)
      else
        sr.cartiles[@tx][@ty] = [@name]
    
    if @name is sr.user and @current_tile is 2 and @completed_tiles is 2 and sr.currentlap is 0
      sr.currentlap = new Date().getTime();
      
    if sr.user == @name  
      if @current_tile > @completed_tiles and @last_tile < @current_tile
        @completed_tiles++
        @last_tile = @current_tile
      if @current_tile is 1 and @last_tile is SS.config.map.tile_count
        @last_tile = @current_tile
        
    if @current_tile is 1 and @completed_tiles >= SS.config.map.tile_count
      @completed_tiles = 1
      @last_tile = 1
      laptime = new Date().getTime() - sr.currentlap
      if @name is sr.user and (sr.bestlap > laptime or sr.bestlap is 0) and sr.currentlap != 0
        sr.bestlap = laptime
      sr.currentlap = 0
      
    if @current_tile is 1
      @completed_tiles = 1
      
  checkCarCollision: (foreign) ->
    fx = foreign.xpos
    fy = foreign.ypos
    
    r = @width * 1.5
    cx = @xpos
    cy = @ypos
    
    if @checkCollidePoint(fx, fy, cx, cy, r) and @colliding_car is false
      @velX = (@velX + -foreign.velX) * -1
      @velY = (@velY + -foreign.velY) * -1
      @speed *= -0.5
      @colliding_car = true
    else
      @colliding_car = false
      
  checkTileCollision: () ->
    
    tile = sr.tilemap.getTileLimits(@tx, @ty)
    if tile is null
      return true
    cx = @xpos
    cy = @ypos
    r = @width
    
    collision = false
    
    # Top
    if tile[0] != null and @colliding_tile is false
      fx = @xpos
      fy = tile[0]
      
      if @checkCollidePoint(fx, fy, cx, cy, r)
        collision = true
        @velY *= -1
       
        
    # Right
    if tile[1] != null and @colliding_tile is false
      fx = tile[1]
      fy = @ypos
      
      if @checkCollidePoint(fx, fy, cx, cy, r)
        collision = true
        @velX *= -1
        
    # Bottom
    if tile[2] != null and @colliding_tile is false
      fx = @xpos
      fy = tile[2]
      
      if @checkCollidePoint(fx, fy, cx, cy, r)
        collision = true
        @velY *= -1
     
    # Left
    if tile[3] != null and @colliding_tile is false
      fx = tile[3]
      fy = @ypos

      if @checkCollidePoint(fx, fy, cx, cy, r)
        collision = true
        @velX *= -1
    
    if collision
      @colliding_tile = true
    else
      @colliding_tile = false
 
  tileCollision: () ->
      @velX *= -0.5
      @velY *= -0.5
      @speed *= -0.5
    
  checkCollidePoint: (fx, fy, cx, cy, r) ->
    d = (fx - cx) * (fx - cx) + (fy - cy) * (fy - cy)
    
    if d <= (r * r)
      return true
    
    return false
  updateDebug: () ->
    if sr.currentlap != 0
      laptime = new Date().getTime()-sr.currentlap
    else
      laptime = 0
      
    $('#cardebug').html(
      "Angle: #{@angle}<br />" +
      "Speed: #{@speed}<br />" +
      "Accel: #{@accel}<br />" +
      "Decel: #{@decel}<br />" +
      "St Speed: #{@st_speed}<br />" +
      "Brakes: #{@brakes}<br />" +
      "Handbrake: #{@hbrake}<br />" +
      "Reverse: #{@reverse}<br />" + 
      "TL: #{@tl}<br />" +
      "TR: #{@tr}<br />" +
      "X: #{@xpos}<br />" +
      "Y: #{@ypos}<br />" +
      "VPX: #{sr.viewportx}<br />" +
      "VPY: #{sr.viewporty}<br />" + 
      "TX: #{@tx}<br />" +
      "TY: #{@ty}<br />" + 
      "Tile Type: #{@tile}<br />" + 
      "Current: #{@current_tile}<br />" +
      "Completed: #{@completed_tiles}<br />" +
      "Last: #{@last_tile}<br />"+ 
      "Lap time: #{laptime}<br />" + 
      "Best lap: #{sr.bestlap}"
    )
    
  destroy: () ->
    @element.fadeOut 1000, () =>
      @element.remove()
      $('#_rad-' + @id).remove()
      delete sr.cars[@name]
      
  draw: (ctx) ->
    @moveCar()
    if @element
      bgpos = "#{@getSpriteX()}px #{@getSpriteY()}px"

      xpos = Math.round(@xpos - (@width / 2)) # Offset width by half
      ypos = Math.round(@ypos - (@height / 3)) # Offset by half height
      @element.css({'left': @xpos, 'top': @ypos})

      rotateobj = rotateStyles(@angle+90)
      rotateobj["background-position"] = bgpos
      @imgelement.css(rotateobj)

      # Update radar
      pcl = (@xpos / sr.viewportw) * 100
      pct = (@ypos / sr.viewporth) * 100
      $('#_rad-' + @id).css({'left': pcl + '%', 'top': pct + '%'})

## BIND EVENTS ##

SS.events.on 'carEvent', (data) ->
  if sr.running is false
    return false
  car = sr.cars[data.car]
  car[data.event] = data.value
  
SS.events.on 'initCar', (car) ->
  if sr.running is false or car is null
    return false
  if car.name is sr.user
    sr.startx = car.xpos
    sr.starty = car.ypos
    initMyCar(car)
  else
    sr.cars[car.name] = initCar(car, false)
    
  # Force an update so the newcomer gets it
  broadcastCarData(sr.mycar, true)

SS.events.on 'initMyCar', (car) ->
  if sr.running is false or sr.mycar != null
    return false
  initMyCar(car)

SS.events.on 'updateCar', (car) ->
  if sr.running is false
    return false
    
  # Check to make sure messages aren't being delivered out of order
  if car.msgid >= sr.msgmax
    sr.mrecv = 0
  else
    sr.mrecv = car.msgid

  if car.msgid < sr.mrecv
    return false
  
  # Move my car
  if car.name == sr.user
    return true
    $.each(car, (k, v) ->
      sr.mycar[k] = v
      true
    )
  # Move another car
  else if sr.cars[car.name]
    $.each(car, (k, v) ->
      sr.cars[car.name].set(k, v)
      true
    )
  else
    # Maybe we missed an init message?
    sr.cars[car.name] = initCar(car, false)
    true
    
SS.events.on 'signedOut', (data) ->
  if sr.running is false
    return false
  if sr.cars[data]
    sr.cars[data].destroy()
  
SS.events.on 'chatMsg', (data) ->
 if sr.running is false
   return false
  if data.name is sr.user
    car = sr.mycar
  else
    car = sr.cars[data.name]
  
  if car.cbox is null
    celem = document.createElement('div')
    chat_elem = $(celem).addClass("chat")
    chat_elem.append('<p>' + data.msg + '</p>')
    chat_elem.append('<img src="/images/chatspike.png" class="spike" />')
    car.element.append(chat_elem)
    car.cbox = chat_elem
  else
    clearTimeout car.ctimeout
    car.cbox.find('p').html(data.msg)
  
  car.ctimeout = after 5000, () =>
    car.cbox.fadeOut 500, () =>
      car.cbox.remove()
      car.cbox = null
      car.ctimeout = null
        
  true
  
$(window).resize ->
  sr.canvas = $('#canvas')
  canvas = sr.canvas
  canvas.width window.innerWidth
  canvas.height (window.innerHeight - 97)

after = (ms, cb) -> setTimeout cb, ms
every = (ms, cb) -> setInterval cb, ms
