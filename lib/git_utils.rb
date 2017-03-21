class GitUtils
  class << self
    def current_commit
      @current_commit ||=
        begin
          head_ref = Rails.root.join('.git', 'HEAD').read.split('ref: ').last.chomp
          Rails.root.join('.git', head_ref).read.chomp
        rescue => _
          '???'
        end
    end
  end
end
