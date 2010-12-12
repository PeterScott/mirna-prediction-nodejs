Web server for Triplet-SVM and MiPred
=====================================

Triplet-SVM and MiPred are *ab initio* tools for predicting whether an
RNA sequence is a precursor micro RNA (pre-miRNA). They rely on local
structural features of the RNA sequences, and use machine learning
methods to handle the classification. This provides a snazzy web
interface to both of them, using [node.js](http://nodejs.org/) and
[socket.io](http://socket.io/) to provide a less clunky experience
than is typical.

Installing
----------

You will need the following dependencies:

* [libsvm](http://www.csie.ntu.edu.tw/~cjlin/libsvm/)

* [R](http://www.r-project.org/), and the [randomForest](http://cran.r-project.org/web/packages/randomForest/) package for it.

* [Vienna RNA](http://www.tbi.univie.ac.at/~ivo/RNA/)

* [node.js](http://nodejs.org/), version 0.3.1 or higher.

* The [socket.io](http://socket.io/) and [paperboy](https://github.com/felixge/node-paperboy) packages for node.js, which you can install with [npm](https://github.com/isaacs/npm).

Once you have all these, make sure that the `svm-classify` program
from libsvm is in your `PATH`, and run the server:

    $ node server.js

Then just point your web browser at http://localhost:8080/ and enjoy!

Contributing
------------

This is no longer being actively maintained. If you have a use for it,
and you would like to take over the project, just fork it on
GitHub. You have my blessing.

Peter Scott,

December 2010