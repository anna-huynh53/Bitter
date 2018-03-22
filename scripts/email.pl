#functions that handle emailing users notifications, validation links,
#forgotten passwords

#fills email array to check if emails are used more than once
sub emails {
    my @user_files = glob("$users_dir/*");
    my $email_data = "data/emails";
    my @emails = ();
    
    for my $user (@user_files) {
        my $info = "$user/details.txt";
        open IN, "<$info" or die;     
        while (<IN>) {
            if (/email: (.*)/) { push(@emails,"$1\n"); }
        }
        close IN;
    }
    if (-f $email_data) { unlink $email_data; }
    open OUT, ">$email_data" or die;
    print OUT @emails;
    close OUT;
}

#match user to email
sub find_email {
    my ($user) = @_;
    my $email;
    my $user_file = "$users_dir/$user/details.txt";
    open F, "$user_file" or die;
    while (<F>) {
        if (/email: (.*)/) { $email = $1; }
    }
    close F; 
    return $email;    
}

#sends password to user given email
sub forgotten_password {
    my ($user, $email) = @_;
    my ($user_email, $pw);
    
    if (!(open F, "$users_dir/$user/details.txt")) { 
        print message("User not found"); 
        return;
    }
    while (<F>) {
        if (/email: (.*)/) { $user_email = $1; }
        if (/password: (.*)/) { $pw = $1; }
    }
    if ($user_email ne $email) {
        print message("Email does not match one given");
    } else {
        open MUTT, "|mutt -s 'Forgotten Password' -e 'set copy=no' -- '$email'";
        print MUTT "Your password is $pw";
        close MUTT;
        print message("Email sent to $email");
    }
}

#sends email to notify reply to a bleat
#(although currently not which bleat)
sub replied_notifications {
    my ($user) = @_;
    my $email = find_email($user);
    open MUTT, "|mutt -s 'Bitter Reply Notifications' -e 'set copy=no' -- '$email'";
    print MUTT "Someone has replied to you";
    close MUTT;
}

#sends email to notify mention in a bleat
sub mention_notifications {
    my ($user) = @_;
    my $email = find_email($user);
    open MUTT, "|mutt -s 'Bitter Mention Notifications' -e 'set copy=no' -- '$email'";
    print MUTT "Someone mentioned you";
    close MUTT;
}

#send validation email
sub validate_email {
    my ($user, $email, $validate_key) = @_;
    open MUTT, "|mutt -s 'Bitter Email Validation' -e 'set copy=no' -- '$email'";
    print MUTT "Validate your email\n\n";
    print MUTT "Click this link: http://cgi.cse.unsw.edu.au/~z5075940/ass2/bitter.cgi?page=Validate+Email&key=$validate_key&user=$user";
    close MUTT;
    print error("Validation email sent to $email", "Email+Change");
}    
    
#deletes key from list of users requiring validation and changed
#old email to new email
sub validated_email {
    my ($key, $user) = @_;
    my $key_file = "data/validation_keys";
    my $new_keys = "data/new_keys";
    my $new_email = "";
    
    open IN, "<$key_file" or die;
    while (<IN>) {
        if (/$user(.*)$key/) { $new_email = $_; }
    }
    close IN;
    
    #contains user, old email and key
    my @details = split(" ", $new_email);
    
    open IN, "<$key_file" or die;
    open OUT, ">$new_keys" or die;
    while (<IN>) {
        s/$new_email//g; #remove from key file
        print OUT $_;
    }
    close OUT;
    unlink $key_file;
    rename $new_keys, $key_file;
    
    #verified in emails list
    my $email_file = "data/emails";
    my $new_emails = "data/emails_new";
    open IN, "<$email_file" or die;
    open OUT, ">$new_emails" or die;
    while (<IN>) {
        s/\(NOT VERIFIED\)//g; 
        print OUT $_;
    }
    close OUT;
    unlink $email_file;
    rename $new_emails, $email_file;
    
    my $info = "$users_dir/$user/details.txt";
    my $new_info = "$users_dir/$user/details_new.txt";
    open IN, "<$info" or die;
    open OUT, ">$new_info" or die;
    while (<IN>) {
        s/\(NOT VERIFIED\)//g;
        s/email: (.*)/email: $details[1]/g;
        print OUT $_;
    }
    close OUT;
    unlink $info;
    rename $new_info, $info;
}

#generate validation key
sub generate_key {
    my @chars = ('a'..'z','A'..'Z','0'..'9');
    my $key;
    for (1..16) {
        $key .= $chars[rand @chars];
    }
    return $key;
}

#store username, new email and validation key
sub store_key {
    my ($user, $email, $validate_key) = @_;
    my $key_data = "data/validation_keys";
    my $new_data = "data/validation_keys_new";
    open IN, "<$key_data";
    open OUT, ">$new_data";
    while (<IN>) {
        print OUT "$_\n";
    }
    print OUT "$user $email $validate_key\n";
    close OUT;
    unlink $key_data;
    rename $new_data, $key_data;  
}

1
