# Use this setup block to configure all options available in SimpleForm.
SimpleForm.setup do |config|
  config.button_class = 'btn btn-default'
  config.boolean_label_class = nil

  config.wrappers :vertical_form, tag: 'span', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.use :label, class: 'control-label'

    b.wrapper tag: 'span' do |ba|
      ba.use :input, class: 'form-control'
      ba.use :hint,  wrap_with: { tag: 'p', class: 'help-block' }
    end
  end

  config.wrappers :vertical_file_input, tag: 'span', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.use :label, class: 'control-label'

    b.wrapper tag: 'span' do |ba|
      ba.use :input
      ba.use :hint, wrap_with: { tag: 'p', class: 'help-block' }
    end
  end

  config.wrappers :vertical_boolean, tag: 'div', class: 'checkbox', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder

    b.use :label_input

    b.use :hint, wrap_with: { tag: 'p', class: 'help-block' }
  end

  config.wrappers :vertical_radio_and_checkboxes, tag: 'span', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.use :label_input
    b.use :hint, wrap_with: { tag: 'p', class: 'help-block' }
  end

  config.wrappers :horizontal_form, tag: 'span', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.use :label, class: 'col-sm-3 control-label'

    b.wrapper tag: 'span', class: 'col-sm-9' do |ba|
      ba.use :input, class: 'form-control'
      ba.use :hint,  wrap_with: { tag: 'p', class: 'help-block' }
    end
  end

  config.wrappers :horizontal_file_input, tag: 'span', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.use :label, class: 'col-sm-3 control-label'

    b.wrapper tag: 'span', class: 'col-sm-9' do |ba|
      ba.use :input
      ba.use :hint, wrap_with: { tag: 'p', class: 'help-block' }
    end
  end

  config.wrappers :horizontal_boolean, tag: 'span', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder

    b.wrapper tag: 'span', class: 'col-sm-offset-3 col-sm-9' do |wr|
      wr.wrapper tag: 'span', class: 'checkbox' do |ba|
        ba.use :label_input, class: 'col-sm-9'
      end

      wr.use :hint, wrap_with: { tag: 'p', class: 'help-block' }
    end
  end

  config.wrappers :horizontal_radio_and_checkboxes, tag: 'span', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder

    b.use :label, class: 'col-sm-3 control-label'

    b.wrapper tag: 'span', class: 'col-sm-9' do |ba|
      ba.use :input
      ba.use :hint, wrap_with: { tag: 'p', class: 'help-block' }
    end
  end

  # Wrappers for forms and inputs using the Bootstrap toolkit.
  # Check the Bootstrap docs (http://getbootstrap.com)
  # to learn about the different styles for forms and inputs,
  # buttons and other elements.
  config.default_wrapper = :vertical_form
end
