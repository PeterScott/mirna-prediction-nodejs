#!/usr/bin/perl -w

$input_file_1 = $ARGV[0];
open(IN_1, "$input_file_1")
	or die "can't open the input file : $!";
$output_file = $ARGV[1];
open OUT_1, ">$output_file"
	or die "Can not open $output_file : $!";

$min_basepairing = $ARGV[2];
#$free_energy = -15;

$num_total=0;
$num_candi=0;
while(<IN_1>){
	if($_ =~ />/){
		$num_total++;
	#	print OUT_1 "$_";
	#	$title = $_;
	#	chomp($title);
		$start_ = 1;
	#	$end_ = $3;
	}
	elsif($_ =~ /([ACUG]+)/){	
	#	print OUT_1 "$_";
		$seq_letter = $1;
	}
	elsif($_ =~ /[\(\)\.]/){
		if($_ =~ /(.*?)\s+/){
			$symble = $1;	
		#	$fe=$2;
		#	print OUT_1 "$1\n";
			
		#	if($fe <= $free_energy){
			
			#按照(和)进行分割
			@struct_symble = divide_structure($symble);
			$len_struct_symble = @struct_symble;
			
			if($len_struct_symble >= 2){
				#首先判断是那种类型,返回的是主体结构
				@candidate_struct = get_candidate_structs(\@struct_symble);
				
				#得到每个候选的匹配部分
				$len_main_struct = @candidate_struct;
				if($len_main_struct != 0){
						
						$right_posi = 0;
						for($i=0; $i<$len_main_struct; $i=$i+2){
						$num_candi++;
					
						$left_posi = get_position_in_symble($candidate_struct[$i], $symble, $right_posi);
						$right_posi = get_position_in_symble($candidate_struct[$i+1], $symble, $left_posi);
					
						$len_candi_right_arm = length $candidate_struct[$i+1];
						$len_candi = $right_posi - $left_posi + $len_candi_right_arm;
						$candi = get_seq_in_raw($symble, $left_posi, $len_candi);
						$candi_seq = get_seq_in_raw($seq_letter, $left_posi, $len_candi);
						$start_posi = $start_ + $left_posi;
						$end_posi = $start_ + $left_posi + $len_candi - 1;
					#	print OUT_1 "$candi_seq\n$candi\n";
						$n_t = ">".$num_total."_".$start_posi."_".$end_posi;
						print OUT_1 "$n_t\n$candi_seq\n$candi\n";
					}
				}	
			}
			
		#	}	

		}
	}
	else{
	}
}

print "total is $num_total, there $num_candi candidates\n";
print "done!\n";
#######################################
# sub fuctions
sub unite_probability_{
	local($table) = @_;
	local($len_table, $i, $sum);
#	local($show_table);
	
	$len_table = @$table;
	$sum = 0;
	for($i=0; $i<$len_table; $i++){
		$sum = $sum + $$table[$i];			
	}
#	print OUT_1 "sum is $sum\n";
	for($i=0; $i<$len_table; $i++){
		$$table[$i] = $$table[$i] / $sum;	
	}
}


#串的反向
sub string_reverse{
	local($string) = @_;
	local($len_str, $ret, $i, $char);
	
	$len_str = length $string;
	$ret = "";
	for($i=0; $i<$len_str; $i++){
		$char = substr($string, $i, 1);
		$ret = $char.$ret;		
	}
	
#	print OUT_1 "$ret\n";
	
	return $ret;
}

sub get_seq_in_raw{
	local($seq, $posi, $len_arm) = @_;
	local($ret);
	
	$ret = substr($seq, $posi, $len_arm);
	
#	print OUT_1 "$ret\n";
	
	return $ret;
}

sub get_position_in_symble{
	local($str, $seq, $start_) = @_;
	local($len_seq, $len_str, $i, $sub_str, $posi);
	
	$len_seq = length $seq;
	$len_str = length $str;
	for($i=$start_; $i<$len_seq; $i++){
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

sub get_candidate_structs{
	local($struct) = @_;
	local($len_struct, $i, $left_bracket_number, $right_bracket_number, $len_left_bracket); 
	local(@left_bracket, @right_bracket);
	local($num_1, $j, $num_bp, $len_substr, $k, $char, $cut_posi, $cut, $cut_length);
	local($len_ret, $body);
	
	local(@ret, @ret_body);
	
#	print OUT_1 "????????????????????????????????\n";
	@ret = ();
	
	$len_struct = @$struct;
	for($i=0; $i<$len_struct; $i=$i+2){
		$left_bracket_number = get_left_bracket_number($$struct[$i]);
		$right_bracket_number = get_right_bracket_number($$struct[$i+1]);	
		push(@left_bracket, $left_bracket_number);
		push(@right_bracket, $right_bracket_number);
	#	print OUT_1 "left is $left_bracket_number, right is $right_bracket_number\n";
	}
	
	$num_1=0;
	$len_left_bracket = @left_bracket;
	for($i=0, $j=0; $i<$len_left_bracket; $i++, $j=$j+2){
#		print OUT_1 "raw l: $$struct[$j]\nraw r: $$struct[$j+1]\n";
		if(($left_bracket[$i] >= $min_basepairing) && ($right_bracket[$i] >= $min_basepairing)){
			#多少个可能值
			$num_1++;	
			
			#剪切可能的结构
			if($left_bracket[$i] == $right_bracket[$i]){
				#匹配一样多，直接返回
				push(@ret, $$struct[$j]);
				push(@ret, $$struct[$j+1]);		
#				print OUT_1 "cut l: $$struct[$j]\ncut r: $$struct[$j+1]\n";
#				print OUT_1 "case same\n";	
				$left_bracket_number = get_left_bracket_number($$struct[$i]);
				$right_bracket_number = get_right_bracket_number($$struct[$i+1]);
#				print OUT_1 "left is $left_bracket_number, right is $right_bracket_number\n";
			}
			elsif($left_bracket[$i] > $right_bracket[$i]){
				#左多右少，裁减左
				$num_bp=0;
				$len_substr = length $$struct[$j];
				for($k=$len_substr-1; $k>=0; $k--){
					if($num_bp != $right_bracket[$i]){
						$char = substr($$struct[$j], $k, 1);
						if($char eq "("){
							$num_bp++;
						}
					}	
					else{
						$cut_posi = $k + 1;
						last;
					}
				}
				$cut = substr($$struct[$j], $cut_posi);
				
				push(@ret, $cut);
				push(@ret, $$struct[$j+1]);
#				print OUT_1 "cut l: $cut\ncut r: $$struct[$j+1]\n";
#				print OUT_1 "left big\n";
				$left_bracket_number = get_left_bracket_number($cut);
				$right_bracket_number = get_right_bracket_number($$struct[$j+1]);
	#			print OUT_1 "left is $left_bracket_number, right is $right_bracket_number\n";
			}
			else{
				#右多左少，裁减右
				$num_bp=0;
				$len_substr = length $$struct[$j+1];
				for($k=0; $k<($len_substr-1); $k++){
					if($num_bp != $left_bracket[$i]){
						$char = substr($$struct[$j+1], $k, 1);
						if($char eq ")"){
							$num_bp++;
						}	
					}
					else{
						$cut_length = $k;
						last;
					}
				}
				$cut = substr($$struct[$j+1], 0, $cut_length);
				
				push(@ret, $$struct[$j]);
				push(@ret, $cut);
#				print OUT_1 "cut l: $$struct[$j]\ncut r: $cut\n";
#				print OUT_1 "right big\n";
				$left_bracket_number = get_left_bracket_number($$struct[$j]);
				$right_bracket_number = get_right_bracket_number($cut);
#				print OUT_1 "left is $left_bracket_number, right is $right_bracket_number\n";
			}
			
		}
	}
#	print "there $num_1 candidates\n";
	
	$len_ret = @ret;
	
	for($i=0; $i<$len_ret; $i++){
		$body = get_match_all_body($ret[$i]);
		push(@ret_body, $body);
#		print OUT_1 "$body\n";
	}
	
	return @ret_body;
	
}

sub get_main_struct{
	local($struct) = @_;
	local($len_struct, $i, $left_bracket_number, $right_bracket_number, $len_left_bracket); 
	local($same, $max_left_bracket, $bp_time, $bp_posi, $time_1, $time_2, $time_3);
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
		#多分支环，但是是最简单的一种情况
			$max_left_bracket = find_max(\@left_bracket);
			
			for($i=0; $i<$len_left_bracket; $i++){
				$bp_time = $max_left_bracket / $left_bracket[$i];
				if($bp_time == 1){
					$time_1++;
					$bp_posi=$i;	
				}
				elsif($bp_time > 2){
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
#		print OUT_1 "$sub_struct\n";
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