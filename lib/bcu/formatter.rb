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

  class TableFormatter
    def write(state)
      table = [["No.", "Name", "Cask", "Current", "Latest", "Auto-Update", "State"]]

      state.each_with_index do |app, i|
        app_name = app.first
        cask = app.last[:cask]
        status = app.last[:status]

        row = []
        row << "#{i+1}/#{state.length}"
        row << app_name
        row << cask.token
        row << cask.installed.join(", ")
        row << cask.latest
        row << (cask.auto_updates ? "Y" : "")
        row << status
        table << row
      end

      puts table(table)
    end

    def table(rows, gutter: 2)
      output = ""

      # Maximum number of columns
      cols = rows.map(&:length).max

      # Calculate column widths
      col_widths = Array.new(cols, 0)
      rows.each do |row|
        row.each_with_index do |obj, i|
          len = Tty.strip_ansi(obj.to_s).length
          col_widths[i] = len if col_widths[i] < len
        end
      end

      # Calculate table width including gutters
      table_width = col_widths.inject(:+) + gutter * (cols - 1)

      # Print table header
      output << "=" * table_width + "\n"
      rows.shift.each_with_index do |obj, i|
        output << obj.to_s.ljust(col_widths[i] + gutter)
      end
      output << "\n"
      output << "=" * table_width + "\n"

      # Print table body
      rows.each do |row|
        row.each_with_index do |obj, i|
          output << obj.to_s.ljust(col_widths[i] + gutter)
        end
        output << "\n"
      end
      output << "=" * table_width + "\n"

      output
    end
  end
end
