classdef NetSynth < handle
	
	properties
		
% 		stg % Stage to synthesize
		
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
		
	end
	
	methods
		
		function obj = NetSynth(num, den)			
			
% 			obj.stg = init_stg;
			
			obj.c_isadm = false;
			obj.c_num = num;
			obj.c_den = den;
			obj.c_finished = false;
			
			obj.circ = [];
			
			obj.node_iterator = 1;
			obj.current_node = "IN";
			obj.input_node = obj.current_node;
			obj.output_node = "?";
			
			
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
			obj.circ = addTo(obj.circ, ce);
			
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
				obj.circ = addTo(obj.circ, last_elem);
				
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
			obj.circ = addTo(obj.circ, ce);
			
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
				obj.circ = addTo(obj.circ, last_elem);
				
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
		
	end
	
end