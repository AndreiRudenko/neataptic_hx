package neataptic.layers;


import neataptic.ObjectsType;
import neataptic.NodeType;
import neataptic.Connection;
import neataptic.methods.ConnectionType;
import neataptic.methods.GatingType;
import neataptic.methods.Activation;
import neataptic.Group;
import neataptic.Layer;


class Memory extends Layer {


	public function new(_size:Int, _memory:Int) {
		
		super();

		var _previous:Group = null;
		for (i in 0..._memory) {
			var _block = new Group(_size);

			_block.set(0, Activation.IDENTITY, NodeType.constant);

			if (_previous != null) {
				_previous.connect(_block, ConnectionType.one_to_one, 1);
			}

			nodes.push(_block);
			_previous = _block;
		}

		nodes.reverse();

		var g:Group;
		for (n in nodes) {
			if(n.is(ObjectsType.group)) {
				g = cast n;
				g.nodes.reverse();
			}
		}

		// Because output can only be óne group, fit all memory nodes in óne group
		var _output_group = new Group(0);
		for (n in nodes) {
			if(n.is(ObjectsType.group)) {
				g = cast n;
				_output_group.nodes = _output_group.nodes.concat(g.nodes);
				// _output_group.nodes = _output_group.nodes.concat(nodes[group].nodes);
			}
		}
		output = _output_group;

		input = function(_from:Group, ?_method:ConnectionType, ?_weight:Float):Array<Connection> {

			if(_method == null) {
				_method = ConnectionType.all_to_all;
			}

			var n = nodes[nodes.length - 1];
			if(n.is(ObjectsType.group)) {
				var _g:Group = cast nodes[nodes.length - 1];
				if (_from.nodes.length != _g.nodes.length) {
					throw('Previous layer size must be same as memory size');
				}
			}

			return _from.connect(nodes[nodes.length - 1], ConnectionType.one_to_one, 1);
		};


	}

	
}