#contains functions for bleats
#   populates global variable %bleats stored in form
#       $bleats{$file_name}{$bleater}{$time}{$reply}
#   gives all relevant bleats, including own bleats, those 
#       listening to and any bleat that mentions the user's username
#   sends bleat
#going to another user's page will only show their bleats

#populates global variable %bleats
#also returns a list of bleats that have been replied to
sub bleats {
    my @bleat_files = sort(glob("$bleats_dir/*"));
    my ($bleater, $bleat, $time, $reply, @replies);
    
    for my $file (@bleat_files) {
        open F, "$file" or die;
        $reply = "root";
        for my $line (<F>) {
            if ($line =~ /username: (.*)/) {
                $bleater = $1;
            } elsif ($line =~ /bleat/) { 
                $bleat = (split(':',$line))[1];
            } elsif ($line =~ /time: (.*)/) { 
                $time = $1;
            } elsif ($line =~ /in_reply_to: (.*)/) {
                $reply = $1;
            }
        }
        #users who are suspended have their username and bleats replaced
        #by hidden
        if ($file =~ /hidden-(.*)/) { 
            if ($bleater eq $1) {
                $bleat = "hidden";
            } else {
                $bleat =~ s/$1/hidden/g; 
            }
            $bleater =~ s/$1/hidden/g; 
        }
        $file =~ s/[^0-9]//g;
        my $when = strftime("%d/%m/%Y %H:%M:%S",localtime($time));
        #placing hyperlinks to any users in bleat
        $bleats{$bleater}{$time}{$file}{$reply} = 
        "<a href=./bitter.cgi?page=User+Page&user=$bleater>$bleater</a> bleated $bleat ($when)<p>";
        $bleats{$bleater}{$time}{$file}{$reply} =~ 
            s/@([^ ]*)/<a href=.\/bitter.cgi?page=User+Page&user=$1>\@$1<\/a>/g;
            
        #an array containing replies
        if ($reply ne "root") { push(@replies, $reply); } 
        close F;
    }     
    
    return @replies; 
} 

#show bleats and replies (not working properly)
sub bleat_display {
    my @bleats = end_comments();
    
    for my $b (@bleats) {
        bleat_replies($b);
    }
} 

#helper function to find the ends of a comment thread
#if the function has not been replied to, then it is the end of 
#a thread 
sub end_comments {
    my @bleat_files = relevant_bleats();
    my @replies = bleats();
    my @ends = ();

    for my $f (@bleat_files) {
        $f =~ s/[^0-9]//g;
        push(@ends, $f) unless (grep {$_ eq $f} @replies);
    }
    
    return @ends;
}        

#returns relevant bleats for a current user via ID number/file name
sub relevant_bleats {
    my $username = $curr_user;
    my @relevant_bleats = (); 
    my @follows = split(" ",$details{listens});
    
    for my $bleater (keys %bleats) {
        for my $time (keys %{$bleats{$bleater}}) {
            for my $file (keys %{$bleats{$bleater}{$time}}) {
                for my $reply (keys %{$bleats{$bleater}{$time}{$file}}) {
                    my $bleat = $bleats{$bleater}{$time}{$file}{$reply};
                    #own bleats 
                    if ($bleater eq $username) {
                        if (!(grep {$file eq $_} @relevant_bleats)) {
                            push(@relevant_bleats,$file); 
                        }
                    }
                    #bleats of those listening to
                    for my $f (@follows) {
                        if ($bleater eq $f) {
                            if (!(grep {$file eq $_} @relevant_bleats)) {
                                push(@relevant_bleats,$file); 
                            } 
                        }
                    }
                    #bleats containing user's username
                    if ($bleat =~ /$username/) {
                        if (!(grep {$file eq $_} @relevant_bleats)) {
                            push(@relevant_bleats,$file); 
                        }
                    }
                }
            }
        }
    } 
    return @relevant_bleats;
}

#given a bleat, will show all replies
sub bleat_replies {
    my ($bleat_id) = @_;
    my $bleat_file = "$bleats_dir/$bleat_id";
    my ($bleater, $bleat, $time);
    
    open BLEAT, "$bleat_file" or "$bleats_dir/$bleat_id-hidden-.*";
    $reply = "root";
    for my $line (<BLEAT>) {
        if ($line =~ /username: (.*)/) {
            $bleater = $1;
        } elsif ($line =~ /bleat/) { 
            $bleat = (split(':',$line))[1];
        } elsif ($line =~ /time: (.*)/) { 
            $time = $1;
        } elsif ($line =~ /in_reply_to: (.*)/) {
            $reply = $1;
        }
    }
    $bleat =~ s/@([^ ]*)/<a href=.\/bitter.cgi?page=User+Page&user=$bleater>\@$bleater<\/a>/g;
    
    my $pic = "images/anonymous.jpg";
    if (-f "$users_dir/$bleater/profile.jpg") {
        $pic = "$users_dir/$bleater/profile.jpg";
    } 
    
    $time = strftime("%d/%m/%Y %H:%M:%S",localtime($time));
    my %template_vars = (pic => $pic,
                username => $bleater,
                time => $time,
                content => $bleat,
                replies => $replies,
                file => $bleat_id);               
    if ($reply eq "root") {
        my $root = HTML::Template->new(filename=>"html/root_bleat.template", 
                                       die_on_bad_params=>0);
        $root->param(%template_vars); 
        print $root->output;     
        $replies = "";
    } else {
        bleat_replies($reply);
        #temp fix
        #so the comments appear within the root
        $replies .= "<li class='comment'><a class='pull-left' href='./bitter.cgi?page=User+Page&user=$username'>
        <img class='avatar' src=$pic alt='avatar'></a> <div class='comment-body'>
        <div class='comment-heading'>
        <h4 class='user'><a href='./bitter.cgi?page=User+Page&user=$username'>$username</a></h4>
        <h5 class='time'>$time</h5></div><p>$bleat</p></div></li>"; 
    }
}   

#saves the bleat 
#bleat named via timestamp
sub save_bleat {
    my ($bleat, $user) = @_;
    
    my $replyID = 0;
    my $data_reply = "data/reply"; 
    if (-f $data_reply) { #if file exists, then it is a reply bleat
        open F, "$data_reply";
        while (<F>) {
            $replyID = $_;
        } 
        close F;
    }
    
    #filter contents of $bleat  
    $bleat =~ s/^\s+|\s+$//g; #remove whitespace from front and back
    
    my $time = time();
    my $bleat_file = "$bleats_dir/$time";
    open BLEAT, ">$bleat_file" or die;
    print BLEAT "time: $time\n";
    print BLEAT "longitude: \nlatitude: \n";
    print BLEAT "bleat: $bleat\n";
    print BLEAT "username: $user";
    if ($replyID) {
        print BLEAT "\nin_reply_to: $replyID";
        unlink $data_reply;
    }
    close BLEAT;
    
    #add to bleats list in bleats.txt
    my $bleat_file = "$users_dir/$user/bleats.txt";
    my $new_bleat = "$users_dir/$user/bleats_new.txt";
    open IN, "<$bleat_file" or die;
    open OUT, ">$new_bleat" or die;
    while (<IN>) {
        print OUT "$_";
    }
    print OUT "\n$time";
    close OUT;
    
    unlink $bleat_file;
    rename $new_bleat, $bleat_file;
    
    #send notifications to anyone who was replied to or mentioned
    #and has set their notification settings to yes
    my $user_replied;
    if ($replyID) {
        open F, "$bleats_dir/$replyID" or die "$!";
        while (<F>) {
            if (/username: (.*)/) { $user_replied = $1; }
        }
        close F;
        open F, "$users_dir/$user_replied/notifications.txt";
        while (<F>) {
            if (/bleat_notifications: yes/) { 
                replied_notifications($user_replied); 
            }
        }
        close F;
    }
    my @bleat = split(" ",$bleat);
    for my $i (@bleat) {
        if ($i =~ /@(.*)/) {
            my $user_mention = $1;
            open F, "$users_dir/$user_mention/notifications.txt";
            while (<F>) {
                if (/username_notifications: yes/) { 
                    mention_notifications($user_mention); 
                }
            } 
        }
    }     
    print error("Bleat saved", "User+Page");
}    

#deletes bleat given ID
#file not deleted to keep replies active
sub  delete_bleat {
    my ($delete_num, $user) = @_;  
    $delete = "$bleats_dir/$delete_num";

    my @bleat_files = sort(glob("$bleats_dir/*"));
    for my $bleat (@bleat_files) {
        if ($delete eq $bleat) {
            open IN, "<$delete" or die;
            my $temp_bleat = "$bleats_dir/temp";
            open OUT, ">$temp_bleat" or die "$!";
            while (<IN>) {
                s/username: $user/username: they are hiding something/g;
                s/bleat: (.*)/bleat: deleted/g;
                print OUT $_;
            }
            close OUT;
            unlink $delete;
            rename $temp_bleat, $bleat;
        }
    }

    #delete bleat from bleats.txt
    my $bleat_file = "$users_dir/$user/bleats.txt";
    my $new_bleat = "$users_dir/$user/bleats_new.txt";
    open IN, "<$bleat_file" or die;
    open OUT, ">$new_bleat" or die;
    while (<IN>) {
        if ($_ != $delete_num) { print OUT $_; }
    }
    close OUT;
    unlink $bleat_file;
    rename $new_bleat, $bleat_file;
    
    print error("Bleat deleted", "User+Page");
}
     
#given an array of bleats, will split them up to be viewed in pages     
sub bleat_pagination {
    my (@bleats) = @_; 
    @bleats = sort @bleats;
    my $num_bleats = scalar(@bleats);
    my $num_pages = ceil($num_bleats / 10); 
    my %view_bleats; #bleats stored in groups of 10
    my $i = 0; #counter for bleats
    my $page = 0; #counter for pages
    
    for my $bleat (@bleats) {
        if ($i < 10) { 
            if ($i == 0) { $page++; }
            $view_bleats{$page} .= "$bleat<p>"; 
            $i++;
        } 
        if ($i == 10) {  
            $i = 0;
        }
    }
    return %view_bleats;
}        
              
1
