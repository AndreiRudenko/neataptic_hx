package neataptic.networks;


import neataptic.Connection;
import neataptic.NodeType;
import neataptic.methods.Activation;
import neataptic.methods.ConnectionType;
import neataptic.Group;
import neataptic.Objects;
import neataptic.Layer;
import neataptic.Network;


/**
 * Creates a hopfield network of the given size
 */

class Hopfield extends Network {


	public function new(_size:Int) {

		var _input = new Group(_size);
		var _output = new Group(_size);

		_input.connect(_output, ConnectionType.all_to_all);

		_input.set(null, null, NodeType.input);
		_output.set(null, Activation.STEP, NodeType.output);

		super(0,0);

		setup(cast [_input, _output]);

	}

	
}
