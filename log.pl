#!/usr/local/bin/perl

use strict;
use warnings;
use XML::Twig;
use Data::Dumper;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);

my $usage = "$0 [--options] \"message\"\n".
    "Options:\n".
    "\t--date|-d\tDate for message to be logged under\n".
    "\t--time|-t\tTime for message to be logged under\n".
    "\t--tag|-a\tTags to apply to message\n".
    "\t--category|-c\tCategory for message [required]\n".
    "\t--publish|-p\tPublish log to a permanent logfile\n".
    "\t--view|-v\tView current log information in STDOUT\n".
    "\t--help|-h\tprint usage\n";
my $log_dir = "/home/sadkins/logs";
my $current_logfile = "$log_dir/current.work.log";
my $category;
my $tags = [];
my ($date,$time) = (&prettydate, &prettytime);

my %options;
my $result = GetOptions (\%options, 
			 'publish|p',
			 'view|v',
                         'date|d=s',
                         'time|t=s',
                         'tag|a=s@',
                         'category|c=s',
                         'help|h');

&check_options( \%options );

unless( $ARGV[0] ) {
    die("$usage");
}

&log( @ARGV );

#################################
sub check_options {
    my $opts = shift;
    
    if ($opts->{'publish'}) {
    	publish();
    	exit;
    }
    
    if ($opts->{'view'}) {
    	view();
    	exit;
    }

    if( $opts->{'help'} ) {
        print "$usage\n";
        exit(0);
    }

    if( $opts->{'category'} ) {
        $category = $opts->{'category'};
    } else {
        print STDERR "Option --category is required\n\n";
        print STDERR $usage;
        exit(1);
    }

    if( $opts->{'date'} ) {
        $date = $opts->{'date'};
    }

    if( $opts->{'time'} ) {
        $time = $opts->{'time'};
    }

    if( $opts->{'tag'} ) {
        $tags = $opts->{'tag'};
    }
}

sub log {
    my (@msg) = @_;
    my $message = join( ' ', @msg );

    #Check to make sure date and time are in correct format
    die("Time is not in correct format. Should be 'hh:mm'") unless( $time =~ m|\d{2}:\d{2}| );
    die("Date is not in correct format. Should be 'mm/dd/yyyy'") unless( $date =~ m|\d{2}/\d{2}/\d{4}| );
    
    #open the current logfile for appending
    open( my $fh, ">> $current_logfile") or die("Unable to open $current_logfile");

    #print the time and date and the log message
    print $fh "date $date\n";
    print $fh "time $time\n";
    print $fh "category $category\n";
    map { print $fh "tag $_\n" } @{$tags};
    print $fh "message $message\n";
    print $fh "end\n";
    
    print "Logged message: \n$time $date\n$message\n";

    #Close our file handle
    close($fh);    

}

sub publish {
    die("A current logfile does not exist ( $current_logfile )") 
        unless( -e $current_logfile );

    my @time = localtime( time );
    my $year = $time[5]+1900;
    my $month = $time[4]+1;
    my $day = $time[3];

    system("mkdir -p $log_dir/work_reports/$year/$month");
    
    my $stored_logfile = &prettydate;
    $stored_logfile =~ s/[:\/]/_/g;
    $stored_logfile =~ s/\s/-/g;
    $stored_logfile .= ".log";
    $stored_logfile = "$log_dir/work_reports/$year/$month/$stored_logfile";

    open( OUT, ">$stored_logfile") or die("Unable to open $stored_logfile ($!)");


    print OUT sprintf("%02d%02d%02d", ($time[5]+1900), ($time[4]+1), $time[3] );
    print OUT "Weekly Report - Shaun Adkins \n\n";
    print OUT "Accomplishments:\n\n";

    open( IN, "< $current_logfile") or die("Could not open ($!)");

    my %entries;
    my ($category, $message);
    while( my $line = <IN> ) {
        chomp( $line );

	if ($line =~ /category\s+(.*)/) {
		$category = $1;
	}
	if ($line =~ /message\s+(.*)/) {
		$message = $1;
	}
	if ($line =~ /end/) {
		push @{$entries{$category}}, $message;
		$category = "";
		$message = "";
	}
    }


    foreach my $entry ( keys (%entries) ) {
		my $count = 1;
        print OUT $entry."\n";
        foreach my $m (@{$entries{$entry}}) {
        	print OUT $count . ")\t" . $m . "\n";
			$count++;
        }
		#print OUT "\n";
    }

    close( IN );
    close( OUT );

    print "$stored_logfile\n";

    system("rm $current_logfile");
    system("touch $current_logfile");
}

sub view {
    die("A current logfile does not exist ( $current_logfile )") 
        unless( -e $current_logfile );

    open(IN, "< $current_logfile") or die("Unable to open $current_logfile ($!)");
    print <IN>;
    close(IN);
    
}

sub by_category {

}

sub print_message_to_xml {
    my ($action, $message, $file) = @_;
    
    if( -e $file ) {
        debug( "$file exists. Validating.");

        #Assume it's valid
        my $valid = 1;
        
        #Create a twig, which will do an intial parse
        my $twig = new XML::Twig;

        #This will fail if the file isn't xml
        eval {
            $twig->parsefile( $file );
        }; 
        if( $@ ) {
            #Set to zero if we found an error
            $valid = 0;
        }

        if( $valid ) {
            _debug("XML is valid");
        } else {
            my $backup_file = $file.".bak";
            _warn("XML is not valid.  Moving $file to $file.bak and recreating $file");
        }
    }
    
}


sub prettydate {
   @_ = localtime(time);
   return sprintf("%02d/%02d/%04d", $_[4]+1, $_[3], $_[5]+1900);
} 

sub prettytime {
   my @time = localtime(time);
   return sprintf("%02d:%02d", @time[2,1]);
} 

sub _debug {
    my $debug = shift;
    print $_[0] if( $debug );
}
sub _warn {
    croak( $_[0] );
}
