# Patch the original "htmlize" method, initially defined in TextMate's Support/lib/escape.rb
# Our version allows applications to ask the runner to preserve html in the output

def htmlize(str)
  @text_mode ||= "text"
  
  if str =~ /\[TM_OUTPUT_MODE:\s*(\w*)\s*\]/
    @text_mode = $1
    return ""
  end
  
  case @text_mode
  when "html"
    str
  else
    str = str.to_s.gsub("&", "&amp;").gsub("<", "&lt;")
    str = str.gsub(/\t+/, '<span style="white-space:pre;">\0</span>')
    str = str.reverse.gsub(/ (?= |$)/, ';psbn&').reverse
    str.gsub("\n", "<br>")
  end
end