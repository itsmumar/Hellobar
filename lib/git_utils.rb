class GitUtils
  class << self
    @current_commit = nil
    def current_commit
      # Get the current commit
      unless @current_commit
        begin
          @current_commit = File.read(File.join(Rails.root, '.git', File.read(File.join(Rails.root, '.git', 'HEAD')).split('ref: ').last.chomp)).chomp
        rescue
          @current_commit = '???'
        end
      end

      @current_commit
    end
  end
end
