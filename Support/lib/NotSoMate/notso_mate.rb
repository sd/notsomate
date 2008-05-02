require "#{ENV["TM_SUPPORT_PATH"]}/lib/scriptmate"
require "notso_patches"
require "cgi"

require "notso_mate"

class NotSoScript < UserScript
end

class NotSoMate < ScriptMate
  def initialize(*args)
    super(*args)
    @mate = "(Not So) #{@command.lang}"
    ENV["TM_NOTSOSTUPUD"] = "INDEED"
  end
end
