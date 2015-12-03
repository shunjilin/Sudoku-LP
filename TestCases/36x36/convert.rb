def convert(filename)
  outdata = File.read(filename).gsub(" ", '0').gsub(/\t/, " ")
  array = outdata
  File.open(filename, 'w') do |out|
    out << outdata
  end
  array
end

