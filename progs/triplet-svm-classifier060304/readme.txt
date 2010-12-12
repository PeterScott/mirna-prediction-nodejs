triplet-SVM classifier package

-----------------------------------------------------------------------------------
About triplet-SVM classifier: 
This program is developed for predicting a query sequence with hairpin structure as a real miRNA precursor or not. 
The triplet-SVM classifier analyzes the triplet elements of the query and predicts it using a SVM classifier.
The SVM classifier is previously trained based on the triplet element features of a set of real miRNA precursors and a set of pseudo-miRNA hairpins.
The details are in ref[1].

-----------------------------------------------------------------------------------
How to use triplet-SVM classifier:
triplet-SVM classifier runs directly on Linux with Perl compiler.

triplet-SVM classifier is divided into three parts:
1) predict the secondary structures of the queries using RNAfold program, see ref[2].
2) make a triplet-element format file for the queries.
3) predict the queries as real miRNA precursors or not using Libsvm program see ref[3].

As an example:
1) there is a file "human_pre-miRNA_sequence.txt" contains 40 un-redundant human miRNA precursors from ref[4].
   RNAfold predicted their secondary structures and stored in file "human_pre-miRNA_secondary_structure.txt".

2) command would be something like:
   
   perl triplet_svm_classifier.pl human_pre-miRNA_secondary_structure.txt predict_format.txt 22
   
	   Note: The last parameter ( 22 in this example) can be changed according to the demand. 
	   	 In some cases, the query sequence contains multiple loops, the program will retrieve the stem-loop sub-structure with over 22 paired bases.
	   
	         Besides the result file (predict_format.txt in this example), there are two temp files, "1.txt" and "2.txt", will be created.
	         In "examples" directory, there are "1.txt" and "2.txt" as the instances.
	         If the submitted sequences contained other characters except A, C, G and U, the program will delete these sequences.
	         And the temp results are kept in "1.txt" file. So, the sequences in "1.txt" might be equal to or less than the submitted sequences.
	         The program will give a order number for each kept sequences, then will retrieve all stem-loops with over 22 paired bases in each submitted sequence.
	         All stem-loops are kept in "2.txt" file.
	         
	         For examples,
	         The first submitted sequences in "1.txt" is below:
	         >hsa-mir-492|chr_12|93730667|93730739|73|+|9    93730667    73
		 AUCGAGGACCUGCGGGACAAGAUUCUUGGUGCCACCAUUGAGAACGCCAGGAUUGUCCUGCAGAUCAACAAUG
		 ...(..((.(((((((((((...((((((((.............))))))))))))))))))).))..).... (-29.82)
		 
		 The corresponding retrieved stem-loop in "2.txt" is below:
		 >8_4_69
		 GAGGACCUGCGGGACAAGAUUCUUGGUGCCACCAUUGAGAACGCCAGGAUUGUCCUGCAGAUCAAC
		 (..((.(((((((((((...((((((((.............))))))))))))))))))).))..)
    		 
    		 The title ">8_4_69" means that this stem-loop is generated from No.8 submitted sequence, and the start and end positions of stem-loop are 4 and 69 on the original sequence, respectively.
   		 
   		 The 1.txt and 2.txt files can be used to compare with the submitted sequences.
   
3) copy the file "predict_format.txt" (the triplet elements of the queries) and the a model file "trainset_hsa163_cds168_unite.txt.model" to libsvm local directory. And the command would be something like:

   svm-predict predict_format.txt trainset_hsa163_cds168_unite.txt.model predict_result.txt

The file "predict_result.txt" is prediction results for queries.

Note: the 1) and 3) steps need the third-party softwares, namely RNAfold and Libsvm packages.
RNAfold can be downloaded from http://www.tbi.univie.ac.at/~ivo/RNA/.
Libsvm can be downloaded from http://www.csie.ntu.edu.tw/~cjlin/libsvm/. Please use version 2.36, which can be downloaded on http://www.csie.ntu.edu.tw/~cjlin/libsvm/oldfiles/.
And both softwares should be compiled in local PC.


-----------------------------------------------------------------------------------
The triplet-SVM classifier package contains: 

readme.txt
		
programs:	
	triplet_svm_classifier.pl    -- which sequentially calls four programs
	
	1_check_query_content.pl                -- delete the queries that contain other characters except A, C, G and U.
	2_get_stemloop.pl			-- retrieve stem-loop over a given number of paired bases.
	3_step_triplet_coding_for_queries.pl    -- coding the queries using triplet elements.
	4_libsvm_format.pl                      -- make a libsvm format file for predicting the queries by libsvm. 
	
examples: (in subdirectory "examples/")
	human_pre-miRNA_sequence.txt -- this file contain 40 un-redundant human miRNA precursors from ref[4] as query examples.
	human_pre-miRNA_secondary_structure.txt -- the file contain the secondary structures of 40 miRNA precursors, which are predicted by RNAfold.
	predict_format.txt -- this file is a final output file when use "triplet_svm_classifier.pl" to process query file "human_pre-miRNA_secondary_structure.txt".
			      This file will be used as the input for libsvm program to predict.
	1.txt and 2.txt    -- temp files.
	predict_result.txt -- this file is the prediction results of 40 queries using libsvm.
	
models: (in subdirectory "models/")
	trainset_hsa163_cds168_unite.txt.model -- this model is trained based on 163 human pre-miRNAs and 168 pseudo-miRNA hairpins using libsvm.
			

-----------------------------------------------------------------------------------
References:
1. Chenghai Xue, Fei Li, Tao He, Guo-Ping Liu, Yanda Li, Xuegong Zhang: Classification of Real and Pseudo MicroRNA Precursors Using Local Structure-Sequence Features and Support Vector Machine. BMC Bioinformatics, 6: 310, 2005.
2. Hofacker IL, Fontana W, Stadler PF, Bonhoeffer S, Tacker M, Schuster P: Fast folding and comparison of RNA secondary structures. Monatshefte f Chemie 1994, 125:167-188.
3. Chang C-C, Lin C-J: LIBSVM : a library for support vector machines. 2001.
4. Bentwich I, Avniel A, Karov Y, Aharonov R, Gilad S, Barad O, Barzilai A, Einat P, Einav U, Meiri E et al: Identification of hundreds of conserved and nonconserved human microRNAs. Nat Genet 2005, 37:766-770.



-----------------------------------------------------------------------------------
Chenghai XUE
PHD candidate
Institute of Automation, Chinese Academy of Sciences
China

Email: chenghai.xue@mail.ia.ac.cn

March 04, 2006
