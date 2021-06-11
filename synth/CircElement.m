classdef CircElement < handle
	
	properties
		nodes
		
		ref_type;
		ref_num;
		val;
		val_unit;
		part_no;
		props;
	end
	
	methods
		function obj = CircElement(val, unit)
			obj.nodes = [""]; % pin N connects to node 'nodes(N)'
			obj.ref_type = "?"; % ex. 'R' for resistor, 'Q' for transistor
			obj.ref_num = 0; % ex. the number in 'R4'
			obj.val = val; % ex. the '50' in 50 ohms
			obj.val_unit = unit; % ex. the 'ohms' in 50 ohms
			obj.part_no = ""; % Part number/identifier. Can be for physical part number in manufacturing, or to distiguish type of element
			obj.props = containers.Map; % Other properties (ex. for transmission lines)
		end
		
		function s = str(obj)
			
			% Create node string
			nodestr = "";
			for n=obj.nodes
				
				% Add junction if not first element
				if ~strcmp(nodestr, "")
					nodestr = strcat(nodestr, "-");
				end
				
				nodestr = strcat(nodestr, n);
			end
			
			s = strcat(num2str(obj.val), " ", obj.val_unit, "   (", nodestr, ")");
			
		end
	end
	
end