$.hcn = $.hcn || {};

;(function ($, hcn) {

$.hcn.initReplyToReply = function () {

    /**
     * Click Handler for "Reply to Relpy".
     * ajax get the form for reply
     */
    $('a[id^=add-comment-]').click(function (x) {
        var target = $(x.currentTarget),
            replySection = target.prev('.reply-of-reply'),
            form = replySection.find('form');

        if (form.length > 0) {
            form.find('textarea').focus();
        } else {
           $.get(["/topic",
                  target.attr("data-topic"),
                  target.attr("data-reply"), "reply"].join("/"),
                 function (res) {
                    replySection.append(res);
                    replySection.find('form textarea').focus();
                 }
                );
        }
    });

    /**
     * Dynamicly bind submit to the "reply to reply" form.
     * Submit it in ajax way.
     */
    $('.topic-content').on("submit", 'form[id^=add-comment-form-]', function (event) {
       event.preventDefault();
       var t = $(event.currentTarget),
           parent = t.parent();

       t.find('input:submit').button('loading');
       $.post(t[0].action, t.serialize(), function (res) {
          t.remove();
          parent.append(res);
       });
    });
  };

})(jQuery, $.hcn);

;$(function () {
   $.hcn.initReplyToReply();

   // toggle form submit button loading status
   // TODO: this is duplicated something in topic-form.js
   $('form').submit(function () {
      $(this).find('input:submit').button('loading');
   });

  // conform before delete comment
   $('.reply-per-topic').delegate('a.delete', 'click', function () {
      var deleteBtn = $(this),
          yesBtn = deleteBtn.next(),
          noBtn = yesBtn.next();
      deleteBtn.hide();
      yesBtn.removeClass('hide');
      noBtn.removeClass('hide');
   });

   $('.reply-per-topic').delegate('a.delete-no', 'click', function () {
      var noBtn = $(this),
          yesBtn = noBtn.prev(),
          deleteBtn = yesBtn.prev();
      yesBtn.addClass('hide');
      noBtn.addClass('hide');
      deleteBtn.show();
   });

   $('.reply-per-topic').delegate('a.delete-yes', 'click', function () {
      var yesBtn = $(this),
          noBtn = yesBtn.next();
      yesBtn.button('loading');
      noBtn.addClass('hide');
   });

});
