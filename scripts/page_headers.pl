#functions to print header and trailer

sub user_header {
    my $user = $curr_user;
    my $bleats = "$users_dir/$user/bleats.txt";
    my $pic = "images/anonymous.jpg";
    my $listens;
  
    if (-f "$users_dir/$user/profile.jpg") {
        $pic = "$users_dir/$user/profile.jpg";
    } 
      
    my @listens = split(" ", $details{listens});
    my $listen_num = scalar(@listens);
    
    my $bleat_num = 0;
    open IN, "<$bleats";
    while (<IN>) {
        if (/\d+/) { $bleat_num++ };
    }
    close IN;
    
    my %template_vars = (
        pic => $pic,
        user => $user,
        listen_num => $listen_num,
        bleat_num => $bleat_num);    
    my $user_header = HTML::Template->new(filename=>"html/user_header.template", 
                                          die_on_bad_params=>0);
    $user_header->param(%template_vars); 
    return $user_header->output;       
}

# HTML placed at the bottom of every page
# It includes all supplied parameter values as a HTML comment
# if global variable $debug is set
sub page_trailer {
    #my $html = "";
    #$html .= join("", map("<!-- $_=".param($_)." -->\n", param())) if $debug;
    #$html .= end_html;
    #return $html;
	return <<eof;
</body>
</html>
eof
}

1
