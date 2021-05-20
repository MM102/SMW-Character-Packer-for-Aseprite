--SMW Character Packer written by MM102
--Made for use with my character creation sheet v.2.00

local spr = app.activeSprite
if not spr then
  app.alert("There is no sprite to export")
  return
end

local defaultpath = app.fs.filePath(spr.filename)
if defaultpath == "" then
	defaultpath = app.fs.normalizePath(app.fs.userConfigPath.."\\scripts\\SMW_Character_Packer\\")
end

local source = Image(spr.spec)
source:clear()
source:drawSprite(spr, app.activeFrame)

local playerPalette = Palette(16)
for i=0,15 do
	playerPalette:setColor(i, source:getPixel(762+(i*4), 130))
end
local overworldPalette = Palette(16)
for i=0,15 do
	overworldPalette:setColor(i, source:getPixel(762+(i*4), 154))
end

----------------------------------------------------------------

local function copyRect(s,d,x,y,x2,y2,w,h)
	-- there probably is a better way to do this
	-- but this is how I wrote it while learning the Aseprite API
	width, height = w or 16, h or 16
	local tileImg = Image(width, height)
	tileImg:drawImage(s, -x, -y)
	d:drawImage(tileImg,x2,y2)
end

-- from stack exchange of course
local function toBits(num,bits)
	-- returns a table of bits, most significant first.
	bits = bits or math.max(1, select(2, math.frexp(num)))
	local t = {} -- will contain the bits        
	for b = bits, 1, -1 do
		t[b] = math.fmod(num, 2)
		num = math.floor((num - t[b]) / 2)
	end
	return t
end

-- also from stack exchange
function string.fromhex(str)
	return (str:gsub('..', function (cc)
		return string.char(tonumber(cc, 16))
	end))
end

local function makeChar4BPP(img,x,y)
	local pixelIterator = 0
	local rowIterator = 1
	local bitPlanes = {{{}},{{}},{{}},{{}}}
	for i in img:pixels(Rectangle(x, y, 8, 8)) do
		pixelIterator = pixelIterator + 1
		local pixelBits = toBits(i()%16,4)
		bitPlanes[1][rowIterator][#bitPlanes[1][rowIterator]+1] = pixelBits[4]
		bitPlanes[2][rowIterator][#bitPlanes[2][rowIterator]+1] = pixelBits[3]
		bitPlanes[3][rowIterator][#bitPlanes[3][rowIterator]+1] = pixelBits[2]
		bitPlanes[4][rowIterator][#bitPlanes[4][rowIterator]+1] = pixelBits[1]
		if pixelIterator == 8 and rowIterator < 8 then
			pixelIterator = 0
			rowIterator = rowIterator + 1
			bitPlanes[1][rowIterator] = {}
			bitPlanes[2][rowIterator] = {}
			bitPlanes[3][rowIterator] = {}
			bitPlanes[4][rowIterator] = {}
		end
	end
	for i = 1, 4 do
		for j = 1, 8 do
			bitPlanes[i][j] = string.format('%02X',tonumber(table.concat(bitPlanes[i][j]),2))
		end
	end
	local charOutput = ""
	for i = 1, 8 do
		charOutput = charOutput..bitPlanes[1][i]
		charOutput = charOutput..bitPlanes[2][i]
	end
	for i = 1, 8 do
		charOutput = charOutput..bitPlanes[3][i]
		charOutput = charOutput..bitPlanes[4][i]
	end
	return charOutput
end

local function makeChar2BPP(img,x,y)
	--just ignore bitplanes 3 and 4 easy as that lol
	local pixelIterator = 0
	local rowIterator = 1
	local bitPlanes = {{{}},{{}},{{}},{{}}}
	for i in img:pixels(Rectangle(x, y, 8, 8)) do
		pixelIterator = pixelIterator + 1
		local pixelBits = toBits(i()%4,4)
		bitPlanes[1][rowIterator][#bitPlanes[1][rowIterator]+1] = pixelBits[4]
		bitPlanes[2][rowIterator][#bitPlanes[2][rowIterator]+1] = pixelBits[3]
		bitPlanes[3][rowIterator][#bitPlanes[3][rowIterator]+1] = pixelBits[2]
		bitPlanes[4][rowIterator][#bitPlanes[4][rowIterator]+1] = pixelBits[1]
		if pixelIterator == 8 and rowIterator < 8 then
			pixelIterator = 0
			rowIterator = rowIterator + 1
			bitPlanes[1][rowIterator] = {}
			bitPlanes[2][rowIterator] = {}
			bitPlanes[3][rowIterator] = {}
			bitPlanes[4][rowIterator] = {}
		end
	end
	for i = 1, 4 do
		for j = 1, 8 do
			bitPlanes[i][j] = string.format('%02X',tonumber(table.concat(bitPlanes[i][j]),2))
		end
	end
	local charOutput = ""
	for i = 1, 8 do
		charOutput = charOutput..bitPlanes[1][i]
		charOutput = charOutput..bitPlanes[2][i]
	end
	return charOutput
end

local function round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

local function toSnesRGB(r, g, b, option)
    local R = math.min(31, round(r / 8))
    local G = math.min(31, round(g / 8))
    local B = math.min(31, round(b / 8))
    local color = B*1024 + G*32 + R
	color = string.format("%04X", color)
	if option == "db" then
    	color = "db $"..string.sub(color, 3,4)..",$"..string.sub(color, 1,2)
	elseif option == "rev" then
    	color = string.sub(color, 3,4)..string.sub(color, 1,2)
	end
	return color
end

----------------------------------------------------------------

local function exportGFX32(path)

	local GFX32 = Sprite(128,376)
	local GFX32Image = Image(GFX32.spec)
	
	copyRect(source,GFX32Image,32,208,0,0,80,16)
	copyRect(source,GFX32Image,16,320,80,0)
	copyRect(source,GFX32Image,496,64,96,0)
	copyRect(source,GFX32Image,112,208,112,0)

	copyRect(source,GFX32Image,128,208,0,16)
	copyRect(source,GFX32Image,112,320,16,16)
	copyRect(source,GFX32Image,288,208,32,16)
	copyRect(source,GFX32Image,320,208,48,16)
	copyRect(source,GFX32Image,352,208,64,16)
	copyRect(source,GFX32Image,384,208,80,16)
	copyRect(source,GFX32Image,208,320,96,16)
	copyRect(source,GFX32Image,360,264,112,16)

	copyRect(source,GFX32Image,96,320,0,32)
	copyRect(source,GFX32Image,80,320,16,32)
	copyRect(source,GFX32Image,64,320,32,32)
	copyRect(source,GFX32Image,416,192,48,32)
	copyRect(source,GFX32Image,448,192,64,32)
	copyRect(source,GFX32Image,480,192,80,32)
	copyRect(source,GFX32Image,144,208,96,32,32,16)

	copyRect(source,GFX32Image,176,208,0,48,48,16)
	copyRect(source,GFX32Image,288,64,48,48)
	copyRect(source,GFX32Image,320,64,64,48)
	copyRect(source,GFX32Image,352,64,80,48)
	copyRect(source,GFX32Image,16,64,96,48)
	copyRect(source,GFX32Image,176,320,112,48)

	copyRect(source,GFX32Image,552,128,0,64,8,8)
	copyRect(source,GFX32Image,600,120,8,64,8,8)
	copyRect(source,GFX32Image,640,128,0,72,8,8)
	copyRect(source,GFX32Image,568,88,8,72,8,8)
	copyRect(source,GFX32Image,664,128,16,64,8,8)
	copyRect(source,GFX32Image,672,104,16,72,16,24)
	copyRect(source,GFX32Image,192,320,32,64)
	copyRect(source,GFX32Image,160,320,48,64)
	copyRect(source,GFX32Image,32,320,64,64)
	copyRect(source,GFX32Image,48,320,80,64)
	copyRect(source,GFX32Image,544,112,96,64)
	copyRect(source,GFX32Image,608,112,112,64)

	copyRect(source,GFX32Image,48,264,0,88,16,24)
	copyRect(source,GFX32Image,128,320,32,80,32,16)
	copyRect(source,GFX32Image,608,96,64,80)
	copyRect(source,GFX32Image,592,96,80,80)
	copyRect(source,GFX32Image,224,320,96,80,32,16)

	copyRect(source,GFX32Image,48,48,16,96)
	copyRect(source,GFX32Image,160,64,32,96)
	copyRect(source,GFX32Image,80,48,48,96)
	copyRect(source,GFX32Image,560,96,64,96)
	copyRect(source,GFX32Image,576,88,80,96)
	copyRect(source,GFX32Image,256,320,96,96)
	copyRect(source,GFX32Image,288,320,112,96)

	copyRect(source,GFX32Image,64,192,0,112)
	copyRect(source,GFX32Image,64,272,16,112)
	copyRect(source,GFX32Image,224,48,32,112) 
	copyRect(source,GFX32Image,224,64,48,112) 
	copyRect(source,GFX32Image,80,192,64,112) 
	copyRect(source,GFX32Image,624,112,80,112,48,16) 

	copyRect(source,GFX32Image,96,192,0,128)
	copyRect(source,GFX32Image,384,128,16,128)
	copyRect(source,GFX32Image,256,48,32,128)
	copyRect(source,GFX32Image,256,64,48,128)
	copyRect(source,GFX32Image,112,192,64,128)
	copyRect(source,GFX32Image,192,48,80,128)
	copyRect(source,GFX32Image,416,128,96,128)
	copyRect(source,GFX32Image,448,128,112,128)

	copyRect(source,GFX32Image,128,192,0,144)
	copyRect(source,GFX32Image,384,64,16,144)
	copyRect(source,GFX32Image,416,64,32,144)
	copyRect(source,GFX32Image,240,192,48,144,16,32)
	copyRect(source,GFX32Image,320,272,64,144)
	copyRect(source,GFX32Image,184,64,80,144)
	copyRect(source,GFX32Image,288,272,96,144)
	copyRect(source,GFX32Image,160,272,112,144)

	copyRect(source,GFX32Image,224,192,0,160)
	copyRect(source,GFX32Image,448,64,16,160)
	copyRect(source,GFX32Image,176,272,32,160)
	copyRect(source,GFX32Image,432,192,64,160)
	copyRect(source,GFX32Image,128,48,80,160,16,32)
	copyRect(source,GFX32Image,208,272,96,160)
	copyRect(source,GFX32Image,192,272,112,160)

	copyRect(source,GFX32Image,16,48,0,176)
	copyRect(source,GFX32Image,288,128,16,176)
	copyRect(source,GFX32Image,320,128,32,176)
	copyRect(source,GFX32Image,144,48,48,176)
	copyRect(source,GFX32Image,352,128,64,176)
	copyRect(source,GFX32Image,128,264,96,184,16,24)
	copyRect(source,GFX32Image,144,64,112,176)

	copyRect(source,GFX32Image,48,64,0,192,48,16)
	copyRect(source,GFX32Image,416,272,48,192,24,16)
	copyRect(source,GFX32Image,256,192,112,192)

	copyRect(source,GFX32Image,16,128,0,208)
	copyRect(source,GFX32Image,480,128,16,208)
	copyRect(source,GFX32Image,256,208,32,208)
	copyRect(source,GFX32Image,448,272,48,208)
	copyRect(source,GFX32Image,96,48,64,208,16,32)
	copyRect(source,GFX32Image,112,264,80,216,16,24)
	copyRect(source,GFX32Image,144,120,96,216,16,24)
	copyRect(source,GFX32Image,224,120,112,216,16,8)

	copyRect(source,GFX32Image,48,120,0,232,16,24)
	copyRect(source,GFX32Image,16,208,16,224)
	copyRect(source,GFX32Image,480,56,32,232,16,24)
	copyRect(source,GFX32Image,624,200,48,232,16,24)
	copyRect(source,GFX32Image,352,272,112,224)

	copyRect(source,GFX32Image,128,128,16,240)
	copyRect(source,GFX32Image,64,128,64,240,32,16)
	copyRect(source,GFX32Image,160,128,96,240)
	copyRect(source,GFX32Image,224,128,112,240)

	copyRect(source,GFX32Image,528,112,0,256)
	copyRect(source,GFX32Image,224,264,16,264,16,24)
	copyRect(source,GFX32Image,537,128,32,256)
	copyRect(source,GFX32Image,192,120,48,264,16,8)
	copyRect(source,GFX32Image,592,128,64,256,32,16)
	copyRect(source,GFX32Image,624,128,96,256)
	copyRect(source,GFX32Image,32,48,112,256,16,32)

	copyRect(source,GFX32Image,240,272,0,272)
	copyRect(source,GFX32Image,192,128,32,272)
	copyRect(source,GFX32Image,648,128,48,272)
	copyRect(source,GFX32Image,16,264,64,280,16,8)
	copyRect(source,GFX32Image,16,272,80,272)
	copyRect(source,GFX32Image,672,128,96,272)

	copyRect(source,GFX32Image,96,120,0,296,16,24)
	copyRect(source,GFX32Image,256,120,16,296,16,24)
	copyRect(source,GFX32Image,32,120,32,296,16,24)
	copyRect(source,GFX32Image,80,264,48,296,16,24)
	copyRect(source,GFX32Image,256,264,64,296,16,24)
	copyRect(source,GFX32Image,96,264,80,296,16,24)
	copyRect(source,GFX32Image,392,264,96,288)
	copyRect(source,GFX32Image,384,272,112,288)

	copyRect(source,GFX32Image,528,192,0,320,16,32)
	copyRect(source,GFX32Image,544,192,16,320,16,32)
	copyRect(source,GFX32Image,560,192,32,320,48,16)
	copyRect(source,GFX32Image,560,272,80,320)
	copyRect(source,GFX32Image,496,128,96,320)

	copyRect(source,GFX32Image,624,272,48,336)
	copyRect(source,GFX32Image,640,192,80,336,48,32)

	copyRect(source,GFX32Image,608,208,0,352)
	copyRect(source,GFX32Image,608,272,16,352)
	copyRect(source,GFX32Image,576,264,32,344,16,24)
	copyRect(source,GFX32Image,592,272,48,352)
	copyRect(source,GFX32Image,544,264,64,344,16,24)

	local gfx32pal = playerPalette
	gfx32pal:setColor(0, source:getPixel(872,272))

	local berries = Sprite{ fromFile = app.fs.normalizePath(app.fs.userConfigPath.."\\scripts\\SMW_Character_Packer\\berries.aseprite") }
	berries:setPalette(gfx32pal)
	local berriesImage = Image(berries.width,berries.height)
	berriesImage:clear()
	berriesImage:drawSprite(berries, 1)

	copyRect(berriesImage,GFX32Image,0,0,96,304,32,16)
	copyRect(berriesImage,GFX32Image,0,16,0,368,32,8)
	copyRect(berriesImage,GFX32Image,0,16,32,368,32,8)
	copyRect(berriesImage,GFX32Image,24,32,112,320,8,8)
	copyRect(berriesImage,GFX32Image,24,32,120,320,8,8)
	copyRect(berriesImage,GFX32Image,24,32,112,328,8,8)
	copyRect(berriesImage,GFX32Image,24,32,120,328,8,8)
	copyRect(berriesImage,GFX32Image,16,32,24,64,8,8)


	berries:close()
	GFX32.cels[1].image = GFX32Image
	GFX32:setPalette(gfx32pal)

	app.command.ReplaceColor({ui=false,from={0,0,0,0},to=source:getPixel(872,272)})
	app.command.BackgroundFromLayer()
	app.command.ChangePixelFormat({ format="indexed", dithering="none" })

	local bin = ""
	for i = 1, (GFX32.height/8)-1 do
		for j = 1, (GFX32.width/8) do
			bin = bin..makeChar4BPP(GFX32.cels[1].image,(j-1)*8,(i-1)*8)
		end
	end
	for j = 1, (GFX32.width/8)/2 do
		bin = bin..makeChar4BPP(GFX32.cels[1].image,(j-1)*8,((GFX32.height/8)-1)*8)
	end

	GFX32:close()

	local out = io.open(app.fs.normalizePath(path.."\\GFX32.bin"), "wb")
	local str = string.fromhex(bin)
	out:write(str)
	out:close()

end

local function exportGFX00(path)

	local gfx00pal = playerPalette
	gfx00pal:setColor(0, source:getPixel(808,240))
	local GFX00 = Sprite{ fromFile = app.fs.normalizePath(app.fs.userConfigPath.."\\scripts\\SMW_Character_Packer\\GFX00_orig.aseprite") }
	GFX00:setPalette(gfx00pal)

	local GFX00Image = Image(GFX00.width,GFX00.height)
	GFX00Image:clear()
	GFX00Image:drawSprite(GFX00, 1)

	app.command.ChangePixelFormat({ format="rgb", dithering="none" })

	copyRect(source,GFX00Image,368,64,80,0,8,8)     --0A
	copyRect(source,GFX00Image,368,72,88,0,8,8)     --0B
	copyRect(source,GFX00Image,304,208,96,0,8,8)    --0C
	copyRect(source,GFX00Image,424,208,104,0,8,8)   --0D
	copyRect(source,GFX00Image,400,208,80,8,8,8)    --1A
	copyRect(source,GFX00Image,400,216,88,8,8,8)    --1B
	copyRect(source,GFX00Image,272,56,0,16,8,8)     --20
	copyRect(source,GFX00Image,272,64,8,16,8,8)     --21
	copyRect(source,GFX00Image,304,64,16,16,8,8)    --22
	copyRect(source,GFX00Image,304,72,24,16,8,8)    --23
	copyRect(source,GFX00Image,240,56,0,24,8,8)     --30
	copyRect(source,GFX00Image,240,64,8,24,8,8)     --31
	copyRect(source,GFX00Image,336,64,16,24,8,8)    --32
	copyRect(source,GFX00Image,336,72,24,24,8,8)    --33
	copyRect(source,GFX00Image,529,128,80,32,8,8)   --4A
	copyRect(source,GFX00Image,600,112,88,32,8,8)   --4B
	copyRect(source,GFX00Image,640,136,80,40,8,8)   --5A
	copyRect(source,GFX00Image,584,104,88,40,8,8)   --5B
	copyRect(source,GFX00Image,120,64,112,56,8,8)   --7E
	
	GFX00.cels[1].image = GFX00Image
	app.command.ChangePixelFormat({ format="indexed", dithering="none" })

	local bin = ""
	for i = 1, (GFX00.height/8) do
		for j = 1, (GFX00.width/8) do
			bin = bin..makeChar4BPP(GFX00.cels[1].image,(j-1)*8,(i-1)*8)
		end
	end

	GFX00:close()

	local out = io.open(app.fs.normalizePath(path.."\\GFX00.bin"), "wb")
	local str = string.fromhex(bin)
	out:write(str)
	out:close()

end

local function exportGFX10(path)

	local gfx10pal = overworldPalette
	gfx10pal:setColor(0, source:getPixel(872,240))
	local GFX10 = Sprite{ fromFile = app.fs.normalizePath(app.fs.userConfigPath.."\\scripts\\SMW_Character_Packer\\GFX10_orig.aseprite") }
	GFX10:setPalette(gfx10pal)

	local GFX10Image = Image(GFX10.width,GFX10.height)
	GFX10Image:clear()
	GFX10Image:drawSprite(GFX10, 1)

	app.command.ChangePixelFormat({ format="rgb", dithering="none" })

	copyRect(source,GFX10Image,720,16,48,0)
	copyRect(source,GFX10Image,720,32,64,0)
	copyRect(source,GFX10Image,720,48,80,0)
	copyRect(source,GFX10Image,720,64,96,0)
	copyRect(source,GFX10Image,720,80,112,0)
	copyRect(source,GFX10Image,720,96,0,16)
	copyRect(source,GFX10Image,720,112,32,16)
	copyRect(source,GFX10Image,720,128,48,32)
	copyRect(source,GFX10Image,720,144,32,48)
	copyRect(source,GFX10Image,720,160,48,48)
	
	GFX10.cels[1].image = GFX10Image
	app.command.ChangePixelFormat({ format="indexed", dithering="none" })

	local bin = ""
	for i = 1, (GFX10.height/8) do
		for j = 1, (GFX10.width/8) do
			bin = bin..makeChar4BPP(GFX10.cels[1].image,(j-1)*8,(i-1)*8)
		end
	end

	GFX10:close()

	local out = io.open(app.fs.normalizePath(path.."\\GFX10.bin"), "wb")
	local str = string.fromhex(bin)
	out:write(str)
	out:close()

end

local function exportGFX22(path)

	local gfx22pal = playerPalette
	gfx22pal:setColor(0, source:getPixel(808,256))
	local GFX22 = Sprite{ fromFile = app.fs.normalizePath(app.fs.userConfigPath.."\\scripts\\SMW_Character_Packer\\GFX22_orig.aseprite") }
	GFX22:setPalette(gfx22pal)

	local GFX22Image = Image(GFX22.width,GFX22.height)
	GFX22Image:clear()
	GFX22Image:drawSprite(GFX22, 1)

	app.command.ChangePixelFormat({ format="rgb", dithering="none" })

	copyRect(source,GFX22Image,720,208,64,0)
	
	GFX22.cels[1].image = GFX22Image
	app.command.ChangePixelFormat({ format="indexed", dithering="none" })

	local bin = ""
	for i = 1, (GFX22.height/8) do
		for j = 1, (GFX22.width/8) do
			bin = bin..makeChar4BPP(GFX22.cels[1].image,(j-1)*8,(i-1)*8)
		end
	end

	GFX22:close()

	local out = io.open(app.fs.normalizePath(path.."\\GFX22.bin"), "wb")
	local str = string.fromhex(bin)
	out:write(str)
	out:close()

end

local function exportGFX24(path)

	local gfx24pal = playerPalette
	gfx24pal:setColor(0, source:getPixel(872,256))
	local GFX24 = Sprite{ fromFile = app.fs.normalizePath(app.fs.userConfigPath.."\\scripts\\SMW_Character_Packer\\GFX24_orig.aseprite") }
	GFX24:setPalette(gfx24pal)

	local GFX24Image = Image(GFX24.width,GFX24.height)
	GFX24Image:clear()
	GFX24Image:drawSprite(GFX24, 1)

	app.command.ChangePixelFormat({ format="rgb", dithering="none" })

	copyRect(source,GFX24Image,720,184,112,48)
	
	GFX24.cels[1].image = GFX24Image
	app.command.ChangePixelFormat({ format="indexed", dithering="none" })

	local bin = ""
	for i = 1, (GFX24.height/8) do
		for j = 1, (GFX24.width/8) do
			bin = bin..makeChar4BPP(GFX24.cels[1].image,(j-1)*8,(i-1)*8)
		end
	end

	GFX24:close()

	local out = io.open(app.fs.normalizePath(path.."\\GFX24.bin"), "wb")
	local str = string.fromhex(bin)
	out:write(str)
	out:close()

end

local function exportGFX28(path)

	local GFX28 = Sprite{ fromFile = app.fs.normalizePath(app.fs.userConfigPath.."\\scripts\\SMW_Character_Packer\\GFX28_orig.aseprite") }

	local GFX28Image = Image(GFX28.width,GFX28.height)
	GFX28Image:clear()
	GFX28Image:drawSprite(GFX28, 1)

	app.command.ChangePixelFormat({ format="rgb", dithering="none" })

	copyRect(source,GFX28Image,488,272,0,24,40,16)
	
	GFX28.cels[1].image = GFX28Image
	app.command.ChangePixelFormat({ format="indexed", dithering="none" })

	local bin = ""
	for i = 1, (GFX28.height/8) do
		for j = 1, (GFX28.width/8) do
			bin = bin..makeChar2BPP(GFX28.cels[1].image,(j-1)*8,(i-1)*8)
		end
	end

	GFX28:close()

	local out = io.open(app.fs.normalizePath(path.."\\GFX28.bin"), "wb")
	local str = string.fromhex(bin)
	out:write(str)
	out:close()

end

local function exportGFX33(path)

	local GFX33 = Sprite{ fromFile = app.fs.normalizePath(app.fs.userConfigPath.."\\scripts\\SMW_Character_Packer\\GFX33_orig.aseprite") }

	local GFX33Image = Image(GFX33.width,GFX33.height)
	GFX33Image:clear()
	GFX33Image:drawSprite(GFX33, 1)

	app.command.ChangePixelFormat({ format="rgb", dithering="none" })

	copyRect(source,GFX33Image,752,168,0,32,64,16)
	copyRect(source,GFX33Image,832,168,80,32,48,16)
	copyRect(source,GFX33Image,752,184,0,48,128,16)
	copyRect(source,GFX33Image,752,200,0,64,48,16)
	
	GFX33.cels[1].image = GFX33Image
	app.command.ChangePixelFormat({ format="indexed", dithering="none" })

	local bin = ""
	for i = 1, (GFX33.height/8) do
		for j = 1, (GFX33.width/8) do
			bin = bin..makeChar4BPP(GFX33.cels[1].image,(j-1)*8,(i-1)*8)
		end
	end

	GFX33:close()

	local out = io.open(app.fs.normalizePath(path.."\\GFX33.bin"), "wb")
	local str = string.fromhex(bin)
	out:write(str)
	out:close()

end

----------------------------------------------------------------

local function exportPalASM(path)

	local playercolors = {}

	local getR = app.pixelColor.rgbaR
	local getG = app.pixelColor.rgbaG
	local getB = app.pixelColor.rgbaB

	for i=1,10 do
		playercolors[i+00] = {getR(source:getPixel(786+((i-1)*4), 130)),getG(source:getPixel(786+((i-1)*4), 130)),getB(source:getPixel(786+((i-1)*4), 130))}
	end
	for i=1,10 do
		playercolors[i+10] = {getR(source:getPixel(786+((i-1)*4), 134)),getG(source:getPixel(786+((i-1)*4), 134)),getB(source:getPixel(786+((i-1)*4), 134))}
	end
	for i=1,10 do
		playercolors[i+20] = {getR(source:getPixel(786+((i-1)*4), 138)),getG(source:getPixel(786+((i-1)*4), 138)),getB(source:getPixel(786+((i-1)*4), 138))}
	end
	for i=1,10 do
		playercolors[i+30] = {getR(source:getPixel(786+((i-1)*4), 142)),getG(source:getPixel(786+((i-1)*4), 142)),getB(source:getPixel(786+((i-1)*4), 142))}
	end
	for i=1,7 do
		playercolors[i+40] = {getR(source:getPixel(766+((i-1)*4), 154)),getG(source:getPixel(766+((i-1)*4), 154)),getB(source:getPixel(766+((i-1)*4), 154))}
	end
	for i=1,7 do
		playercolors[i+47] = {getR(source:getPixel(766+((i-1)*4), 158)),getG(source:getPixel(766+((i-1)*4), 158)),getB(source:getPixel(766+((i-1)*4), 158))}
	end

    local asmOutput = "; Player Palette Patch\n"..
    "; Changes the global colors for the player without effecting other global colors\n"..
    "; Created with MM102's SMW Player Exporter"..
    "\n\norg $00B2C8"..
    "\n\n; Mario Pal"
    for i=1,10 do
        asmOutput = asmOutput .. "\n" .. toSnesRGB(playercolors[i][1],playercolors[i][2],playercolors[i][3],"db") .. " ; Color " .. string.format("%X", i+5)
    end
    asmOutput = asmOutput ..
    "\n\n; Luigi Pal"
    for i=11,20 do
        asmOutput = asmOutput .. "\n" .. toSnesRGB(playercolors[i][1],playercolors[i][2],playercolors[i][3],"db") .. " ; Color " .. string.format("%X", i+5-10)
    end
    asmOutput = asmOutput ..
    "\n\n; Mario Fire Pal"
    for i=21,30 do
        asmOutput = asmOutput .. "\n" .. toSnesRGB(playercolors[i][1],playercolors[i][2],playercolors[i][3],"db") .. " ; Color " .. string.format("%X", i+5-20)
    end
    asmOutput = asmOutput ..
    "\n\n; Luigi Fire Pal"
    for i=31,40 do
        asmOutput = asmOutput .. "\n" .. toSnesRGB(playercolors[i][1],playercolors[i][2],playercolors[i][3],"db") .. " ; Color " .. string.format("%X", i+5-30)
    end
    asmOutput = asmOutput ..
    "\n\norg $00B598"..
    "\n\n; Mario OW Pal"
    for i=41,47 do
        asmOutput = asmOutput .. "\n" .. toSnesRGB(playercolors[i][1],playercolors[i][2],playercolors[i][3],"db") .. " ; Color " .. string.format("%X", i-40)
    end
    asmOutput = asmOutput ..
    "\n\n; Luigi OW Pal"
    for i=48,54 do
        asmOutput = asmOutput .. "\n" .. toSnesRGB(playercolors[i][1],playercolors[i][2],playercolors[i][3],"db") .. " ; Color " .. string.format("%X", i-47)
    end

	local out = io.open(app.fs.normalizePath(path.."\\Player_Palette_Patch.asm"), "wb")
	out:write(asmOutput)
	out:close()

end

local function exportPalPal(path)

	local playercolors = {}

	local getR = app.pixelColor.rgbaR
	local getG = app.pixelColor.rgbaG
	local getB = app.pixelColor.rgbaB

	for i=1,10 do
		playercolors[i+00] = {getR(source:getPixel(786+((i-1)*4), 130)),getG(source:getPixel(786+((i-1)*4), 130)),getB(source:getPixel(786+((i-1)*4), 130))}
	end
	for i=1,10 do
		playercolors[i+10] = {getR(source:getPixel(786+((i-1)*4), 134)),getG(source:getPixel(786+((i-1)*4), 134)),getB(source:getPixel(786+((i-1)*4), 134))}
	end
	for i=1,10 do
		playercolors[i+20] = {getR(source:getPixel(786+((i-1)*4), 138)),getG(source:getPixel(786+((i-1)*4), 138)),getB(source:getPixel(786+((i-1)*4), 138))}
	end
	for i=1,10 do
		playercolors[i+30] = {getR(source:getPixel(786+((i-1)*4), 142)),getG(source:getPixel(786+((i-1)*4), 142)),getB(source:getPixel(786+((i-1)*4), 142))}
	end
	for i=1,7 do
		playercolors[i+40] = {getR(source:getPixel(766+((i-1)*4), 154)),getG(source:getPixel(766+((i-1)*4), 154)),getB(source:getPixel(766+((i-1)*4), 154))}
	end
	for i=1,7 do
		playercolors[i+47] = {getR(source:getPixel(766+((i-1)*4), 158)),getG(source:getPixel(766+((i-1)*4), 158)),getB(source:getPixel(766+((i-1)*4), 158))}
	end

	local spal = io.open(app.fs.normalizePath(app.fs.userConfigPath.."\\scripts\\SMW_Character_Packer\\Shared_palette_orig.pal"), "rb")
	local part1 = spal:read(552)
	spal:seek("cur", 80)
	local part3 = spal:read(640)
	spal:seek("cur", 28)
	local part5 = spal:read(718)
	spal:close()

	local part2 = ""
	for i=1,40 do
		part2 = part2..toSnesRGB(playercolors[i][1],playercolors[i][2],playercolors[i][3],"rev")
	end
	part2 = string.fromhex(part2)
	
	local part4 = ""
	for i=41,54 do
		part4 = part4..toSnesRGB(playercolors[i][1],playercolors[i][2],playercolors[i][3],"rev")
	end
	part4 = string.fromhex(part4)

	local out = io.open(app.fs.normalizePath(path.."\\Shared_palette.pal"), "wb")
	out:write(part1..part2..part3..part4..part5)
	out:close()
end

local function exportPalOw(path)

	local playercolors = {}

	local getR = app.pixelColor.rgbaR
	local getG = app.pixelColor.rgbaG
	local getB = app.pixelColor.rgbaB

	for i=1,16 do
		playercolors[i] = {getR(source:getPixel(762+((i-1)*4), 154)),getG(source:getPixel(762+((i-1)*4), 154)),getB(source:getPixel(762+((i-1)*4), 154))}
		playercolors[i] = string.format("%02X", playercolors[i][1])..string.format("%02X", playercolors[i][2])..string.format("%02X", playercolors[i][3])
	end
	for i=17,32 do
		playercolors[i] = {getR(source:getPixel(762+((i-17)*4), 158)),getG(source:getPixel(762+((i-17)*4), 158)),getB(source:getPixel(762+((i-17)*4), 158))}
		playercolors[i] = string.format("%02X", playercolors[i][1])..string.format("%02X", playercolors[i][2])..string.format("%02X", playercolors[i][3])
	end

	local owpal = io.open(app.fs.normalizePath(app.fs.userConfigPath.."\\scripts\\SMW_Character_Packer\\Overworld_palette_orig.pal"), "rb")
	local part1 = owpal:read(480)
	owpal:seek("cur", 96)
	local part3 = owpal:read(192)

	part2 = string.fromhex(table.concat(playercolors))

	local out = io.open(app.fs.normalizePath(path.."\\Overworld_palette.pal"), "wb")
	out:write(part1..part2..part3)
	out:close()

end

----------------------------------------------------------------

local dlg1 = Dialog("SMW Player Exporter by MM102")
local function addDialogWidgets() -- this is here so I can collapse it in my code editor
	dlg1:check{
		id = "o_gfx32",
		text = "GFX32 (Main)­­­­­­­­­­­­­­­­­­­­­­",
		selected = true
	}
	dlg1:check{
		id = "o_gfx00",
		text = "GFX00 (Extras)­­­­­­­­­­­­­",
		selected = true
	}
	dlg1:newrow{}
	dlg1:check{
		id = "o_gfx10",
		text = "GFX­1­0 (Map)­­­­­­­­­­­­­­­­­­­­­­­­",
		selected = false
	}
	dlg1:check{
		id = "o_gfx22",
		text = "GFX22 (Kiss small)",
		selected = false
	}
	dlg1:newrow{}
	dlg1:check{
		id = "o_gfx28",
		text = "GFX28 (HUD text)­­­­",
		selected = false
	}
	dlg1:check{
		id = "o_gfx24",
		text = "GFX24 (Kiss big)­­­­­­­­­",
		selected = false
	}
	dlg1:newrow{}
	dlg1:check{
		id = "o_gfx33",
		text = "GFX33 (Yoshi)­­­­­­­­­­­­­­­­­­",
		selected = false
	}
	dlg1:separator{}
	dlg1:check{
		id = "o_pal_asm",
		text = "Export shared palette as .asm patch",
		selected = false
	}
	dlg1:newrow{}
	dlg1:check{
		id = "o_pal_pal",
		text = "Export shared palette as .pal file",
		selected = false
	}
	dlg1:newrow{}
	dlg1:check{
		id = "o_pal_ow",
		text = "Export overworld .pal file (for 16 color palettes)",
		selected = false
	}
	dlg1:separator{}
	dlg1:label{
		text = "Destination folder:"
	}
	dlg1:entry{
		id="o_path",
		text=defaultpath
	}
	dlg1:separator{}
end
addDialogWidgets()

local dlg2 = Dialog("­­­­­­­­­­­­­­­­­­­­- SWITCH PALACE -")
local function addDialogWidgets2()
	dlg2:label{
		text = "    ­­­­­The power of the­­­­    "
	}
	dlg2:newrow{}
	dlg2:label{
		text = "    ­­­­­­­­switch you have­­­­­­­­    "
	}
	dlg2:newrow{}
	dlg2:label{
		text = "    ­­­­­­­­­pushed will turn­­­­­­­­­    "
	}
	dlg2:newrow{}
	dlg2:label{
		text = "    ­­­­­­­­­­­­­­­­­­­­( )­ into [­!­]­­­­­­­­­­­­­­­­­­­­    "
	}
	--[[
	dlg2:check{
		text="into",
		selected=false
	}
	dlg2:check{
		text=".",
		selected=true
	}
	--]]
	dlg2:newrow{}
	dlg2:label{
		text = "    ­­­­­­­­Your player has­­­­­­­­    "
	}
	dlg2:newrow{}
	dlg2:label{
		text = "    also been exported.    "
	}
	dlg2:button{
		text = "SAVE AND CONTINUE",
		focus=true,
		onclick = function() dlg2:close() end
	}
end
addDialogWidgets2()

local dlg3 = Dialog("um,")
dlg3:label{
	text = "you didn't select anything............"
}
dlg3:button{
	text = "sorry?",
	focus=true,
	onclick = function() dlg3:close() end
}


local function doExport()
	if not app.fs.isDirectory(dlg1.data.o_path) then
		app.alert("Cannot export to folder.")
		return
	end
	local export = false
	if dlg1.data.o_gfx32 then
		exportGFX32(dlg1.data.o_path)
		export = true
	end
	if dlg1.data.o_gfx00 then
		exportGFX00(dlg1.data.o_path)
		export = true
	end
	if dlg1.data.o_gfx10 then
		exportGFX10(dlg1.data.o_path)
		export = true
	end
	if dlg1.data.o_gfx22 then
		exportGFX22(dlg1.data.o_path)
		export = true
	end
	if dlg1.data.o_gfx24 then
		exportGFX24(dlg1.data.o_path)
		export = true
	end
	if dlg1.data.o_gfx28 then
		exportGFX28(dlg1.data.o_path)
		export = true
	end
	if dlg1.data.o_gfx33 then
		exportGFX33(dlg1.data.o_path)
		export = true
	end
	if dlg1.data.o_pal_asm then
		exportPalASM(dlg1.data.o_path)
		export = true
	end
	if dlg1.data.o_pal_pal then
		exportPalPal(dlg1.data.o_path)
		export = true
	end
	if dlg1.data.o_pal_ow then
		exportPalOw(dlg1.data.o_path)
		export = true
	end
	app.refresh()
	if export then
		dlg1:close()
		dlg2:show{ wait=false }
	else
		dlg3:show{ wait=false }
	end
end

dlg1:button{
	id = "ok",
	text = "Export",
	onclick = doExport,
	focus=true
}

dlg1:show{ wait=false }