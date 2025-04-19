#!/usr/bin/perl -wl

# CommonAccord - bringing the world to agreement
# Written in 2014 by Primavera De Filippi To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.


use warnings;
use strict;

my %remote;
my $remote_cnt = 0;

my $path = "./Doc/";
my $orig;

# You can do a trace of all files consulted by uncommenting this and the other lines with $filelist in them.
my $filelist = ""; 

sub parse {
	
	my($file,$root,$part) = @_; my $f;

	ref($file) eq "GLOB" ? $f = $file : open $f, "<$file" or die $!;
	
	$orig = $f unless $orig;
	
	my $content = parse_root($f, $root, $part);
	if($content) { expand_fields($f, \$content, $part); return($content) }

	return;
	 
}


sub parse_root { 
	
	my ($f, $field, $oldpart) = @_; my $root;


	seek($f, 0, 0);
	while(<$f>) {
		return $root if ($root) = $_ =~ /^\Q$field\E\s*=\s*(.*?)$/;
	}
	
	
	seek($f, 0, 0);
	while(<$f>) {
		my($part,$what, $newfield);
		if( (($part, $what) = $_ =~ /^([^=]*)=\[(.+?)\]/) and ($field =~ /^\Q$part\E/ )) {
			if ( $part && ($field =~ /^\Q$part\E(.+?)$/) ){ $newfield = $1;}
			
			$part = $oldpart . $part if $oldpart;
			# Follow a URL
			if($what =~ s/^http//) { 
				$what = 'http' . $what;
				if(! $remote{$path.$what}) {  $remote_cnt++;
					`curl '$what' > '$path/tmp$remote_cnt'`;
					$remote{$path.$what} = "$path/tmp$remote_cnt";
				}
				$root = parse($remote{$path.$what}, $newfield || $field, $part);
			}
			# Look locally for a file
			else {
				$root = parse($path.$what, $newfield || $field, $part);
			}
  $filelist =  "<tr><td align='left' valign='top'>" . $part . "</td><td valign='top' align='left' valign=top>" . $field. " <br>[" . $what. "]</td><td>" . $root . "</td></tr>" . $filelist  ; # to make a list of each file visited.

			return $root if $root;
		}
	      }
	
	return $root;

} 

sub expand_fields  {

	my($f,$field,$part) = @_;
	

	foreach( $$field =~ /\{([^}]+)\}/g ) {
	  my $ex = $_;
	  my $ox = $part ? $part . $ex : $ex;
	  my $value = parse($orig, $ox); 
	  my $spanvalue = "<span title=\"" . $ox . "\" id=\"" . $ox . "\" >". $value . "</span>";
	  $$field =~ s/\{\Q$ex\E\}/$spanvalue/gg if $value;
	}
      }

# Now with key option as $ARGV[1]

my $output  = parse($ARGV[0], $ARGV[1]);
# "$filelist is list of files visited if line 65 is uncommented"

# print $output . "\n\n";

print  "<table style='width:100%'><tr><th align='left' style='width:10%'>Prefix</th><th align='left' style='width:10%'>Key -- File</th><th align='left' style='width:80%'>Output</th></tr>" . $filelist . "</table>";


#clean up the temporary files (remote fetching)
`rm $_` for values %remote;

################################################################################
#!/usr/bin/perl -wl

# CommonAccord - bringing the world to agreement
# Written in 2014 by Primavera De Filippi To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.


use warnings;
use strict;

my $path = "./Doc/";

my %imports;

sub tree_parse {

	my ($file) = @_; my $f; open $f,  $file or die "error opening ($file):  $!\n";

	$imports{$file} = [];

	while(<$f>) {
	
		my($one, $two);
		
		 if( ( ($one,$two) = $_ =~m/^([^=]*)=\[(.+?)\]/ ) ) {

                        push @{ $imports{$file} }, $path . $two;

                        tree_parse($path. $two);
		}
	}
	
}


tree_parse($ARGV[0]);

print " [ \n";
foreach my $k (keys(%imports)) {
	print ' { "name": "'.$k.'", "imports": ['; 
	print '"'. $_ .'",' foreach @{ $imports{$k} };
	print '] },';
}
print " ] \n";

################################################################################
#!/usr/bin/perl -wl

# CommonAccord - bringing the world to agreement
# Written in 2014 by Primavera De Filippi To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.


use warnings;
use strict;

my %remote;
my $remote_cnt = 0;

my $path = "./Doc/";
my $orig;
my $defterm;
  
sub parse {
	
	my($file,$root,$part) = @_; my $f;


	ref($file) eq "GLOB" ? $f = $file : open $f, $file or die $!;
	$orig = $f unless $orig;
	
	my $content = parse_root($f, $root, $part);
	if($content) { expand_fields($f, \$content, $part); return($content) }

	return;
}


sub parse_root { 
	
	my ($f, $field, $oldpart) = @_; my $root;


	seek($f, 0, 0);
	while(<$f>) {
		return $root if ($root) = $_ =~ /^\Q$field\E\s*=\s*(.*?)$/;
	}
	
	
	seek($f, 0, 0);
	while(<$f>) {
		my($part,$what, $newfield);
#		if( (($part, $what) = $_ =~ /^([^=]*)=\[(.+?)\]/) and ($field =~ s/^\Q$part\E//) ) {
		if( (($part, $what) = $_ =~ /^([^=]*)=\[(.+?)\]/) and ($field =~ /^\Q$part\E/ )) {
			if ( $part && ($field =~ /^\Q$part\E(.+?)$/) ){ $newfield = $1;}
			
			$part = $oldpart . $part if $oldpart;
			# Follow a URL
			if($what =~ s/^http//) { 
				$what = 'http' . $what;
				if(! $remote{$path.$what}) {  $remote_cnt++;
					`curl '$what' > '$path/tmp$remote_cnt.cmacc'`;
					$remote{$path.$what} = "$path/tmp$remote_cnt.cmacc";
				}
				$root = parse($remote{$path.$what}, $newfield || $field, $part);
			}
			# Look locally for a file
			else {
				$root = parse($path.$what, $newfield || $field, $part);
			}
			return $root if $root;
		}
	}
	return $root;

} 

sub expand_fields  {

	my($f,$field,$part) = @_;

	foreach( $$field =~ /\{([^}]+)\}/g ) {
		my $ex = $_;
		my $ox = $part ? $part . $ex : $ex;
		my $value = parse($orig, $ox);
		$$field =~ s/\{\Q$ex\E\}/$value/gg if $value;
	}
} 


# Now with key option as $ARGV[1]

my $output  = parse($ARGV[0], $ARGV[1]);

# print $output;

# XXX FIX ME XXX This is horrible - but  I'm just dead tired  :(
my %seen; my @arr = $output=~/\{([^}]+)\}/g;
@arr = grep { ! $seen{$_}++ } @arr;

# select one:

# Key=

print "$_=<br><br>" foreach @arr;

# Key=Key;

# print "$_=<span class='param'>$_</a>" foreach @arr;

# To make a new DefinedTerm, with a hyperlink to the definition:

# print "$_=<a href='#Def." . substr($_, 1).".sec' class='definedterm'>". substr($_, 1)."</a>\n" foreach @arr;

# to mark the place a defined term is defined inline - use the convention "{DefT.My_Term}".  This will make Def.My_Term.sec={_My_Term}.

# print "$_=\{_" . substr($_, 4, -4) ."\}\n" foreach @arr;

# Make cross-references (that already have "".Xnum");

# print "$_=<a href='#" . substr($_, 0, -5) . ".sec'>" . substr($_, 0, -5)."</a>\n" foreach @arr;


# Make footnote, FtNt cross-references (that already have "".Xnum");

# print "$_=<sup><a href='#" . substr($_, 0, -5) . ".sec'>" . substr($_, 5, -5)."</a></sup>\n" foreach @arr;

#clean up the temporary files (remote fetching)
`rm $_` for values %remote;

################################################################################
#!/usr/bin/perl -wl

# CommonAccord - bringing the world to agreement
# Written in 2014 by Primavera De Filippi To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.


use warnings;
use strict;

my %remote;
my $remote_cnt = 0;

my $path = "./Doc/";
my $orig;

# You can do a trace of all files consulted by using the parser-trace.pl file.
# my $filelist = ""; 

sub parse {
	
	my($file,$root,$part) = @_; my $f;

	ref($file) eq "GLOB" ? $f = $file : open $f, "<$file" or die $!;
	
	$orig = $f unless $orig;
	
	my $content = parse_root($f, $root, $part);
	if($content) { expand_fields($f, \$content, $part); return($content) }

	return;
	 
}


sub parse_root { 
	
	my ($f, $field, $oldpart) = @_; my $root;


	seek($f, 0, 0);
	while(<$f>) {
		return $root if ($root) = $_ =~ /^\Q$field\E\s*=\s*(.*?)$/;
	}
	
	
	seek($f, 0, 0);
	while(<$f>) {
		my($part,$what, $newfield);
		if( (($part, $what) = $_ =~ /^([^=]*)=\[(.+?)\]/) and ($field =~ /^\Q$part\E/ )) {
			if ( $part && ($field =~ /^\Q$part\E(.+?)$/) ){ $newfield = $1;}
			
			$part = $oldpart . $part if $oldpart;
			# Follow a URL
			if($what =~ s/^http//) { 
				$what = 'http' . $what;
				if(! $remote{$path.$what}) {  $remote_cnt++;
					`curl '$what' > '$path/tmp$remote_cnt'`;
					$remote{$path.$what} = "$path/tmp$remote_cnt";
				}
				$root = parse($remote{$path.$what}, $newfield || $field, $part);
			}
			# Look locally for a file
			else {
				$root = parse($path.$what, $newfield || $field, $part);
			}
 # $filelist =  "<tr><td>" . $part . "</td><td>" . $field. "</td><td>" . $what. "</td></tr>" . $filelist  ; # to make a list of each file visited.

			return $root if $root;
		}
	      }
	
	return $root;

} 

sub expand_fields  {

	my($f,$field,$part) = @_;
	

	foreach( $$field =~ /\{([^}]+)\}/g ) {
	  my $ex = $_;
	  my $ox = $part ? $part . $ex : $ex;
	  my $value = parse($orig, $ox); 
	  my $spanvalue = "<span title='" . $ox . "' id='" . $ox . "'>". $value . "</span>";
	  if($ox =~ /!!$/) { $spanvalue = $value; }
 	    
		  $$field =~ s/\{\Q$ex\E\}/$spanvalue/gg if $value;
	}
      }

# Now with key option as $ARGV[1]

my $output  = parse($ARGV[0], $ARGV[1]);
# "$filelist is list of files visited if line 65 is uncommented"

print $output . "\n\n";

#  print  "<table style='width:100%'><tr><th style='width:10%'>Prefix</th><th style='width:10%'>Key</th><th style='width:80%'>File</th></tr>" . $filelist . "</table>";


#clean up the temporary files (remote fetching)
`rm $_` for values %remote;

################################################################################
#!/usr/bin/perl -wl

# CommonAccord - bringing the world to agreement
# Written in 2014 by Primavera De Filippi To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.


use warnings;
use strict;

my %remote;
my $remote_cnt = 0;

my $path = "./Doc/";
my $orig;

my $filelist = "";

my $counter = 0;

sub parse {
	
	my($file,$root,$part) = @_; my $f;


	ref($file) eq "GLOB" ? $f = $file : open $f, $file or die $!;
	$orig = $f unless $orig;
	
	my $content = parse_root($f, $root, $part);
	if($content) { expand_fields($f, \$content, $part); return($content) }

	return;
}


sub parse_root { 
	
	my ($f, $field, $oldpart) = @_; my $root;


	seek($f, 0, 0);
	while(<$f>) {
		return $root if ($root) = $_ =~ /^\Q$field\E\s*=\s*(.*?)$/;
	}
	
	
	seek($f, 0, 0);
	while(<$f>) {
		my($part,$what, $newfield);
#		if( (($part, $what) = $_ =~ /^([^=]*)=\[(.+?)\]/) and ($field =~ s/^\Q$part\E//) ) {
		if( (($part, $what) = $_ =~ /^([^=]*)=\[(.+?)\]/) and ($field =~ /^\Q$part\E/ )) {
			if ( $part && ($field =~ /^\Q$part\E(.+?)$/) ){ $newfield = $1;}
			
			$part = $oldpart . $part if $oldpart;
			# Follow a URL
			if($what =~ s/^http//) { 
				$what = 'http'. $what;
				if(! $remote{$path.$what}) {  $remote_cnt++;
					`curl '$what' > '$path/tmp$remote_cnt.cmacc'`;
					$remote{$path.$what} = "$path/tmp$remote_cnt.cmacc";
				}
				$root = parse($remote{$path.$what}, $newfield || $field, $part);
			}
			# Look locally for a file
			else {
				$root = parse($path.$what, $newfield || $field, $part);
			}
	$filelist = $filelist . "<br><br>". $counter . ":  [" . $what. "] ". $field . " = " . $root ;
			$counter = $counter+1;
			return $root if $root;
		}
	      }
	
	return $root;

} 

sub expand_fields  {

	my($f,$field,$part) = @_;



foreach( $$field =~ /\{([^}]+)\}/g ) {
       my $ex = $_;
       my $ox = $part ? $part . $ex : $ex;

       my $value = parse($orig, $ox);      
  	  my $spanvalue = "<span title=\"" . $ox . "\" id=\"" . $ox . "\" >(<b>". $ox . "</b> = ". $value . ")</span><br>";

#       my $spanvalue = "<span title=\"" . $ox . "\" id=\"" . $ox . "\" >(". $value . ")</span>";
       $$field =~ s/\{\Q$ex\E\}/$spanvalue/gg if $value;
     }
      }

# Now with key option as $ARGV[1]

my $output  = parse($ARGV[0], $ARGV[1]);

print $output;

# print "\n\n" . $filelist;

#clean up the temporary files (remote fetching)
`rm $_` for values %remote;

################################################################################
#!/usr/bin/perl -wl

# CommonAccord - bringing the world to agreement
# Written in 2014 by Primavera De Filippi To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.


use warnings;
use strict;

my %remote;
my $remote_cnt = 0;

my $path = "./Doc/";
my $orig;

sub parse {
	
	my($file,$root,$part) = @_; my $f;


	ref($file) eq "GLOB" ? $f = $file : open $f, $file or die $!;
	$orig = $f unless $orig;
	
	my $content = parse_root($f, $root, $part);
	if($content) { expand_fields($f, \$content, $part); return($content) }

	return;
}


sub parse_root { 
	
	my ($f, $field, $oldpart) = @_; my $root;


	seek($f, 0, 0);
	while(<$f>) {
		return $root if ($root) = $_ =~ /^\Q$field\E\s*=\s*(.*?)$/;
	}
	
	
	seek($f, 0, 0);
	while(<$f>) {
		my($part,$what, $newfield);
#		if( (($part, $what) = $_ =~ /^([^=]*)=\[(.+?)\]/) and ($field =~ s/^\Q$part\E//) ) {
		if( (($part, $what) = $_ =~ /^([^=]*)=\[(.+?)\]/) and ($field =~ /^\Q$part\E/ )) {
			if ( $part && ($field =~ /^\Q$part\E(.+?)$/) ){ $newfield = $1;}
			
			$part = $oldpart . $part if $oldpart;
			
			if($what =~ s/^\?//) { 
				if(! $remote{$path.$what}) {  $remote_cnt++;
					`curl '$what' > '$path/tmp$remote_cnt.cmacc'`;
					$remote{$path.$what} = "$path/tmp$remote_cnt.cmacc";
				}
				$root = parse($remote{$path.$what}, $newfield || $field, $part);
			}
			else {
				$root = parse($path.$what, $newfield || $field, $part);
			}
			return $root if $root;
		}
	}
	return $root;

} 

sub expand_fields  {

	my($f,$field,$part) = @_;

	foreach( $$field =~ /\{([^}]+)\}/g ) {
		my $ex = $_;
		my $ox = $part ? $part . $ex : $ex;
    if ( substr($ox,-2) eq "!!") {
      $ox = substr($ox,0,-2)}
 
		my $value = parse($orig, $ox);
		$$field =~ s/\{\Q$ex\E\}/$value/gg if $value;
	}
} 



my $output  = parse($ARGV[0], "CSS.Special");
print $output;

#clean up the temporary files (remote fetching)
`rm $_` for values %remote;

################################################################################
#!/usr/bin/perl -wl

# CommonAccord - bringing the world to agreement
# Written in 2014 by Primavera De Filippi To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.


use warnings;
use strict;

my %remote;
my $remote_cnt = 0;

my $path = "./Doc/";
my $orig;

my $filelist = "";

sub parse {
	
	my($file,$root,$part) = @_; my $f;


	ref($file) eq "GLOB" ? $f = $file : open $f, $file or die $!;
	$orig = $f unless $orig;
	
	my $content = parse_root($f, $root, $part);
	if($content) { expand_fields($f, \$content, $part); return($content) }

	return;
}


sub parse_root { 
	
	my ($f, $field, $oldpart) = @_; my $root;


	seek($f, 0, 0);
	while(<$f>) {
		return $root if ($root) = $_ =~ /^\Q$field\E\s*=\s*(.*?)$/;
	}
	
	
	seek($f, 0, 0);
	while(<$f>) {
		my($part,$what, $newfield);
#		if( (($part, $what) = $_ =~ /^([^=]*)=\[(.+?)\]/) and ($field =~ s/^\Q$part\E//) ) {
		if( (($part, $what) = $_ =~ /^([^=]*)=\[(.+?)\]/) and ($field =~ /^\Q$part\E/ )) {
			if ( $part && ($field =~ /^\Q$part\E(.+?)$/) ){ $newfield = $1;}
			
			$part = $oldpart . $part if $oldpart;
			
			if($what =~ s/^\?//) { 
				if(! $remote{$path.$what}) {  $remote_cnt++;
					`curl '$what' > '$path/tmp$remote_cnt.cmacc'`;
					$remote{$path.$what} = "$path/tmp$remote_cnt.cmacc";
				}
				$root = parse($remote{$path.$what}, $newfield || $field, $part);
			}
			else {
				$root = parse($path.$what, $newfield || $field, $part);
			}
	$filelist = $filelist . "<br><br>[" . $what. "]";

			return $root if $root;
		}
	      }
	
	return $root;

} 

sub expand_fields  {

	my($f,$field,$part) = @_;



foreach( $$field =~ /\{([^}]+)\}/g ) {
       my $ex = $_;
       my $ox = $part ? $part . $ex : $ex;

       my $value = parse($orig, $ox);      
       my $spanvalue = "<span title=\"" . $ox . "\" id=\"" . $ox . "\" >". $value . "</span>";
       $$field =~ s/\{\Q$ex\E\}/$spanvalue/gg if $value;
     }
      }


my $output  = parse($ARGV[0], "r00t");
print $output . "\n\n" . $filelist;

#clean up the temporary files (remote fetching)
`rm $_` for values %remote;

################################################################################
#!/usr/bin/perl -wl

# CommonAccord - bringing the world to agreement
# Written in 2014 by Primavera De Filippi To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.


use warnings;
use strict;

my %remote;
my $remote_cnt = 0;

my $path = "./Doc/";
my $orig;
my $defterm;
  
sub parse {
	
	my($file,$root,$part) = @_; my $f;


	ref($file) eq "GLOB" ? $f = $file : open $f, $file or die $!;
	$orig = $f unless $orig;
	
	my $content = parse_root($f, $root, $part);
	if($content) { expand_fields($f, \$content, $part); return($content) }

	return;
}


sub parse_root { 
	
	my ($f, $field, $oldpart) = @_; my $root;


	seek($f, 0, 0);
	while(<$f>) {
		return $root if ($root) = $_ =~ /^\Q$field\E\s*=\s*(.*?)$/;
	}
	
	
	seek($f, 0, 0);
	while(<$f>) {
		my($part,$what, $newfield);
#		if( (($part, $what) = $_ =~ /^([^=]*)=\[(.+?)\]/) and ($field =~ s/^\Q$part\E//) ) {
		if( (($part, $what) = $_ =~ /^([^=]*)=\[(.+?)\]/) and ($field =~ /^\Q$part\E/ )) {
			if ( $part && ($field =~ /^\Q$part\E(.+?)$/) ){ $newfield = $1;}
			
			$part = $oldpart . $part if $oldpart;
			
		if($what =~ s/^http//) { 
				$what = 'http' . $what;
					if(! $remote{$path.$what}) {  $remote_cnt++;
					`curl '$what' > '$path/tmp$remote_cnt.cmacc'`;
					$remote{$path.$what} = "$path/tmp$remote_cnt.cmacc";
				}
				$root = parse($remote{$path.$what}, $newfield || $field, $part);
			}
			else {
				$root = parse($path.$what, $newfield || $field, $part);
			}
			return $root if $root;
		}
	}
	return $root;

} 

sub expand_fields  {

	my($f,$field,$part) = @_;

	foreach( $$field =~ /\{([^}]+)\}/g ) {
		my $ex = $_;
		my $ox = $part ? $part . $ex : $ex;
		my $value = parse($orig, $ox);
		$$field =~ s/\{\Q$ex\E\}/$value/gg if $value;
	}
} 



# Now with key option as $ARGV[1]

my $output  = parse($ARGV[0], $ARGV[1]);

# print $output;

# XXX FIX ME XXX This is horrible - but  I'm just dead tired  :(
my %seen; my @arr = $output=~/\{([^}]+)\}/g;
@arr = grep { ! $seen{$_}++ } @arr;


foreach ( @arr ) {

#Change print substr($_, 0) to print substr($_, 0, 5) to remove the "DefT." prefix.
if (substr($_, 0, 5) eq "DefT.") {	
	print substr($_, 0) . "={_". substr($_ , 5) . "}\n";	
}

elsif (substr($_, 0, 1) eq "_") {	
		print substr($_, 1) . "=<a class='definedterm' href='{!!!}DefT." . substr($_, 1) . "'>". substr($_ , 1) . "</a>\n";
}

elsif(substr($_, -5 ) eq ".Xnum") {
	print "$_=<a class='xref' href='{!!!}" . substr($_, 0, -5) . ".sec'>" . substr($_, 0, -5)."</a>\n";	
		}

else { print $_ . "=\n"; }
} 

#clean up the temporary files (remote fetching)
`rm $_` for values %remote;

################################################################################
#!/usr/bin/perl -wl

# CommonAccord - bringing the world to agreement
# Written in 2014 by Primavera De Filippi To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.


use warnings;
use strict;

my %remote;
my $remote_cnt = 0;

my $path = "./Doc/";
my $orig;

sub parse {
	
	my($file,$root,$part) = @_; my $f;


	ref($file) eq "GLOB" ? $f = $file : open $f, $file or die $!;
	$orig = $f unless $orig;
	
	my $content = parse_root($f, $root, $part);
	if($content) { expand_fields($f, \$content, $part); return($content) }

	return;
}


sub parse_root { 
	
	my ($f, $field, $oldpart) = @_; my $root;


	seek($f, 0, 0);
	while(<$f>) {
		return $root if ($root) = $_ =~ /^\Q$field\E\s*=\s*(.*?)$/;
	}
	
	
	seek($f, 0, 0);
	while(<$f>) {
		my($part,$what, $newfield);
#		if( (($part, $what) = $_ =~ /^([^=]*)=\[(.+?)\]/) and ($field =~ s/^\Q$part\E//) ) {
		if( (($part, $what) = $_ =~ /^([^=]*)=\[(.+?)\]/) and ($field =~ /^\Q$part\E/ )) {
			if ( $part && ($field =~ /^\Q$part\E(.+?)$/) ){ $newfield = $1;}
			
			$part = $oldpart . $part if $oldpart;
			
			if($what =~ s/^http//) { 
				$what = 'http' . $what;
				if(! $remote{$path.$what}) {  $remote_cnt++;
					`curl '$what' > '$path/tmp$remote_cnt.cmacc'`;
					$remote{$path.$what} = "$path/tmp$remote_cnt.cmacc";
				}
				$root = parse($remote{$path.$what}, $newfield || $field, $part);
			}
			else {
				$root = parse($path.$what, $newfield || $field, $part);
			}
			return $root if $root;
		}
	}
	return $root;

} 

sub expand_fields  {

	my($f,$field,$part) = @_;

	foreach( $$field =~ /\{([^}]+)\}/g ) {
		my $ex = $_;
		my $ox = $part ? $part . $ex : $ex;
    if ( substr($ox,-2) eq "!!") {
      $ox = substr($ox,0,-2)}
 
		my $value = parse($orig, $ox);
		$$field =~ s/\{\Q$ex\E\}/$value/gg if $value;
	}
} 

# Now with key option as $ARGV[1]

my $output  = parse($ARGV[0], $ARGV[1]);

print $output;

#clean up the temporary files (remote fetching)
`rm $_` for values %remote;

################################################################################