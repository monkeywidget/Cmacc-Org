sub expand_fields_docmap  {

	my($f,$field,$part) = @_;



    foreach( $$field =~ /\{([^}]+)\}/g ) {
       my $ex = $_;
       my $ox = $part ? $part . $ex : $ex;

       my $value = parse($orig, $ox);      
       my $spanvalue = "<span title=\"" . $ox . "\" id=\"" . $ox . "\" >". $value . "</span>";
       $$field =~ s/\{\Q$ex\E\}/$spanvalue/gg if $value;
     }
      }

sub expand_fields_docmap  {

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
