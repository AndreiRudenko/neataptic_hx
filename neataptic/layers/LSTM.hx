package neataptic.layers;


import neataptic.Connection;
import neataptic.methods.ConnectionType;
import neataptic.methods.GatingType;
import neataptic.Group;
import neataptic.Layer;


class LSTM extends Layer {


	public function new(size:Int) {
		
		super();

		// Init required nodes (in activation order)
		var input_gate = new Group(size);
		var forget_gate = new Group(size);
		var memory_cell = new Group(size);
		var output_gate = new Group(size);
		var output_block = new Group(size);

		input_gate.set(1);
		forget_gate.set(1);
		output_gate.set(1);

		// Set up internal connections
		memory_cell.connect(input_gate, ConnectionType.all_to_all);
		memory_cell.connect(forget_gate, ConnectionType.all_to_all);
		memory_cell.connect(output_gate, ConnectionType.all_to_all);
		var _forget = memory_cell.connect(memory_cell, ConnectionType.one_to_one);
		var _output = memory_cell.connect(output_block, ConnectionType.all_to_all);

		// Set up gates
		forget_gate.gate(_forget, GatingType.self);
		output_gate.gate(_output, GatingType.output);

		// Add to nodes array
		nodes = [input_gate, forget_gate, memory_cell, output_gate, output_block];

		// Define output
		output = output_block;

		input = function(_from:Group, ?_method:ConnectionType, ?_weight:Float):Array<Connection> {

			if(_method == null) {
				_method = ConnectionType.all_to_all;
			}

			var _connections:Array<Connection> = [];

			var input = _from.connect(memory_cell, _method, _weight);
			_connections = _connections.concat(input);

			_connections = _connections.concat(_from.connect(input_gate, _method, _weight));
			_connections = _connections.concat(_from.connect(output_gate, _method, _weight));
			_connections = _connections.concat(_from.connect(forget_gate, _method, _weight));

			input_gate.gate(input, GatingType.input);

			return _connections;

		};


	}

	
}