#prints html pages

sub home_page {
    open F, "html/home_page.html";
    return <F>;
}

sub register {
    open F, "html/register_form.html";
    return <F>;
}

sub login_page {
    open F, "html/login.html";
	return <F>;
}

sub logout_page {
    open F, "html/logout.html";
    return <F>;
}

sub forgot_password {
    open F, "html/forgot_pw.html";
    return <F>;
}

sub search_page {
    open F, "html/search_results.html";
    return <F>;
}

sub send_bleat {
    open F, "html/send_bleat.html";
    return <F>;
}

sub reply_page {
    open F, "html/reply.html";
    return <F>;
}

sub upload_page {
    open F, "html/upload_image.html";
    return <F>;
}

sub password_page {
    open F, "html/change_pw.html";
    return <F>;
}

sub suspend_page {
    open F, "html/suspend.html";
    return <F>;
}

sub unsuspend_page {
    open F, "html/unsuspend.html";
    return <F>;
}

sub delete_page {
    open F, "html/delete.html";
    return <F>;
}

sub delete_confirm {
    open F, "html/delete_account.html";
    return <F>;
}

1
