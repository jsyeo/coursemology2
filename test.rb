(1..100).detect {|i| i % 5 == 0 and i % 7 == 0 }
(1..100).find {|i| i % 5 == 0 and i % 7 == 0 }
