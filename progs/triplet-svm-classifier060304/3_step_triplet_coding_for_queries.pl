#!/usr/bin/perl -w

$input_file_1 = $ARGV[0];
open(IN_1, "$input_file_1")
	or die "can't open the input file : $!";
$output_file = $ARGV[1];
open OUT_1, ">$output_file"
	or die "Can not open $output_file : $!";

#全局的权值数组
for($i=0; $i<32; $i++){
	push(@weight, 0);	
}
get_weight_table(\@weight);

$method = 1;
#0 右臂取正序， 1 右臂取逆序
$reverse_flag = 0;

$num_main=0;
$num_total=0;
while(<IN_1>){
	if($_ =~ />()/){	
		$num_total++;
	#	print OUT_1 "$_";
	#	$title = $_;
	#	chomp($title);
	}
	elsif($_ =~ /([ACUG]+)/){	
	#	print OUT_1 "$_";
		$seq_letter = $1;
	}
	else{
		if($_ =~ /(.*?)\s+/){
			$symble = $1;	
		#	print OUT_1 "$1\n";
			
			#按照(和)进行分割
			@struct_symble = divide_structure($symble);
			
			#首先判断是那种类型,返回的是主体结构
			@main_struct = get_main_struct(\@struct_symble);
			$len_main_struct = @main_struct;
			if($len_main_struct == 2){
				$num_main++;
				#结构的左臂、右臂
				$left_arm = get_match_all_body($main_struct[0]);
				$right_arm = get_match_all_body($main_struct[1]);
				$len_left_arm = length $left_arm;
				$len_right_arm = length $right_arm;
			
				#定位结构的左臂、右臂在原结构中的位置
				$left_posi = get_position_in_symble($left_arm, $symble);
				$right_posi = get_position_in_symble($right_arm, $symble);
			
				#字符序列的左臂、右臂
				$left_raw_letter = get_seq_in_raw($seq_letter, $left_posi, $len_left_arm);
				$right_raw_letter = get_seq_in_raw($seq_letter, $right_posi, $len_right_arm);
				
				#计算特征表	
				if($reverse_flag == 0){		
					#注意：这里对右臂只取正链顺序，和下面一行不能同时使用
					@coding_table = translate_to_coding($left_raw_letter, $left_arm, $right_raw_letter, $right_arm);
				}
				else{
					#注意：这里对右臂取反链顺序
					#注意：这一步有选择的执行
					$reverse_right_arm = string_reverse($right_arm);
					$reverse_right_raw_letter = string_reverse($right_raw_letter);
				
					@coding_table = translate_to_coding($left_raw_letter, $left_arm, $reverse_right_raw_letter, $reverse_right_arm);
				}
				$len_coding_table = @coding_table;
				
=pod			
				$temp_sum=0;
				for($i=0; $i<$len_coding_table; $i++){
					print OUT_1 "$i: $coding_table[$i] ";	
					$temp_sum = $temp_sum + $coding_table[$i];
				}
				print OUT_1 "\n";
				print OUT_1 "sum is $temp_sum\n";
=cut			
				#多种方法
				if($method == 1){
					#用归一化法
					unite_probability_(\@coding_table);					
				}
				elsif($method == 2){
					#用布尔法
					bool_(\@coding_table);				
				}
				elsif($method == 3){
					#用权值法
					#注意，这一步要用到一个全局的权值数组
					product_weight_(\@coding_table);
				}
				else{
					print "ERROR: not choose method\n";
				}			

=pod			
				$temp_sum=0;
				for($i=0; $i<$len_coding_table; $i++){
					print OUT_1 "$i: $coding_table[$i] ";	
					$temp_sum = $temp_sum + $coding_table[$i];
				}
				print OUT_1 "\n";
				print OUT_1 "sum is $temp_sum\n";
=cut					
				unite_probability_(\@coding_table);
					
			#	$temp_sum=0;
				for($i=0; $i<$len_coding_table; $i++){
					print OUT_1 "$coding_table[$i] ";	
			#		$temp_sum = $temp_sum + $coding_table[$i];
				}
				print OUT_1 "\n";
			#	print OUT_1 "sum is $temp_sum\n";
			}		
		}
	}
}

print "$num_total queries, triplet coding $num_main queries!\n";
print "done!\n";
#######################################
# sub fuctions
sub get_weight_table{
	local($table) = @_;
	local($i);
	
	for($i=0; $i<32; $i=$i+8){
		$$table[$i+0] = 0.15 / 8;
		$$table[$i+1] = 0.05 / 8;
		$$table[$i+2] = 0.25 / 8;
		$$table[$i+3] = 0.15 / 8;
		$$table[$i+4] = 0.05 / 8;
		$$table[$i+5] = 0.1 / 8;
		$$table[$i+6] = 0.15 / 8;
		$$table[$i+7] = 0.1 / 8;		
		
	}
	
	return @$table;
}

sub product_weight_{
	local($table) = @_;
	local($len_table, $i);
	
	$len_table = @$table;
	for($i=0; $i<$len_table; $i++){
		$$table[$i] = $$table[$i] * $weight[$i];			
	}
}

sub bool_{
	local($table) = @_;
	local($len_table, $i);
	
	$len_table = @$table;
	for($i=0; $i<$len_table; $i++){
		if($$table[$i] != 0){
			$$table[$i] = 1;	
		}	
	}
}

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

sub get_char_value{
	local($char) = @_;
	local($l_char, $ret);
	
	$l_char = lc($char);
	$ret = -1;
	if($l_char eq 'a'){
		$ret = 0;	
	}
	elsif($l_char eq 'g'){
		$ret = 1;	
	}
	elsif($l_char eq 'c'){
		$ret = 2;	
	}
	elsif($l_char eq 'u'){
		$ret = 3;	
	}
	elsif($l_char eq 't'){
		$ret = 3;	
	}
	elsif($l_char eq 's'){
		$ret = 4;	
	}
	else{
		print "ERROR: has not A G C U or S(deleted stem-loop)\n";
	}
	
	return $ret;
}

sub get_near_value{
	local($line) = @_;
	local($value, $len_line, $i, $char, $value_char);
	
	$len_line = length $line;
	$value = 0;
	for($i=$len_line-1; $i>=0; $i--){
		$char = substr($line, $i, 1);
		$value_char = get_dot_brackle_value($char); 
		$value = $value + 2**($len_line - 1 - $i) * $value_char;	
	#	print OUT_1 "temp value is $value\n";
	}
	
	return $value;
}

sub get_dot_brackle_value{
	local($char) = @_;
	local($ret);
	
	$ret = -1;
	if($char eq '.'){
		$ret = 0;	
	}
	elsif($char eq '('){
		$ret = 1;	
	}
	elsif($char eq ')'){
		$ret = 1;	
	}
	else{
		print "ERROR: has neither . or ( or )\n";
	}
	
	return $ret;
}

sub translate_to_coding{
	local($left_seq, $left_arm, $right_seq, $right_arm) = @_;
	local($len_left_arm, $len_right_arm, $i, $char, $value_char, $near_2, $near_3, $value_near, $loca_near_in_table);
	local(@table);
	
	for($i=0; $i<32; $i++){
		push(@table, 0);	
	}
	
	$len_left_arm = length $left_arm;
	$len_right_arm = length $right_arm;
	
	#计算左臂
	for($i=0; $i<$len_left_arm; $i++){
		$char = substr($left_seq, $i, 1);
		$value_char = get_char_value($char);
	#	print OUT_1 "$i	char is $char, value is $value_char	";
		if($value_char == -1){
			return @table;	
		}
		
		
		if($i == 0){
			$near_2 = substr($left_arm, $i, 2);
			$near_3 = ".".$near_2;	
			$value_near = get_near_value($near_3);
		#	print OUT_1 "$near_2	$near_3, value is $value_near\n";
			
		}	
		elsif($i == ($len_left_arm - 1)){
			$near_2 = substr($left_arm, $i-1, 2);
			$near_3 = $near_2.".";	
			$value_near = get_near_value($near_3);
		#	print OUT_1 "$near_2	$near_3, value is $value_near\n";
			
		}
		else{
			$near_3 = substr($left_arm, $i-1, 3);
			$value_near = get_near_value($near_3);
		#	print OUT_1 "$near_3, value is $value_near\n";
			
		}
		
		$loca_near_in_table = $value_char * 8 + $value_near;
	#	print OUT_1 "loca in table is $loca_near_in_table\n";
		$table[$loca_near_in_table]++;
	}
	
	#计算右臂 
	for($i=0; $i<$len_right_arm; $i++){
		$char = substr($right_seq, $i, 1);
		$value_char = get_char_value($char);
	#	print OUT_1 "$i	char is $char, value is $value_char	";
	#	if($value_char == -1){
	#		return @table;	
	#	}
		
		
		if($i == 0){
			$near_2 = substr($right_arm, $i, 2);
			$near_3 = ".".$near_2;	
			$value_near = get_near_value($near_3);
		#	print OUT_1 "$near_2	$near_3, value is $value_near\n";
			
		}	
		elsif($i == ($len_right_arm - 1)){
			$near_2 = substr($right_arm, $i-1, 2);
			$near_3 = $near_2.".";	
			$value_near = get_near_value($near_3);
		#	print OUT_1 "$near_2	$near_3, value is $value_near\n";
			
		}
		else{
			$near_3 = substr($right_arm, $i-1, 3);
			$value_near = get_near_value($near_3);
		#	print OUT_1 "$near_3, value is $value_near\n";
			
		}
		
		$loca_near_in_table = $value_char * 8 + $value_near;
	#	print OUT_1 "loca in table is $loca_near_in_table\n";
		$table[$loca_near_in_table]++;
	}
	
	return @table;
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
