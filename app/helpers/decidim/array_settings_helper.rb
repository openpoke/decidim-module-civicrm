# frozen_string_literal: true

module Decidim
  module ArraySettingsHelper
    include Decidim::Admin::SettingsHelper

    def multiple_select_input(form, attribute, name, i18n_scope, options = {})
      container_class = "#{name}_container"

      form_method = :select

      help_text ||= text_for_setting(name, "help", i18n_scope)
      help_text_options = help_text ? { help_text: } : {}

      options = { label: t(name, scope: i18n_scope) }
                .merge(help_text_options)
                .merge(extra_options_for_type(form_method))
                .merge(options)

      content_tag(:div, class: container_class) do
        render_select_form_field(form, attribute, name, i18n_scope, options)
      end.html_safe
    end

    private

    # Returns a multiple select input for the given attribute
    def render_select_form_field(form, attribute, name, i18n_scope, options)
      html = label_tag(name) do
        concat options[:label]
        concat tag(:br)
        concat form.select(name, build_select_choices(name, i18n_scope, attribute.build_choices),
                           { selected: form.object.send(name) },
                           options.merge(multiple: true))
      end
      html << content_tag(:p, options[:help_text], class: "help-text") if options[:help_text]
      html
    end

    # Build options for select attributes
    def build_select_choices(name, i18n_scope, choices)
      choices.map do |choice|
        [t("#{name}_choices.#{choice}", scope: i18n_scope), choice]
      end
    end
  end
end
