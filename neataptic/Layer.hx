package neataptic;


import neataptic.IActivator;
import neataptic.NodeType;
import neataptic.ObjectsType;
import neataptic.Objects;
import neataptic.Node;
import neataptic.Group;
import neataptic.methods.ConnectionType;
import neataptic.methods.GatingType;

import neataptic.utils.Log;


class Layer extends Objects {


	public var output:Group;

	public var nodes:Array<Objects>;
	public var connections:LayerConnections;

	public var input:Group->ConnectionType->Float->Array<Connection>;
	

	public function new() {

		super(ObjectsType.layer);

		nodes = [];
		connections = new LayerConnections([], [], []);

		input = function(g,m,w) {
			return [];
		}

	}

	/**
	 * Activates all the nodes in the group
	 */
	public function activate(?_value:Array<Float>):Array<Dynamic> { // todo, make optimisation, like (into:Array<Dynamic>)

		var values:Array<Dynamic> = [];

		if (_value != null && _value.length != nodes.length) {
			throw('Array with values should be same as the amount of nodes!');
		}

		var _n:Objects;
		for (i in 0...nodes.length) {
			_n = nodes[i];
			var _activation:Dynamic = null;
			if(_n.is(ObjectsType.node)) {
				var _node:Node = cast _n;
				if (_value == null) {
					_activation = _node.activate();
				} else {
					_activation = _node.activate(_value[i]);
				}
			} else if(_n.is(ObjectsType.group)) {
				var _group:Group = cast _n;
				_activation = _group.activate(_value);
			}

			values.push(_activation);
		}

		return values;

	}

	/**
	 * Propagates all the node in the group
	 */
	public function propagate(?_rate:Float, ?_momentum:Float, ?_target:Array<Float>):Void {

		if (_target != null && _target.length != nodes.length) {
			throw('Array with values should be same as the amount of nodes!');
		}

		var _n:Objects;
		var i:Int = nodes.length - 1;
		while(i >= 0) {
			_n = nodes[i];
			if(_n.is(ObjectsType.node)) {
				var _node:Node = cast _n;
				if (_target == null) {
					_node.propagate(_rate, _momentum);
				} else {
					_node.propagate(_rate, _momentum, false, _target[i]);
				}
			} else if(_n.is(ObjectsType.group)) {
				var _group:Group = cast _n;
				_group.propagate(_rate, _momentum, _target);
			}
			i--;
		}

	}

	/**
	 * Connects the nodes in this group to nodes in another group or just a node
	 */
	override function connect(_obj:Objects, ?_method:ConnectionType, ?_weight:Float):Array<Connection> {

		var _connections:Array<Connection> = [];

		switch (_obj._type_) {
			case ObjectsType.node | ObjectsType.group:{
				_connections = output.connect(_obj, _method, _weight);
			}
			case ObjectsType.layer:{
				var _layer:Layer = cast _obj;
				_connections = _layer.input(output, _method, _weight);
			}
		}

		return _connections;

	}

	/**
	 * Make nodes from this group gate the given connection(s)
	 */
	public function gate(_connections:Array<Connection>, ?_method:GatingType):Void {

		output.gate(_connections, _method);
		
	}

	/**
	 * Sets the value of a property for every node
	 */
	public function set(?_bias:Float, ?_squash:IActivator, ?_type:NodeType):Void {	

		for (n in nodes) {
			if(n.is(ObjectsType.node)) {
				var _node:Node = cast n;
				_node.set(_bias, _squash, _type);
			} else if(n.is(ObjectsType.group)) {
				var _group:Group = cast n;
				_group.set(_bias, _squash, _type);
			}
		}
		
	}

	/**
	 * Disconnects all nodes from this group from another given group/node
	 */
	override function disconnect(_target:Objects, _twosided:Bool = false):Void {
		
		if(_target.is(ObjectsType.group)) {
			var _group:Group = cast _target;
			for (i in 0...nodes.length) {
				for (j in 0..._group.nodes.length) {
					nodes[i].disconnect(_group.nodes[j], _twosided);

					var k:Int = connections.output.length - 1;
					while(k >= 0) {
						var conn = this.connections.output[k];
						if (conn.from == nodes[i] && conn.to == _group.nodes[j]) {
							connections.output.splice(k, 1);
							break;
						}
						k--;
					}

					if (_twosided) {
						k = connections.input.length - 1;
						while(k >= 0) {
							var conn = connections.input[k];
							if (conn.from == _group.nodes[j] && conn.to == nodes[i]) {
								connections.input.splice(k, 1);
								break;
							}
							k--;
						}
					}
				}
			}
		} else if(_target.is(ObjectsType.node)) {
			var _node:Node = cast _target;
			for (i in 0...nodes.length) {
				nodes[i].disconnect(_node, _twosided);

				var j:Int = connections.output.length - 1;
				while(j >= 0) {
					var conn = connections.output[j];
					if (conn.from == nodes[i] && conn.to == _node) {
						connections.output.splice(j, 1);
						break;
					}
					j--;
				}

				if (_twosided) {
					j = connections.output.length - 1;
					while(j >= 0) {
						var conn = connections.input[j];

						if (conn.from == _node && conn.to == nodes[i]) {
							connections.input.splice(j, 1);
							break;
						}
						j--;
					}
				}
			}
		}

	}

	/**
	 * Clear the context of this group
	 */
	override function clear():Void {

		for (n in nodes) {
			n.clear();
		}
		
	}

}


class LayerConnections {


	public var input:Array<Connection>;
	public var output:Array<Connection>;
	public var self:Array<Connection>;


	public function new(_input:Array<Connection>, _output:Array<Connection>, _self:Array<Connection>) {

		input = _input;
		output = _output;
		self = _self;

	}


}