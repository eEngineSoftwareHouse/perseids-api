ExUnit.configure(exclude: [pending: true])
ExUnit.start
Perseids.IndependentDatabase.initialize("pl_pln")
IO.puts "---===============================================================---"
IO.puts "---====           DATABASE LAST UPDATE 29.03.2018r            ====---"
IO.puts "---====           BE SURE YOU GOT NEWEST DB VERSION           ====---"
IO.puts "---====           THE REACTOR TESTS STARING......             ====---"
IO.puts "---===============================================================---"
:timer.sleep(3000)