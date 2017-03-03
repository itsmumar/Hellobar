# This provides a method for generating and parsing obfuscated URL-friendly
# IDs. This is just to avoid numeric IDs in the Javascript and Data APIs
#
# This class will randomly generate the ID so the output for the same input
# will not always be the same.
#
class ObfuscatedID
  SEP = '-'
  ZERO_ENCODE = '_'
  ENCODE = 'S6pjZ9FbD8RmIvT3rfzVWAloJKMqg7CcGe1OHULNuEkiQByns5d4Y0PhXw2xta'

  class << self
    def generate(int)
      raise 'Does not work with negative values' if int < 0
      id = int.to_s
      outputs = []
      inputs = [id[0...3], id[3...6], id[6...9]].reject { |i| !i or i == '' }
      inputs.each do |input|
        output = ''
        input.split('').each do |c|
          break if c != '0'
          output << ZERO_ENCODE
        end
        input = input.to_i
        unless input == 0
          loop do
            if input > ENCODE.length
              val = rand(ENCODE.length) + 1
            else
              val = rand(input) + 1
            end
            output += ENCODE[(val - 1)..(val - 1)]
            input -= val
            break if input <= 0
          end
          raise "Error: #{output.inspect} with #{input.inspect}" if input != 0
        end
        outputs << output
      end
      outputs.join(SEP)
    end

    def parse(string)
      outputs = []

      string.split(SEP).each do |data|
        value = 0
        data.length.times do |i|
          char = data[i..i]
          if char == ZERO_ENCODE
            outputs << '0'
          else
            value += ENCODE.index(char) + 1
          end
        end
        unless value == 0
          outputs << value.to_s
        end
      end
      outputs.join('').to_i
    end
  end
end
