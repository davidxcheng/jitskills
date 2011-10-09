var express = require('express'),
	app = express.createServer(),
	fs = require('fs');

app.use('/css', express.static(__dirname + '/css'));
app.use('/js', express.static(__dirname + '/js'));

app.get('/jitsearch.html', function(req, res){
	fs.readFile('./html/jitsearch.html', function(error, content){
		if(!error) {
			res.writeHead(200, { content: 'text/html' });
			res.end(content, 'utf-8');
		}
	});
});

app.listen(8000);