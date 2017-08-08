package neataptic.networks;


import neataptic.Connection;
import neataptic.methods.ConnectionType;
import neataptic.methods.MutationType;
import neataptic.Group;
import neataptic.Objects;
import neataptic.Layer;
import neataptic.Network;


/**
 * Creates a multilayer perceptron (MLP)
 */

	
class Perceptron extends Network {


	public function new(_layers:Array<Int>) {

		if (_layers.length < 3) {
			throw('You have to specify at least 3 layers');
		}

		// Create a list of nodes/groups
		var _nodes:Array<Group> = [];
		_nodes.push(new Group(_layers[0]));

		for (i in 1..._layers.length) {
			_nodes.push(new Group(_layers[i]));
			_nodes[i - 1].connect(_nodes[i], ConnectionType.all_to_all);
		}

		super(0,0);

		setup(cast _nodes);

	}

	
}
