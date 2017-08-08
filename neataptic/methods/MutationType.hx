package neataptic.methods;


@:keep
@:enum abstract MutationType(Int) from Int to Int {

    var add_node             = 0;
    var sub_node             = 1;
    var add_conn             = 2;
    var sub_conn             = 3;
    var mod_weight           = 4;
    var mod_bias             = 5;
    var mod_activation       = 6;
    var add_self_conn        = 7;
    var sub_self_conn        = 8;
    var add_gate             = 9;
    var sub_gate             = 10;
    var add_back_conn        = 11;
    var sub_back_conn        = 12;
    var swap_nodes           = 13;

}


