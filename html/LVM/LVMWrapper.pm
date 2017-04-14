package LVM::LVMWrapper;

our $VERSION = '0.1';

use strict;
use Net::OpenSSH;

sub new {
	my $class = shift;
	my ($remoteHost, $private_key_path, $user, $timeout, $password) = @_;
	my $self = {};
	
	bless( $self, $class );
	
	my $ssh;
	if ( $private_key_path ) {
		$ssh = Net::OpenSSH->new(
			$remoteHost,
			key_path	=> $private_key_path,
			user		=> $user || 'root',
			timeout		=> $timeout || 6,
			master_opts	=> [-o => "StrictHostKeyChecking=no"],
		);
	} elsif ( $password ) {
		$ssh = Net::OpenSSH->new(
			$remoteHost,
			user		=> $user || 'root',
			timeout		=> $timeout || 6,
			master_opts	=> [-o => "StrictHostKeyChecking=no"],
			password	=> $password,
		);
	}
    
	$self->{server} = $ssh;
	$self->{error} = $ssh->error if $ssh->error;
	
	return $self;
}

sub vgdisplay {
	my $self = shift;
	my %VG;
	
	my $vgdisplay = $self->{server}->capture(qq~vgdisplay | awk '/VG Name/{a=\$NF};/VG Size/{b=\$(NF-1)" "\$NF};/Free/{print a","b","\$(NF-1)" "\$NF}'~);
	chomp $vgdisplay;
	
	foreach my $line ( split(/\n/, $vgdisplay) ) {
		my ($vgName, $size, $uuid) = split(/,/, $line);
		$VG{$vgName} = [$size, $uuid];
	}
	
	return \%VG;
}

sub lvremove {
	my $self = shift;
	my ($vgName, $lvName, $containerName) = @_;
	
	my $umount = $self->{server}->capture(qq~umount -f /dev/$vgName/$lvName 2>/dev/null~);
	
	my $lvremove = $self->{server}->capture(qq~lvremove -f -q /dev/$vgName/$lvName~);
	
	my $rmtree = $self->{server}->capture(qq~perl -e 'use File::Path qw(rmtree); rmtree("/var/lib/lxc/$containerName")'~);
	
	my $date = date();
	# my $cleanfstab = $self->{server}->capture(qq~perl -pi.$date -e 's/\\/dev\\/$vgName\\/$lvName/\\#\\/dev\\/$vgName\\/$lvName/' /etc/fstab~);
	my $cleanfstab = $self->{server}->capture(qq~perl -pi.$date -e 's/\\/dev\\/$vgName\\/$lvName.+\n//' /etc/fstab~);
	
	return $lvremove;
}

sub date {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year += 1900;
	$mon ++;
	$mon = "0$mon" if $mon < 10;
	$mday = "0$mday" if $mday < 10;
	$hour = "0$hour" if $hour < 10;
	$min = "0$min" if $min < 10;
	$sec = "0$sec" if $sec < 10;
	return "$year$mon$mday$hour$min$sec";
}

sub lvcreate {
	my $self = shift;
	my ($lvSize, $lvName, $vgName) = @_;
	
	my $lvcreate = $self->{server}->capture(qq~lvcreate -L $lvSize -n $lvName $vgName --yes~);
	chomp $lvcreate;
	
	return $lvcreate;
}

sub mkfsxfs {
	my $self = shift;
	my ($vgName, $lvName) = @_;
	
	my $mkfsxfs = $self->{server}->capture(qq~mkfs.xfs -f -q /dev/$vgName/$lvName~);
	chomp $mkfsxfs;
	
	return $mkfsxfs;
}

sub lvmount {
	my $self = shift;
	my ($containerName, $vgName, $lvName) = @_;
	
	my $mkdir = $self->{server}->capture(qq~mkdir /var/lib/lxc/$containerName~);
	$mkdir = $self->{server}->capture(qq~mkdir /var/lib/lxc/$containerName/rootfs~);
	
	# my $uuid = $self->{server}->capture(qq~lsblk -no UUID /dev/$vgName/$lvName~); # Does not read the UUID in auto. Check this later
	# chomp $uuid;
	# my $fstabAdd = $self->{server}->capture(qq~echo "UUID=$uuid  /var/lib/lxc/$containerName/rootfs  xfs  defaults,noatime  0 2" >> /etc/fstab~);
	my $fstabAdd = $self->{server}->capture(qq~echo "/dev/$vgName/$lvName  /var/lib/lxc/$containerName/rootfs  xfs  defaults,noatime  0 2" >> /etc/fstab~);
	chomp $fstabAdd;
	
	my $vgmount = $self->{server}->capture(qq~mount /var/lib/lxc/$containerName/rootfs~);
	chomp $vgmount;
	
	return $vgmount;
}

1;






