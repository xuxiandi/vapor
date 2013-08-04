require("lib/json")

http = require("socket.http")

function imgname(gameobj)
  return gameobj.id..".png"
end

function fname(gameobj,sourceindex)
  return gameobj.id.."-"..sourceindex..".love"
end

function dogame(gameobj)
  
  local fn = fname(gameobj,gameobj.stable)
    
  if love.filesystem.exists(fn) then
    print(fn .. " already exists.")
    local exe
    if love._os == "Windows" then
      exe = "start \""..binary.."\" \"".."%appdata%/LOVE/vapor-data".."/"..fname(gameobj,gameobj.stable).."\""
    else -- osx, linux, unknown, crazy
      exe = "\""..binary.."\" \""..love.filesystem.getSaveDirectory( ).."/"..fname(gameobj,gameobj.stable).."\""
    end
    os.execute(exe)
  else
    print(fn .. " is being downloaded.")
    r,e = http.request(gameobj.sources[gameobj.stable])
    if e == 200 then
      local success = love.filesystem.write(fn,r)
      if success then
        print(fn .. " downloaded successfully.")
      end
    end
  end
end

function love.load(args)
  love.graphics.setCaption("Vapor")
  binary = love.arg.getLow(args)
  
  icons = require("core/icons")
  fonts = require("core/fonts")
  colors = require("core/colors")
  settings = require("core/settings")
  remote = require("core/remote")

  remote.load()
  settings.load()

  nogame = love.graphics.newImage("assets/nogame.png")
  overlay = love.graphics.newImage("assets/overlay.png")

  images = {}

  selectindex = nil

  love.graphics.setMode(love.graphics.getWidth(),settings.padding*(#remote.data.games+2)+settings.offset,false,false,0)
  
end

function love.update(dt)
  local current = math.floor( ( love.mouse.getY() - settings.offset ) / settings.padding )
  if current >= 1 and current <= #remote.data.games then
    selectindex = current
  else
    selectindex = nil
  end
  
  if selectindex then  
  
    local imgn = imgname(remote.data.games[selectindex])
    if not love.filesystem.exists(imgn) then
      r,e = http.request(remote.data.games[selectindex].image)
      if e == 200 then
        local success = love.filesystem.write(imgn,r)
        if success then
          print(imgn .. " downloaded successfully.")
        end
      end
    end
    
    if not images[selectindex] then
      images[selectindex] = love.graphics.newImage(imgn)
    end

  end
  
  
end

function love.keypressed(key)
  if key == "return" or key == " " then
    if remote.data.games[selectindex] then
      dogame(remote.data.games[selectindex])
    end
  elseif key == "escape" then
    love.event.quit()
  elseif key == "delete" then
    local gameobj = remote.data.games[selectindex]
    if gameobj then
      love.filesystem.remove(fname(gameobj,gameobj.stable))
      love.filesystem.remove(imgname(gameobj))
    end
  end
end

function love.mousepressed(x,y,button)
  local gameobj = remote.data.games[selectindex]
  if button == "l" then
    if gameobj then
      dogame(gameobj)
    end
  elseif button == "r" then
    if gameobj then
      settings.data.games[gameobj.id].favorite = not settings.data.games[gameobj.id].favorite
    end
  end
end

function love.draw()

  love.graphics.setColor(colors.reset)
  if selectindex then
    love.graphics.draw(images[selectindex],settings.padding,settings.padding)
  else
    love.graphics.draw(nogame,settings.padding,settings.padding)
  end
  love.graphics.draw(overlay,settings.padding,settings.padding)

  love.graphics.setColor(colors.overlaybar)
  love.graphics.rectangle(
    "fill",
    settings.padding,
    settings.padding*2,
    love.graphics.getWidth()-settings.padding*2,
    fonts.title:getHeight()+fonts.basic:getHeight())

  local gameobj = remote.data.games[selectindex]

  love.graphics.setColor(colors.reset)
  love.graphics.setFont(fonts.title)
  if selectindex then
    love.graphics.print(gameobj.name,settings.padding*2,settings.padding*2)
  else
    love.graphics.print("Vapor",settings.padding*2,settings.padding*2)  
  end

  love.graphics.setFont(fonts.basic)
  local subline
  if selectindex then
    if love.filesystem.exists(fname(gameobj,gameobj.stable)) then
      subline = "CLICK TO PLAY"
    else
      subline = "CLICK TO INSTALL"
    end
  else
    subline = "LÖVE DISTRIBUTION CLIENT"
  end
  love.graphics.printf(
    subline,
    settings.padding*2,
    settings.padding*2+fonts.title:getHeight(),
    love.graphics.getWidth()-settings.padding*4,"right")
  
  love.graphics.setFont(fonts.basic)

  for gi,gv in pairs(remote.data.games) do
    local fn = fname(gv,gv.stable)
    local icon
    if love.filesystem.exists(fn) then
      icon = icons.play
    elseif love.filesystem.exists(imgname(gv)) then
      icon = icons.view
    else
      icon = icons.download
    end

    if gi%2==0 then
      love.graphics.setColor(colors.bareven)
    else
      love.graphics.setColor(colors.barodd)    
    end
    love.graphics.rectangle("fill",settings.padding,settings.padding*gi+settings.offset,love.graphics.getWidth()-settings.padding*2,settings.padding)

    if settings.data.games[gv.id].favorite then
      love.graphics.setColor(colors.active)
    else
      love.graphics.setColor(colors.inactive)
    end
    love.graphics.draw(icons.favorite, settings.padding, settings.padding*gi+settings.offset)
    love.graphics.setColor(colors.reset)

    love.graphics.draw(icon,settings.padding*2,settings.padding*gi+settings.offset)

    if gi == selectindex then
      love.graphics.setColor(colors.selected)
    else
      love.graphics.setColor(colors.unselected)
    end
    love.graphics.print(gv.name,settings.padding*3,settings.padding*gi+settings.offset)
    love.graphics.printf(gv.author,settings.padding*3,settings.padding*gi+settings.offset,love.graphics.getWidth()-settings.padding*4.5,"right")

  end
end

function love.quit()
  local raw = json.encode(settings.data)
  love.filesystem.write(settings.file, raw)
end
