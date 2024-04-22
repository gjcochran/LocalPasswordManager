$(document).ready(function () {
    $(".password__check").click(function () {
        var input = document.getElementsByClassName("password__input");
        if ($(input).attr("type") == "password") {
            $(input).attr("type", "text");
            $(".password__icon--shown").addClass("show");
            $(".password__icon--shown").removeClass("hide");
            $(".password__icon--hidden").addClass("hide");
        } else {
            $(input).attr("type", "password");
            $(".password__icon--shown").removeClass("show");
            $(".password__icon--shown").addClass("hide");
            $(".password__icon--hidden").removeClass("hide");
            $(".password__icon--hidden").addClass("show");
        }
    });

    $("form.delete").submit(function (event) {
        event.preventDefault();
        event.stopPropagation();

        var ok = confirm("Are you sure? This cannot be undone!");
        if (ok) {
            this.submit();
        }
    });

    $("a.form__external").click(function (event) {
        event.preventDefault();
        event.stopPropagation();

        var ok = confirm("Are you sure? This will navigate off this page and all unsaved changes will be lost.");
        if (ok) {
            window.location.href = $(this).attr("href");
        }
    });

});