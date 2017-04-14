package Page::Paginator;
our $VERSION = '0.1';
use strict;

sub new {
	my $class = shift;
	my $self = {};
	bless( $self, $class );
	
	return $self;
}

sub Buttons {
	my $self = shift;
		# class	=> $_[0]
		# href	=> $_[1]
		# total	=> $_[2]
		# range	=> $_[3]
		# page	=> $_[4]
	my @array;
	$_[4] = 1 unless $_[4];
	
	my $num_pages = (int( $_[2] / $_[3] ));
	$num_pages ++ if $num_pages ne ($_[2] / $_[3]);
	
	#### Left Bottom Button
	if ( $_[4] > 1 ) {
		push @array, qq~<a href="$_[1]&page=1" class="$_[0]"> << </a>~;
	} else {
		push @array, qq~<a href="#" class="$_[0]"> << </a>~;
	}
	
	#### Left page Button
	if ( $_[4] > 1 ) {
		my $before_page = $_[4] - 1;
		push @array, qq~<a href="$_[1]&page=$before_page" class="$_[0]"> < </a>~;
	} else {
		push @array, qq~<a href="#" class="$_[0]"> < </a>~;
	}
	
	push @array, "Page $_[4] of $num_pages";
	
	#### Right page Button
	if ( $_[4] < $num_pages ) {
		my $after_page = $_[4] + 1;
		push @array, qq~<a href="$_[1]&page=$after_page" class="$_[0]"> > </a>~;
	} else {
		push @array, qq~<a href="#" class="$_[0]"> > </a>~;
	}
	
	#### Right Top Button
	if ( $_[4] < $num_pages ) {
		push @array, qq~<a href="$_[1]&page=$num_pages" class="$_[0]"> >> </a>~;
	} else {
		push @array,  qq~<a href="#" class="$_[0]"> >> </a>~;
	}
	#	10		2  *	5
	my $to = $_[4] * $_[3];
	
	#	5		10 -	5
	my $from = $to - $_[3];
	#	9
	$to --;
	
	push @array, $from;
	push @array, $to;
	
	return \@array;
}

sub formatted_datetime {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year += 1900;
	$mon ++;
	$mon = "0$mon" if $mon < 10;
	$mday = "0$mday" if $mday < 10;
	$hour = "0$hour" if $hour < 10;
	$min = "0$min" if $min < 10;
	$sec = "0$sec" if $sec < 10;
	
	# return ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
	return "$year-$mon-$mday $hour:$min:$sec";
}


1;
