var http	= require('http');
var paperboy	= require('paperboy');
var path	= require('path');
var io		= require('socket.io');
var util	= require('util');
var classify    = require('./classify');
var exec        = require('child_process').exec;

var WEB_ROOT = path.join(path.dirname(__filename), 'webroot');
var server = http.createServer(function(req, res) {
    paperboy.deliver(WEB_ROOT, req, res);
});
server.listen(8080);

// Kill a child process, and all its children. Grim!
function kill_nicely(child) {
    if (!child) return;		// Ignore null children
    exec('ps -o pid,ppid -ax | grep "' + child.pid + '$" | sed s/' + child.pid + '$//g | xargs kill',
	 function() {
	     child.kill('SIGTERM');
	     setTimeout(function() { child.kill('SIGKILL'); }, 5000);
	 });
}

var socket = io.listen(server);
socket.on('connection', function(client) {
    client.on('message', function(msg) {
	console.log(msg);

	if (msg.seq) {
	    // Kill any existing child processes
	    kill_nicely(client.tsvm_child);
	    kill_nicely(client.mipred_child)

	    // Create a Triplet-SVM child process for this client.
	    client.tsvm_child = classify.run_triplet_svm(msg.seq, function(result_html) {
		client.send({triplet_svm: result_html});
	    });

	    // Create a MiPred child process for this client.
	    client.mipred_child = classify.run_mipred(msg.seq, function(result_html) {
		client.send({mipred: result_html});
	    });
	}

	// Handle abort messages. When the child is aborted, send back
	// a confirmation message.
	if (msg.abort) {
	    if (msg.abort === 'triplet-svm') {
		var old_msg = classify.triplet_svm_timeout_msg;
		classify.triplet_svm_timeout_msg = "<p><b>Triplet-SVM aborted.</b></p>";
		kill_nicely(client.tsvm_child); client.tsvm_child = null;
		setTimeout(function() { classify.triplet_svm_timeout_msg = old_msg; }, 1000);
	    }

	    if (msg.abort === 'mipred') {
		var old_msg = classify.mipred_timeout_msg;
		classify.mipred_timeout_msg = "<p><b>MiPred aborted.</b></p>";
		kill_nicely(client.mipred_child); client.mipred_child = null;
		setTimeout(function() { classify.mipred_timeout_msg = old_msg; }, 1000);
	    }
	}
    });

    client.on('disconnect', function() {
	console.log('Client disconnected: ' + client.sessionId);
    });
});