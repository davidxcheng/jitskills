var jitskills = {};

$(document).ready(function(){
	$.getJSON('../js/db.json', function(json){
		jitskills.db =  json;
	});
});

