// Socket.io setup
var socket = new io.Socket(); 
socket.on('connect', function(){ console.log('Connected'); });
socket.on('message', handle_msg); 
socket.on('disconnect', function(){ console.log('Disconnected'); }); 
socket.connect();

// Make dummy console.log on browsers that don't define it.
if (typeof window.console == 'undefined') {
    window.console = {log: function() {}};
}

function classify() {
    console.log('Classifying, yo?');
    socket.send({seq: $('#fasta').val()});
    $('#results-splitter').show();
    $('#tsvm-results').html('<div style="text-align: center">Calculating...<br/><img src="spinner.gif"/><br/><br/><input class="cancel-button" type="submit" value="Cancel Triplet-SVM" onclick="cancel_tsvm()"></div>')
    $('#mipred-results').html('<div style="text-align: center">Calculating...<br/><img src="spinner.gif"/><br/><br/><input class="cancel-button" type="submit" value="Cancel MiPred" onclick="cancel_mipred()"></div>')
}

function handle_msg(msg) {
    console.log('Message:', msg);
    if (msg.triplet_svm) {
	$('#tsvm-results').html(msg.triplet_svm);
    }

    if (msg.mipred) {
	$('#mipred-results').html(msg.mipred);
    }
}

function cancel_tsvm() {
    socket.send({abort: 'triplet-svm'});
}

function cancel_mipred() {
    socket.send({abort: 'mipred'});
}

function show_example() {
    $('#fasta').val(">ppy-mir-1207 MI0015191\nGCAGGGCUGGCAGGGAGGCAGGGAGGGGCUGGCUGGGCCUGGUAGUGGGCAUCAGCUGGCCCUCAUUUCUUAAGACAGCACUCCUGU\n>eca-mir-1204 MI0012754\nGCCUCGUGGCCUGGUCCCCACUAUUUGAGAAGAGUCACAUCUCGGAGGUGAGGACCGCCUCGUGGUA\n>ppy-mir-1909 MI0015276\nCAUCCAGGACAAUGGUGAGUGCCGGUGUUGCCCUGGGGCCGUCCCUGCGUGGGGGCCGGGUGCUCACCGCAUCUGCCC");
    return false;
}