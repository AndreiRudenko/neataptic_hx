package neataptic.networks;


import neataptic.Connection;
import neataptic.methods.ConnectionType;
import neataptic.NodeType;
import neataptic.Group;
import neataptic.Layer;
import neataptic.Objects;
import neataptic.Network;


class NARX extends Network {


	public function new(_input_size:Int, _hidden_layers:Array<Int>, _output_size:Int, _previous_input:Int, _previous_output:Int) {
		
		var _nodes:Array<Objects> = [];

		var _input = new neataptic.layers.Dense(_input_size);
		var _input_memory = new neataptic.layers.Memory(_input_size, _previous_input);
		var _hidden:Array<Layer> = [];
		var _output = new neataptic.layers.Dense(_output_size);
		var _output_memory = new neataptic.layers.Memory(_output_size, _previous_output);

		_nodes.push(_input);
		_nodes.push(_output_memory);

		for (i in 0..._hidden_layers.length) {
			var _hidden_layer = new neataptic.layers.Dense(_hidden_layers[i]);
			_hidden.push(_hidden_layer);
			_nodes.push(_hidden_layer);
			if (_hidden[i - 1] != null) {
				_hidden[i - 1].connect(_hidden_layer, ConnectionType.all_to_all);
			}
		}

		_nodes.push(_input_memory);
		_nodes.push(_output);

		_input.connect(_hidden[0], ConnectionType.all_to_all);
		_input.connect(_input_memory, ConnectionType.one_to_one, 1);
		_input_memory.connect(_hidden[0], ConnectionType.all_to_all);
		_hidden[_hidden.length - 1].connect(_output, ConnectionType.all_to_all);
		_output.connect(_output_memory, ConnectionType.one_to_one, 1);
		_output_memory.connect(_hidden[0], ConnectionType.all_to_all);

		_input.set(null, null, NodeType.input);
		_output.set(null, null, NodeType.output);

		super(0, 0);

		setup(_nodes);

	}

	
}
