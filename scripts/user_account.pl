#contains functions for a user
#   displaying a user page
#   editing profile
#   listening and unlistening to other users
#   changing password, email and other info

#user information for any given user
sub user_page {
    my ($username) = @_;
    my %details;
    
    #if user hidden or deleted
    if (-f "$users_dir/hidden-$username") {
        my $user_page = HTML::Template->new(filename=>"html/another_user.template", 
                                            die_on_bad_params=>0);
        $user_page->param(); 
        return $user_page->output;  
    }
    
    #profile picture is anonymous if one does not exist
    my $pic = "images/anonymous.jpg";
    if (-f "$users_dir/$username/profile.jpg") {
        $pic = "$users_dir/$username/profile.jpg";
    } 
    
    #extracts information 
    my $user_file = "$users_dir/$username";
    open F, "$user_file/details.txt";
    while (<F>) {
        if (/(full_name):(.*)/) { $details{$1} = $2; }
        if (/(listens):(.*)/)   { $details{$1} = $2; }
        if (/(suburb):(.*)/)    { $details{$1} = $2; }
        if (/(latitude):(.*)/)  { $details{$1} = $2; }
        if (/(longitude):(.*)/) { $details{$1} = $2; }
    }
    close F;
    
    my @listens = split(" ", $details{listens});
    my $list_num = scalar(@listens);
    
    #extracts profile
    my $profile = "$users_dir/$username/profile.txt";
    open PROFILE, "$profile";
    my $content = "";
    while (<PROFILE>) {
        $content .= "$_";
    } 
    close PROFILE;
    
    #sorts bleats
    my $bleats = "";
    my $bleat_num = 0;
    for my $time (reverse sort keys %{$bleats{$username}}) {
        for my $file (keys %{$bleats{$username}{$time}}) {
            for my $reply (keys %{$bleats{$username}{$time}{$file}}) {
                my $bleat = $bleats{$username}{$time}{$file}{$reply};
                if ($username eq $session->param('username')) {
                    #temporary fix
                    $bleats .= "<li class='list-group-item'>$bleat <a href='./bitter.cgi?page=Delete+Bleat&bleatID=$file' class='btn btn-xs btn-default'><span class='glyphicon glyphicon-remove'></span> Delete Bleat</a>";
                } else {
                    $bleats .= "<li class='list-group-item'>$bleat<a href='./bitter.cgi?page=Reply+Bleat&replyTo=$file' class='btn btn-xs btn-default' role='button' data-toggle='modal'><span class='glyphicon glyphicon-share-alt'></span> Reply</a></li>";
                }
            }
            $bleat_num++;
        }
    }
    
    my @vars = (profile => $content,
                name => $details{full_name},
                listening => $details{listens},
                suburb => $details{suburb},
                latitude => $details{latitude},
                longitude => $details{longitude},
                bleats => $bleats);
    if ($curr_user eq $username) { 
        my %template_vars = (@vars);    
        my $user_page = HTML::Template->new(filename=>"html/user_page.template", die_on_bad_params=>0);
        $user_page->param(%template_vars); 
        return $user_page->output;      
    } else { #if viewing another user's profile, the pic will show
        my %template_vars = (pic => $pic, 
                             username => $username, 
                             list_num => $list_num, 
                             bleat_num => $bleat_num, @vars);   
        my $user_page = HTML::Template->new(filename=>"html/another_user.template", die_on_bad_params=>0);
        $user_page->param(%template_vars); 
        return $user_page->output; 
    }     
}

#edit name and suburb
#any empty spaces in the form will mean those parts remain the same
sub edit_information {
    my $user = $curr_user;
    my $info = "$users_dir/$user/details.txt";
    my $new_info = "$users_dir/$user/details_new.txt";
    my ($name, $email, $suburb, %details);
      
    open IN, "<$info" or die;
    while (<IN>) {
        if (/(full_name): (.*)/) { $details{$1} = $2; }
        if (/(email): (.*)/)     { $details{$1} = $2; }
        if (/(suburb): (.*)/)    { $details{$1} = $2; }
    }
    close IN;
    if (param('name') eq "") { 
        $name = $details{full_name}; 
    } else {
        $name = param('name');
    }
    if (param('email') eq "") { 
        $email = $details{email}; 
    } else {
        $email = param('email');
        $email .= " (NOT VERIFIED)";
    }
    if (param('suburb') eq "") { 
        $suburb = $details{suburb}; 
    } else {
        $suburb = param('suburb');
    }   
    open IN, "<$info" or die;
    open OUT, ">$new_info" or die;
    while (<IN>) {
        s/(full_name:).*/$1 $name/g;
        s/(email:).*/$1 $email/g;
        s/(suburb:).*/$1 $suburb/g;
        print OUT $_;
    }
    close OUT;
    unlink $info;
    rename $new_info, $info;
    
    return information_view();   
}

#old email stays until verified
sub change_email {
    my %template_vars = (email => $details{email});    
    my $email_change = HTML::Template->new(filename=>"html/change_email.template", die_on_bad_params=>0);
    $email_change->param(%template_vars); 
    return $email_change->output;   
}

sub change_password {
    my $user = $curr_user;
    my $info = "$users_dir/$user/details.txt";
    my $new_info = "$users_dir/$user/details_new.txt";

    my $old_pw;
    open IN, "<$info" or die;
    while (<IN>) {
        if (/(password):(.*)/) { $old_pw = $2; }
    }
    close IN;  
    
    my $old_input = param('old_pw');
    if ($old_pw != $old_input) {
        print "Wrong password";
    } else {       
        my $pw = param('password');
        open IN, "<$info" or die;
        open OUT, ">$new_info" or die;
        while (<IN>) {
            s/(password:).*/$1 $pw/g;
            print OUT $_;
        }
        close OUT;
        unlink $info;
        rename $new_info, $info;    
    }
    print error("Password changed", "Password+Change");
}

#displays the edit info form
sub information_view {
    my $username = $session->param('username');
    my $user_file = "$users_dir/$username";
    my %details;
    
    open F, "$user_file/details.txt";
    for (<F>) {
        if (/(full_name): (.*)/) { $details{$1} = $2; }
        if (/(email): (.*)/)     { $details{$1} = $2; }
        if (/(suburb): (.*)/)    { $details{$1} = $2; }
    }
    close F;
    
    my %template_vars = (
        name => $details{full_name},
        email => $details{email},
        suburb => $details{suburb});    
    my $edit_info = HTML::Template->new(filename=>"html/edit_info.template", die_on_bad_params=>0);
    $edit_info->param(%template_vars); 
    return $edit_info->output;   
}

#FILTER CONTENTS
sub edit_profile {  
    my $user = $curr_user;
    my $profile = "$users_dir/$user/profile.txt";
      
    open PROFILE_NEW, ">$profile" or die;
    my $new_content = param('content');
    $new_content =~ s/^\s+|\s+$//g;
    print PROFILE_NEW $new_content;
    close PROFILE_NEW;
    
    return profile_view($new_content);  
} 

#displays the current profile before edits are made
sub current_profile {
    my $user = $curr_user;
    my $profile = "$users_dir/$user/profile.txt";
    
    open PROFILE, ">$profile" or die "$!";
    my $old_content = "";
    while (<PROFILE>) {
        $old_content .= "$_";
    } 
    close PROFILE; 
    
    return profile_view($old_content);
}

#uses a template to display profile when editing
sub profile_view {
    my ($file_content) = @_;
    my %template_vars = (content=>$file_content,);  
    my $text = HTML::Template->new(filename=>"html/profile.template", die_on_bad_params=>0);
    $text->param(%template_vars); 
    return $text->output;
}

#listening and unlistening users
#options: 1 for listen, 0 for unlisten
sub listen_unlisten {
    my ($option, $user) = @_;
    my @listens = split(" ", $details{listens});
    
    my $details = "$users_dir/$curr_user/details.txt";
    my $new_details = "$users_dir/$curr_user/details_new.txt";
    open IN, "<$details" or die;
    open OUT, ">$new_details" or die;
    while (<IN>) {
        if ($option == 1) {
            if (grep {$_ eq $user} @listens) { 
                print error("User already listening to", "User+Page&user=$user"); 
                return; 
            }
            s/(listens:.*)/$1 $user/g;
        } elsif ($option == 0) {
            s/$user//g;
        }
        print OUT $_;
    }
    close OUT;
    unlink $details;
    rename $new_details, $details;
    
    if ($option == 1) {
        print error("Listening to $user", "User+Page&user=$user");
    } else {
        print error("$user is dead to you now", "User+Page&user=$user");
    }
}

1
