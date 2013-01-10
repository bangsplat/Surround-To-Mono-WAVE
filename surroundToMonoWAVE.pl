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

## pack("L") is essentially the same as the old long_value() sub
## pack("S") is the same as the old short_value() sub

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





close( INPUT_FILE );


# # Read 12 bytes (ChunkID, ChunkSize, Format)
# read( INPUT_FILE, $header, 12 )
# or die "Error reading $input_file\n";
# 
# $chunk_id = substr( $header, 0, 4 );
# $chunk_size = long_value( substr( $header, 4, 4 ) );
# $format = substr( $header, 8, 4 );
# 
# # ChunkID should be "RIFF"
# if ( $chunk_id ne "RIFF" ) { die "Error: $input_file is not a WAVE file (no RIFF)\n"; }
# 
# # ChunkSize + 8 should equal the total file size
# # if it doesn't match, we may have an Omneon-style too-big WAVE file
# # go ahead and process anyway
# if ( ( $chunk_size + 8) ne $file_size ) { warn "Warning: ChunkSize is not correct\n"; }
# 
# # Format should be "WAVE"
# if ( $format ne "WAVE" ) { die "Error: $input_file is not a WAVE file (no WAVE)\n"; }
# 
# # Go find the fmt chunk
# $sub_chunk_1_id = "fmt ";
# $sub_chunk_1_size = find_chunk( $sub_chunk_1_id );
# if ( $sub_chunk_1_size eq 0 ) { die "Error: no fmt chunk\n"; }
# 
# # Subchunk1Size is the amount we need to read for the remainder of the fmt sub chunk
# read( INPUT_FILE, $header, $sub_chunk_1_size )
# or die "Error reading $input_file\n";
# 
# $audio_format = short_value( substr( $header, 0, 2 ) );
# $num_channels = short_value( substr( $header, 2, 2 ) );
# $sample_rate = long_value( substr( $header, 4, 4 ) );
# $byte_rate = long_value( substr( $header, 8, 4 ) );
# $block_align = short_value( substr( $header, 12, 2 ) );
# $bits_per_sample = short_value( substr( $header, 14, 2 ) );







sub short_value {
	my $short_bytes = $_[0];
	
	my $first_byte = ord( substr( $short_bytes, 0, 1 ) );
	my $second_byte = ord( substr( $short_bytes, 1, 1 ) );
	
	my $short_value = $first_byte;
	$short_value += $second_byte * 256;
	
	return $short_value;
}

sub long_value {
	my $long_bytes = $_[0];
	
	my $first_byte = ord( substr( $long_bytes, 0, 1 ) );
	my $second_byte = ord( substr( $long_bytes, 1, 1 ) );
	my $third_byte = ord( substr( $long_bytes, 2, 1 ) );
	my $fourth_byte = ord( substr( $long_bytes, 3, 1 ) );
	
	my $long_value = $first_byte;
	$long_value += $second_byte * 256;
	$long_value += $third_byte * 65536;
	$long_value += $fourth_byte * 16777216;
	
	return $long_value;
}
