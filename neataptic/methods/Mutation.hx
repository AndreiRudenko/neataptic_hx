package neataptic.methods;

import neataptic.methods.MutationType;

@:keep
@:enum abstract Mutation(Array<MutationType>) from Array<MutationType> to Array<MutationType> {

	public static var all = [
		MutationType.add_node,
		MutationType.sub_node,
		MutationType.add_conn,
		MutationType.sub_conn,
		MutationType.mod_weight,
		MutationType.mod_bias,
		MutationType.mod_activation,
		MutationType.add_gate,
		MutationType.sub_gate,
		MutationType.add_self_conn,
		MutationType.sub_self_conn,
		MutationType.add_back_conn,
		MutationType.sub_back_conn,
		MutationType.swap_nodes
	];

	public static var ffw = [
		MutationType.add_node,
		MutationType.sub_node,
		MutationType.add_conn,
		MutationType.sub_conn,
		MutationType.mod_weight,
		MutationType.mod_bias,
		MutationType.mod_activation,
		MutationType.swap_nodes
	];


}