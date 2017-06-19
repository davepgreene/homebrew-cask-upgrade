module Bcu
  class VerticalFormatter
    def write(state)
      installed_count = state.keys.length
      zero_pad = installed_count.to_s.length

      state.each_with_index do |app, i|
        app_name = app.first
        cask = app.last[:cask]
        status = app.last[:status]

        string_template = "(%0#{zero_pad}d/%d) #{app_name} (#{cask.token}): "
        print format(string_template, i + 1, installed_count)
        ohai status
      end
    end
  end
end
