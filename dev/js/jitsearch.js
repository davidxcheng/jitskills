(function() {
  var filterByDepartments, findSkilledConsultants, formatListingOfSkills, getDayByDayUtilizationOfConsultant, getDepartmentsFromDocument, getIntersectingProjects, getWantedSkillsFromDocument, initDateRange, initUtilization, jitDateFilter, jitSkillFilter, normalizeSearchTerm, root, search, txtJitDate, txtWantedSkills;
  var __hasProp = Object.prototype.hasOwnProperty, __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (__hasProp.call(this, i) && this[i] === item) return i; } return -1; };

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  $(document).ready(function() {
    root.jitskills = {};
    $.getJSON('../js/db.json', function(json) {
      var dep, haystack, skill, _i, _len, _ref;
      root.jitskills.db = json;
      _ref = root.jitskills.db.departments;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        dep = _ref[_i];
        $('#departments').append("<span class='filter-button'>" + dep.name + "</span>");
      }
      haystack = (function() {
        var _j, _len2, _ref2, _results;
        _ref2 = root.jitskills.db.skills;
        _results = [];
        for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
          skill = _ref2[_j];
          _results.push(skill.name);
        }
        return _results;
      })();
      return $('#txtWantedSkills').focus();
    });
    return $("span.filter-button").live("click", function(e) {
      var $teams, department, departmentFilters;
      department = this.innerHTML;
      departmentFilters = getDepartmentsFromDocument();
      if (__indexOf.call(departmentFilters, department) >= 0) {
        $teams = $("#teams").fadeOut();
        $("#organization h3").fadeOut("normal", function() {
          return $(this).html("Teams").fadeIn();
        });
        return $("#departments").slideUp("normal", function() {
          var dep, team, teams, _i, _j, _len, _len2, _ref;
          _ref = (function() {
            var _j, _len, _ref, _results;
            _ref = root.jitskills.db.departments;
            _results = [];
            for (_j = 0, _len = _ref.length; _j < _len; _j++) {
              dep = _ref[_j];
              if (dep.name === department) _results.push(dep.teams);
            }
            return _results;
          })();
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            teams = _ref[_i];
            for (_j = 0, _len2 = teams.length; _j < _len2; _j++) {
              team = teams[_j];
              $teams.append("<span class='filter-button'>" + team + "</span>");
            }
          }
          return $teams.slideDown("normal");
        });
      } else {
        $("#organizationFilter").append("<span class='filter' data-department='" + department + "'>" + department + " <a href='#' class='removeFilter'>&nbsp;</a></span>");
        return search({
          departments: getDepartmentsFromDocument(),
          wantedSkills: getWantedSkillsFromDocument()
        });
      }
    });
  });

  search = function(clues) {
    var consultants, departments, jitDate, skilled, theSkilled, wantedSkills, _i, _len;
    clues = clues || {};
    wantedSkills = clues.wantedSkills || [];
    jitDate = clues.jitDate || Date.today();
    departments = clues.departments || [];
    consultants = filterByDepartments(departments);
    theSkilled = findSkilledConsultants(consultants, wantedSkills);
    for (_i = 0, _len = theSkilled.length; _i < _len; _i++) {
      skilled = theSkilled[_i];
      skilled.utilization = initDateRange(jitDate);
      skilled.utilization.days = getDayByDayUtilizationOfConsultant(skilled, jitDate);
    }
    $('div#items').empty();
    $('#itemTemplate').tmpl(theSkilled).appendTo('div#items');
    $('.jitDate').text(jitDate.toString("ddd dd MMM"));
    return formatListingOfSkills();
  };

  getDayByDayUtilizationOfConsultant = function(consultant, jitDate) {
    var date, dates, intersectingProjects, proj, projectEndDate, projectStartDate, utilization;
    dates = consultant.utilization.dates;
    utilization = [];
    intersectingProjects = getIntersectingProjects(consultant, jitDate);
    initUtilization(utilization, dates);
    proj = 0;
    while (proj < intersectingProjects.length) {
      projectStartDate = new Date(intersectingProjects[proj].startdate);
      projectEndDate = new Date(intersectingProjects[proj].enddate);
      date = 0;
      while (date < dates.length) {
        if (dates[date].getDay() === 0 || dates[date].getDay() === 6) {
          date++;
          continue;
        }
        if (dates[date].between(projectStartDate, projectEndDate)) {
          utilization[date].hours = '8';
        }
        date++;
      }
      proj++;
    }
    return utilization;
  };

  filterByDepartments = function(departments) {
    var c, _i, _len, _ref, _ref2, _results;
    if (departments.length === 0) return jitskills.db.consultants;
    _ref = jitskills.db.consultants;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      c = _ref[_i];
      if (_ref2 = c.department, __indexOf.call(departments, _ref2) >= 0) {
        _results.push(c);
      }
    }
    return _results;
  };

  formatListingOfSkills = function() {
    var s, _i, _len, _ref, _results;
    _ref = document.getElementsByClassName('skills');
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      s = _ref[_i];
      _results.push(s.innerHTML = s.innerHTML.replace(/,/g, ', '));
    }
    return _results;
  };

  findSkilledConsultants = function(consultants, wantedSkills) {
    var c, skill, _i, _len;
    for (_i = 0, _len = wantedSkills.length; _i < _len; _i++) {
      skill = wantedSkills[_i];
      consultants = (function() {
        var _j, _len2, _results;
        _results = [];
        for (_j = 0, _len2 = consultants.length; _j < _len2; _j++) {
          c = consultants[_j];
          if (c.skills.indexOf(skill) !== -1) _results.push(c);
        }
        return _results;
      })();
    }
    return consultants;
  };

  normalizeSearchTerm = function(searchTerm) {
    var skill, skills;
    return skills = (function() {
      var _i, _len, _ref, _results;
      _ref = jitskills.db.skills;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        skill = _ref[_i];
        if (skill.tags.indexOf(searchTerm.toLowerCase()) !== -1) {
          _results.push(skill.name);
        }
      }
      return _results;
    })();
  };

  txtWantedSkills = $('#txtWantedSkills');

  jitSkillFilter = $('#jitSkillFilters');

  txtWantedSkills.keyup(function(e) {
    var allWantedSkills, skill, skills, _i, _len;
    if (txtWantedSkills.val().length === 0) return;
    skills = normalizeSearchTerm(txtWantedSkills.val() || []);
    if (!skills.length) return;
    for (_i = 0, _len = skills.length; _i < _len; _i++) {
      skill = skills[_i];
      jitSkillFilter.append("<span class='filter' data-skill='" + skill + "'>" + skill + " <a href='#' class='removeFilter'>&nbsp;</a></span>");
    }
    allWantedSkills = skills.concat(getWantedSkillsFromDocument());
    if (allWantedSkills.length !== 0) {
      return search({
        wantedSkills: allWantedSkills
      });
    }
  });

  $('a.removeFilter').live("click", function(e) {
    return $(e.currentTarget.parentNode).fadeOut("fast", function() {
      $(this).remove();
      return search({
        wantedSkills: getWantedSkillsFromDocument(),
        departments: getDepartmentsFromDocument()
      });
    });
  });

  txtJitDate = $('#txtJitDate');

  jitDateFilter = $('#jitDateFilter');

  txtJitDate.keyup(function(e) {
    var date;
    date = Date.parse(txtJitDate.val()) || Date.today();
    jitDateFilter.empty().append("<span class='filter'>" + (date.toString('ddd d MMM yyyy')) + "<a href='#' class='removeFilter'>&nbsp;</a></span>");
    return search({
      jitDate: date,
      wantedSkills: getWantedSkillsFromDocument(),
      departments: getDepartmentsFromDocument()
    });
  });

  getWantedSkillsFromDocument = function() {
    var filterSkills;
    filterSkills = [];
    $("#jitSkillFilters span.filter").each(function(index) {
      return filterSkills.push($(this).data("skill"));
    });
    return filterSkills;
  };

  getDepartmentsFromDocument = function() {
    var departments;
    departments = [];
    $("#organizationFilter span").each(function(index) {
      return departments.push($(this).data("department"));
    });
    return departments;
  };

  initUtilization = function(utilization, dates) {
    var day, _results;
    day = 0;
    _results = [];
    while (day < dates.length) {
      utilization.push({
        date: dates[day],
        hours: '0'
      });
      if (dates[day].getDay() === 0 || dates[day].getDay() === 6) {
        utilization[day].hours = '';
      }
      _results.push(day++);
    }
    return _results;
  };

  getIntersectingProjects = function(consultant, jitDate) {
    var endDate, intersectors, project, startDate;
    startDate = jitDate.clone();
    endDate = jitDate.clone();
    startDate.add(-7).days();
    endDate.add(21).days();
    return intersectors = (function() {
      var _i, _len, _ref, _results;
      _ref = consultant.projects;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        project = _ref[_i];
        if (new Date(project.startdate).isBefore(endDate) && new Date(project.enddate).isAfter(startDate)) {
          _results.push(project);
        }
      }
      return _results;
    })();
  };

  initDateRange = function(jitDate) {
    var currentDate, dateRange, daysLeftInMonth, i, month_daysLeftInRange, noOfDaysInRange, week_daysLeftInRange;
    noOfDaysInRange = 27;
    dateRange = {
      dates: [],
      days: [],
      weeks: [],
      months: []
    };
    currentDate = jitDate.clone();
    currentDate.add(-4).days();
    i = 0;
    week_daysLeftInRange = noOfDaysInRange;
    month_daysLeftInRange = noOfDaysInRange;
    while (i < noOfDaysInRange) {
      dateRange.dates.push(currentDate.clone());
      if (!dateRange.weeks.some(function(element) {
        return element.name === currentDate.getWeek();
      })) {
        dateRange.weeks.push({
          name: currentDate.getWeek(),
          firstDayInRange: i,
          length: week_daysLeftInRange < 7 ? week_daysLeftInRange : 7 - (currentDate.getDay() === 0 ? 6 : currentDate.getDay() - 1)
        });
        week_daysLeftInRange -= dateRange.weeks.slice(-1)[0].length;
      }
      if (!dateRange.months.some(function(element) {
        return element.name === currentDate.toString("MMMM");
      })) {
        daysLeftInMonth = Date.getDaysInMonth(currentDate.getYear(), currentDate.getMonth()) - (+currentDate.toString("dd") - 1);
        dateRange.months.push({
          name: currentDate.toString("MMMM"),
          firstDayInRange: i,
          length: month_daysLeftInRange < daysLeftInMonth ? month_daysLeftInRange : daysLeftInMonth
        });
        month_daysLeftInRange -= dateRange.months.slice(-1)[0].length;
      }
      currentDate.add(1).days();
      i++;
    }
    return dateRange;
  };

}).call(this);
