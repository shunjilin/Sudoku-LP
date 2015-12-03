require 'CSV'

class Sudoku
  attr_reader :dictionary, :clue_constraints, :cell_constraints, :row_constraints, :column_constraints, :subsquare_constraints, :all_constraints, :display_array, :m
  
  def initialize
    @clue_constraints = []
    @cell_constraints = []
    @row_constraints = []
    @column_constraints = []
    @subsquare_constraints = []
    @all_constraints = []
    @dictionary = []
  end
  
  def transform_2d(dict)
    deeper_array = []
    for i in 0...m**2
      sub_array = dict[i * m ... i * m + m]
      deeper_array << sub_array
    end
    return deeper_array
  end
  
  def transform_3d(dict)
    deeper_array = []
    for i in 0...m
      sub_array = dict[i * m ... i * m + m]
      deeper_array << sub_array
    end
    return deeper_array
  end
  
  def display_grid
    @display_array = transform_3d(transform_2d(dictionary))
    display_array.each do |row|
      puts ""
      row.each do |cell|
        if cell == [0] * m
          print " . |"
        else 
          cell.each.with_index do |binary, index|
            if binary == 1
              print " #{index + 1} |"
            end
          end
        end
      end
    end
    puts ""
  end
  
  def get_clues_from_text
    puts "Enter name of the file containing your Sudoku clues (e.g. 'clues.txt'): " 
    clue_file = gets.chomp
    if !File.exist?(clue_file)
      puts "No such file!"
      get_clues_from_text
    else
      clues = CSV.read(clue_file, col_sep: " ", skip_blanks: true, converters: :numeric)
      clues.each do |array|
        array.reject! {|s| s==nil} 
      end
      m = clues.length
      if (m**0.5 != (m**0.5).to_i || m == 1)
        puts "Sudoku board must be of m*m dimension, where m > 1!)"
        return false
      end
      clues.each do |cell|
        if cell.length != m
          puts cell.length
          puts "Sudoku board must be of m*m dimension, where m >1!)"
          puts "Make sure file is space delimited."
          return false
        end
      end
      @m = m
      @dictionary = clues.flatten
      @dictionary.map! do |value|
        cell_array = Array.new(m, 0)
        if value != 0
          cell_array[value - 1] = 1
        end
        value = cell_array
      end
      @dictionary.flatten!
      get_clues_from_dict
    end
  end
  
  def get_clues_from_dict
    @dictionary.each.with_index do |value, index|
      if value == 1
        @clue_constraints << "x#{index + 1.0} = 1"
      end
    end
  end
  
  def set_cell_constraints
    for r in 1..m
      for c in 1..m
        constraint_string = ""
        for i in 1..m
          constraint_string += "+ x#{i.to_f + (r - 1) * m**2 + (c - 1) * m} "
        end
        constraint_string.slice!(0..1)
        constraint_string += " = 1"
        @cell_constraints << constraint_string
      end
    end
  end
        
  
  def set_row_constraints
    for number in 1..m
      for row_index in 1..m
        constraint_string = ""
        for k in (row_index - 1) * m...(row_index - 1) * m + m 
          constraint_string += "+ x#{k * m + number.to_f} "
        end
        constraint_string.slice!(0..1)
        constraint_string += " = 1"
        @row_constraints << constraint_string
      end
    end
  end
  
  def set_column_constraints
    for number in 1..m
      for column_index in 1..m
        constraint_string = ""
        for k in 0...m
          constraint_string += "+ x#{(column_index - 1) * m + number.to_f + k * m**2} "
        end
        constraint_string.slice!(0..1)
        constraint_string += " = 1"
        @column_constraints << constraint_string
      end
    end
  end
  
  def set_subsquare_constraints
    for number in 1..m
      for ss_row in 0...m**0.5
        for ss_column in 0...m**0.5
          constraint_string = ""
          for l in 0...m**0.5
            for k in 0...m**0.5
              constraint_string += "+ x#{k * m + l * m**2 + ss_row * m**(5.0 / 2.0) + ss_column * m**(3.0 / 2.0) + number.to_f}"
            end
          end
          constraint_string.slice!(0..1)
          constraint_string += " = 1"
          @subsquare_constraints << constraint_string
        end
      end
    end
  end
  
  def set_all_constraints
    set_cell_constraints
    set_row_constraints
    set_column_constraints
    set_subsquare_constraints
    @all_constraints += cell_constraints + row_constraints + column_constraints + subsquare_constraints + clue_constraints
    @all_constraints = @all_constraints.each_with_index.map {|string, index| "c#{index}: " + string }
  end
  
  def output_constraints(filename)
    lp_file = File.open(filename, "a")
    lp_file.puts "subject to"
    @all_constraints.each {|constraint| lp_file.puts constraint}
    lp_file.puts "end"
    lp_file.close
  end
  
  def scip(constraints_file, solutions_file)
    puts "Enter the filepath for the SCIP program (e.g. './scip.spx'):"
    filepath = gets.chomp
    if File.exist?(filepath)
      scip_output = ""
      IO.popen(filepath, 'r+') do |pipe|
        pipe.puts("read " + constraints_file)
        pipe.puts("optimize")
        pipe.puts("write solution")
        pipe.puts("#{solutions_file}")
        pipe.close_write
        scip_output = pipe.read
        pipe.close_read
      end
    else
      puts "Filepath does not exist!"
      scip(constraints_file, solutions_file)
    end
  end
  
  
  def read_solutions(filename)
    solutions_array = []
    File.open(filename).each do |line|
      solutions_array << line
    end
    return solutions_array
  end 
  
  def scip_sequence
    puts "Input a new filename to export (SCIP-formatted) constraints to (lp file):"
    filename = gets.chomp
    if File.exist?(filename)
      puts "File with the given filename already exists!"
      scip_sequence
    elsif File.exist?(filename[0...-2] + "solution")
      puts ".solution file with given filename already exists!"
      puts "Please choose a different filename!"
      scip_sequence
    else
      solution_file = filename[0...-2] + "solution"
      output_constraints(filename)
      scip(filename, solution_file) 
      solutions_file_array = read_solutions(solution_file)
      solutions_array = []
      optimized_message = "solutionstatus:optimalsolutionfound"
      if solutions_file_array[0].gsub(/[" "\t\n]/,"") == optimized_message
        solutions_array = solutions_file_array[2..-1]
        solutions_array.map! do |string| 
          array = string.split(" ")
          if array[1].to_f > 0.9999
            array[0].slice!(0)
            string = array[0].to_f
          else
            puts "Solution Error!"
            delete_file(filename)
            return false
          end
        end
        puts "Solution found!"
        delete_file(filename)
        return solutions_array
      else
        puts "Solution Error! #{solutions_file_array[0]}"
        delete_file(filename)
        return false
      end
    end
  end

  def store_solutions(solutions_array)
    if solutions_array == false 
      puts "Solutions could not be obtained."
    else
      solutions_array.each {|index| @dictionary[index-1] = 1}
    end
  end

  def delete_file(filename)
    puts "Would you like to [k]eep or [d]elete the SCIP constraint and solution files?"
    ans = gets.chomp.downcase
    if (ans != "k" && ans != "d")
      puts "Invalid response."
      delete_file(filename)
    elsif ans == "d"
      File.delete(filename)
      File.delete(filename[0...-2] + "solution")
      puts "Files deleted."
      return 
    else
      puts "#{filename} and #{filename[0...-2] + "solution"} was stored in the current directory."
      return
    end
  end

  def output_solved
    puts "Would you like to save the grid-form of the solved sudoku to a file? [y]/[n]"
    ans = gets.chomp.downcase
    if (ans != "y" && ans != "n")
      puts "Invalid response."
      output_solved
    elsif ans == "n"
      puts "Solved sudoku was not saved."
      return 
    else
      puts "Input a new filename to export the grid-form of solved sudoku to file (e.g. example.solved):"
      filename = gets.chomp
      if File.exist?(filename)
        puts "File with the given filename already exists!"
        output_solved
      else
        array = []
        for i in 0...m**2
          for j in 0...m
            if dictionary[i*m + j] == 1
              array << j + 1
            end
          end
        end
        output_array = []
        for i in 0...m
          row_array = []
          for j in 0...m
            row_array << array[i * m + j]
          end
          output_array << row_array
        end
        output_file = File.open(filename, "w")
        output_array.each do |array|
          row = array.join(" ")
          output_file.puts row
        end
        output_file.close 
        puts "File is saved in the current directory as '#{filename}'."
        return
      end
    end
  end

##################################################################
# This section is for manual entry of clues (method: manual_solve)
 
  def new_dictionary
    @m = get_row
    @dictionary = Array.new(m**3, 0)
  end

 def get_row
    puts "How many rows does the Sudoku have?"
    ans = gets.chomp.to_i
    if (ans**0.5 == (ans**0.5).to_i) && ans != 0 && ans != 1
      return ans
    else
      puts "Only accept positive numbers > 1 that are perfect squares"
      puts "-----------------------------------------------------"
      get_row
    end
  end
  
  def get_clues
    puts "Would you like to input a/another clue for the Sudoku? (y/n):"
    ans = gets.chomp
    if !(ans == "y" || ans =="n")
      puts "Invalid input"
      "-----------------------------------------------------"
      get_clues
    else
      if ans == "y"
        get_clue
        puts "Current clue constraints: #{clue_constraints}"
        display_grid
        get_clues
      elsif ans == "n"
        puts "Current clue constraints: #{clue_constraints}"
        display_grid
        puts "-----------------------------------------------------"
        return clue_constraints
      end
    end
  end
  
  def get_clue
    clue_row = which_row
    clue_column = which_column
    clue_number = which_number
    cell_index = (clue_row - 1) * m**2 + (clue_column - 1) * m
    clue_index =  cell_index + clue_number
    current_clue_constraint = "x#{clue_index.to_f} = 1"
    zero_constraints_array = []
    for i in cell_index ... cell_index + m
      if @dictionary[i] == 1
        puts "The cell has already been filled with a clue!"
        return
      else
        zero_constraint = "x#{i} = 0"
        zero_constraints_array << zero_constraint
      end
    end
    @dictionary[clue_index - 1] = 1 
    @clue_constraints << current_clue_constraint
    @clue_constraints += zero_constraints_array
  end
  
  def which_row
    puts "Which row is the clue in? Please input a number from 1 to m:"
    clue_row = gets.chomp.to_i
    if clue_row.between?(1,m)
      return clue_row
    else 
      puts "Invalid input"
      which_row
    end
  end
    
  def which_column
    puts "Which column is the clue in? Please input a number from 1 to m:"
    clue_column = gets.chomp.to_i
    if clue_column.between?(1,m)
      return clue_column
    else 
      puts "Invalid input"
      which_column
    end
  end
    
  def which_number
    puts "What is the clue number? Please input a number from 1 to m:"
    clue_number = gets.chomp.to_i
    if clue_number.between?(1,m)
      return clue_number
    else
      puts "Invalid input"
      which_number
    end
  end

#################################################################  
      
  def solve
    get_clues_from_text
    set_all_constraints
    display_grid
    store_solutions(scip_sequence)
    display_grid
    output_solved
  end

  def manual_solve
    new_dictionary
    get_clues
    set_all_constraints
    store_solutions(scip_sequence)
    display_grid
    output_solved
  end
end

  