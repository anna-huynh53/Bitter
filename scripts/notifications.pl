#functions for notifications
#    changing settings
#    making a notifications file for all users

#change notification settings
sub edit_notifications {
    $user = $curr_user; 
    my $username_not = param('username_not');
    my $bleat_not = param('bleat_not');
    my $listener_not = param('listener_not');
    my $notifs = "$users_dir/$user/notifications.txt";
    my $new_notifs = "$users_dir/$user/notifications_new.txt";

    if (-f "$notifs") {
        open IN, "<$notifs" or die;
        open OUT, ">$new_notifs" or die;
        while (<IN>) {           
            s/(username_notifications:).*/$1 $username_not/g;
            s/(bleat_notifications:).*/$1 $bleat_not/g;
            s/(listener_notifications:).*/$1 $listener_not/g;
            print OUT $_;
        }
    }    
    close OUT; 
    unlink $notifs;
    rename $new_notifs, $notifs;
    print notifications_page();
}

sub notifications_page {
    my $user = $curr_user;
    my $notifs = "$users_dir/$user/notifications.txt";
    my @options = ();

    open F, "<$notifs" or die;
    while (<F>) {
        if (/username_notifications: (.*)/) { push(@options,$1); }
        if (/bleat_notifications: (.*)/)    { push(@options,$1); }
        if (/listener_notifications: (.*)/) { push(@options,$1); }
    }
    close F;

    my %template_vars = (username_not=>$options[0],
                         bleat_not=>$options[1],
                         list_not=>$options[2]);  
    my $nots = HTML::Template->new(filename=>"html/notifications.template", die_on_bad_params=>0);
    $nots->param(%template_vars); 
    return $nots->output;
}

#notifications are default no until yes
#passing in a user will reset their options back to default
sub generate_notifications { 
    my ($default_user) = @_;
    my @user_files = sort(glob("$users_dir/*"));  
    
    if ($default_user) {
        unlink "$users_dir/$default_user/notifications.txt";
    }
    
    for my $user (@user_files) { 
        my $notifs = "$user/notifications.txt";
        if (!-f $notifs) { #or empty
            open F, ">$notifs" or die "$!";
            print F "username_notifications: no\n";
            print F "bleat_notifications: no\n";
            print F "listener_notifications: no\n";
            close F;
        }
    }
}          

1
