-- ReplicatedStorage.Shared.Crew
-- Co-op schools (CrewService): up to four principals run ONE school together. The school belongs to
-- its host (their plot, their save); everyone else in the crew plays for it. Every player carries a
-- "SchoolId" attribute: their own UserId, or their host's while they help run a friend's school.
-- Anything owned by a school (seated kids, bench kids, pens, raid goons) is marked with the school's
-- id, so "is this mine?" is always Crew.owns(player, thatId), on the server and on the client.
local Crew = {}

function Crew.schoolId(player)
	return player:GetAttribute("SchoolId") or player.UserId
end

-- do these two players play for the same school?
function Crew.same(a, b)
	return a == b or Crew.schoolId(a) == Crew.schoolId(b)
end

-- is something marked with this owner id (a UserId) this player's school's?
function Crew.owns(player, ownerId)
	return ownerId ~= nil and ownerId ~= 0 and Crew.schoolId(player) == ownerId
end

-- the player's co-op role ("President", "Teacher", "Monitor", "Recruiter"), nil when playing solo
function Crew.role(player)
	return player:GetAttribute("Role")
end

-- does this player's role perk apply? (perks are for crews: two or more running the school)
function Crew.perk(player, role)
	return player:GetAttribute("Role") == role and (player:GetAttribute("CrewSize") or 1) >= 2
end

return Crew
