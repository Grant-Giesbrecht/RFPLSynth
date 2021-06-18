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
			
			obj.format();
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
			
			scaled_str = scaleNumUnit(obj.val, obj.val_unit);
			
			s = strcat(scaled_str, "   (", nodestr, ")");
			
			if strcmp(obj.ref_type, "TL") && isKey(obj.props, "Z0")
				s = strcat(s, "  [Z0 = ", string(obj.props("Z0")), " Ohms, ");
				
				if isKey(obj.props, "Stub") && islogical(obj.props("Stub")) && obj.props("Stub")
					if isKey(obj.props, "Term") && strcmp(obj.props("Term"), "SHORT")
						s = strcat(s, "Shorted Stub]");
					else
						s = strcat(s, "Open Stub]");
					end
				else
					s = strcat(s, "TLine]");
				end
				
			end
			
		end
		
		function format(obj) %============== format() =====================
			
			ustr = string(obj.val_unit);
			cu = char(obj.val_unit);
			
			if length(ustr) > 1
				[mult, baseUnit] = parseUnit(ustr);
			else
				mult = 1;
				baseUnit = ustr;
			end
			
			baseUnit = upper(baseUnit);
			
			switch baseUnit
				case "F"	% Capacitors
					obj.ref_type = "C";
				case "H"	% Inductors
					obj.ref_type = "L";
				case "OHM"	% Resistors
					obj.ref_type = "R";
				case "R"	% Resistors
					obj.ref_type = "R";
				case "M"	% Transmission Lines
					obj.ref_type = "TL";
				otherwise	% Otherwise assume unit is type (ex. transistor 
					obj.ref_type = obj.val_unit;
			end
			
		end %==================== END format() ============================
		
		function zf = Z(obj, freq) %===================== Z() =============
			
			switch obj.ref_type
				case "C"
					zf = Zc(obj.val, freq);
				case "L"
					zf = Zl(obj.val, freq);
				case "R"
					zf = obj.val;
				otherwise
					zf = NaN;
			end
					
		end %========================== END Z =============================
	end
	
end