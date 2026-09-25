-- ServerScriptService.Server.QuizService
-- Pop Quiz: every 10 minutes (at :03, :13, :23 ... UTC) everyone gets a 10-second question with three
-- answers. One try each; a right answer pays 60 seconds of your tuition (at least $100).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Actions = require(script.Parent.Actions)
local Signals = require(script.Parent.Signals)

local QuizService = {}

-- { question, right answer, wrong, wrong }
local QUESTIONS = {
	{ "7 x 8 = ?", "56", "54", "63" },
	{ "What do plants breathe in?", "Carbon dioxide", "Oxygen", "Helium" },
	{ "How many sides does a hexagon have?", "6", "5", "8" },
	{ "Which planet is the Red Planet?", "Mars", "Venus", "Jupiter" },
	{ "12 x 12 = ?", "144", "124", "132" },
	{ "What is H2O?", "Water", "Salt", "Air" },
	{ "How many continents are there?", "7", "5", "9" },
	{ "Which is a mammal?", "Whale", "Shark", "Salmon" },
	{ "What is 100 / 4?", "25", "20", "40" },
	{ "Which word is a noun?", "School", "Quickly", "Jump" },
	{ "The biggest ocean on Earth?", "Pacific", "Atlantic", "Arctic" },
	{ "How many minutes in an hour?", "60", "100", "30" },
	{ "Which is the closest star to Earth?", "The Sun", "Polaris", "Sirius" },
	{ "What freezes at 0 degrees Celsius?", "Water", "Milk only", "Nothing" },
	{ "9 + 10 = ?", "19", "21", "910" },
	{ "Which animal lays eggs?", "Chicken", "Dog", "Cat" },
	{ "A triangle's angles add up to?", "180", "360", "90" },
	{ "What do bees make?", "Honey", "Milk", "Slime" },
	{ "Which is a prime number?", "13", "15", "21" },
	{ "The capital letter of 'apple' is?", "A", "P", "E" },
	{ "How many legs does a spider have?", "8", "6", "10" },
	{ "Which gas do we need to breathe?", "Oxygen", "Carbon dioxide", "Neon" },
	{ "What is 3 squared?", "9", "6", "12" },
	{ "Which season comes after winter?", "Spring", "Summer", "Autumn" },
	{ "Opposite of 'ancient'?", "Modern", "Old", "Antique" },
	{ "How many days in a leap year?", "366", "365", "364" },
	{ "Which one is a vowel?", "E", "B", "T" },
	{ "Largest planet in our solar system?", "Jupiter", "Saturn", "Earth" },
	{ "What's half of 50?", "25", "20", "15" },
	{ "Who writes on the chalkboard?", "The teacher", "The janitor", "The bus" },
}
local EVERY, OFFSET, WINDOW = 600, 180, 10

local current -- { id, answer = index, closes = time, answered = { [player] = true } }
local n = 0

local function shuffle(t)
	for i = #t, 2, -1 do
		local j = math.random(i)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

function QuizService.ask()
	n += 1
	local q = QUESTIONS[math.random(#QUESTIONS)]
	local options = shuffle({ q[2], q[3], q[4] })
	local answer = table.find(options, q[2])
	current = { id = n, answer = answer, closes = workspace:GetServerTimeNow() + WINDOW, answered = {} }
	Remotes.Push:FireAllClients("quiz", { id = n, question = q[1], options = options, closes = current.closes })
	Remotes.Sfx:FireAllClients("SchoolBell")
end

Actions.register("quizAnswer", function(player, p, id, choice)
	local c = current
	if not c or id ~= c.id or type(choice) ~= "number" then return { ok = false, err = "No quiz right now" } end
	if workspace:GetServerTimeNow() > c.closes + 0.5 then return { ok = false, err = "Time's up!" } end
	if c.answered[player] then return { ok = false, err = "One try only!" } end
	c.answered[player] = true
	if choice == c.answer then
		local amount = math.max(100, math.floor((player:GetAttribute("BaseIncome") or 0) * 60))
		Data.addCash(player, amount)
		Remotes.Sfx:FireClient(player, "Cheer")
		Signals.fire("quizRight", player)
		return { ok = true, right = true, amount = amount }
	end
	Remotes.Sfx:FireClient(player, "SadTrombone")
	return { ok = true, right = false, answer = c.answer }
end)

function QuizService.start()
	task.spawn(function()
		local now = workspace:GetServerTimeNow()
		local nextAt = OFFSET + EVERY * math.ceil((now - OFFSET) / EVERY)
		workspace:SetAttribute("QuizAt", nextAt)
		while true do
			task.wait(1)
			if workspace:GetServerTimeNow() >= nextAt then
				nextAt += EVERY
				workspace:SetAttribute("QuizAt", nextAt)
				if #Players:GetPlayers() > 0 then pcall(QuizService.ask) end
			end
		end
	end)
end

return QuizService
