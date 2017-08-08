package neataptic;


import neataptic.IActivator;
import neataptic.NodeType;
import neataptic.Node;


class Connection {


	public var from:Node;
	public var to:Node;
	public var gain:Float = 1;

	public var weight:Float;

	public var gater:Node = null;
	public var elegibility:Float = 0;

	  // For tracking momentum
	public var previous_delta_weight:Float = 0;

	  // Batch training
	public var total_delta_weight:Float = 0;

	public var xtrace:ConnectionTrace;


	public function new(_from:Node, _to:Node, ?_weight:Float) {

		from = _from;
		to = _to;

		weight = _weight == null ? Math.random() * 0.2 - 0.1 : _weight;

		xtrace = {
			values : [],
			nodes : []
		}

	}

	public function to_json():ConnectionData {
		
		var _json = {
			weight: weight
		};

		return _json;

	}

	/**
	 * Returns an innovation ID
	 * https://en.wikipedia.org/wiki/Pairing_function (Cantor pairing function)
	 */
	public static function innovation_id(a:Int, b:Int):Int { // maybe other pairing function

	    return Std.int(1 / 2 * (a + b) * (a + b + 1) + b);

	}

	// An Elegant Pairing Function by Matthew Szudzik @ Wolfram Research, Inc.
	// function elegant_pair(x:Int, y:Int):Int {

	// 	var z:Int = (x >= y) ? (x * x + x + y) : (y * y + x);
	// 	assert(z > 0, 'pairing error');
	// 	return z;

	// }




}


typedef ConnectionData = {

    var weight:Float;
    
    @:optional var from:Int;
    @:optional var to:Int;
    @:optional var gater:Int;

}


private typedef ConnectionTrace = {

    var values:Array<Float>;
    var nodes:Array<Node>;

}

