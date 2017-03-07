require 'spec_helper'

describe 'Benchmarking: ScriptGenerator' do
  let!(:sites) { create_list :site, 2, :with_rule }

  def generate(options = {})
    sites.each do |site|
      ScriptGenerator.new(site, options.merge(compress: true)).generate_script
    end
  end

  def measure(**options)
    ScriptGenerator.load_templates
    generate(options)
    Benchmark.ms { generate(options) }
  end

  specify do
    es5_time = measure(es6: false, cache: true)
    es6_time = measure(es6: true, cache: true)

    expect(es6_time / es5_time).to be < 1.2
  end

  context 'benchmark', benchmark: true do
    specify do
      Benchmark.bmbm(10) do |x|
        x.report('es5') { generate(es6: false) }
        x.report('es5 + cache (miss)') do
          ScriptGenerator.load_templates
          generate(es6: false, cache: true)
        end
        x.report('es5 + cache (hit)') { generate(es6: false, cache: true) }

        x.report('es6') { generate(es6: true) }
        x.report('es6 + cache (miss)') do
          ScriptGenerator.load_templates
          generate(es6: true, cache: true)
        end
        x.report('es6 + cache (hit)') { generate(es6: true, cache: true) }
      end
    end
  end
end
