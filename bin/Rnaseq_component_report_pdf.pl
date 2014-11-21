#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

################################################################################
### POD Documentation
################################################################################

=head1 NAME

    Rnaseq_component_report_pdf.pl  -    Creates a PDF report for the component of RnaSeq pipeline.

=head1 SYNOPSIS

    Rnaseq_component_report_pdf.pl       --i <indir> --c  <component>   
                                         [--o outdir] [--v]

    parameters in [] are optional
    do NOT type the carets when specifying options

=head1 OPTIONS
    
    --i <input dir>           = Path to input directory.

    --c <component>           = Component Name

    --o <output dir>          = /path/to/output directory. Optional.[PWD]

    --v                       = generate runtime messages. Optional

=head1 DESCRIPTION

Creates a PDF report for the component of the RnaSeq pipeline.

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
use Text::Table;
use Image::Scale;


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
            'indir|i=s',      'outdir|o=s', 
            'component|c=s',
            'debug',
            'help',         'verbose|v',
            'man') or pod2usage(2);

## display documentation
pod2usage( -exitval => 0, -verbose => 2) if $hCmdLineOption{'man'};
pod2usage( -msg => $sHelpHeader, -exitval => 1) if $hCmdLineOption{'help'};

## make sure everything passed was peachy
check_parameters(\%hCmdLineOption);

## Define variables
my ($sOutDir, $indir, $out_file);
my $bDebug   = (defined $hCmdLineOption{'debug'}) ? TRUE : FALSE;
my $bVerbose = (defined $hCmdLineOption{'verbose'}) ? TRUE : FALSE;
my ($path, $txtfh, $imgfh, $pdffh, $txtpath, $imgpath, $pdfpath); 
my ($text, $pdf, $font, $tab_font, $page, $image, $img, $gfx, $lines, $title,$width, $height, $height_after);
my (%quality);
my (@arr_txt, @arr_img, @file);
my $cmd;

################################################################################
### Main
################################################################################

($bDebug || $bVerbose) ? 
	print STDERR "\nProcessing file in $hCmdLineOption{'indir'} ...\n" : ();

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
$out_file = "$sOutDir/$hCmdLineOption{'component'}\.pdf";

##Create a new PDF object

$pdf = PDF::API2->new();

#Add text file and image file
$txtpath = $hCmdLineOption{'indir'}."/report_text_file.list";
$imgpath = $hCmdLineOption{'indir'}."/report_image_file.list";
$pdfpath = $hCmdLineOption{'indir'}."/report_pdf_file.list";

# add table to pdf file
$tab_font = $pdf->corefont('Courier');
$font = $pdf->corefont('Arial');
$page = $pdf->page();
$height = 850;
$page->mediabox(700, 900);


#	print "$txtpath";
if (-e $txtpath) {

	open($txtfh, "<$txtpath") or die "Error Cannot open the Quality png list file $path\n";
	while(<$txtfh>) {
		chomp($_);

		@arr_txt = split(/\t/, $_);
		$title = $arr_txt[0];
		$path = $arr_txt[1];
		$lines = `cat $path |wc -l`;
	
		if ( ($lines*10+33) <= $height ){ 
			($page,$height) = add_text_page($title, $path, $page,$tab_font, $font, $height-30);
		} 
		else{
			$page = $pdf->page();
			$height = 850;
			$page->mediabox(700, 900);
			($page,$height) = add_text_page($title, $path, $page,$tab_font, $font, $height);
		}
	}
	close $txtpath;
}

if (-e $imgpath) {
	$width = 30;
	open($imgfh, "<$imgpath") or die "Error Cannot open the Quality png list file $path\n";
	while(<$imgfh>) {
		chomp($_);
		@arr_img = split(/\t/, $_);
		$title = $arr_img[0];
		$path  = $arr_img[1];
		if ($title =~ /Base Quality/){ 
			my $img = Image::Scale->new($path) || die "Invalid png file";
			$img->resize_gd( { width => 150 } );
			$path = "$sOutDir/temp.png";
			$img->save_png($path);
		}
		
		$image = $pdf->image_png($path);

		if ( !defined $height_after){
			$height_after = $height -$image->height;
		}
		elsif ($height_after >  $height -$image->height){
			$height_after = $height -$image->height;
		}

		if(($height - $image->height) < 20){
			$page = $pdf->page();
			
			$page->mediabox(700, 900);
			$width = 30; 
			$height = 850;
			($pdf, $width, $height_after) = add_image($path, $title, $pdf, $page, $width, $height);
			
		}
		
		elsif($image->width + $width < 670){
			($pdf, $width, $height_after) = add_image($path, $title, $pdf, $page, $width, $height);
		}
			
		elsif($image->width + $width > 670 &&  $height_after - $image->height > 20){
			$width = 30;
			$height = $height_after;
			($pdf, $width, $height_after) = add_image($path, $title, $pdf, $page, $width, $height);
		}
		elsif($image->width + $width > 670 &&  $height_after - $image->height < 20){
			$page = $pdf->page();
			
			$page->mediabox(700, 900);
			$width = 30; 
			$height = 850;
			($pdf, $width, $height_after) = add_image($path, $title, $pdf, $page, $width, $height);
		}
	}
	close $imgfh;
}


if ( -e $pdfpath) {
	open($pdffh, "<$pdfpath") or die "Error Cannot open the Quality png list file $path\n";
	while(<$pdffh>) {
		chomp($_);
		$pdf = add_pdf_page($_, $pdf, $page, $height);		
	}
}

$pdf->saveas($out_file);




################################################################################
### Subroutines
################################################################################
sub add_text_page {

	my $title = shift;
	my $path = shift;
	my $page =shift;
	my $tab_font =shift;
	my $font = shift;
	my $height = shift;

	my ($fh, $ofh);
	my ($tab_title, $element, $len, $txt_string, $width, $tb, $content, $table_content);
	my (@colNames, @parts,  @lines);
	open ($fh, "<", $path) or die "cannot open $path:$!";
	$tab_title = <$fh>; 
	chomp($tab_title);
	$tab_title =~ s/\#//;
	@colNames = split("\t", $tab_title);

	foreach $element (@colNames){
		if ( $tab_title =~ /\./){
			$element =~ s/\./\.\n/;
			@parts = split(/\n/, $element);
			if ( defined $parts[1] && length($parts[0])>length($parts[1])){
				$len = length($parts[0]); 
			}
			elsif(! defined $parts[1]){
				$len = length($parts[0]);
				$element .= "\n";
			}
			else{
				$len = length($parts[1]);
			}
		}
		else {
			$len = length($element);
		}
		$element.= "\n";
		for (my $i=0; $i < $len; $i++){
			$element .= "-";
		}
	}
	$tb = Text::Table->new(@colNames);

	while(<$fh>){
		$tb->load( 
				   [split(/\t/, $_)],
				   );
	}
	close $fh;

# Export table to a string
	$txt_string = '';
	open ( $ofh, ">", \ $txt_string) or die "cann't open $ofh";
	print $ofh $tb->rule('-');
	print $ofh $tb;
	print $ofh $tb->rule('-');
	close $ofh;
	
	$width = 30;
	
# Add title
	$content = $page->text();
	$content->translate($width, $height);
	$content->font($font,12);
	$table_content .= $title;
	$content->text($table_content);
	$height = $height - 13;

	@lines = split /\n/, $txt_string;

    # Add a new content object
	foreach(@lines){
		$content = $page->text();
		$content->translate($width, $height);
		$content->font($tab_font,8);
		my $table_content .= $_;
		$content->text($table_content);
		$height = $height - 10;
	}
	

	return ($page, $height);
}

sub add_image{

	my $path = shift;
	my $title = shift;
	my $pdf = shift;
	my $page = shift;
	my $width = shift;
	my $height =shift;
	my ($image, $content, $img_title, $gfx, $height_after);
	
	$image = $pdf->image_png($path);
#$page->mediabox(-50,-50,$image->width, $image->height);
#$page->trimbox(0,0,$image->width, $image->height);

	$content = $page->text();
	$content->translate($width, $height -20);
	$content->font($font,12);
	$img_title .= $title;
	$content->text($img_title);
 
	$gfx = $page->gfx;
	$gfx->image($image, $width, $height-$image->height - 30);
	$width += (10 + $image->width);
	$height_after = $height - $image->height -30; 
	return ($pdf, $width, $height_after); 
}

sub add_pdf_page{

	my $path = shift;
	my $pdf = shift;
	my $page = shift;
	my $height = shift;

	my ($old, $count, $gfx, $xo);

	$old = PDF::API2->open($path);
	$count = $old->pages();


	for(my $i =1; $i <= $count; $i++){ 

		if ($i%2 ==1){
			if($height != 850){
				$page = $pdf->page();
				$page->mediabox(700, 900);
			}
			print "I'm here!\n";
			$gfx = $page->gfx();
# Import first figure from the old PDF

			$xo = $pdf->importPageIntoForm($old, $i);
		
# Add it to the new PDF's first half page at the same scale
			$gfx->formimage($xo, 100, 420, 0.8); 
		}
		else{
			$xo = $pdf->importPageIntoForm($old, $i);
		
# Add it to the new PDF's second half page at the same scale
			$gfx->formimage($xo, 100, 20, 0.8);
		} 
	}
	return $pdf;
}


sub check_parameters {
    my $phOptions = shift;
    
    ## make sure input files provided
    if (! (defined $phOptions->{'indir'}) ) {
	pod2usage( -msg => $sHelpHeader, -exitval => 1);
    }
    
	if (! (defined $phOptions->{'outdir'}) ) {
	pod2usage( -msg => $sHelpHeader, -exitval => 1);
    }

	if (! (defined $phOptions->{'component'}) ) {
		$phOptions->{'out_prefix'} = 'Component';
    }
}
    
sub exec_command {
        my $sCmd = shift;

        if ((!(defined $sCmd)) || ($sCmd eq "")) {
                die "\nSubroutine::exec_command : ERROR! Incorrect command!\n";
        }

        my $nExitCode;

        print STDERR "\n$sCmd\n";
        $nExitCode = system("$sCmd");
        if ($nExitCode != 0) {
                die "\tERROR! Command Failed!\n\t$!\n";
        }
        print STDERR "\n";

        return;
}  

################################################################################
