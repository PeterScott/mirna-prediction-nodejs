#!/usr/bin/perl
use strict;
use File::Temp;
use Getopt::Std;
use vars qw($opt_d $opt_f $opt_i);
getopts("d:i:f:");
#This software allows parallelization on a unix compute cluster
#To gain full advantage of this, large fasta files should be split into files containing ~10 sequences and this program can be run
#on each file on a separate node, ensuring that the -f option provides unique output file names (alternatively, files named RESULT* 
#will be generated by default and can be concatenated
#Before use, the three global variables below must be set correctly for your system.  This software assumes the RandomForest package is installed
#in R and that RNAFold (of the ViennaRNA package) is compiled on your system

#set this parameter to the location of the file model.Rdata:
my $r_model = "model.RData";

#and set this one to point to your installed R binary
my $r_binary = "R";

#set this to the path to the RNAfold binary
my $rnafold_binary = "RNAfold";

my $usage = "$0 -i input.fa -d temp_directory -f [name of output file (default is to leave it in temp_directory)]\nexample: $0 -i /home/me/input.fa -d /home/me/temp -f /home/me/output.out\nENSURE YOU HAVE SET THE GLOBAL VARIABLES THAT FOLLOW:\n$r_model\n$r_binary\n$rnafold_binary\n";

my $dir = $opt_d || die "$usage";
my $outfile;
if($opt_f){
    $outfile = $opt_f;
}

# variables for global use
my $shuffle_times = 999;

#generate temp file names using File::Temp

my $prefix = "TEMP";
my $InfileName_RNAfold = File::Temp::tempnam( $dir, $prefix );
my $OutfileName_RNAfold = File::Temp::tempnam( $dir, $prefix );
my $RInfile = File::Temp::tempnam( $dir, $prefix );
my $ROutfile = File::Temp::tempnam( $dir, $prefix );
my $FileShuffledSeqs = File::Temp::tempnam( $dir, $prefix );
my $FileProcessedShuffledSeqs = File::Temp::tempnam( $dir, $prefix );
my $R_script = File::Temp::tempnam($dir,$prefix);
my $fileResult = File::Temp::tempnam($dir,"RESULT_");
my $origin_seq = undef;# original data posted from textarea in the webpage
my $command = undef;# a atring used to invoke "system"
my $rtValCmd = -1;#stands for error. must be 0 or 1
my @temp;#temp array(used to write lots of data into $resultPageURL)
my $debugMode = 0;#must be 0 or 1



############################################################################################
#
# Get the parameters and do some data-preprocessing work
# NOTE that preparation of global variables for format translating was also put here 
#
############################################################################################
# list of global variables for format translating
# prepare a variable "$origin_seq" as public data domain for format translating

#READ IN FASTA FORMATTED SEQUENCE HERE
my $fasta_file = $opt_i || die "$usage";
my $origin_seq;# global variable for format translating <!!!><OK>

#load seqs
open F, $fasta_file or die "$!\n";
while(<F>){
  $origin_seq .= $_;
}
close F;
my @seqHead = undef; # global variable for format translating <!!!><OK>
my @seqContent = undef; # global variable for format translating <!!!><OK>
my $tmpSeqVal = undef; # global variable for format translating <!!!><OK>
my $numSeq=0;# global variable for format translating <!!!><OK>

############################################################################################    


#delete the first sequence starter and useless chars before it
my $pos_first_starter = index($origin_seq,">");

$origin_seq = substr($origin_seq,$pos_first_starter+1);

#split and seperate the sequences
my @sequences = split(/>/,$origin_seq);
if($debugMode == 1) {
	print debugOut "\n\nSequences seperated:\n@sequences\n";
}
my @fasta_heads;
my @seqs_len;#added later.(by KevinWang)
for(my $indx = 0; $indx <= $#sequences; $indx++){#seperate the FASTA heads
	my $pos_line_end = index($sequences[$indx],"\n");
	$fasta_heads[$indx] = substr($sequences[$indx],0,$pos_line_end);
	$sequences[$indx] = substr($sequences[$indx],$pos_line_end+1);
	$sequences[$indx] =~ tr/atcgATCGUu/ /c;# convert other chars into space
	$sequences[$indx] =~ tr/\t \r\n\f//d;# delete: tab, return, nextline, etc.
	$sequences[$indx] = uc($sequences[$indx]);#upper case
	$sequences[$indx] =~ tr/T/U/;#change T into U (MAYBE NOT WELL NOW)
	$seqs_len[$indx] = length($sequences[$indx]); # get the length
	if ($debugMode == 1){
		print "<p>FASTA head: $fasta_heads[$indx]</p>";
		print "<p>Sequence content: $sequences[$indx]</p>";
		print debugOut "<p>FASTA head: $fasta_heads[$indx]</p>\n";
		print debugOut "<p>Sequence content: $sequences[$indx]</p>\n";
	}
      }
   

my $num_of_seqs = @sequences; 
   


# form a string as command and invoke another application
open foldIn , ">$InfileName_RNAfold" or die("could not open a file to write for RNAfold binary\n");
foreach my $seq (@sequences) {
	print foldIn "$seq\n";
      }
print foldIn "\@";# @ is needed by "RNAfold"
close(foldIn);
my $comand = "$rnafold_binary \<$InfileName_RNAfold \>$OutfileName_RNAfold\n";

if ($debugMode == 1) {
	print debugOut "Command to invoke \"system\" is: $command\n";
      }
$rtValCmd = system($comand);

if ($rtValCmd == -1 && $debugMode == 1) {
	print debugOut "Error: when invoke RNAfold for pre-judging use.\n";
      }


my @is_hairpins_like;
my @structures;
my @seq_pairs_num;
my @seq_fe;
my @seq_has_multiloops;#boolean
    print "opening $OutfileName_RNAfold\n";
open foldOut, "<$OutfileName_RNAfold" or die ("could not open a file written by RNAfold.exe\n");
for (my $indx = 0; $indx<=$#sequences; $indx++) {
	my $buffer = <foldOut>;# line of odd line number: a sequence
	if($debugMode == 1){
		print debugOut "Total number of sequences is $#sequences\n";
		print debugOut "A buffer read in: $buffer";
		print "<p>A buffer read in: $buffer</p>\n";
	}
	my $buffer = <foldOut>;# line of even line number: result of RNAfold.exe
	chomp($buffer);# do chomp
	if($debugMode == 1){
		print debugOut "A buffer read in: $buffer\n";
		print "<p>A buffer read in: $buffer</p>\n";
	}
	my $space_index = index($buffer," ");
	my $str_pairs = substr($buffer,0,$space_index);
	
	$structures[$indx] = $str_pairs;
	my $str_fe = substr($buffer,$space_index+1);# free energy # ,length($buffer)-2);
	$str_fe =~ tr/)(//d;
	if($debugMode == 1){
		print debugOut "Pre-judge: FE of a sequence: $str_fe\n";
	}
	
	$_ = $str_fe;
  /-\d*\.\d*/; 
  $seq_fe[$indx] = $&; 
  
 	my $structure = $str_pairs;
  if($structure!~ m/\(\.+\)[\.,\(,\)]*\(\.+\)/)
  {
  	my $count = 0;
    my $start = -1;
    while(($start = index($structure,"(",$start))!=-1) 
    {
    	$start++;
      $count++;
    }
    $seq_pairs_num[$indx] = $count;# when determine, use: if($seq_pairs_num[$indx]>=18)
      }
  
  $structure="";
  
  my $indx_first_right_bracket = index($str_pairs,")");
  my $temp = substr($str_pairs,$indx_first_right_bracket);
  my $indx_extra_left_bracket = index($temp,"(");
  if($indx_extra_left_bracket == -1){#no extra left bracket, so there is no multiloop
  	$seq_has_multiloops[$indx] = 0;
  }
  else{
  	$seq_has_multiloops[$indx] = 1;
  }
  #4. determine if this miRNA is a hairpins-like sequence.
  ##########Check#####################
  if($seq_fe[$indx] <= -15 && $seq_pairs_num[$indx] >= 18 && $seq_has_multiloops[$indx] ==0 && $seqs_len[$indx]<=137 && $seqs_len[$indx]>=51){
  	$is_hairpins_like[$indx] = 1;
  }
  else{
  	$is_hairpins_like[$indx] = 0;
  }
  #$seqs_len[$indx]
  #5. Output the judging detail, if in debug mode.
  if($debugMode == 1){
  	print "<p>Boolean about if this is a hairpins-like sequence: $is_hairpins_like[$indx]</p>";
  	print "<p>Detail: Free energy, number of base pairs, and boolean about if there are multiloops: ";
  	print "$seq_fe[$indx],$seq_pairs_num[$indx],$seq_has_multiloops[$indx]. </p>";
      }
      }
close(foldOut);

############################################################################################
#
# Prepare for Random Forest Prediction System.
# (generate an array of 34 dimionsian and write it into a file.)
# Variables used: my @fasta_heads; my @sequences; my @structures; my @is_hairpins_like; my @seq_fe;
#
############################################################################################

my @pValue;#added by KevinWang # This array will be assigned here and used later
if($debugMode == 1){
	print "<p><b>Construct arrays of 34 dimensions:</b></p>";
}
open writeForR , ">$RInfile" or die("could not open a file to write for R\n");
my @seqCheckResult;
for (my $indx = 0; $indx<=$#sequences; $indx++){
	my $mother_seq=$sequences[$indx];#added by KevinWu
	if($debugMode == 1){
		print "<p>Index value: $indx. Mother sequence: $mother_seq</p>";
	}
	if($is_hairpins_like[$indx] == 0){
		$seqCheckResult[$indx] = -1;
		$seqCheckResult[$indx] = -1;
		# Acturally, the variable in next line will not be output.
		$pValue[$indx] = "-- (not pre-miRNA-like, so needn't shuffling)";# HERE SHOULD BE REPORTED
	}
	else{
		#generate the array of 34 dimensions
		#1. generate an array of 32 dimensions
		my @array32;#to store the array
		my @list1=("A","U","G","C");
		my @list2=("(((","((.","(.(","(..",".((",".(.","..(","...");
		my @count;
		for(my $i=0;$i<@list1;$i++){#reset all values to zero
    	for(my $j=0;$j<@list2;$j++){
    		$count[$i*8+$j] = 0;
    	} 
		}
		my @sequence= split(//,$sequences[$indx]);# convert a string to array
		# $sequences[$indx] can not be changed, cos it will be shuffled later.
		#$a[0]=~tr/\)/\(/;##why ??? (in Ma Wei 's tt.pl)(PUZZLE)
		my @structure= split(//,$structures[$indx]);
		my $size = @sequence;
		for(my $k=1;$k<$size-1;$k++){
			for(my $i=0;$i<@list1;$i++){
				if($sequence[$k] eq $list1[$i]){
					my $triplet="$structure[$k-1]$structure[$k]$structure[$k+1]";
					for(my $j=0;$j<@list2;$j++){
						if($triplet eq $list2[$j]) {
							$count[$i*8+$j]++;
						}
					} 
				}
			}
		}
		for(my $i=0;$i<@list1;$i++){
			for(my $j=0;$j<@list2;$j++){
				$count[$i*8+$j]=$count[$i*8+$j]/$size;
				print writeForR "$count[$i*8+$j]\t";#write into the file opened above
			} 
		}#WARNING: do NOT write a "\n" here out of the loop, cos another TWO values should be appended
		#2. shuffle and find MFE and 3. calculate p_value(s)
		my @seqs_shuffled;
		for(my $i=0;$i<$shuffle_times;$i++){#alert: not $indx.($indx is being used outer.)
			my $temp_seq = shuffle_sequence_dinucleotide($mother_seq);
   		$seqs_shuffled[$i]= "$temp_seq\n";
		}
		#write the shuffled sequences into a file
		#my $FileProcessedShuffledSeqs = "ProcessedShuffledSeqs.txt";
		open writeShuffledSeq , ">$FileShuffledSeqs" or die("could not open a file to write for R.exe\n");
		print writeShuffledSeq "@seqs_shuffled";
		close(writeShuffledSeq);
		$rtValCmd == 1;#set to a value not equal to 0 and 1 before invoke "system".(PROPER?)
		#$rtValCmd = system("$rnafold_binary <ShuffledSeqs.txt >ProcessedShuffledSeqs.txt");#(NOT WELL NOW)
		$rtValCmd = system("$rnafold_binary < $FileShuffledSeqs > $FileProcessedShuffledSeqs");
		#$rtValCmd = system($command);#(NOT WELL NOW)
		if ($rtValCmd == -1 && $debugMode == 1) {
			print debugOut "Error: when invoking RNAfold to process shuffled sequences.\n";
			print "<p>Error: when invoking RNAfold  to process shuffled sequences.</p>";
		}
		## sumarize the output of RNAfold.exe
		#read the output file
		#my $FileProcessedShuffledSeqs = "ProcessedShuffledSeqs.txt";
		open (hResultProcessedShuffledSeqs,"$FileProcessedShuffledSeqs");
    my @stuff=<hResultProcessedShuffledSeqs>;
    close(hResultProcessedShuffledSeqs);
    if($debugMode == 1){
			print "<p>Stuff value before processing: @stuff</p>";
		}
		# initialization
		my $cpt_sup = 0;# greater than
		my $cpt_inf = 0;# smaller than
		my $cpt_ega = 1;# it is myself !
		for (my $j=0;$j<$shuffle_times;$j++) {
			my $jj=$j*2+1;
			$stuff[$jj]=~tr/().//d;
      my $rand_mfe=$stuff[$jj]/100;
			if ($rand_mfe < $seq_fe[$indx]) {
				$cpt_inf++;
			}
			if ($rand_mfe == $seq_fe[$indx]) {
				$cpt_ega++;
			}
			if ($rand_mfe > $seq_fe[$indx]) {		
				$cpt_sup++;
			}
		}
		#if($debugMode == 1){
		#	print "<p>Stuff value after processing: @stuff</p>";
		#}
		#if($debugMode == 1){
			print "Count of sequences with FE greater than, equal to, and smaller than mother sequences: \n";
			print "$cpt_sup, $cpt_ega, and $cpt_inf .\n";
		#}
		my $this_pValue = ($cpt_ega + $cpt_inf) / ($shuffle_times + 1);#p_value
		print "$this_pValue = ($cpt_ega + $cpt_inf) / ($shuffle_times + 1)\n";
		$pValue[$indx] = $this_pValue;
		print writeForR "$seq_fe[$indx]\t$this_pValue";
		if($debugMode == 1){
			print "<p>p_Value: $this_pValue</p>";
		}
		$this_pValue = 0;# reset it for debug use
		#WARNING:remember to write a "\n" here, cos an array has be written now.
		print writeForR "\n";
	}
      }
close(writeForR);

############################################################################################
#
# Random Forest Prediction System.
# Invoke a R application to process the arrays of 34 dimensions, and do some sumarry work.
#
############################################################################################
my @seqCheckResult;# 1: yes; 0: no; -1: does not satisfy the THREE neccesary conditions above
my @checkProba;#probability. -1:does not satisfy the THREE neccesary conditions above.

#print a script file with filename in place of hardcoded file name
#
my @r_lines = ('library(randomForest)',
	       'load("' . $r_model . '")',
	       'test=read.table("' . $RInfile . '")',
	       'pred=predict(model,test,type="prob")',
	       'decision=pred[,2]',
	       'decision=as.matrix(decision)',
	       'write.table(decision,"' . $ROutfile . '",quote=FALSE,sep=" ",col.names = FALSE,row.names = FALSE)',
	       'q("yes")');

open SCRIPT, ">$R_script";
for my $line (@r_lines){
    print SCRIPT "$line\n";
}
close SCRIPT;

my $aa = system("$r_binary CMD BATCH $R_script ");
print STDERR "R script is at $R_script\n";
print STDERR "running command: $r_binary CMD BATCH $R_script\n";
print STDERR "R output file: $ROutfile\n";

open (ROut,"$ROutfile");

chomp(my @DataROut=<ROut>);
close(ROut);


if($debugMode==1){
  print "<p>Data output by R: $DataROut[0]</p>";
}

#print "<p>Data output by R: $DataROut[0]</p>"; ####Kevin Degbuging

my $curValidIndex = 0;
for (my $indx = 0; $indx<=$#sequences; $indx++) {
	#print "<p>Main index is $indx, and current valid index is $curValidIndex</p>"; ####Kevin Degbuging
	if($is_hairpins_like[$indx] != 1){
		#print "<p>Find one sequence not hairpins-like</p>"; ####Kevin Degbuging
		$seqCheckResult[$indx] = -1;
		$checkProba[$indx] = -1;
	}
	else {
		#Here can only use: $DataROut[$curValidIndex],$seqCheckResult[$indx],$checkProba[$indx]
		if($DataROut[$curValidIndex]>0.5){
			$seqCheckResult[$indx]=1;
			$checkProba[$indx]=$DataROut[$curValidIndex]*100;
		
			}
		
		else{
			$seqCheckResult[$indx]=0;
			$checkProba[$indx]=100-$DataROut[$curValidIndex]*100;

			}
	  $curValidIndex++;
	}

      }


open resultOut, ">$fileResult" or die("Can not open a file to write result.");

	
# new output

for (my $indx = 0; $indx<=$#sequences; $indx++) {
	# prepare a string used to ouput here
	my $str_if_hairpinlike;
	if($is_hairpins_like[$indx] != 1){
		$str_if_hairpinlike = "No";
	}
	else
	{
		$str_if_hairpinlike = "Yes";
	}
	# print the six+one lines first
@temp = "Sequence Name:\t$fasta_heads[$indx]\nSequence Content:\t$sequences[$indx]\nLength:\t$seqs_len[$indx]\nPre-miRNA-like Hairpin?\t$str_if_hairpinlike\nThe Secondary Structure:\t$structures[$indx]\nMFE:\t$seq_fe[$indx]\n";
  print resultOut "@temp";

	# if hairpin-like, print another two lines
	if($is_hairpins_like[$indx] != 1){
		@temp = "Prediction result:\tIt is not a pre-miRNA-like hairpin.\n";
		print resultOut "@temp";
	}
	else{
	    my $comment;                                        
	    if($seqCheckResult[$indx] == 1){                    
                        $comment = "It is a real microRNA precursor"; 
            }                                             
            else{                                             
              $comment = "It is a pseudo microRNA precursor"; 
            }                                               

@temp = "p-value (shuffle times:1000)\t$pValue[$indx]\nPrediction result:\t$comment\nPrediction confidence:$checkProba[$indx]%\n";
print resultOut "@temp";
	}
	#print end of table

      }



############################################################################################
#
# Definitions of functions: shuffle
#
############################################################################################
sub shuffle_sequence_dinucleotide {
	## obtained from randfold.pl.
	my ($str) = @_;

	# upper case and convert to ATGC
	$str = uc($str);
	$str =~ s/U/T/g;
	
	my @nuc = ('A','T','G','C');
	my $count_swap = 0;
	# set maximum number of permutations
	my $stop = length($str) * 10;
	my $ii=0;
	
	while(($count_swap < $stop)&&($ii<3*$stop)) {
		my @pos;
		# look start and end letters
		my $firstnuc = $nuc[int(rand 4)];
		my $thirdnuc = $nuc[int(rand 4)];	

		# get positions for matching nucleotides
		for (my $i=0;$i<(length($str)-2);$i++) {
			if ((substr($str,$i,1) eq $firstnuc) && (substr($str,$i+2,1) eq $thirdnuc)) {
				push (@pos,($i+1));
				$i++;
			}
		}
	
		# swap at random trinucleotides
		my $max = scalar(@pos);
		for (my $i=0;$i<$max;$i++) {
			my $swap = int(rand($max));
			if ((abs($pos[$swap] - $pos[$i]) >= 3) && (substr($str,$pos[$i],1) ne substr($str,$pos[$swap],1))) {			
				$count_swap++;
				my $w1 = substr($str,$pos[$i],1);
				my $w2 = substr($str,$pos[$swap],1);			
				substr($str,$pos[$i],1,$w2);
				substr($str,$pos[$swap],1,$w1);		
			}
		}
		$ii++;
	}
	return($str);	
}



############################################################################################
#
# Do some extra jobs before ending.
#
############################################################################################
## Use another "\n" to seperate the logs
#print debugOut "\n";# this can be done at first

close(resultOut);

if($outfile){
    system("mv $fileResult $outfile");
}

exit;# this line must be at the end of file
