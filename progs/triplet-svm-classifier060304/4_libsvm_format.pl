#!/usr/bin/perl -w

$input_file = $ARGV[0];
$output_file_1 = $ARGV[1];

=pod
$y_ = $ARGV[2];
if($y_ == -1){
	$y_label = "-"."1";	
}
else{
	$y_label = "+"."1";
}
=cut

open(IN_1, "$input_file")
	or die "can't open the input file : $!";
open OUT_1, ">$output_file_1"
	or die "Can not open $output_file_1 : $!";
	
while(<IN_1>){
	if($_ =~ />/){
		
	}
	else{
	$line = $_;
	chomp($line);
	@array=split(" ",$line);
#	$code = $y_label." ";
	$code = "";
	$len_array = @array;
	for($i=0; $i<$len_array; $i++){
		$dem = $i + 1;
		if($array[$i] != 0){
			$code = $code.$dem.":".$array[$i]." ";
		}	
	}
	print OUT_1 "$code\n";
	}
}


print "done!\n";
#######################################
# sub fuctions

###############################################
close IN_1 or die "can't close the input file : $!";
close OUT_1 or die "can't close the output file : $!"; 