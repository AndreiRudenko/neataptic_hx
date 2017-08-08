package neataptic.networks;


import neataptic.Connection;
import neataptic.methods.ConnectionType;
import neataptic.methods.MutationType;
import neataptic.Group;
import neataptic.Layer;
import neataptic.Network;


class Random extends Network {


	public function new(_input:Int, _hidden:Int, _output:Int, ?_options:RandomNetworkOptions) {
		
		super(_input, _output);

		if(_options == null) {
			_options = {};
		}
		
	    var _connections = _options.connections != null ? _options.connections : _hidden * 2;
	    var _backconnections = _options.backconnections != null ? _options.backconnections : 0;
	    var _selfconnections = _options.selfconnections != null ? _options.selfconnections : 0;
	    var _gates = _options.gates != null ? _options.gates : 0;

	    for (_ in 0..._hidden) {
	      mutate(MutationType.add_node);
	    }

	    for (_ in 0...(_connections - _hidden)) {
	      mutate(MutationType.add_conn);
	    }

	    for (_ in 0..._backconnections) {
	      mutate(MutationType.add_back_conn);
	    }

	    for (_ in 0..._selfconnections) {
	      mutate(MutationType.add_self_conn);
	    }

	    for (_ in 0..._gates) {
	      mutate(MutationType.add_gate);
	    }

	}

	
}


typedef RandomNetworkOptions = {

	@:optional var connections:Int;
	@:optional var backconnections:Int;
	@:optional var selfconnections:Int;
	@:optional var gates:Int;

}