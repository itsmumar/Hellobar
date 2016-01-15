$ ->
  if $("form.edit_referral .referral_site").length
    $("form.edit_referral .referral_site select").on 'change', ->
      $(this).parents("form").submit()
