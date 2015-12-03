##Sudoku-LP

Sudoku Solver SCIP Interface (ruby)

Lin Gengxian Shunji

####Instructions

1. Include skip.spx in Sudoku folder, download here: http://scip.zib.de/#download
2. Change directory to the Sudoku folder
3. Open the ruby environment in the Sudoku directory
4. load the ruby file <load 'sudoku.rb'>
5. Instantiate a sudoku class e.g. <problem1 = Sudoku.new>
6. Load the sudoku problem from a text file
  - Example of sudoku problems can be found in './TestCases'
    and they have the extension '.sudoku'
  - File has to be space separated between cell numbers
  - Empty cells are represented by '0's.
7. Using the 'solve' method, e.g. <problem1.solve>, the program 
    will do the following steps:
    - Convert the text file into an array containing the binary 
        values of all variables, and displays the puzzle
    - Convert the Sudoku puzzle into constraints in the SCIP format,
        and prompts to outputs an lp file e.g. 'problem1.lp'
    - Prompts for SCIP filepath, runs SCIP and reads the lp file
    - Optimizes the problem and outputs the solution into an lp 
        file, e.g. 'problem1_solution.lp'
    - Converts the lp solution back into the array containing binary
        values, and displays the solved grid
    - Gives the option of saving the solved puzzle in the original 
        text format, e.g. 'problem1.solved'

####Test Cases

* The 'TestCases' contain examples of 4x4, 9x9, 16x16, 25x25 and 36x36 
  puzzles
* The test cases are stored in '.sudoku' format
* The SCIP formatted constraints are stored in '.lp' format, and the
  raw output of SCIP solutions are stored in '_solution.lp' format
* The output of solved puzzles are stored in '.output' format
