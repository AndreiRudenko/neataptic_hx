package neataptic.methods;


@:keep
@:enum abstract ConnectionType(Int) from Int to Int {

    var all_to_all       = 0;
    var all_to_else      = 1;
    var one_to_one       = 2;

}


