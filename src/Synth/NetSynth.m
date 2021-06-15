classdef NetSynth < handle
	
	properties
		
		stg % Stage to synthesize
		
		% Parameters for Cauer 1st and 2nd for Synthesis
		c_isadm % Is modelling admittance
		c_num % Numerator poly
		c_den % Denominator poly
		c_finished = true; % True when completed
		
		circ
		
		node_iterator
		current_node
		input_node
		output_node
		
		msg
		
	end
	
	methods
		
		function obj = NetSynth(stg_num, den)			
			
			% Check if user is initializing with numerator and denominator
			% vectors, or with Stage class.
			if isa(stg_num, 'double')
				
				num = stg_num;
				
				obj.stg = [];
				
			elseif isa(stg_num, 'Stage')
				
				%Generate Zin(s) from stage
				[~, Zn, Zd] = stg_num.zpoly();

				% Get polynomial vectors
				num = Zn.getVec();
				den = Zd.getVec();
				
				% Save stage
				obj.stg = stg_num;
				
			end
			
			obj.c_isadm = false;
			obj.c_num = num;
			obj.c_den = den;
			obj.c_finished = false;
			
			obj.circ = Netlist([]);
			
			obj.node_iterator = 1;
			obj.current_node = "IN";
			obj.input_node = obj.current_node;
			obj.output_node = "?";
			
			obj.msg = [""];
			
		end
		
		function cauer2(obj) %============ cauer2() =======================
			
			% Perform Cauer I-form Synthesis
			[k, tn, td] = cauer2el(obj.c_num, obj.c_den);
			
			% Create circuit element from output of Cauer-I
			if obj.c_isadm % Is an admittance
				
				% Create circuit element
				ce = CircElement(1/k, "H"); % L = 1/k
				
				% Set nodes
				ce.nodes(1) = obj.current_node;
				ce.nodes(2) = "GND";
				
			else % Is an impedance
				
				% Create circuit element
				ce = CircElement(1/k, "F"); % C = 1/k
				
				% Set nodes
				ce.nodes(1) = obj.current_node;
				ce.nodes(2) = strcat("n", num2str(obj.node_iterator));
				
				% Update next node
				obj.node_iterator = obj.node_iterator + 1;
				obj.current_node = ce.nodes(2);
			end

			% Add circuit element to network
			obj.circ.add(ce);
			
			% Update numerator & denominator
			obj.c_num = tn;
			obj.c_den = td;
			
			% Check for remainder == 0		TODO: Also check for tn == 0?
			if td == 0
				obj.c_finished = true;
			end
			
			% Check for last element
			last_elem = obj.getlastelement(tn, td);
			if ~isempty(last_elem)
				obj.circ.add(last_elem);
				
				obj.c_finished = true;
			end
			
			% Toggle if in admittance mode
			obj.c_isadm = ~obj.c_isadm;
			
		end %================== END cauer2() ==============================
		
		function cauer1(obj) %=================== cauer1() ================
			
			% Perform Cauer II-form Synthesis
			[k, tn, td] = cauer1el(obj.c_num, obj.c_den);
			
			% Create circuit element from output of Cauer-II
			if obj.c_isadm % Is an admittance
				
				% Create circuit element
				ce = CircElement(k, "F"); % C = k
				
				
				% Set nodes
				ce.nodes(1) = obj.current_node;
				ce.nodes(2) = "GND";
				
			else % Is an impedance
				
				% Create circuit element
				ce = CircElement(k, "H"); % L = k
				
				% Set nodes
				ce.nodes(1) = obj.current_node;
				ce.nodes(2) = strcat("n", num2str(obj.node_iterator));
				
				% Update next node
				obj.node_iterator = obj.node_iterator + 1;
				obj.current_node = ce.nodes(2);
			end
			
			% Add circuit element to network
			obj.circ.add(ce);
			
			% Update numerator & denominator
			obj.c_num = tn;
			obj.c_den = td;
			
			% Check for remainder == 0		TODO: Also check for tn == 0?
			if td == 0
				obj.c_finished = true;
			end
			
			%TODO: Check if c_finished already true (could be true if
			%remainder == 0), ie. td = 0
			%
			% Check for last element
			last_elem = obj.getlastelement(tn, td);
			if ~isempty(last_elem)
				obj.circ.add(last_elem);
				
				obj.c_finished = true;
			end
			
			% Toggle if in admittance mode
			obj.c_isadm = ~obj.c_isadm;
			
		end %======================== END cauer1() ========================
		
		function ce = getlastelement(obj, tn, td) %== getlastelement =

			% Get K-value and position of 's' variable
			if iselement(td, tn, "NUM") % Check if in numerator
				in_num = true;
				k_end = td(end-1)/tn(end);
			elseif iselement(td, tn, "DEN") % CHeck if in denom.
				in_num = false;
				k_end = td(end)/tn(end-1);
			else % Else, exit
				ce = [];
				return;
			end

			% Create circuit element from output of Cauer-II
			if obj.c_isadm % Is an admittance

				% Create circuit element
				if in_num
					ce = CircElement(k_end, "F"); % C = k
				else
					ce = CircElement(1/k_end, "H"); % L = 1/k
				end
				% Set nodes
				ce.nodes(1) = obj.current_node;
				ce.nodes(2) = "GND";
				
				% Mark end node
				obj.output_node = ce.nodes(1);

			else % Is an impedance

				% Create circuit element
				if in_num
					ce = CircElement(k_end, "H"); % L = k
				else
					ce = CircElement(1/k_end, "F"); % C = 1/k
				end

				% Set nodes
				ce.nodes(1) = obj.current_node;
				ce.nodes(2) = strcat("n", num2str(obj.node_iterator));

				% Mark end node
				obj.output_node = ce.nodes(2);
				
				% Update next node (TODO: remove?)
				obj.node_iterator = obj.node_iterator + 1;
				obj.current_node = ce.nodes(2);
			end

		end %================== END getlastelement() ======================
		
		function generate(obj, varargin)
			
			%================= Parse Function Inputs ===================
			
			expectedRoutines = {'Automatic', 'Cauer1', 'Cauer2', 'Foster1', 'Foster2'};
			
			p = inputParser;
			p.addRequired('Routine', @(x) any(validatestring(x,expectedRoutines))   );
			p.addParameter('MaxEval', 20, @(x) x > 0);
			p.addParameter('Simplification', 0, @(x) x >= 0); %TODO: Implement
			p.addParameter('f_scale', 1, @(x) x > 0);
			p.addParameter('Z0_scale', 1, @(x) x > 0);
			
			p.parse(varargin{:});
			
			routine = string(p.Results.Routine);
			
			% Call appropriate function
			switch routine
				case "Cauer1"
					obj.genCauer1(p);
					
				case "Cauer2"
					obj.genCauer2(p);
				case "Foster1"
					obj.genFoster1(p);
				case "Foster2"
					obj.genFoster2(p);
				otherwise
					error("Unexpected value for routine");
					
			end
			
			
		end %==================== END generate() =========================
		
		function genCauer1(obj, p)
			
			maxEval = p.Results.MaxEval;
			synth_f_scale = p.Results.f_scale;
			synth_Z0_scale = p.Results.Z0_scale;
			
			% Run cauer synthesis until entire circuit is extracted
			count = 0;
			while ~obj.c_finished % Check if completely extracted
				
				% Rerun Cauer-1 algorithm
				obj.cauer1();
				
				% Increment counter
				count = count +1;
				if  count > maxEval
					error("Maximum number of Cauer executions exceeded");
				end
			end
			
			% Scale circuit
			for elmt=obj.circ.components

				% Scale by frequency
				elmt.val = elmt.val/synth_f_scale;

				% Scale by Z0
				if strcmp(elmt.nodes(2), "GND") %If is an admittance...
					elmt.val = elmt.val/synth_Z0_scale;
				else % Else if an impedance
					elmt.val = elmt.val*synth_Z0_scale;
				end

			end
			
		end
		
		function genCauer2(obj, p)
			warning("Cauer II-form not implemented!"); %TODO: Implement
		end
		
		function genFoster1(obj, p)
			warning("Foster I-form not implemented!"); %TODO: Implement
		end
		
		function genFoster2(obj, p)
			warning("Foster II-form not implemented!"); %TODO: Implement
		end
		
	end
	
end