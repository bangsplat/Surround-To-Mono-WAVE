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






