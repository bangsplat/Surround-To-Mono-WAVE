#!/usr/bin/perl

#
# surroundToMonoWAVE.pl
#
# create six mono WAVE files from a single six-channel WAVE file
#
# version 0
# created 2013-01-09
# modified 2013-01-10
#

use strict;
use Getopt::Long;
use Time::localtime;
use POSIX;

#	constants

use constant NUM_STREAMS	=>	6;

#	variables

my ( $input_param, $output_param, $channels_param, $debug_param, $help_param, $version_param );
my ( $file_size, @channels );
my ( $header, $chunk_id, $chunk_size, $format );
my ( $sub_chunk_1_id, $sub_chunk_1_size );
my ( $audio_format, $num_channels, $sample_rate, $byte_rate, $block_align, $bits_per_sample );
my ( $sub_chunk_2_id, $sub_chunk_2_size );
my ( @temp_file_names, @file_names, @file_handles );
my ( $base_name, $extension );
my ( $data_bytes_per_file, $samples_per_file );
my @MONTHS = qw( 01 02 03 04 05 06 07 08 09 10 11 12 );
my @DAYS = qw( 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 );
my @HOURS = qw( 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 );
my @MINUTES = qw ( 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 );
my @SECONDS = qw( 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 );

my $temp_date = localtime()->year + 1900 . $MONTHS[localtime()->mon] . $DAYS[localtime()->mday] . $HOURS[localtime()->hour] . $MINUTES[localtime()->min] . $SECONDS[localtime()->sec];

#	get parameters

GetOptions(	'input|i=s'		=>	\$input_param,
			'output|o=s'	=>	\$output_param,
			'channels|c=s'	=>	\$channels_param,
			'debug'			=>	\$debug_param,
			'help|?'		=>	\$help_param,
			'version'		=>	\$version_param );

if ( $debug_param ) {
	print "DEBUG: passed parameters:\n";
	print "input_param: $input_param\n";
	print "output_param: $output_param\n";
	print "channels_param: $channels_param\n";
	print "debug_param: $debug_param\n";
	print "help_param: $help_param\n\n";
}

if ( $version_param ) {
	print "surroundToMonoWAVE.pl version 0\n";
	exit;
}

if ( $help_param ) {
	print "surroundToMonoWAVE.pl\n\n";
	print "version 0\n\n";
	print "--input <filename>\n";
	print "\tfile to process (required)\n";
	print "--output <filename>\n";
	print "\toptional, and doesn't do anything right now\n";
	print "--channels <channelconfig>\n";
	print "\toptional, defaults to \"L_R_C_LFE_LS_RS\"\n";
	print "--help | -?\n";
	print "\tdisplay this text\n";
	print "--version\n";
	print "\tdisplay version information\n";
	exit;
}

# if no input file is specified, grab the first command line parameter and use that
if ( $input_param eq undef ) { $input_param = $ARGV[0]; }

if ( $channels_param eq undef ) { $channels_param = "L_R_C_LFE_LS_RS"; }

@channels = split( '_', $channels_param );
if ( $debug_param ) { print "DEBUG: channels: @channels\n"; }

if ( $debug_param ) {
	print "DEBUG: adjusted parameters:\n";
	print "input_param: $input_param\n";
	print "output_param: $output_param\n";
	print "channels_param: $channels_param\n";
	print "debug_param: $debug_param\n";
	print "help_param: $help_param\n\n";
}

if ( $debug_param ) { print "DEBUG: opening input file $input_param\n"; }
open( INPUT_FILE, "<", $input_param )
or die "Can't open input file $input_param\n";

binmode( INPUT_FILE );

$file_size = -s INPUT_FILE;
if ( $debug_param ) { print "DEBUG: input file $input_param is $file_size bytes\n"; }

# read the first twelve bytes of the file - this is the RIFF header
read( INPUT_FILE, $header, 12 )
or die "Error reading $input_param\n";

## unpack("L") is essentially the same as the old long_value() sub
## unpack("S") is the same as the old short_value() sub

$chunk_id = substr( $header, 0, 4 );
$chunk_size = unpack( "L", substr( $header, 4, 4 ) );
$format = substr( $header, 8, 4 );

if ( $debug_param ) {
	print "DEBUG: ChunkID: $chunk_id\n";
	print "DEBUG: ChunkSize: $chunk_size\n";
	print "DEBUG: Format: $format\n";
}

# ChunkSize should be the rest of the file after the first 8 bytes
# check this - if it does not match, warn, but continue
if ( ( $chunk_size + 8 ) ne $file_size ) { warn "Warning: ChunkSize is not correct\n"; }

# go find the "fmt " chunk

$sub_chunk_1_id = "fmt ";
$sub_chunk_1_size = find_chunk( \*INPUT_FILE, $sub_chunk_1_id );

if ( $debug_param ) { print "DEBUG: fmt  chunk size: $sub_chunk_1_size\n"; }

if ( $sub_chunk_1_size eq 0 ) { die "ERROR: no fmt  chunk\n"; }

# sub_chunk_1_size is the amount we need to read for the remainder of the fmt  sub chunk
read( INPUT_FILE, $header, $sub_chunk_1_size )
or die "Error reading $input_param\n";

$audio_format = unpack( "S", substr( $header, 0, 2 ) );
$num_channels = unpack( "S", substr( $header, 2, 2 ) );
$sample_rate = unpack( "L", substr( $header, 4, 4 ) );
$byte_rate = unpack( "L", substr( $header, 8, 4 ) );
$block_align = unpack( "S", substr( $header, 12, 2 ) );
$bits_per_sample = unpack( "S", substr( $header, 14, 2 ) );

if ( $debug_param ) {
	print "DEBUG: audio_format: $audio_format\n";
	print "DEBUG: num_channels: $num_channels\n";
	print "DEBUG: sample_rate: $sample_rate\n";
	print "DEBUG: byte_rate: $byte_rate\n";
	print "DEBUG: block_align: $block_align\n";
	print "DEBUG: bits_per_sample: $bits_per_sample\n";
}

# go find the "data" chunk
$sub_chunk_2_id = "data";
$sub_chunk_2_size = find_chunk( \*INPUT_FILE, $sub_chunk_2_id );
if ( $sub_chunk_2_size eq 0 ) { die "Error: no data chunk\n"; }

# figure out how big each file will be (the data chunk at least)
$data_bytes_per_file = $sub_chunk_2_size / NUM_STREAMS;
$samples_per_file = $data_bytes_per_file / ( $bits_per_sample / 8 );

if ( $debug_param ) {
	print "DEBUG: size of data chunk: $sub_chunk_2_size\n";
	print "DEBUG: number of data bytes per output file: $data_bytes_per_file\n";
	print "DEBUG: number of samples per output file: $samples_per_file\n";
}

# confirm that this is a 6 channel WAVE file
if ( $num_channels ne NUM_STREAMS ) {
	print "ERROR: wrong number of channels found\n";
	close( INPUT_FILE );
	exit;
}

# create file names
$base_name = $input_param;
$base_name =~ s/\.(.*)$//;		# lop off everything from the last period on
$extension = $1;				# use everything after the last period as the extension

if ( $debug_param ) {
	print "DEBUG: base_name: $base_name\n";
	print "DEBUG: extension: $extension\n";
}

# load @file_names array with each file name we're going to use
for ( my $i = 0; $i < NUM_STREAMS; $i++ ) {
	@file_names[$i] = "$base_name" . "_" . @channels[$i] . ".$extension";
}

if ( $debug_param ) {
	for ( my $i = 0; $i < NUM_STREAMS; $i++ ) {
		print "DEBUG: file name ($i): @file_names[$i]\n";
	}
}

# open/create the files
for ( my $i = 0; $i < NUM_STREAMS; $i++ ) {
	open( my $fh, '>', @file_names[$i] );			# open file $i
	binmode( $fh );									# set to binary mode
	@file_handles[$i] = $fh;						# put handle in file_handles array
}

# output a WAVE header into each file
# each should be the same
for ( my $i = 0; $i < NUM_STREAMS; $i++ ) {
	output_header( @file_handles[0] );
}

# now...
# read, write, read, write, etc.

# read $samples_per_file * NUM_STREAMS times
# write $samples_per_file * NUM_STREAMS times

### Basic steps
###		open input file							DONE
###		read/parse through the header			DONE
###		confirm it is six channels				DONE
###		queue file to start of audio data		DONE
###		create six new WAVE files				DONE
###		de-interleave out to WAVe files			


close( INPUT_FILE );
for ( my $i = 0; $i < NUM_STREAMS; $i++ ) {
	close( @file_handles[$i] ) or warn "CAN'T CLOSE FILE @file_handles[$i]\n";
}


# subroutines

sub output_header {
	my $fh = $_[0];
	
	my ( $output_chunk_size, $output_sub_chunk_1_size, $output_audio_format, $output_num_channels );
	my ( $output_sample_rate, $output_byte_rate, $output_block_align, $output_bits_per_sample );
	
	# chunk size next
	#  = remainder of file from this point
	#  = lenth of sample data + size of fmt chunk + remainder of chunk descriptor
	#  = will generally be sample data + 36 bytes
	$output_chunk_size = $data_bytes_per_file + 36;
	# subChunk1Size is always 18 in Sound Forge WAV files
	#  but as far as I can tell, it only needs to be 16
	#  why the two pad bytes?
	#	apparently there is an obscure Microsoft document that says
	# 	it shall be block aligned such that it shall be 18
	$output_sub_chunk_1_size = 16;
	$output_audio_format = $audio_format;
	$output_num_channels = 1;
	$output_sample_rate = $sample_rate;
	$output_bits_per_sample = $bits_per_sample;
	$output_block_align = ceil( $output_num_channels * int( $output_bits_per_sample / 8 ) );
	$output_byte_rate = $output_sample_rate * $output_block_align;

	print $fh "RIFF";
	print $fh pack( 'L', $output_chunk_size );
	print $fh "WAVE";

	print $fh "fmt ";
	print $fh pack( 'L', $output_sub_chunk_1_size );
	print $fh pack( 'S', $output_audio_format );
	print $fh pack( 'S', $output_num_channels );
	print $fh pack( 'L', $output_sample_rate );
	print $fh pack( 'L', $output_byte_rate );
	print $fh pack( 'S', $output_block_align );
	print $fh pack( 'S', $output_bits_per_sample );

	print $fh "data";
	print $fh pack( 'L', $data_bytes_per_file );
}

sub find_chunk {
	my $file_handle = $_[0];
	my $find_chunk_id = $_[1];
	my $done = 0;
	my ( $result, $buffer, $result, $read_chunk_id, $read_chunk_size );
	
	if ( $debug_param ) {
		print "DEBUG (find_chunk): looking in file $file_handle\n";
		print "DEBUG (find_chunk): looking for $find_chunk_id chunk\n";
	}
	
	# assume that $file_handle is an open file
	
	seek( $file_handle, 12, 0 );		# start just past the end of the header
	
	while ( !$done ) {
		$result = read( $file_handle, $buffer, 8 );		# read the header of the next chunk
		if ( $result eq 0 ) {							# end of file
			seek( $file_handle, 0, 0 );					# rewind file
			return( 0 );								# return 0, which indicates an error
		}
		
		# parse the next chunk info
		$read_chunk_id = substr( $buffer, 0, 4 );
		$read_chunk_size = unpack( "L", substr( $buffer, 4, 4 ) );
		
		if ( $read_chunk_id eq $find_chunk_id ) { return( $read_chunk_size ); }	# return the chunk size
		else { seek( $file_handle, $read_chunk_size, 1 ); }						# seek to next chunk
	}
}
