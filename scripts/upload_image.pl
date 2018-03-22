#upload profile pic

$CGI::POST_MAX = 1024*5000;

sub profile_pic {
    $user = $curr_user;
    my $file_dir = "$users_dir/$user/profile.jpg";
    my $filehandle = upload('photo');
    
    if ($filename =~ /[^\w\d\_\.\-]/) {
        die "Filename contains invalid characters (only alphanumeric, _, ., - allowed)";
    } else {
       open UPLOAD_FILE, ">$file_dir" or die;
       binmode UPLOAD_FILE;
       while (<$filehandle>) {
           print UPLOAD_FILE;
       }
       close UPLOAD_FILE;
    }
    print error("Image uploaded","Upload+Profile+Picture");
}

1
