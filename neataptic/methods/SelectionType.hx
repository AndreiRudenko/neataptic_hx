package neataptic.methods;


// https://en.wikipedia.org/wiki/Selection_(genetic_algorithm)

@:keep
@:enum abstract SelectionType(Int) from Int to Int {

    var fitness_proportionate      = 0;
    var power                      = 1;
    var tournament                 = 2;

}


