package neataptic.layers;


import neataptic.Connection;
import neataptic.NodeType;
import neataptic.Group;
import neataptic.Layer;
import neataptic.methods.ConnectionType;
import neataptic.methods.GatingType;
import neataptic.methods.Activation;


class GRU extends Layer {


	public function new(size:Int) {
		
		super();

		var _update_gate = new Group(size);
		var _inverse_update_gate = new Group(size);
		var _reset_gate = new Group(size);
		var _memory_cell = new Group(size);
		var _output = new Group(size);
		var _previous_output = new Group(size);

		_previous_output.set(0, Activation.IDENTITY, NodeType.constant);
		_memory_cell.set(null, Activation.TANH);
		_inverse_update_gate.set(0, Activation.INVERSE, NodeType.constant);
		_update_gate.set(1);
		_reset_gate.set(0);

		// Update gate calculation
		_previous_output.connect(_update_gate, ConnectionType.all_to_all);

		// Inverse update gate calculation
		_update_gate.connect(_inverse_update_gate, ConnectionType.one_to_one, 1);

		// Reset gate calculation
		_previous_output.connect(_reset_gate, ConnectionType.all_to_all);

		// Memory calculation
		var reset = _previous_output.connect(_memory_cell, ConnectionType.all_to_all);

		_reset_gate.gate(reset, GatingType.output); // gate

		// Output calculation
		var update1 = _previous_output.connect(output, ConnectionType.all_to_all);
		var update2 = _memory_cell.connect(output, ConnectionType.all_to_all);

		_update_gate.gate(update1, GatingType.output);
		_inverse_update_gate.gate(update2, GatingType.output);

		// Previous output calculation
		_output.connect(_previous_output, ConnectionType.one_to_one, 1);

		// Add to nodes array
		nodes = [_update_gate, _inverse_update_gate, _reset_gate, _memory_cell, output, _previous_output];

		output = _output;

		input = function(_from:Group, ?_method:ConnectionType, ?_weight:Float):Array<Connection> {

			if(_method == null) {
				_method = ConnectionType.all_to_all;
			}

			var _connections:Array<Connection> = [];

			_connections = _connections.concat(_from.connect(_update_gate, _method, _weight));
			_connections = _connections.concat(_from.connect(_reset_gate, _method, _weight));
			_connections = _connections.concat(_from.connect(_memory_cell, _method, _weight));

			return _connections;

		};


	}

	
}