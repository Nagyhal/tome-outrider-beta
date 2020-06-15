require "engine.class"

local Dialog = require "engine.ui.Dialog"
local Button = require "engine.ui.Button"
local NameGenerator = require "engine.NameGenerator"
local ActorFrame = require "engine.ui.ActorFrame"

module(..., package.seeall, class.inherit(Dialog))

local rules = {
	phonemesVocals = "y, o, ie, en, er",
	phonemesConsonants = "r, ff, g, ck",
	syllablesStart = "Wolf, Beast, Battle, Blood, Bone, Flesh, Fang, Red, Umbra, Grey, Mist, Crimson, Sorrow, Bitter, Dark, Winter, Death, Murder, Dawn, Dread, Night, Twilight, Fear, Bear, Astro, Mega, Boss, Great, Giga, Bite, Bark, Moon, Wild, Forest, Steppe, Swamp, Horde, War, Sky, Heart, Tyrrano, Fleet, Dire, Super, Monster, Ultra, Luna, Gut, Fur, Face, Human, Orc, Spleen, Warg, Aggro, Spell, Cat, Dog, Silver",
	syllablesMiddle = "en, yn",
	syllablesEnd = "fang, tooth, scar, claw, nail, tongue, tail, eye, slicer, slasher, gnasher, biter, breaker, crusher, killer, tearer, devourer, face, rex, rise, dawn, paw, howler, harbinger, core, heart, soul, mate, wulf, seeker, hunter, rex, king, raptor, ender, max, runner, ferno, comet, eviscerator, er, coat, mane, dog, pup, bert, odon, oceros, rush, brain, leg, rider",
	rules = "$87s$4m$e",
}

local function getName()
	local ng = NameGenerator.new(rules)

 	--We'll use patterns to make short names more interesting.
	local patterns = {"The %s", "%s of the %s", "Big %s", "%s %s", "Mister %s", "%s Wolf", "The Great %s", "%s of %s"}

	local name = (ng:generate()):capitalize()

	--If the name is very short, we'll add a pattern to it to make it funkier.
	if #name<=5 or (#name==6 and rng.percent(50)) then
		local pattern = rng.table(patterns)
		name = (pattern):format(name, (ng:generate()):capitalize())
	end

	return name
end

-- @idea I'm worried that dupilicating this much code from the Dialog file 
-- could cause bugs further down the line. Ideally, there'd be a hook somewhere
-- within multiButtonPopup where I could insert a picture plus re-align the last
-- box to be on a different row.
function _M:getPetNames(player, pet)
	--First, we'll set up all the things that are used by multiButtonPopup.
	escape = escape or 1
	default = default or 1

	local title = ("%s, choose a name for your %s!"):format(player.name:capitalize(), pet.original_name)
	-- @todo : Find out if I can add the other lines, keeping them centred prettily some way
	local text = [[You dive deep into your memory, searching for a name which evokes courage, power and sheer domination...]]
	-- Which will it be?
	-- Remember, you can change or edit this choice afterward.]]
	local num_buttons = 5

	local max_w, max_h = game.w*.5, game.h*.75

	local text_w, text_h = self.font:size(text)
	local tex, text_lines, text_width = self.font:draw(text, (w or max_w)*.9, 255, 255, 255, false, true)
	local text_height = text_lines*text_h+5
	local button_spacing = 10
	
	local d = new(title, 1, 1)
	d.key:addBind("EXIT", function() game:unregisterDialog(d) end)

	local buttons, buttons_width, button_height = {}, 0, 0

	for i = 1, num_buttons do
		--Simply get and capitalize the basic generated name.
		local name = getName()
		local b = require("engine.ui.Button").new{
			text=name,
			fct=function()
				game:unregisterDialog(d)
				pet.name = name
				pet.changed = true
			end}
		buttons[i] = b
		buttons_width = buttons_width + b.w
		button_height = math.max(button_height, b.h)
	end

	--We'll run the rows routine as usual, because we don't know if our names
	--aren't going to be so long that they won't fit on the screen.
	local rows = {{buttons_width=0}}
	local left, top, nrow = 5, 0, #rows
	local max_buttons_width = 0

	local rows_threshold = (buttons_width + (num_buttons - 1)*button_spacing)*1.1/math.ceil((buttons_width + (num_buttons - 1)*button_spacing)/max_w)

	for i = 1, num_buttons do
		left = left + buttons[i].w + button_spacing
		buttons_width = buttons_width - buttons[i].w
		if left >= max_w or left > rows_threshold then -- add a row
			rows[nrow].left = left
			left = 5 + buttons[i].w + button_spacing
			table.insert(rows, {buttons_width=0})
			nrow = #rows
		end
		table.insert(rows[nrow], buttons[i])
		rows[nrow].buttons_width = rows[nrow].buttons_width + buttons[i].w
		max_buttons_width = math.max(max_buttons_width, rows[nrow].buttons_width+button_spacing*(#rows[nrow]-1))
	end

	--Here we insert our last button.
	table.insert(rows, {
		buttons_width=0,
		[1] = require("engine.ui.Button").new{
			text="Try again",
			fct=function(n)
				game:unregisterDialog(d)
				self:petNameGeneratorDialog(player, pet)
				return
			end}
		})
	rows[nrow+1].buttons_width = rows[nrow+1][1].w

	local width = w or math.min(max_w, math.max(text_width + 20, max_buttons_width + 20))
	local height = h or math.min(max_h, text_height + 10 + nrow*button_height)
	local uis = {
		{left = (width - text_width)/2, top = 3, ui=require("engine.ui.Textzone").new{width=text_width, height=text_height, text=text, can_focus=false}}
	}

	top = math.max(text_height, text_height + (height - text_height - nrow*button_height - 5)/2)
	
	--Short buffer space because a pet tile with flame wings can be quite tall.
	top = top + 52

	--We'll put a nice image of the Outrider pet right here:
	uis[#uis+1] = {left=(width-96)/2, top=top, ui=ActorFrame.new{actor=pet, w=96, h=96}}
	top = top + 96

	--And then do the usual row routine to display each row of buttons:
	for i, row in ipairs(rows) do
		left = (width - row.buttons_width - (#row - 1)*button_spacing)/2
		top = top + button_height
		--Let's add a little bit more buffer space before the final row
		if i == #rows then top = top + math.ceil(button_height/4) end
		if top > max_h - button_height - d.iy then break end
		for j, button in ipairs(row) do
			uis[#uis+1] = {left=left, top=top, ui=button}
			left = left + button.w + button_spacing
		end
	end
	d:loadUI(uis)

	if uis[default + 1] then d:setFocus(uis[default + 1])
	elseif uis[escape + 1] then d:setFocus(uis[escape + 1])
	end
	d:setupUI(not w, not h)
	game:registerDialog(d)
	return d
end