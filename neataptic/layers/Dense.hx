package neataptic.layers;


import neataptic.Connection;
import neataptic.methods.ConnectionType;
import neataptic.Group;
import neataptic.Layer;


class Dense extends Layer {


	public function new(_size:Int) {
		
		super();

		var block = new Group(_size);

		nodes.push(block);
		output = block;

		input = function(_from:Group, ?_method:ConnectionType, ?_weight:Float):Array<Connection> {

			if(_method == null) {
				_method = ConnectionType.all_to_all;
			}

			return _from.connect(block, _method, _weight);

		}

	}

	
}