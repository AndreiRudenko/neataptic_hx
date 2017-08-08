package neataptic.methods;


@:keep
@:enum abstract GatingType(Int) from Int to Int {

    var output     = 0;
    var input      = 1;
    var self       = 2;

}


