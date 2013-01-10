#!/usr/bin/perl

#
# surroundToMonoWAVE.pl
#
# create six mono WAVE files from a single six-channel WAVE file
#
# version 0
# created 2013-01-09
# modified 2013-01-09
#

use strict;
use Getopt::Long;


### Basic steps
###		open input file
###		read/parse through the header
###		confirm it is six channels
###		queue file to start of audio data
###		create six new raw pcm (temp) files
###		de-interleave out to temp files
###		wrap temp files to mono WAVE files
###		delete temp files
###
###	all of these steps I've done in separate scripts before
###	but I want to combine the functionality into one here

#	variables

my ( $input_param, $output_param, $debug_param, $help_param, $version_param );
my ( $file_size );
my ( $header, $chunk_id, $chunk_size, $format );
my ( $sub_chunk_1_id, $sub_chunk_1_size );
my ( $audio_format, $num_channels, $sample_rate, $byte_rate, $block_align, $bits_per_sample );
my ( $sub_chunk_2_id, $sub_chunk_2_size );

#	get parameters

GetOptions(	'input|i=s'		=>	\$input_param,
			'output|o=s'	=>	\$output_param,
			'debug'			=>	\$debug_param,
			'help|?'		=>	\$help_param,
			'version'		=>	\$version_param );

if ( $debug_param ) {
	print "DEBUG: passed parameters:\n";
	print "input_param: $input_param\n";
	print "output_param: $output_param\n";
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
	print "--help | -?\n";
	print "\tdisplay this text\n";
	print "--version\n";
	print "\tdisplay version information\n";
	exit;
}

# if no input file is specified, grab the first command line parameter and use that
if ( $input_param eq undef ) { $input_param = $ARGV[0]; }

if ( $debug_param ) {
	print "DEBUG: adjusted parameters:\n";
	print "input_param: $input_param\n";
	print "output_param: $output_param\n";
	print "debug_param: $debug_param\n";
	print "help_param: $help_param\n\n";
}

if ( $debug_param ) { print "DEBUG: opening input file $input_param\n"; }
open( INPUT_FILE, "<", $input_param )
	or die "Can't open input file $input_param\n";

$file_size = -s INPUT_FILE;
if ( $debug_param ) { print "DEBUG: input file $input_param is $file_size bytes\n"; }

### for now, just read enough and report the values of the various chunks


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
$sub_chunk_2_size = find_chunk( $sub_chunk_2_id );
if ( $sub_chunk_2_size eq 0 ) { die "Error: no data chunk\n"; }


### start processing from here


close( INPUT_FILE );


# subroutines

sub find_chunk {
	my $file_handle = $_[0];
	my $find_chunk_id = $_[1];
	my $done = 0;
	my ( $result, $buffer, $result, $read_chunk_id, $read_chunk_size );
	 
	# assume that $file_handle is an open file
	
	seek( $file_handle, 12, 0 );		# skip past the end of the header
	
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
