package neataptic.methods;


@:keep
@:enum abstract MutationType(Int) from Int to Int {

    var none                 = -1;
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

    public static function from_string(s:String):MutationType {

        switch (s) {
            case 'add_node':{
                return add_node;
            }
            case 'sub_node':{
                return sub_node;
            }
            case 'add_conn':{
                return add_conn;
            }
            case 'sub_conn':{
                return sub_conn;
            }
            case 'mod_weight':{
                return mod_weight;
            }
            case 'mod_bias':{
                return mod_bias;
            }
            case 'mod_activation':{
                return mod_activation;
            }
            case 'add_self_conn':{
                return add_self_conn;
            }
            case 'sub_self_conn':{
                return sub_self_conn;
            }
            case 'add_gate':{
                return add_gate;
            }
            case 'sub_gate':{
                return sub_gate;
            }
            case 'add_back_conn':{
                return add_back_conn;
            }
            case 'sub_back_conn':{
                return sub_back_conn;
            }
            case 'swap_nodes':{
                return swap_nodes;
            }

        }

        return -1;
        
    }

}


