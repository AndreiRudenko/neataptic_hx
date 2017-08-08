package neataptic;


@:keep
@:enum abstract NodeType(Int) from Int to Int {

    var hidden      = 0;
    var input       = 1;
    var output      = 2;
    var constant    = 3;

    public static inline function to_string(_t:NodeType):String {

        var str:String = '';

        switch (_t) {
        	case hidden:{
        		str = 'hidden';
        	}
        	case input:{
        		str = 'input';
        	}
        	case output:{
        		str = 'output';
        	}
        	case constant:{
        		str = 'constant';
        	}
        }


        return str;
    }

}


