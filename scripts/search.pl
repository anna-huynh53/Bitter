#searching functions
#    names and usernames
#    words in bleats

#searches for a user's name or username
sub search_user {
    my ($search_string) = @_;
    if (!$search_string) { print "<h2>Enter something</h2>"; return; } 
    my @user_files = sort(glob("$users_dir/*"));
    my (@users, $full, $usern);
    my %user_names; #matches name with a username
    
    for my $u (@user_files) {
        open F, "$u/details.txt" or die;
        for (<F>) {
            if (/full_name: (.*)/) { push(@users,$1); $full = $1; }
            if (/username: (.*)/)  { push(@users,$1); $usern = $1; }
        }
        $user_names{$full} = $usern;
        close F;
    }
    
    my @results = ();
    for my $i (@users) {
       if ($i =~ /$search_string/i) {
           if ($user_names{$i}) {
               push(@results,"<li><a href=./bitter.cgi?page=User+Page&user=$user_names{$i}>$i</a><p>");
           } else {
               push(@results,"<li><a href=./bitter.cgi?page=User+Page&user=$i>$i</a><p>");
           }
       }
    } 
    return @results;
}

#searches for strings in bleats
sub search_bleats {
    my ($search_string) = @_;
    if (!$search_string) { return; } 
    my @results = ();
    
    for my $file (keys %bleats) {
        for my $bleater (keys %{$bleats{$file}}) {
            for my $time (keys %{$bleats{$file}{$bleater}}) {
                for my $reply (keys %{$bleats{$file}{$bleater}{$time}}) {
                    my $bleat = $bleats{$file}{$bleater}{$time}{$reply};
                    if ($bleat =~ /$search_string/i) {
                        push(@results,"<li>$bleat<p>");
                    }
                }
            }
        }
    }
    return @results;
}

#prints out results
sub search_results {
    my $search = param('search');
    $page = 1;
    if (defined param('pages')) { $page = param('pages'); }
    my @user_results = search_user($search);
    my @bleat_results = search_bleats($search);
    my $total = scalar(@user_results) + scalar(@bleat_results);
    
    my ($user_results, $bleat_results); 
    for (@user_results) { $user_results .= $_; }  
    my %bleat_pages = bleat_pagination(@bleat_results);
    my $i = 1;
    while (exists $bleat_pages{$i}) {
        $bleat_results .= "<li><a href=./bitter.cgi?search=$search&page=Search&pages=$i>$i</a></li>";
        $i++;
    }
    
    #if << pressed, goes to beginning
    #if >> pressed, goes to end of results
    if ($page eq "end") { $page = $i-1; }

    my %vars = (total => $total, 
                search => $search, 
                user_results => $user_results,
                bleat_results => $bleat_pages{$page},
                pages => $bleat_results);  
    my $results = HTML::Template->new(filename=>"html/pagination.template", die_on_bad_params=>0);
    $results->param(%vars); 
    return $results->output;
}

1
