#suspend account
#becomes invisible to all however, as the user can be unsuspended,
#    nothing should be deleted
#viewing profile leads to a hidden page
#any bleat by the user and mentions of their name will be replaced
#    with hidden (identified by all files having their name 
#    tagged with hidden_$user)

sub suspend_account {
    my ($user) = @_;
    my $user_file = "$users_dir/$user";
    my $hidden_user = "$users_dir/hidden-$user";
    rename $user_file, $hidden_user;
    
    my @bleat_files = glob("$bleats_dir/*");    
    for my $bleat (@bleat_files) {
        open F, "<$bleat" or die;
        my $hidden_bleat = "$bleat-hidden-$user";
        while (<F>) {
            if (/$user/) {
                rename $bleat, $hidden_bleat;
            }      
        }  
    }        
}

#if a suspended user tries to log in, it will ask if they wish to 
#unsuspend their account
sub unsuspend_account {
    my ($user) = @_;
    my $user_file = "$users_dir/hidden-$user";
    my $unhide = "$users_dir/$user";
    rename $user_file, $unhide;
    
    my @bleat_files = glob("$bleats_dir/*");  
    for my $bleat (@bleat_files) {
        open F, "<$bleat" or die;
        my $unhide_bleat = $bleat;
        $unhide_bleat =~ s/[^0-9]//g;
        $unhide_bleat = "$bleats_dir/$unhide_bleat";
        while (<F>) {
            if (/$user/) {
                rename $bleat, $unhide_bleat;
            }      
        }  
    } 
}

#deletes account
#must delete name from users who are listening to them
#bleats written by them will be deleted although replies will stay
#bleats with mentions of their name will be replaced with 'dead' 
sub delete_account {
    my ($user) = @_;
    my @user_files = glob("$users_dir/$user/*");
    my @bleat_files = glob("$bleats_dir/*");
        
    #get user to login again
    if (login($user,param('password'))) {
        #deletes everything inside user folder then the folder itself
        for my $file (@user_files) {
            unlink $file;
        }
        rmdir "$users_dir/$user";
        #replaces their bleats with deleted to ensure that replies
        #will still be visible
        #all mentions of their name will be replaced with dead
        for my $bleat (@bleat_files) {
            open IN, "<$bleat" or die;
            my $temp_bleat = "$bleats_dir/temp";
            open OUT, ">$temp_bleat" or die "$!";
            my $delete = 0;
            while (<IN>) {
                s/$user/dead/g;
                if (/username: dead/) { $delete = 1; }
                print OUT $_;
            }
            close OUT;
            unlink $bleat;
            if ($delete) {
                open IN, "<$temp_bleat" or die;
                my $new_bleat = "$bleats_dir/new";
                open OUT, ">$new_bleat" or die "$!"; 
                while (<IN>) {
                    s/bleat: (.*)/bleat: deleted/g;
                    print OUT $_;
                }
                close OUT;
                unlink $temp_bleat;
                rename $new_bleat, $temp_bleat;
            } else {
                rename $temp_bleat, $bleat;
            }
        }   
        logout();
    } else {
        print error("Incorrrect details", "Delete");
    }
}

1
