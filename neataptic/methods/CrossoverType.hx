package neataptic.methods;


// https://en.wikipedia.org/wiki/Crossover_(genetic_algorithm)

@:keep
@:enum abstract CrossoverType(Int) from Int to Int {

    var single_point            = 0;
    var two_point               = 1;
    var uniform                 = 2;
    var average                 = 3;

}


