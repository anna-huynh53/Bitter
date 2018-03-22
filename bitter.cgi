#!/usr/bin/perl -w
#Bitter by z5075940
#https://gitlab.cse.unsw.edu.au/z5075940/15s2-comp2041-cgi/tree/master/ass2

#contains main calling functions
#for all other functions: scripts/.? 
#for html pages: html/.?

use CGI qw/:all/;
use CGI::Carp qw/fatalsToBrowser warningsToBrowser/;
use CGI::Session;
use HTML::Template;
use POSIX;
use POSIX qw/strftime/;

require 'scripts/page_headers.pl';
require 'scripts/pages.pl';
require 'scripts/user_account.pl';
require 'scripts/bleats.pl';
require 'scripts/search.pl';
require 'scripts/email.pl';
require 'scripts/notifications.pl';
require 'scripts/suspend_delete.pl';
require 'scripts/upload_image.pl';

main();

sub main() {
    warningsToBrowser(1);
    
    global_variables();
    
    my $page = param('page'); 
     
    print $session->header();
    if ($session->param('username')) {
        print user_header();
    } 
    show_page($page);
    print page_trailer();
}

#shows pages and calls required functions
sub show_page {
    my ($page) = @_;
    
    if ($page eq "Login") {
        print login_page();
    } elsif ($page eq "Sign In") {   
        my $username = param('username');
        my $password = param('password');     
        if (login($username, $password) == 1) {   
            $session->param('username', $username);
        } elsif (login($username, $password) eq -1) {
            print unsuspend_page(); #if account has been suspended
        } else {
            print message("Wrong username or password");
            print login_page(); #if wrong, login will appear again
        }
    } elsif ($page eq "Forgot Password") {
        print forgot_password();
    } elsif ($page eq "Send Password") {
        my $user = param('username');
        my $email = param('email');
        forgotten_password($user, $email);
    #registering a new account
    } elsif ($page eq "New User") {
        print register();    
    } elsif ($page eq "Register") {
        print new_account();
    } elsif ($page eq "New User Validation") {
        my $key = param('key');
        my $user = param('user');
        validated_email($key, $user);
        print message("You are now a bitter user, that's so great.");
    } elsif ($page eq "Validate Email") {
        my $key = param('key');
        my $user = param('user');
        validated_email($key, $user);
        print message("Email validated");    
    #unsuspending account 
    } elsif ($page eq "Unsuspend") {
        my $username = param('username');
        my $password = param('password');     
        if (login($username, $password) == -1) { 
            unsuspend_account(param('username'));
            print message("Login again");
            print login_page();
        } else {
            print message("Wrong username or password");
            print unsuspend_page();
        }        
    } elsif ($page eq "Help") {
        print message("There is no help");
    }
  
    #pages for users
    if ($curr_user) {
        if ($page eq "Logout") {
            logout();
            print logout_page();
        } elsif ($page eq "User Page") {
            if (param('user')) {
                print user_page(param('user'));
            } else {
                print user_page($curr_user);
            }
        #searching names and bleats
        } elsif ($page eq "Search") {
            print search_results();
        #editing profile
        } elsif ($page eq "Edit Profile") {
            print current_profile();
        } elsif ($page eq "Save Profile") {
            print edit_profile();
        #upload picture
        } elsif ($page eq "Upload Profile Picture") {
            print upload_page();
        } elsif ($page eq "Upload Picture") {
            profile_pic();
        #sending bleat
        } elsif ($page eq "Send Bleat" || $page eq "Reply") { 
            my $bleat = param('bleat');
            save_bleat($bleat, $curr_user);
        } elsif ($page eq "Delete Bleat") {
            my $bleatID = param('bleatID');
            delete_bleat($bleatID, $curr_user);
        } elsif ($page eq "Reply Bleat") {
            my $replyID = param('replyTo'); 
            #places replyID in file
            open F, ">data/reply";
            print F $replyID;
            close F;
            print reply_page();
        #editing user information
        } elsif ($page eq "Edit User Info") {
            print edit_information();
        } elsif ($page eq "Edit Notifications") {
            print notifications_page();
        } elsif ($page eq "Save settings") {
            edit_notifications();
        } elsif ($page eq "Edit Information") {
            print information_view();
        } elsif ($page eq "Save changes") {
            print edit_information();
        #changing password
        } elsif ($page eq "Password Change") {
            print password_page();
        } elsif ($page eq "Change password") {
            if (login($curr_user,param('old_pw'))) {
                change_password();
            } else {
                print error("Old password does not match", "Password+Change");
            }
        #changing email
        } elsif ($page eq "Email Change") {
            print change_email();
        } elsif  ($page eq "Change email") {
            my $email = param('new_email');
            my $key = generate_key();
            store_key($curr_user, $email, $key);
            validate_email($curr_user, $email, $key);
        #listen/unlisten
        } elsif ($page eq "Listen") { 
            my $user = param('user');
            listen_unlisten(1, $user);    
        } elsif ($page eq "Unlisten") {
            my $user = param('user');
            listen_unlisten(0, $user);
        } elsif ($page eq "Listening") {
            bleat_display();
        #suspend account 
        } elsif ($page eq "Suspend Account") {
            print suspend_page();
        } elsif ($page eq "Suspend") {
            suspend_account($curr_user);
            logout();
            print error("You have been suspended");
        #delete account
        } elsif ($page eq "Delete Account") {
            print delete_page();
        } elsif ($page eq "Delete") {
            print delete_confirm();
        } elsif ($page eq "Delete account forever") {
            delete_account($curr_user);
        } 
    } else {
        print home_page();
    }
}

#message printing
sub message {
    my ($message) = @_;
    return "<center><h2>$message</h2></center>";
}
  
#prints out errors/messages with a link to go back to previous page
sub error {
    my ($error, $link) = @_;
    my %template_vars = (error=>$error, link=>$link);    
    my $error_page = HTML::Template->new(filename=>"html/error.template", 
                                         die_on_bad_params=>0);
    $error_page->param(%template_vars); 
    return $error_page->output;   
}

#makes a new folder containing files: details.txt, bleats.txt
sub new_account {
    my $username = param('username');
    my $email = param('email'); 
    my ($name, $pw, $suburb);

    #can't use an email that is already in use
    open F, "data/emails";
    while (<F>) {
        if (/$email/) { 
            print register(); 
            return message("Email already in use");  
        }
    }
    close F;

    if (-r "$users_dir/$username") { 
        print register();
        return message("User already exists");
    } else {
        $name = param('name');       
        $pw = param('password');
        $suburb= param('suburb');
        mkdir "$users_dir/$username" or die "Can not create user file: $!";
        open F, ">$users_dir/$username/bleats.txt" or die "$!";
        open NEW_USER, ">$users_dir/$username/details.txt" or die;
        print NEW_USER "full_name: $name\nusername: $username\n";
        print NEW_USER "password: $pw\nemail: $email (NOT VERIFIED)\n";
        print NEW_USER "home_suburb: $suburb\nhome_latitude:\n";
        print NEW_USER "home_longitude:\nlistens: ";
        close NEW_USER;
    }
    
    #add to list of users who need to be verified
    my $validate_key = generate_key();
    store_key($username, $email, $validate_key);
    
    #send email to user to validate account
    #system("echo \"./bitter.cgi?page=Validate+Email&key=$validate_key\" | mail -s \"bitter\" $email");
    open MUTT, "|mutt -s 'Bitter Registration' -e 'set copy=no' -- '$email'";
    print MUTT "Welcome to Bitter\n\n";
    print MUTT "Click this link: http://cgi.cse.unsw.edu.au/~z5075940/ass2/bitter.cgi?page=New+User+Validation&key=$validate_key&user=$username";
    close MUTT;
    my %template_var = (login=>$username,email=>$email);
    my $new_user = HTML::Template->new(filename=>"html/new_user.template", 
                                       die_on_bad_params => 0);
	$new_user->param(%template_var);
	return $new_user->output;
}

#checks login details
sub login {	
    my ($username, $password) = @_; 
	my %user_details;
	
	#for hidden users
    if (-e "$users_dir/hidden-$username") {
	    return -1;
	} elsif (!open(F,"$users_dir/$username/details.txt")) {
	    return 0;
	} else {
	    while (<F>) {
	        if (/(.*): (.*)/) { $user_details{$1} = $2; }
	    }
	    close F;
	}
	return 1 if ($user_details{'password'} eq $password);
}

#clears session
sub logout {
    $session->delete();
    $session->flush();
}

sub global_variables {
    $debug = 1;
    
    $q = CGI->new();
    $session = CGI::Session->new($q);
    $session->expire('1h');
    
    $dataset_size = "small"; 
    $users_dir = "dataset-$dataset_size/users";
    $bleats_dir = "dataset-$dataset_size/bleats";
    
    if ($session->param('username')) { 
        $curr_user = $session->param('username');
    } else {
        $curr_user = "";
    }
    if ($curr_user) {
        #extracts information 
        my $user_file = "$users_dir/$curr_user";
        open F, "$user_file/details.txt"; 
        while (<F>) {
            if (/(full_name):(.*)/) { $details{$1} = $2; }
            if (/(email):(.*)/)     { $details{$1} = $2; }
            if (/(listens):(.*)/)   { $details{$1} = $2; }
            if (/(suburb):(.*)/)    { $details{$1} = $2; }
            if (/(latitude):(.*)/)  { $details{$1} = $2; }
            if (/(longitude):(.*)/) { $details{$1} = $2; }
        }
        close F;
    }
    
    %bleats = ();
    bleats(); #to populate %bleats
    generate_notifications(); #makes notification options if it 
                              #does not exist
    emails(); #saves all emails so an email is not used twice
}
