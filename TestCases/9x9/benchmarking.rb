require 'benchmark'

def benchmarking(constraints_file)
  time = Benchmark.measure do 
    (1..1000).each { scip(constraints_file) }
  end
  puts time
end

def scip(constraints_file)
  system('./scip.spx -f #{constraints_file}')
end

