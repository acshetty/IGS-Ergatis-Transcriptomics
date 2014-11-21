#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

################################################################################
### POD Documentation
################################################################################

=head1 NAME

    Rnaseq_report_combine.pl  -    Creates a PDF report for the whole pipeline of RnaSeq pipeline.

=head1 SYNOPSIS

 Rnaseq_report_combine.pl    --i <pdf list> [--o  <output dir>]   
                            [--p <project>] [--pl <pipeline>]
                            [--v]

    parameters in [] are optional
    do NOT type the carets when specifying options

=head1 OPTIONS
    
    --i <pdf list>         = Path to list of pdf fies.

    --o <output dir>       = /path/to/output directory. Optional.[PWD]

    --p <project>          = Pipeline id

    --pl <pipeline>        = pipeline

    --v                    = generate runtime messages. Optional

=head1 DESCRIPTION

Creates a PDF report for RnaSeq pipeline with individual component report, adding cover page and software information

=head1 AUTHOR

 Weizhong Chang
 Bioinformatics Software Engineer 
 Institute for Genome Sciences
 University of Maryland
 Baltimore, Maryland 21201

=cut

################################################################################

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev pass_through);
use Pod::Usage;
use File::Spec;
use PDF::API2;

##############################################################################
### Constants
##############################################################################

use constant FALSE => 0;
use constant TRUE  => 1;

#use constant BIN_DIR => '/usr/local/bin';


use constant PROGRAM => eval { ($0 =~ m/(\w+\.pl)$/) ? $1 : $0 };

##############################################################################
### Globals
##############################################################################

my %hCmdLineOption = ();
my $sHelpHeader = "\nThis is ".PROGRAM."\n";

GetOptions( \%hCmdLineOption,
            'pdflist|i=s',      'outdir|o=s', 
            'project|p=s',      'pipeline|pl=s',
            'debug',
            'help',         'verbose|v',
            'man') or pod2usage(2);

## display documentation
pod2usage( -exitval => 0, -verbose => 2) if $hCmdLineOption{'man'};
pod2usage( -msg => $sHelpHeader, -exitval => 1) if $hCmdLineOption{'help'};

## make sure everything passed was peachy
check_parameters(\%hCmdLineOption);

## Define variables
my ($sOutDir, $out_file);
my $bDebug   = (defined $hCmdLineOption{'debug'}) ? TRUE : FALSE;
my $bVerbose = (defined $hCmdLineOption{'verbose'}) ? TRUE : FALSE;
my ( $fh, $ofh, $pdffh); 
my ($content, $info_content, $title_content, $text, $pdf, $font, $page);
my ($title,$width, $height);
my (@lines, @input_files);

################################################################################
### Main
################################################################################

($bDebug || $bVerbose) ? 
	print STDERR "\nProcessing output dirctory ...\n" : ();

$sOutDir = File::Spec->curdir();
if (defined $hCmdLineOption{'outdir'}) {
    $sOutDir = $hCmdLineOption{'outdir'};

    if (! -e $sOutDir) {
        mkdir($hCmdLineOption{'outdir'}) ||
            die "ERROR! Cannot create output directory\n";
    }
    elsif (! -d $hCmdLineOption{'outdir'}) {
            die "ERROR! $hCmdLineOption{'outdir'} is not a directory\n";
    }
}

$sOutDir = File::Spec->canonpath($sOutDir);

$title = "RNA-Seq Analysis Report";
my ($sec,$min,$hour,$day,$month,$yr19,@rest) =   localtime(time);


# Export pipeline info to a string
($bDebug || $bVerbose) ? 
	print STDERR "\nCollecting cover page info...\n" : ();

# Export pipeline information into a string scalar
my $info_string = '';
open ( $ofh, ">", \ $info_string) or die "cann't open $ofh";
print $ofh "Project:  $hCmdLineOption{'project'}\n";
#print $ofh "Pipeline: $hCmdLineOption{'pipeline'}\n";
print $ofh "Date:     ".++$month." - $day - ".($yr19+1900)."\n";
close $ofh;

$out_file = "$sOutDir/$hCmdLineOption{'project'}\.$hCmdLineOption{'pipeline'}\.pdf";

##Create a new PDF object

$pdf = PDF::API2->new();

$font = $pdf->corefont('Arial');
$page = $pdf->page();
$width = 120;
$height = 550;
$page->mediabox(700, 900);

# Title of cover page
$content = $page->text();
$content->translate($width, $height);
$content->font($font,36);
$title_content = $title;
$content->text($title_content);
$height = $height - 100;


@lines = split /\n/, $info_string;

    # Add a new content object
foreach(@lines){
	$content = $page->text();
	$width = 170;
	$content->translate($width, $height);
	$content->font($font,32);
	$info_content = $_;
	$content->text($info_content);
	$height = $height - 50;
}

($bDebug || $bVerbose) ? 
	print STDERR "\nProcessing PDF files in $hCmdLineOption{'pdflist'} ...\n" : ();

# PDF files to merge
if(defined $hCmdLineOption{'pdflist'}){
	open ($fh, "<",  $hCmdLineOption{'pdflist'}) or die "cannot open <  $hCmdLineOption{'pdflist'}: $!";

	@input_files = ();
	while (<$fh>){
		chomp;
		push (@input_files, $_);
	}
}
else {
	die "No pdf file is provided.\n";
}
 
foreach my $input_file (@input_files) {
    my $input_pdf = PDF::API2->open($input_file);
    my @numpages = (1..$input_pdf->pages());
    foreach my $numpage (@numpages) {
        # add page number $numpage from $input_file to the end of 
        # the file $output_file
        $pdf->importpage($input_pdf,$numpage,0);        
    }
}

$pdf->saveas($out_file);



################################################################################
### Subroutines
################################################################################


sub check_parameters {
    my $phOptions = shift;
    
    ## make sure input files provided
    if (! (defined $phOptions->{'pdflist'}) ) {
	pod2usage( -msg => $sHelpHeader, -exitval => 1);
    }
    
	if (! (defined $phOptions->{'project'}) ) {
		$phOptions->{'project'} = 'IGS';
    }
	if (! (defined $phOptions->{'pipeline'}) ) {
		$phOptions->{'pipeline'} = 'analysis';
    }
}
    

################################################################################
