classdef CircElement < handle
% CIRCELEMENT Represent an element of a circuit
%
%	CIRCELEMENT Properties
%		nodes - Circuit nodes to which each pin of the component connects
%		ref_type - Letter used in reference identifier (eg. 'R' for 'R1')
%		ref_num - Reference number (eg. '1' in 'R1')
%		val - Component value
%		val_unit - Units of 'val'
%		part_no - Manufacturer's part number for BOM
%		props - Map of additional component properties
%		unique_id - Circuit number, unique among circuit elements in a
%		netlist for easy identification of components.
%
%	CIRCELEMENT Methods
%		CircElement - Initailzer
%		str - Generate string
%		format - Populate fields from ref_type
%		Z - Calcualte element impedance


	properties
		nodes

		ref_type;
		ref_num;
		val;
		val_unit;
		part_no;
		props;

		unique_id;
	end

	methods
		function obj = CircElement(val, unit)
		%CIRCELEMENT Initialize the CIRCELEMENT object
		%
		%	obj = CIRCELEMENT(val, unit) Create a circuit element with
		%	value 'val' with units 'unit'.
		%

			obj.nodes = [""]; % pin N connects to node 'nodes(N)'
			obj.ref_type = "?"; % ex. 'R' for resistor, 'Q' for transistor
			obj.ref_num = 0; % ex. the number in 'R4'
			obj.val = val; % ex. the '50' in 50 ohms
			obj.val_unit = unit; % ex. the 'ohms' in 50 ohms
			obj.part_no = ""; % Part number/identifier. Can be for physical part number in manufacturing, or to distiguish type of element
			obj.props = containers.Map; % Other properties (ex. for transmission lines)

			obj.format();

			obj.unique_id = -1;
		end

		function s = str(obj)
		%STR Display the object as a string
		%
		%	s = STR() Create a string containing the circuit element's
		%	data.

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
		% FORMAT Populate the object's data fields inferring from val_unit.
		%
		% Uses val_unit to infer the component's type.
		%
		%	FORMAT() Populate the object's data fields
		%

			ustr = string(obj.val_unit);
			cu = char(obj.val_unit);

			if length(ustr) > 1
				[mult, baseUnit] = parseUnit(ustr);
			else
				mult = 1;
				baseUnit = ustr;
			end

			baseUnit = upper(baseUnit);

			% Handle many units of electical length in the switch below
			if strcmp(baseUnit, "DEGREE") || strcmp(baseUnit, "DEGREES")
				baseUnit = "DEG";
			end
			if strcmp(baseUnit, "RADIAN") || strcmp(baseUnit, "RADIANS")
				baseUnit = "DEG";
			end

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
				case "DEG"	% Transmission Lines
					obj.ref_type = "TL";
				case "RAD"	% Transmission Lines
					obj.ref_type = "TL";
				otherwise	% Otherwise assume unit is type (ex. transistor
					obj.ref_type = obj.val_unit;
			end

		end %==================== END format() ============================

		function zf = Z(obj, freq) %===================== Z() =============
		% Z Calculate the component's impedance
		%
		% zf = Z(freq) Calcualtes the object's impedance at frequency
		% 'freq'. This function is only valid for inductors, capacitors,
		% and resistors with ref_types 'L', 'C', and 'R', respectively.
		%

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
