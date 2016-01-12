$ ->
  if $("form.edit_referral .referral_site").length
    $("form.edit_referral .referral_site select").on 'change', ->
      console.log $(this).parents("form")
      $(this).parents("form").submit()
