require "#{ENV["TM_SUPPORT_PATH"]}/lib/scriptmate"
require "notso_patches"
require "cgi"

require "notso_mate"

class NotSoRubyScript < NotSoScript
  def lang; "Ruby" end
  def executable; @hashbang || ENV['TM_RUBY'] || 'ruby' end
  def args; ['-rcatch_exception', '-rstdin_dialog'] end
  def version_string
    ruby_path = %x{ #{executable} -e 'require "rbconfig"; print Config::CONFIG["bindir"] + "/" + Config::CONFIG["ruby_install_name"]'}
    res = "Ruby r" + %x{ #{executable} -e 'print RUBY_VERSION' }
    res + " (#{ruby_path})"
  end
  def test_script?
    @path    =~ /(?:\b|_)(?:tc|ts|test)(?:\b|_)/ or
    @content =~ /\brequire\b.+(?:test\/unit|test_helper)/
  end
  def filter_cmd(cmd)
    if test_script?
      path_ary = @path.split("/")
      if index = path_ary.rindex("test")
        test_path = File.join(*path_ary[0..-2])
        lib_path  = File.join( *( path_ary[0..-2] +
                                  [".."] * (path_ary.length - index - 1) ) +
                                  ["lib"] )
        if File.exist? lib_path
          cmd.insert(1, "-I#{e_sh lib_path}:#{e_sh test_path}")
        end
      end
    end
    cmd
  end
end

class NotSoRubyMate < NotSoMate
  def filter_stdout(str)
    if @command.test_script? and str =~ /\A[.EF]+\Z/
      return htmlize(str).gsub(/[EF]+/, "<span style=\"color: red\">\\&</span>") +
            "<br style=\"display: none\"/>"
    else
      if @command.test_script?
        return ( str.map do |line|
          if line =~ /^(\s+)(\S.*?):(\d+)(?::in\s*`(.*?)')?/
            indent, file, line, method = $1, $2, $3, $4
            url, display_name = '', 'untitled document';
            unless file == "-"
              indent += " " if file.sub!(/^\[/, "")
              url = '&amp;url=file://' + e_url(file)
              display_name = File.basename(file)
            end
            "#{indent}<a class='near' href='txmt://open?line=#{line + url}'>" +
            (method ? "method #{CGI::escapeHTML method}" : '<em>at top level</em>') +
            "</a> in <strong>#{CGI::escapeHTML display_name}</strong> at line #{line}<br/>"
          elsif line =~ /(\[[^\]]+\]\([^)]+\))\s+\[([\w\_\/\.]+)\:(\d+)\]/
            spec, file, line = $1, $2, $3, $4
            "<span><a style=\"color: blue;\" href=\"txmt://open?url=file://#{e_url(file)}&amp;line=#{line}\">#{spec}</span>:#{line}<br/>"
          elsif line =~ /([\w\_]+).*\[([\w\_\/\.]+)\:(\d+)\]/
            method, file, line = $1, $2, $3
            "<span><a style=\"color: blue;\" href=\"txmt://open?url=file://#{e_url(file)}&amp;line=#{line}\">#{method}</span>:#{line}<br/>"
          elsif line =~ /^\d+ tests, \d+ assertions, (\d+) failures, (\d+) errors\b.*/
            "<span style=\"color: #{$1 + $2 == "00" ? "green" : "red"}\">#{$&}</span><br/>"
          else
            htmlize(line)
          end
        end.join )
      else
        return htmlize(str)
      end
    end
  end
end

script = NotSoRubyScript.new(STDIN.read)
NotSoRubyMate.new(script).emit_html