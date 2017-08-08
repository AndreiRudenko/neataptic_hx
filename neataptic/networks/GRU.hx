package neataptic.networks;


import neataptic.Connection;
import neataptic.methods.ConnectionType;
import neataptic.methods.MutationType;
import neataptic.Group;
import neataptic.Objects;
import neataptic.Layer;
import neataptic.Network;


/**
 * Creates a gated recurrent unit network
 */

	
class GRU extends Network {


	public function new(_args:Array<Int>) {

		if (_args.length < 3) {
			throw('You have to specify at least 3 layers');
		}

		var _input_layer = new Group(_args.shift()); // first argument
		var _output_layer = new Group(_args.pop()); // last argument
		var _blocks = _args; // all the arguments in the middle

		var _nodes:Array<Objects> = [];
		_nodes.push(_input_layer);

		var _previous:Objects = _input_layer;
		for (b in _blocks) {
			var l = new neataptic.layers.GRU(b);
			_previous.connect(l);
			_previous = l;

			_nodes.push(l);
		}

		_previous.connect(_output_layer);
		_nodes.push(_output_layer);

		super(0,0);

		setup(cast _nodes);

	}

	
}
