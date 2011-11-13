root = exports ? this

$(document).ready () ->
	root.jitskills = {}

	$.getJSON '../js/db.json', (json) ->
		root.jitskills.db = json

		for dep in root.jitskills.db.departments
			$('#departments').append("<span class='filter-button'>#{dep.name}</span>")

	$("span.filter-button").live "click", (e) ->
		department = this.innerHTML
		departmentFilters = getDepartmentsFromDocument()

		if department in departmentFilters
			$teams = $("#teams").fadeOut()
			$("#organization h3").fadeOut "normal", () ->
				$(this).html("Teams").fadeIn()

			$("#departments").slideUp "normal", () ->
				for teams in (dep.teams for dep in root.jitskills.db.departments when dep.name is department)
					$teams.append("<span class='filter-button'>#{team}</span>") for team in teams

				$teams.slideDown("normal");
		else
			$("#organizationFilter").append("<span class='filter' data-department='#{ department }'>#{ department } <a href='#' class='removeFilter'>&nbsp;</a></span>")

			search
				departments: getDepartmentsFromDocument()
				wantedSkills: getWantedSkillsFromDocument()

search = (clues) ->
  clues = clues || {}
  wantedSkills = clues.wantedSkills || []
  jitDate = clues.jitDate or Date.today()
  departments = clues.departments || []

  consultants = filterByDepartments departments
  theSkilled = findSkilledConsultants consultants, wantedSkills
  #jitDateRange = initDateRange jitDate

  for skilled in theSkilled
    skilled.utilization = initDateRange jitDate
    skilled.utilization.days = getDayByDayUtilizationOfConsultant(skilled, jitDate)

  $('div#items').empty();
  $('#itemTemplate').tmpl(theSkilled).appendTo('div#items')
  $('.jitDate').text(jitDate.toString("ddd dd MMM"))
  formatListingOfSkills()

# Blah
getDayByDayUtilizationOfConsultant = (consultant, jitDate) ->
  dates = consultant.utilization.dates
  utilization = []
  intersectingProjects = getIntersectingProjects(consultant, jitDate)
  initUtilization(utilization, dates)

  proj = 0

  while proj < intersectingProjects.length
    projectStartDate = new Date(intersectingProjects[proj].startdate)
    projectEndDate = new Date(intersectingProjects[proj].enddate)

    date = 0

    while date < dates.length
      if dates[date].getDay() == 0 or dates[date].getDay() == 6
        date++
        continue

      if dates[date].between(projectStartDate, projectEndDate)
        utilization[date].hours = '8'

      date++

    proj++

  return utilization

filterByDepartments = (departments) ->
	return jitskills.db.consultants if departments.length is 0
	c for c in jitskills.db.consultants when c.department in departments

formatListingOfSkills = ->
	for s in document.getElementsByClassName('skills')
		s.innerHTML = s.innerHTML.replace(/,/g, ', ')

findSkilledConsultants = (consultants, wantedSkills) ->
	for skill in wantedSkills
		consultants = (c for c in consultants when c.skills.indexOf(skill) != -1)

	return consultants

normalizeSearchTerm = (searchTerm) ->
	skills = (skill.name for skill in jitskills.db.skills when skill.tags.indexOf(searchTerm.toLowerCase()) != -1)

txtWantedSkills = $('#txtWantedSkills')
jitSkillFilter = $('#jitSkillFilters')

txtWantedSkills.keyup (e) ->
	if txtWantedSkills.val().length is 0 then return

	skills = normalizeSearchTerm txtWantedSkills.val() || []

	for skill in skills
		jitSkillFilter.append("<span class='filter' data-skill='#{ skill }'>#{ skill } <a href='#' class='removeFilter'>&nbsp;</a></span>")

	search({wantedSkills: skills }) if skills.length isnt 0

getWantedSkillsFromDocument = () ->
	filterSkills = []
	$("#jitSkillFilters span").each (index) ->
  		filterSkills.push $(this).data("skill")

	return filterSkills

getDepartmentsFromDocument = () ->
	departments = []
	$("#organizationFilter span").each (index) ->
		departments.push $(this).data("department")

	return departments

$('a.removeFilter').live "click", (e) ->
	$(e.currentTarget.parentNode).fadeOut "fast", () ->
		$(this).remove()
		search
			wantedSkills: getWantedSkillsFromDocument()
			departments: getDepartmentsFromDocument()

txtJitDate = $('#txtJitDate')
jitDateFilter = $('#jitDateFilter')

txtJitDate.keyup (e) ->
	date = Date.parse(txtJitDate.val()) or Date.today()
	jitDateFilter.empty().append("<span class='filter'>#{date.toString 'ddd d MMM yyyy'}<a href='#' class='removeFilter'>&nbsp;</a></span>")

	search
		jitDate: date
		wantedSkills: getWantedSkillsFromDocument()
		departments: getDepartmentsFromDocument()

initUtilization = (utilization, dates) ->
	day = 0
	while day < dates.length
		utilization.push({date: dates[day], hours: '0'})
		if dates[day].getDay() == 0 or dates[day].getDay() == 6
			utilization[day].hours = ''
		day++

getIntersectingProjects = (consultant, jitDate) ->
	startDate = jitDate.clone()
	endDate = jitDate.clone()

	startDate.add(-7).days()
	endDate.add(21).days()

	intersectors = (project for project in consultant.projects when (new Date(project.startdate).isBefore(endDate) and new Date(project.enddate).isAfter(startDate)))

initDateRange = (jitDate) ->
  noOfDaysInRange = 29

  dateRange =
    dates: []
    days: []
    weeks: []
    months: []

  currentDate = jitDate.clone()
  # Start the range x days before the requested date..
  currentDate.add(-7).days()
  i = 0
  week_daysLeftInRange = noOfDaysInRange
  month_daysLeftInRange = noOfDaysInRange

  # ..and include y days in the range.
  while i < noOfDaysInRange
    dateRange.dates.push(currentDate.clone())

    unless dateRange.weeks.some((element) ->
      element.name is currentDate.getWeek()
    )
      dateRange.weeks.push
        name: currentDate.getWeek()
        firstDayInRange: i
        length: if week_daysLeftInRange < 7 then week_daysLeftInRange else 7 - (if currentDate.getDay() is 0 then 6 else currentDate.getDay() - 1)
      week_daysLeftInRange -= dateRange.weeks.slice(-1)[0].length

    unless dateRange.months.some((element) ->
      element.name is currentDate.toString "MMMM"
    )
      daysLeftInMonth = Date.getDaysInMonth(currentDate.getYear(), currentDate.getMonth()) - (+currentDate.toString("dd") - 1)

      dateRange.months.push
        name: currentDate.toString "MMMM"
        firstDayInRange: i
        length: if month_daysLeftInRange < daysLeftInMonth then month_daysLeftInRange else daysLeftInMonth
      month_daysLeftInRange -= dateRange.months.slice(-1)[0].length

    currentDate.add(1).days()
    i++

  return dateRange