# Server-side Code

msgsend = 0
msgmax = 100010 # Slightly increased to make sure the messages get delivered

exports.actions =
  init: (cb) ->
    
    @session.on 'disconnect', (session) ->
      R.del "user:#{session.user_id}", (err, data) ->
      SS.publish.broadcast 'signedOut', session.user_id
      session.user.logout ->
    
    if @session.username
      R.get "user:#{@session.user_id}", (err, data) =>
        if data
          @broadcastUserCar JSON.parse(data, cb)
        else
          cb false
    else
      cb false

  # Notify all users when a new person signs in
  broadcastUserCar: (data, cb) ->
    @session.setUserId data.name
    SS.publish.broadcast 'initCar', data
    cb data
          
  chatMsg: (data, cb) ->
    SS.publish.broadcast 'chatMsg', data
    cb
    
  getUsersOnline: (cb) ->
    SS.users.online.now (usernames) =>
      keys = usernames.map (username) -> "user:#{username}"
      R.mget keys, (err, data) =>
        cb data.map (user) -> JSON.parse(user)
        
  signIn: (username, cb) ->
    R.get "user:#{username}", (err, udata) =>
      if udata
        
        # User is online already, deny
        cb false
        
        @broadcastUserCar JSON.parse(udata), cb
        @getUsersOnline (data) ->
          for car in data
            SS.publish.broadcast 'initCar', car
          
      else
        # Make new user data
        
        # TODO
        # Find a random road tile and
        car = {
            "colour": randomRange(0, 7), 
            "xpos": randomRange(200, 500),
            "ypos": randomRange(200, 500),
            "rot": randomRange(0, 359),
            "speed": randomRange(0, 20),
            "name": username,
            "id": getUUID()
        }
    
        R.set "user:#{username}", JSON.stringify(car), (err, data) =>
          if data
            @broadcastUserCar car, cb
            @getUsersOnline (cdata) =>
              for car in cdata
                SS.publish.user username, 'initCar', car
  
  updateCar: (car, cb) ->
    # Update car in redis
    R.set "user:#{car.name}", JSON.stringify(car), (err, data) ->
    car.msgid = msgsend++
    if msgsend >= msgmax
      msgsend = 0
    SS.publish.broadcast 'updateCar', car
    
randomRange = (from, to) ->
  Math.floor(Math.random() * (to - from + 1) + from)
after = (ms, cb) -> setTimeout cb, ms
every = (ms, cb) -> setInterval cb, ms
getUUID = ->
    S4 = () ->
       return (((1+Math.random())*0x10000)|0).toString(16).substring(1)
    return (S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4())
