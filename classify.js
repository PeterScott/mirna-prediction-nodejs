var exec = require('child_process').exec;
var fs   = require('fs');
var path = require('path');
var util = require('util');

function joincwd(relpath) {
    return path.join(process.cwd(), relpath);
}

var triplet_svm_dir = joincwd('progs/triplet-svm-classifier060304')
var triplet_svm_tdata = path.join(triplet_svm_dir, 'models',
				  'trainset_hsa163_cds168_unite.txt.model');
var zip3 = 'python ' + joincwd('zip3.py') + ' ';
var zip1 = 'python ' + joincwd('zip1.py') + ' ';
var devnull = ' >/dev/null ';
var mipred_dir = joincwd('progs/MiPred');

// Return a temporary filename
function tempname() {
    return joincwd('tmp/tmp' + Math.random());
}

exports.triplet_svm_timeout_msg = "                                \
<p><b>Error: Triplet-SVM timed out.</b> This seldom happens, since \
Triplet-SVM is a very fast classifier. Perhaps there's something   \
messed up about your data? Or maybe you've hit a weird edge case?  \
A possible approach you could try is to                            \
<a href='http://bioinfo.au.tsinghua.edu.cn/mirnasvm/'>download     \
Triplet-SVM</a> and run it locally.</p>";

exports.mipred_timeout_msg = "            					\
<p><b>Error: MiPred timed out.</b> It can take quite a while, because		\
the people who wrote it didn't put much effort into speeding it up.		\
They just needed it to be fast enough to get publishable results.</p>		\
<p>You can download it from <a href='http://www.bioinf.seu.edu.cn/miRNA/'>	\
the MiPred web site,</a> and run it locally, if you wish.</p>"

// Start running triplet-svm on a given chunk of FASTA text. Returns a
// child process object that can be killed with child.kill(). Will
// call callback with some HTML. Process will time out in 5 minutes.
exports.run_triplet_svm = function(fasta, callback) {
    var file2     = tempname();
    var seqfile   = tempname();
    var secstruct = tempname();
    var svminput  = tempname();
    var svmoutput = tempname();
    fs.writeFileSync(seqfile, fasta);
    var child = 
	exec('cd ' + triplet_svm_dir + ' && RNAfold -noPS <' + seqfile + ' >' + secstruct
	     + ' && perl triplet_svm_classifier.pl ' + secstruct + ' ' + svminput + ' 22 ' + file2 + devnull
	     + ' && svm-predict ' + svminput + ' ' + triplet_svm_tdata + ' ' + svmoutput + devnull
	     + ' && ' + zip3 + [seqfile, file2, svmoutput].join(' '),
	     {timeout: 1000*60*5},
	     function(err, stdout, stderr) {
		 fs.unlink(seqfile);
		 fs.unlink(secstruct);
		 fs.unlink(svminput);
		 fs.unlink(svmoutput);
		 fs.unlink(file2);
		 if (err !== null) {
		     // There was some kind of error. Assume it was a
		     // timeout error, and send back such a message.
		     callback(exports.triplet_svm_timeout_msg);
		 } else {
		     // Success! Send the results back.
		     callback(stdout);
		 }
	     });
    return child;
}

// Start running MiPred on a given chunk of FASTA text. Returns a
// child process object that can be killed with child.kill(). Will
// call callback with some HTML. Process will time out in 5 minutes.
exports.run_mipred = function(fasta, callback) {
    var seqfile   = tempname();
    var tmpdir    = tempname();
    var outfile   = tempname();
    fs.mkdirSync(tmpdir, 0755);
    fs.writeFileSync(seqfile, fasta);
    console.log('cd ' + mipred_dir + ' && ./microRNAcheck_parallel.pl -i ' + seqfile
	     + ' -d ' + tmpdir + ' -f ' + outfile + devnull
	     + ' && rm -R ' + tmpdir + devnull
		+ ' && ' + zip1 + [seqfile, outfile].join(' '))
    var child = 
	exec('cd ' + mipred_dir + ' && ./microRNAcheck_parallel.pl -i ' + seqfile
	     + ' -d ' + tmpdir + ' -f ' + outfile + devnull
	     + ' && rm -R ' + tmpdir + devnull
	     + ' && ' + zip1 + outfile,
	     {timeout: 1000*60*5},
	     function(err, stdout, stderr) {
		 fs.unlink(seqfile);
		 fs.unlink(outfile);
		 if (err !== null) {
		     // There was some kind of error. Assume it was a
		     // timeout error, and send back such a message.
		     callback(exports.mipred_timeout_msg);
		 } else {
		     // Success! Send the results back.
		     callback(stdout);
		 }
	     });
    return child;
}