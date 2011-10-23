root = exports ? this

root.jitskills = {}

$.getJSON '../js/db.json', (json) ->
  root.jitskills.db = json

###
$('#btnSearch').live 'click', (e) ->
	e.preventDefault()
	search()
###

search = () ->
	jitDate = Date.parse(txtJitDate.val())
	wantedSkill = normalizeSearchTerm($('#txtWantedSkills').val())
	theSkilled = findSkilledConsultants wantedSkill.toString()

	# Default to today if no date is specified
	jitDate = jitDate or Date.today()

	for skilled in theSkilled
		skilled.utilization = getUtilizationForConsultant(skilled, jitDate)

	$('div#items').empty();
	$('#itemTemplate').tmpl(theSkilled).appendTo('div#items')
	$('.jitDate').text(jitDate.toString("ddd dd MMM"))
	formatListingOfSkills()

formatListingOfSkills = ->
	for s in document.getElementsByClassName('skills')
		s.innerHTML = s.innerHTML.replace(/,/g, ', ')

findSkilledConsultants = (wantedSkill) ->
	experts = (c for c in jitskills.db.consultants when c.skills.indexOf(wantedSkill) != -1)

normalizeSearchTerm = (searchTerm) ->
	skills = (skill.name for skill in jitskills.db.skills when skill.tags.indexOf(searchTerm.toLowerCase()) != -1)

txtWantedSkills = $('#txtWantedSkills')
jitSkillFilter = $('#jitSkillFilter')

txtWantedSkills.keyup (e) ->
	if txtWantedSkills.val().length is 0 then return

	skills = normalizeSearchTerm txtWantedSkills.val()
	if skills.length
		jitSkillFilter.removeClass("hide").find('span').text(skill.toString())
	else
		jitSkillFilter.addClass("hide")

	search()

txtJitDate = $('#txtJitDate')
jitDateFilter = $('#jitDateFilter')

txtJitDate.keyup (e) ->
	date = Date.parse(txtJitDate.val())
	if date != null
		jitDateFilter.removeClass("hide").find('span').text(date.toString "ddd d MMM yyyy")
	else
		jitDateFilter.addClass("hide")

	search()

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
