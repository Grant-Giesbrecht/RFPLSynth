classdef NetSynth < hanlde
	
	properties
		
% 		stg % Stage to synthesize
		
		% Parameters for Cauer 1st and 2nd for Synthesis
		c_isadm % Is modelling admittance
		c_num % Numerator poly
		c_den % Denominator poly
		
		circ
		
		node_iterator
		current_node
		
	end
	
	methods
		
		function obj = NetSynth(init_stg)			
			
% 			obj.stg = init_stg;
			
			obj.c_isadm = false;
			obj.c_num = [];
			obj.c_den = [];
			
			obj.circ = [];
			
			obj.node_iterator = 1;
			obj.current_node = "IN";
			
		end
		
		function cauer1(obj)
			
			% Perform Cauer I-form Synthesis
			[k, tn, td] = cauer1el(obj.c_num, obj.c_den);
			
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
				obj.currnet_node = ce.nodes(2);
			end

			% Add circuit element to network
			obj.circ = addTo(obj.circ, ce);
			
			% Toggle if in admittance mode
			obj.c_isadm = ~obj.c_isadm;
			
			% Update numerator & denominator
			obj.c_num = tn;
			obj.c_den = td;
			
		end
		
		function cauer2(obj)
			
			% Perform Cauer II-form Synthesis
			[k, tn, td] = cauer2el(obj.c_num, obj.c_den);
			
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
			
			% Toggle if in admittance mode
			obj.c_isadm = ~obj.c_isadm;
			
			% Update numerator & denominator
			obj.c_num = tn;
			obj.c_den = td;
			
		end
		
	end
	
end