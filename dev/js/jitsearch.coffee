root = exports ? this

root.jitskills = {}

$.getJSON '../js/db.json', (json) ->
  root.jitskills.db = json

$(document).ready (jitskills) ->
	sidebar = $('#sidebar')

	for dep in jitskills.db.departments
		sidebar.append(dep)

search = (clues) ->
	clues = clues || {}
	wantedSkills = clues.wantedSkills || []
	jitDate = clues.jitDate or Date.today()

	theSkilled = findSkilledConsultants wantedSkills

	for skilled in theSkilled
		skilled.utilization = getUtilizationForConsultant(skilled, jitDate)

	$('div#items').empty();
	$('#itemTemplate').tmpl(theSkilled).appendTo('div#items')
	$('.jitDate').text(jitDate.toString("ddd dd MMM"))
	formatListingOfSkills()

formatListingOfSkills = ->
	for s in document.getElementsByClassName('skills')
		s.innerHTML = s.innerHTML.replace(/,/g, ', ')

findSkilledConsultants = (wantedSkills) ->
	experts = jitskills.db.consultants
	for skill in wantedSkills
		experts = (c for c in experts when c.skills.indexOf(skill) != -1)

	return experts

normalizeSearchTerm = (searchTerm) ->
	skills = (skill.name for skill in jitskills.db.skills when skill.tags.indexOf(searchTerm.toLowerCase()) != -1)

txtWantedSkills = $('#txtWantedSkills')
jitSkillFilter = $('#jitSkillFilters')

txtWantedSkills.keyup (e) ->
	if txtWantedSkills.val().length is 0 then return
	skills = normalizeSearchTerm txtWantedSkills.val() || []

	for skill in skills
		jitSkillFilter.append("<span data-skill='#{ skill }'>#{ skill } <a href='#' class='removeFilter'>&nbsp;</a></span>")

	search({wantedSkills: skills }) if skills.length isnt 0

getWantedSkillsFromDocument = () ->
	filterSkills = []
	$("#jitSkillFilters span").each (index) ->
  		filterSkills.push $(this).data("skill")

	return filterSkills

$('a.removeFilter').live "click", (e) ->
	$(e.currentTarget.parentNode).fadeOut "fast", () ->
		$(this).remove()
		search({wantedSkills: getWantedSkillsFromDocument()})

txtJitDate = $('#txtJitDate')
jitDateFilter = $('#jitDateFilter')

txtJitDate.keyup (e) ->
	date = Date.parse(txtJitDate.val()) or Date.today()
	jitDateFilter.removeClass("hide").find('span').text(date.toString "ddd d MMM yyyy")

	search({jitDate: date, wantedSkills: getWantedSkillsFromDocument()})

getUtilizationForConsultant = (consultant, jitDate) ->
	utilization = []
	jitDateRange = initDateRange jitDate
	intersectingProjects = getIntersectingProjects(consultant, jitDate)

	initUtilization(utilization, jitDateRange)

	proj = 0

	while proj < intersectingProjects.length
		projectStartDate = new Date(intersectingProjects[proj].startdate)
		projectEndDate = new Date(intersectingProjects[proj].enddate)

		day = 0

		while day < jitDateRange.length
			if jitDateRange[day].getDay() == 0 or jitDateRange[day].getDay() == 6
				day++
				continue

			if jitDateRange[day].between(projectStartDate, projectEndDate)
				utilization[day].hours = '8'

			day++

		proj++

	return utilization

initUtilization = (utilization, jitDateRange) ->
	day = 0
	while day < jitDateRange.length
		utilization.push({date: jitDateRange[day], hours: '0'})
		if jitDateRange[day].getDay() == 0 or jitDateRange[day].getDay() == 6
			utilization[day].hours = ''
		day++

getIntersectingProjects = (consultant, jitDate) ->
	startDate = jitDate.clone()
	endDate = jitDate.clone()

	startDate.add(-7).days()
	endDate.add(21).days()

	intersectors = (project for project in consultant.projects when (new Date(project.startdate).isBefore(endDate) and new Date(project.enddate).isAfter(startDate)))

initDateRange = (jitDate) ->
	dateRange = []
	startDate = jitDate.clone()
	startDate.add(-7).days()
	i = 0

	while i < 29
		dateRange.push(startDate.clone())
		startDate.add(1).days()
		i++

	return dateRange
