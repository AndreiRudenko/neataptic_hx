package neataptic;


import neataptic.ObjectsType;
import neataptic.Network;
import neataptic.methods.SelectionType;
import neataptic.methods.CrossoverType;
import neataptic.methods.Mutation;
import neataptic.methods.MutationType;
import neataptic.utils.Maths;


class Neat {


	public var input:Int;
	public var output:Int;
	public var fitness:Network->Float;

	public var equal:Bool;
	public var clear:Bool;

	public var popsize:Int;
	public var elitism:Int;
	public var provenance:Int;
	public var mutation_rate:Float;
	public var mutation_amount:Int;
	public var fitness_population:Bool;
	public var selection:SelectionType;
	public var crossover:Array<CrossoverType>;

	public var mutation:Array<MutationType>;
	public var mutation_selection:Network->MutationType;

	public var template:Network;
	public var population:Array<Network>;

	public var generation:Int;

	public var maxnodes:Int;
	public var maxconns:Int;
	public var maxgates:Int;


	public function new(_input:Int, _output:Int, ?_fitness:Network->Float, ?_options:NeatOptions) {

		input = _input;
		output = _output;
		fitness = _fitness;

		if(_options == null) {
			_options = {};
		}

		equal = _options.equal != null ? _options.equal : false;
		clear = _options.clear != null ? _options.clear : false;
		popsize = _options.popsize != null ? _options.popsize : 50;
		elitism = _options.elitism != null ? _options.elitism : 0;
		provenance = _options.provenance != null ? _options.provenance : 0;
		maxnodes = _options.maxnodes != null ? _options.maxnodes : 0x3fffffff;
		maxconns = _options.maxconns != null ? _options.maxconns : 0x3fffffff;
		maxgates = _options.maxgates != null ? _options.maxgates : 0x3fffffff;
		mutation_rate = _options.mutation_rate != null ? _options.mutation_rate : 0.3;
		mutation_amount = _options.mutation_amount != null ? _options.mutation_amount : 1;
		mutation_selection = _options.mutation_selection != null ? _options.mutation_selection : selectmutationmethod;

		fitness_population = _options.fitness_population != null ? _options.fitness_population : false;

		selection = _options.selection != null ? _options.selection : SelectionType.power;
		crossover = _options.crossover != null ? _options.crossover : [		
			CrossoverType.single_point,
			CrossoverType.two_point,
			CrossoverType.uniform,
			CrossoverType.average
		];

		mutation = _options.mutation != null ? _options.mutation : Mutation.ffw;
		template = _options.network != null ? _options.network : null;

		// Generation counter
		generation = 0;

		// Initialise the genomes
		create_pool(template);

	}

	/**
	 * Create the initial pool of genomes
	 */
	public function create_pool(_network:Network) {

		population = [];

		for (i in 0...popsize) {
			var copy:Network = null;
			if (template != null) {
				copy = Network.from_json(_network.to_json());
			} else {
				copy = new Network(input, output);
			}
			copy.score = null;
			population.push(copy);
		}

	}

	/**
	 * Evaluates, selects, breeds and mutates population
	 */
	public function evolve():Network { // async?
			// Check if evaluated, sort the population
		if (population[population.length - 1].score == null) {
			evaluate();
		}
		sort();

		var fittest = Network.from_json(population[0].to_json());
		fittest.score = population[0].score;

		var _new_population:Array<Network> = [];

		// Elitism
		var elitists:Array<Network> = [];
		for (i in 0...elitism) {
			elitists.push(population[i]);
		}


		// Provenance
		for (i in 0...provenance) {
			_new_population.push(Network.from_json(template.to_json()));
		}

		// Breed the next individuals
		for (i in 0...(popsize - elitism - provenance)) {
			_new_population.push(get_offspring());
		}

		// Replace the old population with the new population
		population = _new_population;
		mutate();

		// population.push(...elitists);
		for (e in elitists) {
			population.push(e);
		}

		// Reset the scores
		for (p in population) {
			p.score = null;
		}

		generation++;

		return fittest;

	}

	/**
	 * Breeds two parents into an offspring, population MUST be surted
	 */
	public function get_offspring():Network {

		var parent1:Network = get_parent();
		var parent2:Network = get_parent();

		return Network.crossover(parent1, parent2, equal);

	}

	/**
	 * Selects a random mutation method for a genome according to the parameters
	 */
	function selectmutationmethod(genome:Network):MutationType {

		var _mutationmethod:MutationType = mutation[Math.floor(Math.random() * mutation.length)];

		if (_mutationmethod == MutationType.add_node && genome.nodes.length >= maxnodes) {
			// if (config.warnings) console.warn('maxnodes exceeded!'); // todo
			trace('maxnodes exceeded!');
			return MutationType.none;
		}

		if (_mutationmethod == MutationType.add_conn && genome.connections.length >= maxconns) {
			// if (config.warnings) console.warn('maxconns exceeded!'); // todo
			trace('maxconns exceeded!');
			return MutationType.none;
		}

		if (_mutationmethod == MutationType.add_gate && genome.gates.length >= maxgates) {
			// if (config.warnings) console.warn('maxgates exceeded!'); // todo
			trace('maxgates exceeded!');
			return MutationType.none;
		}

		return _mutationmethod;
	}

	/**
	 * Mutates the given (or current) population
	 */
	public function mutate():Void {

		// Elitist genomes should not be included
		for (p in population) {
			if (Math.random() <= mutation_rate) {
				for (_ in 0...mutation_amount) {
					var _mutation_method = mutation_selection(p);
					p.mutate(_mutation_method);
				}
			}
		}

	}

	/**
	 * Evaluates the current population
	 */
	public function evaluate():Void { // async?

		if (fitness_population) {
			if (clear) {
				for (genome in population) {
					genome.clear();
				}
			}
			
			if(fitness != null) {
				for (genome in population) {
					fitness(genome);
				}
			} 
			// else {
			// 	for (genome in population) {
			// 		if(genome.score == null) {
			// 			genome.score = 0;
			// 		}
			// 	}
			// }
		} else {
			for (genome in population) {
				if (clear) {
					genome.clear();
				}

				if(fitness != null) {
					genome.score = fitness(genome);
				} 

			}
		}

	}

	/**
	 * Sorts the population by score
	 */
	public function sort(_pop:Array<Network> = null):Void {

		if(_pop == null) {
			_pop = population;
		}

		_pop.sort(function (a, b) {
			var sa = a.score != null ? a.score : 0;
			var sb = b.score != null ? b.score : 0;
			return Maths.sign0(sb - sa);
		});

	}

	/**
	 * Returns the fittest genome of the current population
	 */
	public function get_fittest():Network { 

		// Check if evaluated
		if (population[population.length - 1].score == null) {
			evaluate();
		}

		// todo: does i need sort current in population array?
		// sort();
		// return population[0];

		var _fittest_val:Float = 0;
		var _pop:Network = null;
		for (p in population) {
			if(p.score != null && _fittest_val < p.score) {
				_fittest_val = p.score;
				_pop = p;
			}
		}
		
		if(_pop == null) {
			_pop = population[0];
		}

		return _pop;

	}

	/**
	 * Returns the average fitness of the current population
	 */
	public function get_average():Float {

		if (population[population.length - 1].score == null) {
			evaluate();
		}

		var score:Float = 0;
		for (p in population) {
			score += p.score;
		}

		if(score != 0) {
			score /= population.length;
		}

		return score;

	}

	/**
	 * Gets a genome based on the selection function
	 * @return {Network} genome
	 */
	public function get_parent():Network {

		switch (selection) {
			case SelectionType.power: {
				if (population[0].score < population[1].score) {
					// todo: look at get_fittest
					sort();
				}

				var _power:Float = neataptic.methods.selection.Power.power;
				var index:Int = Math.floor(Math.pow(Math.random(), _power) * population.length);
				return population[index];
			}
			case SelectionType.fitness_proportionate: {
				// As negative fitnesses are possible
				// https://stackoverflow.com/questions/16186686/genetic-algorithm-handling-negative-fitness-values
				// this is unnecessarily run for every individual, should be changed

				var _total_fitness:Float = 0;
				var _minimal_fitness:Float = 0;
				for (p in population) {
					var score = p.score;
					_minimal_fitness = score < _minimal_fitness ? score : _minimal_fitness;
					_total_fitness += score;
				}

				_minimal_fitness = Std.int(Math.abs(_minimal_fitness));
				_total_fitness += _minimal_fitness * population.length;

				var random = Math.random() * _total_fitness;
				var value:Float = 0;

				for (genome in population) {
					value += genome.score + _minimal_fitness;
					if(random < value) {
						return genome;
					}
				}

				// if all scores equal, return random genome
				return population[Math.floor(Math.random() * population.length)];

			}
			case SelectionType.tournament: {

				var _size:Int = neataptic.methods.selection.Tournament.size;
				var _probability:Float = neataptic.methods.selection.Tournament.probability;

				if (_size > popsize) {
					throw('Your tournament size should be lower than the population size, please change methods.selection.TOURNAMENT.size');
				}

				// Create a tournament
				var individuals:Array<Network> = [];
				for (_ in 0..._size) {
					var random:Network = population[Math.floor(Math.random() * population.length)];
					individuals.push(random);
				}

				// Sort the tournament individuals by score
				individuals.sort(function (a, b) {
					return Maths.sign0(b.score - a.score);
				});

				// Select an individual
				for (i in 0..._size) {
					if (Math.random() < _probability || i == _size - 1) {
						return individuals[i];
					}
				}
			}
		}

		return null;

	}

	/**
	 * Export the current population to a json object
	 */
	public function _export():Array<NetworkData> {

		var json = [];
		for (genome in population) {
			json.push(genome.to_json());
		}

		return json;

	}

	/**
	 * Import population from a json object
	 */
	public function _import(json:Array<NetworkData>):Void {

		var _population:Array<Network> = [];
		for (g in json) {
			_population.push(Network.from_json(g));
		}
		population = _population;
		popsize = population.length;

	}

	
}


typedef NeatOptions = {

	@:optional var popsize:Int;
	@:optional var elitism:Int;
	@:optional var provenance:Int;
	@:optional var mutation:Array<MutationType>;
	@:optional var selection:SelectionType;
	@:optional var crossover:Array<CrossoverType>;
	@:optional var fitness_population:Bool;
	@:optional var mutation_rate:Float;
	@:optional var mutation_amount:Int;
	@:optional var maxnodes:Int;
	@:optional var maxconns:Int;
	@:optional var maxgates:Int;
	@:optional var network:Network;
	@:optional var equal:Bool;
	@:optional var clear:Bool;
	@:optional var mutation_selection:Network->MutationType;

}