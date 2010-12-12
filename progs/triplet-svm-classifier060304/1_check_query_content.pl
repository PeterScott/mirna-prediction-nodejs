#!/usr/bin/perl -w

$input_file_1 = $ARGV[0];
open(IN_1, "$input_file_1")
	or die "can't open the input file : $!";
$output_file = $ARGV[1];
open OUT_1, ">$output_file"
	or die "Can not open $output_file : $!";

$num_1=0;
$num_2=0;
$num_total=0;
while(<IN_1>){
	if($_ =~ />()/){	
		$num_total++;
	#	print OUT_1 "$_";
		$title = $_;
	#	chomp($title);
	}
	elsif($_ =~ /([ACUG]+)/){	
	#	print OUT_1 "$_";
		$seq_letter = $_;
		chomp($seq_letter);
	#	$len_seq = length $seq_letter;
	#	$last_char = substr($seq_letter, $len_seq, 1);
	#	if($last_char eq '\r' || $last_char eq '\n' || $last_char eq '\t'){
	#		chop($seq_letter);
	#	}
		
		if($seq_letter =~ /([^ACUG\r])/){
			$num_1++;
		#	print "$1\n";
			$flag = 0;	
		}
		else{
			$num_2++;
			$flag = 1;
		}
		
		if($flag == 1){
			print OUT_1 "$title$_";	
		}
	}
	else{
		if($flag == 1){
			print OUT_1 "$_";	
		}
	}
}

print "check $num_total queries, delete $num_1 queries with non-ACGU and save $num_2 queries\n";
print "done!\n";
#######################################
# sub fuctions
sub get_max_value_in_array{
	local($array) = @_;
	local($len_array, $ret, $i);
	
	$len_array = @$array;
	$ret = $$array[0];
	for($i=1; $i<$len_array; $i++){
		if($ret < $$array[$i]){
			$ret = $$array[$i];
		}	
	}
	
	return $ret;
}

sub get_min_value_in_array{
	local($array) = @_;
	local($len_array, $ret, $i);
	
	$len_array = @$array;
	$ret = $$array[0];
	for($i=1; $i<$len_array; $i++){
		if($ret > $$array[$i]){
			$ret = $$array[$i];
		}	
	}
	
	return $ret;
}

sub var_array{
	local($mean, $array) = @_;
	local($sum, $var, $len_array, $i);
	
	$sum=0;
	$len_array = @$array;
	for($i=0; $i<$len_array; $i++){
		$sum = $sum + ($$array[$i] - $mean) * ($$array[$i] - $mean);	
	}
	
	$var = sqrt($sum / $len_array);
	
	return $var;
}

sub mean_array{
	local($array) = @_;
	local($sum, $len_array, $mean);
	
	$sum = sum_array(\@$array);
	$len_array = @$array;
	$mean = $sum / $len_array;
	
	return $mean;
}

sub sum_array{
	local($array) = @_;
	local($sum, $len_array, $i);
	
	$sum=0;	
	$len_array = @$array;
	for($i=0; $i<$len_array; $i++){
		$sum = $sum + $$array[$i];	
	}
	
	return $sum;
}

sub get_GC_content{
	local($seq) = @_;
	local($len_seq, $num_g, $num_c, $lower_seq, $i, $char, $content_gc);
		
	$len_seq = length $seq;
	$num_g=0;
	$num_c=0;
	$lower_seq = lc($seq);
	
	for($i=0; $i<$len_seq; $i++){
		$char = substr($lower_seq, $i, 1);
		if($char eq 'g'){
			$num_g++;
		}	
		elsif($char eq 'c'){
			$num_c++;
		}
		else{
		}
	}	
	
	$content_gc = ($num_g + $num_c) / $len_seq;
	
	return $content_gc;
	
}

sub get_letter_content{
	local($seq, $let_a) = @_;
	local($len_seq, $num_a, $lower_let_a, $lower_seq, $i, $char, $content_let_a);
		
	$len_seq = length $seq;
	$num_a=0;
	$lower_let_a = lc($let_a);
	$lower_seq = lc($seq);
	
	for($i=0; $i<$len_seq; $i++){
		$char = substr($lower_seq, $i, 1);
		if($char eq $lower_let_a){
			$num_a++;
		}	
	}	
	
	$content_let_a = $num_a / $len_seq;
	
	return $content_let_a;
	
}

sub get_seq_in_raw{
	local($seq, $posi, $len_arm) = @_;
	local($ret);
	
	$ret = substr($seq, $posi, $len_arm);
	
#	print OUT_1 "$ret\n";
	
	return $ret;
}

sub get_position_in_symble{
	local($str, $seq) = @_;
	local($len_seq, $len_str, $i, $sub_str, $posi);
	
	$len_seq = length $seq;
	$len_str = length $str;
	for($i=0; $i<$len_seq; $i++){
		$sub_str = substr($seq, $i, $len_str);
		if($str eq $sub_str){
			$posi = $i;
			last;	
		}
	}
	
	return $posi;
}

sub get_match_all_body{
	local($seq) = @_;
	local($len_seq, $i, $char, $ext_str, $len_ext_str, $body);
	
	$len_seq = length $seq;
	for($i=0; $i<$len_seq; $i++){
		$char = substr($seq, $i, 1);
		if($char ne "\."){
			$ext_str = substr($seq, $i);
			last;	
		}					
	}
	$len_ext_str = length $ext_str;
	$body = $ext_str;
	for($i=($len_ext_str-1); $i>=0; $i--){
		$char = $char = substr($ext_str, $i, 1);
		if($char eq "\."){
			chop($body);
		}
		else{
			last;
		}	
	}
	
#	print OUT_1 "$body\n";
	
	return $body;			
}

#数组中的最大值
sub find_max{
	local($array) = @_;
	local($ret, $max, $one);
	
	$max = 0;
	foreach $one (@$array){
		if($max < $one){
			$max = $one;	
		} 	
	}
	
	$ret = $max;
#	print "the max number of exons is $ret\n";
	return $ret;
}

sub get_left_bracket_number{
	local($seq) = @_;
	local($len_seq, $i, $char, $ret);
	
	$len_seq = length $seq;
	$ret=0;
	for($i=0; $i<$len_seq; $i++){
		$char = substr($seq, $i, 1);
		if($char eq '('){
			$ret++;	
		}
	}
	
	return $ret;
}

sub get_right_bracket_number{
	local($seq) = @_;
	local($len_seq, $i, $char, $ret);
	
	$len_seq = length $seq;
	$ret=0;
	for($i=0; $i<$len_seq; $i++){
		$char = substr($seq, $i, 1);
		if($char eq ')'){
			$ret++;	
		}
	}
	
	return $ret;
}

sub get_main_struct{
	local($struct) = @_;
	local($len_struct, $i, $left_bracket_number, $right_bracket_number, $len_left_bracket); 
	local($same, $time_1, $time_2, $time_3);
#	local($max_left_bracket, $bp_time, $bp_posi);
	local(@left_bracket, @right_bracket);
	local(@ret);
	
	$len_struct = @$struct;
	for($i=0; $i<$len_struct; $i=$i+2){
		$left_bracket_number = get_left_bracket_number($$struct[$i]);
		$right_bracket_number = get_right_bracket_number($$struct[$i+1]);	
		push(@left_bracket, $left_bracket_number);
		push(@right_bracket, $right_bracket_number);
	#	print OUT_1 "left is $left_bracket_number, right is $right_bracket_number\n";
	}
	
	$same=0;
	$len_left_bracket = @left_bracket;
	for($i=0; $i<$len_left_bracket; $i++){
		if($left_bracket[$i] == $right_bracket[$i]){
			#相等
			$same++;	
		}
	}
	
	$time_1=0;
	$time_2=0;
	$time_3=0;
	if($same == $len_left_bracket){
		#是相等的情况，进行处理
		if($same == 1){
			@ret = @$struct;
		#	print OUT_1 "type 1\n";
		}
		else{
			@ret=();

=pod
		#多分支环，但是是最简单的一种情况
			$max_left_bracket = find_max(\@left_bracket);
			
			for($i=0; $i<$len_left_bracket; $i++){
				$bp_time = $max_left_bracket / $left_bracket[$i];
				if($bp_time == 1){
					$time_1++;
					$bp_posi=$i;	
				}
				elsif($bp_time > 3){
					$time_3++;	
				}
				else{
					$time_2++;
				}
			}
			
			if($time_1 == 1 && $time_2 == 0){
				push(@ret, $$struct[$bp_posi*2]);
				push(@ret, $$struct[$bp_posi*2+1]);	
			#	print OUT_1 "type 2\n";
			}
			else{
				@ret=();
			#	print OUT_1 "type 3\n";
			}
=cut
		}
	}
	else{
		#如果不是全部相等的情况，返回的是空的结果。
		@ret=();
	#	print OUT_1 "type 0\n";
	}
	
	return @ret;

}

sub divide_structure{
	local($symble) = @_;
	local($bracket_flag, $len_symble, $i, $char, @posi, $len_posi, $sub_struct);
	local(@struct);
	
	push(@posi, 0);
	$bracket_flag = '(';
	$len_symble = length $symble;
	for($i=0; $i<$len_symble; $i++){
		$char = substr($symble, $i, 1);
		if($char ne '.' && $char ne $bracket_flag){
			$bracket_flag = $char;
			push(@posi, $i);
		#	print OUT_1 "$i\n";
		}
	}
	
	$len_posi = @posi;
	for($i=0; $i<($len_posi-1); $i++){
		$sub_struct = substr($symble, $posi[$i], $posi[$i+1] - $posi[$i]);	
	#	print OUT_1 "$sub_struct\n";
		push(@struct, $sub_struct);
	}
	$sub_struct = substr($symble, $posi[$len_posi-1]);		
#	print OUT_1 "$sub_struct\n";
	push(@struct, $sub_struct);
	
	return @struct;
}

###############################################
close IN_1 or die "can't close the input file : $!";
close OUT_1 or die "can't close the output file : $!"; 
