classdef NetSynth < handle

	properties

		stg % Stage to synthesize
		num_orig
		den_orig

		% Parameters for Cauer 1st and 2nd for Synthesis
		is_admit % Is modelling admittance
		num % Numerator poly
		den % Denominator poly
		finished = true; % True when completed

		circ

		node_iterator
		current_node
		input_node
		output_node

		msg
		
		freq % Frequency
		vel % Propagation speed
		vf_init 
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

			obj.is_admit = false;
			obj.num = num;
			obj.den = den;
			obj.num_orig = num;
			obj.den_orig = den;
			obj.finished = false;

			obj.circ = Netlist([]);

			obj.node_iterator = 1;
			obj.current_node = "IN";
			obj.input_node = obj.current_node;
			obj.output_node = "?";

			obj.msg = [];
			
			obj.vel = "Not Initialized";
			obj.freq = "Not Initialized";

		end
		
		function initFreqVF(v, f)
			obj.vel = v;
			obj.freq = f;
		end

		function [forms, m] = realizable(obj, varargin)

			m = "";

			% Parse optional parameter
			expectedForms = {'Cauer1', 'Cauer2', 'Foster1', 'Foster2', 'None'};
			p = inputParser;
			p.addParameter('DetailedForm', 'None' ,@(x) any(validatestring(x,expectedForms))   );
			p.parse(varargin{:});
			detailedForm = p.Results.DetailedForm;

			forms = [];

			% Create Polynomial class from numerator and denominator vecs
			np = Polynomial(0);
			dp = Polynomial(0);
			np.setVec(obj.num);
			dp.setVec(obj.den);

			%===== Initialize Variables used for Multiple Conditions ======

			% Lossless Driving Point (DP) function conditions
			dpc1 = false;
			dpc2 = false;
			dpc3 = false;
			dpc4 = false;
			dpc5 = false;
			dpc6 = false;

			%================== Evaluate Conditions =======================

			% DP Condition 1 (Poles and Zeros only on imag. axis)
			dpc1 = true; %TODO: Implement

			% DP Condition 2 (Function is odd and rational)
			if (rem(np.order(), 2) == 0 && rem(dp.order(), 2) == 1)...
			|| (rem(np.order(), 2) == 1 && rem(dp.order(), 2) == 0 )
				dpc2 = true;
			end

			% DP Condition 3 (Num and Den order differ by exactly 1)
			if (np.order() == dp.order()+1) || (np.order()+1 == dp.order())
				dpc3 = true;
			end

			% DP Condition 4 (All poles and zeros are simple)
			dpc4 = true; %TODO: Implement

			% DP Condition 5 (Exept at poles, monotinically increasing)
			dpc5 = true; %TODO: Implement

			% DP Condition 6 (0 and inf are CPs, CPs alternate btwn P & Z).
			dpc6 = true; %TODO: Implement

			% Lossless DP Function Condition
			lpd = dpc1 && dpc2 && dpc3 && dpc4 && dpc5 && dpc6;

			% TODO: Darlington?

			% If Lossess DP function condition not met, specify why
			ldp_msg = "";
			if ~lpd
				m = "Failed lossless-DP condition(s): ";
				if ~dpc1
					m = strcat(m, "1 ");
				end
				if ~dpc2
					m = strcat(m, "2 ");
				end
				if ~dpc3
					m = strcat(m, "3 ");
				end
				if ~dpc4
					m = strcat(m, "4 ");
				end
				if ~dpc5
					m = strcat(m, "5 ");
				end
				if ~dpc6
					m = strcat(m, "6 ");
				end
			end

			%=============== Evaluate Network Realizability ===============



			% Evaluate Foster Realizability
			if lpd
				forms = addTo(forms, "Foster1");
				forms = addTo(forms, "Foster2");
			elseif detailedForm == "Foster1" || detailedForm == "Foster2"
				m = ldp_msg;
			end

			% Cauer I-form
			cauer1_cond1 = np.order() > dp.order();
			if lpd && cauer1_cond1
				forms = addTo(forms, "Cauer1");
			elseif detailedForm == "Cauer1"
				if ~lpd
					m = strcat(ldp_msg, ".");
				end
				if ~cauer1_cond1
					m = strcat(m, "Numerator order is not exactly 1 greater than denominator order.");
				end
			end

			% Cauer II-form
			cauer2_cond1 = rem(np.order(), 2) == 0;
			cauer2_cond2 = rem(dp.order(), 2) == 1;
			if lpd && cauer2_cond1 && cauer2_cond2
				forms = addTo(forms, "Cauer2");
			elseif detailedForm == "Cauer2"
				if ~lpd
					m = strcat(ldp_msg, ".");
				end
				if ~cauer2_cond1
					m = strcat(m, "Numerator is not even.");
				end
				if ~cauer2_cond2
					m = strcat(m, "Denominator is not odd.");
				end

			end



		end
		
		function tf = changeZaddStubs(obj, varargin)
			
			
		
			p = inputParser;
			p.addParameter('Zmin', 35, @(x) x > 0 );
			p.addParameter('Zmax', 100, @(x) x > 0);
			p.addParameter('Index', -1, @isnumeric);

			p.parse(varargin{:});

			Zmin = p.Results.Zmin;
			Zmax = p.Results.Zmax;
			
			% Check Zmax and Zmin
			if Zmax < Zmin
				warning("Zmax is less than Zmin");
				temp = Zmax;
				Zmax = Zmin;
				Zmin = temp;
			end
			
			% Get indexes
			elmts_idx = [];
			if p.Results.Index == -1 % Use all indeces if -1
				
				for e = obj.circ.components 
					if e.ref_type == "TL" && isKey(e.props, "Z0") % Add to list if is  TL and has Z0 defined
						elmts_idx = addTo(elmts_idx, e.unique_id);
					end
				end
				
			else
				elmts_idx = p.Results.Index;
			end
		
			% Check each listed TL, see if in bounds
			for id = elmts_idx
				
				idx = obj.circ.ID2Idx(id);
				
				if obj.circ.components(idx).props("Z0") < Zmin 
					obj.raiseZ(idx, Zmin);
				elseif obj.circ.components(idx).props("Z0") > Zmax
					obj.lowerZ(idx, Zmax);
				end
			
			end
			
			obj.circ.simplify();
			
			for t = elmts_idx
				obj.toStub();
			end
			
		end
		
		function tf = lowerZ(obj, eidx, ZB)
			
			% Ensure not out of bounds
			if length(obj.circ.components) < eidx
				warning("Out of bounds");
				tf = false;
				return;
			end
			
			% Ensure correct component type
			if ~strcmp(obj.circ.components(eidx).ref_type, "TL")
				warning("Incorrect component type");
				tf = false;
				return;
			end
			
			% Ensure impedance starts higher than 'Z' and 'Z0' is specified
			if ~isKey(obj.circ.components(eidx).props, "Z0") || obj.circ.components(eidx).props("Z0") < ZB
				warning("Wrong impedance change direction");
				tf = false;
				return;
			end
			
			% Get original length
			[mult, baseUnit] = parseUnit(obj.circ.components(eidx).val_unit);
			if strcmp(baseUnit, "DEG") || strcmp(baseUnit, "DEGREE") || strcmp(baseUnit, "DEGREES")
				theta_A = obj.circ.components(eidx).val * mult / 180 * 3.1415926535;
			elseif strcmp(baseUnit, "RAD") || strcmp(baseUnit, "RADIAN") || strcmp(baseUnit, "RADIANS")
				theta_A = obj.circ.components(eidx).val * mult;
			elseif strcmp(baseUnit, "M")
				theta_A = obj.virc.components(eidx).val / obj.vel * obj.freq;
			end
			
			% Get new length
			theta_B = asin(ZB/obj.circ.components(eidx).props("Z0")*sin(theta_A));
			Z_L = (cos(theta_B) - cos(theta_A))*ZB / (sin(theta_B));
			
			% Create shunt elements
			ce1 = CircElement(Z_L/(2*3.1415926535*obj.freq), "H");
			ce1.props("ConvertToStub") = true;
			ce1.props("StubZ") = ZB;
			
			ce2 = CircElement(Z_L/(2*3.1415926535*obj.freq), "H");
			ce2.props("ConvertToStub") = true;
			ce2.props("StubZ") = ZB;
			
			% Set nodes
			ce1.nodes(1) = obj.circ.components(eidx).nodes(1);
			obj.circ.components(eidx).nodes(1) = strcat("n", num2str(obj.node_iterator));	
			obj.node_iterator = obj.node_iterator + 1;
			ce1.nodes(2) = obj.circ.components(eidx).nodes(1);
			ce2.nodes(2) = obj.circ.components(eidx).nodes(2);
			obj.circ.components(eidx).nodes(2) = strcat("n", num2str(obj.node_iterator));	
			obj.node_iterator = obj.node_iterator + 1;
			ce2.nodes(1) = obj.circ.components(eidx).nodes(2);
			
			% Change transmission line values
			obj.circ.components(eidx).props("Z0") = ZB;
			obj.circ.components(eidx).val = theta_B*180/3.1415926535;
			obj.circ.components(eidx).val_unit = "DEG";
			
			% Add new elements
			obj.circ.addAt(ce2, eidx+1);
			obj.circ.addAt(ce1, eidx);
			
		end
		
		function tf = raiseZ(obj, eidx, ZB)
			
			% Ensure not out of bounds
			if length(obj.circ.components) < eidx
				warning("Out of bounds");
				tf = false;
				return;
			end
			
			% Ensure correct component type
			if ~strcmp(obj.circ.components(eidx).ref_type, "TL")
				warning("Incorrect component type");
				tf = false;
				return;
			end
			
			% Ensure impedance starts higher than 'Z' and 'Z0' is specified
			if ~isKey(obj.circ.components(eidx).props, "Z0") || obj.circ.components(eidx).props("Z0") > ZB
				warning("Wrong impedance change direction");
				tf = false;
				return;
			end
			
			% Get original length
			[mult, baseUnit] = parseUnit(obj.circ.components(eidx).val_unit);
			if strcmp(baseUnit, "DEG") || strcmp(baseUnit, "DEGREE") || strcmp(baseUnit, "DEGREES")
				theta_A = obj.circ.components(eidx).val * mult / 180 * 3.1415926535;
			elseif strcmp(baseUnit, "RAD") || strcmp(baseUnit, "RADIAN") || strcmp(baseUnit, "RADIANS")
				theta_A = obj.circ.components(eidx).val * mult;
			elseif strcmp(baseUnit, "M")
				theta_A = obj.virc.components(eidx).val / obj.vel * obj.freq;
			end
			
			% Get new length
			theta_B = asin(obj.circ.components(eidx).props("Z0")/ZB*sin(theta_A));
			Z_L = 1/((cos(theta_B) - cos(theta_A)) / (ZB*sin(theta_B)));
			
			% Create shunt elements
			ce1 = CircElement(1/(2*3.1415926535*obj.freq*Z_L), "F");
			ce1.props("ConvertToStub") = true;
			ce1.props("StubZ") = ZB;
			
			ce2 = CircElement(1/(2*3.1415926535*obj.freq*Z_L), "F");
			ce2.props("ConvertToStub") = true;
			ce2.props("StubZ") = ZB;
			
			ce1.nodes(1) = obj.circ.components(eidx).nodes(1);
			ce1.nodes(2) = "GND";
			ce2.nodes(1) = obj.circ.components(eidx).nodes(2);
			ce2.nodes(2) = "GND";
			
			% Change transmission line values
			obj.circ.components(eidx).props("Z0") = ZB;
			obj.circ.components(eidx).val = theta_B*180/3.1415926535;
			obj.circ.components(eidx).val_unit = "DEG";
			
			% Add new elements
			obj.circ.addAt(ce2, eidx+1);
			obj.circ.addAt(ce1, eidx);
% 			obj.circ.components = [obj.circ.components(1:eidx-1), ce1, obj.circ.components(eidx), ce2, obj.circ.components(eidx+1:end)];
			
		end
		
		function tf = toStub(obj)
			
			tf = true;
			
			% For each element...
			for el = obj.circ.components
				
				% Skip elements not marked for stub conversion
				if ~isKey(el.props, "ConvertToStub") || el.props("ConvertToStub") == false
					continue;
				end
				
				% Get stub impedance
				if ~isKey(el.props, "StubZ")
					warning("Missing new impedance for stub conversion");
					Zstub = 50;
				else
					Zstub = el.props("StubZ");
				end
				
				% Get element impedance
				[mult, ~] = parseUnit(el.val_unit);
				if strcmp(el.ref_type, "C")
					Zl = 1/(2*3.1415926535*obj.freq*el.val*mult);
					Xl = 1/Zl;
					
					el.props("Term") = "OPEN";
					el.nodes(2) = strcat("n", num2str(obj.node_iterator));
					
				elseif strcmp(el.ref_type, "L")
					Zl = 2*3.1415926535*obj.freq*el.val*mult;
					Xl = Zl;
					
					el.props("Term") = "SHORT";
				
				else
					warning(strcat("No rule for processing element type '", el.ref_type, "'."));
					continue;
				end
				
				
				% Get stub length
				theta_L = atan(Zstub * Xl);
				
				% Change element
				el.props("ConvertToStub") = false;
				el.val = theta_L*180/3.1415926535;
				el.val_unit = "DEG";
				el.ref_type = "TL";
				el.props("Stub") = true;
				
				el.props("Z0") = Zstub;
				
				% Increment Node
				obj.node_iterator = obj.node_iterator + 1;
				
			end
			
		end
		
		function tf = richardStepZ(obj)
			
			%TODO: Check realizability
			
			% TODO: Determine how compatability with Foster and Cauer is
			% affected, or if an actual transformation process is required
			% other than just deciding it's now a function of t instead of
			% s.
			
			tf = true;
			
			% Get Z numerator and denominator
			if obj.is_admit
				Z_num = obj.den;
				Z_den = obj.num;
			else
				Z_num = obj.num;
				Z_den = obj.den;
			end
			
			% Define symbolic polynomial
			syms t;
			n = poly2sym(Z_num, t);
			d = poly2sym(Z_den, t);
			Z_t = n/d;
			
			% Define impedance of UE
			Z_ue = subs(Z_t, t, 1);
			
			% Determine remaining Z function
			Z_rem = Z_ue * (Z_t - t * Z_ue ) / (Z_ue - t * Z_t);
			[tn, td] = sym2nd(Z_rem);
			
			% Create circuit element
			tl = CircElement(1, "m"); %TODO: Fix length of line
			tl.props("Z0") = Z_ue;
			tl.props("Stub") = false;
			
			tl.nodes(1) = obj.current_node;
			
			% Increment Node
			obj.current_node = strcat("n", num2str(obj.node_iterator));
			obj.node_iterator = obj.node_iterator + 1;

			tl.nodes(2) = obj.current_node;
			
			obj.circ.add(tl);
			
			% Update numerator & denominator
			if obj.is_admit
				obj.num = td;
				obj.den = tn;
			else
				obj.num = tn;
				obj.den = td;
			end
			
			% Check for is last stage
			np = Polynomial(0);
			dp = Polynomial(0);
			np.setVec(tn);
			dp.setVec(td);
			if np.order() == 0 && dp.order() == 0
				obj.finished = true;
				
				R = CircElement(np.get(0)/dp.get(0), "Ohms");
				R.nodes(1) = obj.current_node;
				R.nodes(2) = "GND";
				obj.output_node = obj.current_node;
				
				obj.circ.add(R);
				
			end
			
		end
		
		function tf = richardStub(obj)
			
			%TODO: Check realizability
			
			
			% TODO: Determine how compatability with Foster and Cauer is
			% affected, or if an actual transformation process is required
			% other than just deciding it's now a function of t instead of
			% s.
			
			tf = true;
			
			% Get Z numerator and denominator
			if obj.is_admit
				Z_num = obj.den;
				Z_den = obj.num;
			else
				Z_num = obj.num;
				Z_den = obj.den;
			end
			
			% Define Polynomial
			np = Polynomial(0);
			dp = Polynomial(0);
			np.setVec(Z_num);
			dp.setVec(Z_den);
			
			% Define symbolic polynomial
			syms t;
			n = poly2sym(Z_num, t);
			d = poly2sym(Z_den, t);
			Z_t = n/d;
			
			% Determine if open or shorted stub is to be extracted
			extract_open = true;
			if np.order() > dp.order()
				extract_open = false;
			end
			
			
			if extract_open
				
				n = dp.order();
				
				% Define impedance of UE
				Z_ue = np.get(n-1)/dp.get(n);
				
				% Get remainder polynomial
				Z_rem = (Z_ue * Z_t)/(Z_ue - t * Z_t);
				[tn, td] = sym2nd(Z_rem);
				
			else
				
				n = np.order();
				
				% Define impedance of UE
				Z_ue = np.get(n)/dp.get(n-1);
				
				% Get remainder polynomial
				Z_rem = (Z_ue * Z_t)/(Z_ue - t * Z_t);
				[tn, td] = sym2nd(Z_rem);
			end
			
			% Create circuit element
			tl = CircElement(1, "m"); %TODO: Fix length of line
			tl.props("Z0") = Z_ue;
			tl.props("Stub") = true;
			
			if extract_open
				tl.props("Term") = "OPEN";
				
				tl.nodes(1) = obj.current_node;
				tl.nodes(2) = strcat("n", num2str(obj.node_iterator));
				
				% Increment Node
				obj.node_iterator = obj.node_iterator + 1;
				
			else
				tl.props("Term") = "SHORT";
				
				tl.nodes(1) = obj.current_node;
			
				% Increment Node
				obj.current_node = strcat("n", num2str(obj.node_iterator));
				obj.node_iterator = obj.node_iterator + 1;

				tl.nodes(2) = obj.current_node;
				
			end
			
			obj.circ.add(tl);
			
			% Update numerator & denominator
			if obj.is_admit
				obj.num = td;
				obj.den = tn;
			else
				obj.num = tn;
				obj.den = td;
			end
			
			% Check for is last stage
			np = Polynomial(0);
			dp = Polynomial(0);
			np.setVec(tn);
			dp.setVec(td);
			if np.order() == 0 && dp.order() == 0
				obj.finished = true;
				
				R = CircElement(np.get(0)/dp.get(0), "Ohms");
				R.nodes(1) = obj.current_node;
				R.nodes(2) = "GND";
				obj.output_node = obj.current_node;
				
				obj.circ.add(R);
				
			end
			
		end
		
		

		function tf = foster1(obj)

			tf = true;

			% Check realizability criteria
			[formats, fm] = obj.realizable('DetailedForm', 'Foster1');
			if ~any(formats == "Foster1")
				
				% Try flipping poly
				obj.is_admit = ~obj.is_admit;
				temp = obj.num;
				obj.num = obj.den;
				obj.den = temp;
				[formats, fm] = obj.realizable('DetailedForm', 'Foster1');
				
				if ~any(formats == "Foster1")
					tf = false;
					obj.msg = addTo(obj.msg, strcat("Cannot synthesize form 'Foster1' (", fm , ")"));
					return;
				else
					obj.msg = addTo(obj.msg, "To realize as Foster1, function was inverted.");
				end
				
			end

			% Get Z numerator and denominator
			if obj.is_admit
				Z_num = obj.den;
				Z_den = obj.num;
			else
				Z_num = obj.num;
				Z_den = obj.den;
			end

			% Perform Foster I-form synthesis
			[L, C, tn, td] = foster1el(Z_num, Z_den);

			ind = CircElement(L, "H");
			cap = CircElement(C, "F");

			ind.nodes(1) = obj.current_node;
			cap.nodes(1) = obj.current_node;

			% Increment Node
			obj.current_node = strcat("n", num2str(obj.node_iterator));
			obj.node_iterator = obj.node_iterator + 1;

			ind.nodes(2) = obj.current_node;
			cap.nodes(2) = obj.current_node;

			% Add circuit element to network
			obj.circ.add(ind);
			obj.circ.add(cap);

			% Update numerator & denominator
			if obj.is_admit
				obj.num = td;
				obj.den = tn;
			else
				obj.num = tn;
				obj.den = td;
			end


			% TODO: Is this correct for Foster?
			% Check for remainder == 0		TODO: Also check for tn == 0?
			if tn == 0
				obj.finished = true;
			end

			%TODO: Check if finished already true (could be true if
			%remainder == 0), ie. td = 0
			%
			% Check for last element
			[last_ind, last_cap] = obj.getlastfoster(tn, td, 1);
			if ~isempty(last_ind)
				obj.circ.add(last_ind);
				obj.circ.add(last_cap);

				obj.finished = true;
			end
			ce = obj.getlastcauer(tn, td);
			if ~isempty(ce)
				obj.circ.add(ce);
				obj.finished = true;
			end

		end

		function tf = foster2(obj)

			tf = true;

			% Check realizability criteria
			[formats, fm] = obj.realizable('DetailedForm', 'Foster2');
			if ~any(formats == "Foster2")
				
				% Try flipping poly
				obj.is_admit = ~obj.is_admit;
				temp = obj.num;
				obj.num = obj.den;
				obj.den = temp;
				[formats, fm] = obj.realizable('DetailedForm', 'Foster2');
				
				if ~any(formats == "Foster2")
					tf = false;
					obj.msg = addTo(obj.msg, strcat("Cannot synthesize form 'Foster2' (", fm , ")"));
					return;
				else
					obj.msg = addTo(obj.msg, "To realize as Foster2, function was inverted.");
				end
			end

			% Get Y numerator and denominator
			if obj.is_admit
				Y_num = obj.num;
				Y_den = obj.den;
			else
				Y_num = obj.den;
				Y_den = obj.num;
			end

			% Perform Foster II-form synthesis
			%
			% Note: these are flipped because my numerator and denominator
			% refer to an admittance (Y) function inside this foster2()
			% function but refer to an impedance (Z) in the remainder of
			% the NetSynth class. I keep tn and td as referring to Y here.
			[L, C, tn, td] = foster2el(Y_num, Y_den);

			ind = CircElement(L, "H");
			cap = CircElement(C, "F");

			ind.nodes(1) = obj.current_node;

			% Set Ind node 2, cap node 1
			ind.nodes(2) = strcat("n", num2str(obj.node_iterator));
			cap.nodes(1) = ind.nodes(2);
			obj.node_iterator = obj.node_iterator + 1;

			cap.nodes(2) = "GND";

			% Add circuit element to network
			obj.circ.add(ind);
			obj.circ.add(cap);

			% Update numerator & denominator
			%
			% Note: these are flipped because my numerator and denominator
			% refer to an admittance (Y) function inside this foster2()
			% function but refer to an impedance (Z) in the remainder of
			% the NetSynth class.
			if obj.is_admit
				Z_num = tn;
				Z_den = td;
			else
				obj.num = td;
				obj.den = tn;
			end

			% TODO: Is this correct for Foster?
			% Check for remainder == 0		TODO: Also check for tn == 0?
			if tn == 0
				obj.finished = true;
			end

			%TODO: Check if finished already true (could be true if
			%remainder == 0), ie. td = 0
			%
			% Check for last element
			[last_ind, last_cap] = obj.getlastfoster(tn, td, 2);
			if ~isempty(last_ind)
				obj.circ.add(last_ind);
				obj.circ.add(last_cap);

				obj.finished = true;
			end
			ce = obj.getlastcauer(tn, td);
			if ~isempty(ce)
				obj.circ.add(ce);
				obj.finished = true;
			end

		end


		function tf = cauer1(obj) %=================== cauer1() ================

			tf = true;

			% Check realizability criteria
			[formats, fm] = obj.realizable('DetailedForm', 'Cauer1');
			if ~any(formats == "Cauer1")
				
				% Try flipping poly
				obj.is_admit = ~obj.is_admit;
				temp = obj.num;
				obj.num = obj.den;
				obj.den = temp;
				[formats, fm] = obj.realizable('DetailedForm', 'Cauer1');
				
				if ~any(formats == "Cauer1")
					tf = false;
					obj.msg = addTo(obj.msg, strcat("Cannot synthesize form 'Cauer1' (", fm , ")"));
					return;
				else
					obj.msg = addTo(obj.msg, "To realize as Cauer1, function was inverted.");
				end
			end

			% Note: Admittance chcek is not done here because Y and Z are
			% processed the same way - it's not until the output 'k' is found
			% that Z vs Y manifest differently, hence the later check

			% Perform Cauer II-form Synthesis
			[k, tn, td] = cauer1el(obj.num, obj.den);

			% Create circuit element from output of Cauer-II
			if obj.is_admit % Is an admittance

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
			obj.num = tn;
			obj.den = td;

			% Check for remainder == 0		TODO: Also check for tn == 0?
			if td == 0
				obj.finished = true;
			end

			%TODO: Check if finished already true (could be true if
			%remainder == 0), ie. td = 0
			%
			% Check for last element
			last_elem = obj.getlastcauer(tn, td);
			if ~isempty(last_elem)
				obj.circ.add(last_elem);

				obj.finished = true;
			end

			% Toggle if in admittance mode
			obj.is_admit = ~obj.is_admit;

		end %======================== END cauer1() ========================

		function tf = cauer2(obj) %============ cauer2() =======================

			tf = true;

			% Check realizability criteria
			[formats, fm] = obj.realizable('DetailedForm', 'Cauer2');
			if ~any(formats == "Cauer2")
				
				% Try flipping poly
				obj.is_admit = ~obj.is_admit;
				temp = obj.num;
				obj.num = obj.den;
				obj.den = temp;
				[formats, fm] = obj.realizable('DetailedForm', 'Cauer2');
				
				if ~any(formats == "Cauer1")
					tf = false;
					obj.msg = addTo(obj.msg, strcat("Cannot synthesize form 'Cauer2' (", fm , ")"));
					return;
				else
					obj.msg = addTo(obj.msg, "To realize as Cauer2, function was inverted.");
				end
				
			end
			
			

			% Note: Admittance chcek is not done here because Y and Z are
			% processed the same way - it's not until the output 'k' is found
			% that Z vs Y manifest differently, hence the later check

			% Perform Cauer I-form Synthesis
			[k, tn, td] = cauer2el(obj.num, obj.den);

			% Create circuit element from output of Cauer-I
			if obj.is_admit % Is an admittance

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
			obj.num = tn;
			obj.den = td;

			% Check for remainder == 0		TODO: Also check for tn == 0?
			if td == 0
				obj.finished = true;
			end

			% Check for last element
			last_elem = obj.getlastcauer(tn, td);
			if ~isempty(last_elem)
				obj.circ.add(last_elem);

				obj.finished = true;
			end

			% Toggle if in admittance mode
			obj.is_admit = ~obj.is_admit;

		end %================== END cauer2() ==============================

		function [ind, cap] = getlastfoster(obj, tn, td, form) %== getlastfoster =

			if form ~= 1 && form ~= 2
				error("Argument 'form' must be either 1 or 2.");
			end

			% Get K-value and position of 's' variable
			if iselement(tn, td, 'Format', 'Foster') % Check if in numerator

				scale_fact = td(end);
				nv = tn(end-1)/scale_fact;
				dv = td(end-2)/scale_fact/nv;

			else % Else, exit
				ind = [];
				cap = [];
				return;
			end

			if form == 1
				ind = CircElement(nv, "H");
				cap = CircElement(dv, "F");

				ind.nodes(1) = obj.current_node;
				cap.nodes(1) = obj.current_node;

				% Increment Node
				obj.current_node = strcat("n", num2str(obj.node_iterator));
				obj.node_iterator = obj.node_iterator + 1;

				ind.nodes(2) = obj.current_node;
				cap.nodes(2) = obj.current_node;

				% Mark end node
				obj.output_node = ind.nodes(2);

			else
				ind = CircElement(dv, "H");
				cap = CircElement(nv, "F");

				ind.nodes(1) = obj.current_node;

				% Set Ind node 2, cap node 1
				ind.nodes(2) = strcat("n", num2str(obj.node_iterator));
				cap.nodes(1) = ind.nodes(2);
				obj.node_iterator = obj.node_iterator + 1;

				cap.nodes(2) = "GND";

				% Mark end node
				obj.output_node = obj.current_node;
			end

		end %================== END getlastfoster() ======================

		function ce = getlastcauer(obj, tn, td) %== getlastcauer =

			% Get K-value and position of 's' variable
			if iselement(td, tn, 'Position', "NUM", 'Format', 'Cauer') % Check if in numerator
				in_num = true;
				k_end = td(end-1)/tn(end);
			elseif iselement(td, tn, 'Position', "DEN", 'Format', 'Cauer') % CHeck if in denom.
				in_num = false;
				k_end = td(end)/tn(end-1);
			else % Else, exit
				ce = [];
				return;
			end

			% Create circuit element from output of Cauer-II
			if obj.is_admit % Is an admittance

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

		end %================== END getlastcauer() ======================

		function tf = generate(obj, varargin)

			tf = true;

			%================= Parse Function Inputs ===================

			expectedRoutines = {'Automatic', 'Cauer1', 'Cauer2', 'Foster1', 'Foster2', 'Richard'};

			p = inputParser;
			p.addRequired('Routine', @(x) any(validatestring(x,expectedRoutines))   );
			p.addParameter('MaxEval', 20, @(x) x > 0);
			p.addParameter('Simplification', 0, @(x) x >= 0); %TODO: Implement
			p.addParameter('f_scale', 1, @(x) x > 0);
			p.addParameter('Z0_scale', 1, @(x) x > 0);

			p.parse(varargin{:});

			routine = string(p.Results.Routine);

			maxEval = p.Results.MaxEval;
			synth_f_scale = p.Results.f_scale;
			synth_Z0_scale = p.Results.Z0_scale;

			% Run chosen synthesis method until entire circuit is extracted
			count = 0;
			while ~obj.finished % Check if completely extracted

				% Call appropriate synthesis function
				switch routine
					case "Cauer1"
						if ~obj.cauer1()
							tf = false;
							return
						end
					case "Cauer2"
						if ~obj.cauer2()
							tf = false;
							return
						end
					case "Foster1"
						if ~obj.foster1()
							tf = false;
							return
						end
					case "Foster2"
						if ~obj.foster2()
							tf = false;
							return
						end
					case "Richard"
						
						if length(obj.num) == length(obj.den)
							if ~obj.richardStepZ()
								tf = false;
								return;
							end
						else
							if ~obj.richardStub()
								tf = false;
								return;
							end
						end
					otherwise
						tf = false;
						error("Unexpected value for routine");
						return;
				end

				% Increment counter
				count = count +1;
				if  count > maxEval
					tf = false;
					error("Maximum number of synthesis actions exceeded");
				end

			end

			% Scale circuit
			obj.scaleComponents(synth_f_scale, synth_Z0_scale)


		end %==================== END generate() ==========================

		% function genCauer1(obj, p) %========== genCauer1() ================
		%
		% 	maxEval = p.Results.MaxEval;
		% 	synth_f_scale = p.Results.f_scale;
		% 	synth_Z0_scale = p.Results.Z0_scale;
		%
		% 	% Run cauer synthesis until entire circuit is extracted
		% 	count = 0;
		% 	while ~obj.finished % Check if completely extracted
		%
		% 		% Rerun Cauer-1 algorithm
		% 		obj.cauer1();
		%
		% 		% Increment counter
		% 		count = count +1;
		% 		if  count > maxEval
		% 			error("Maximum number of Cauer executions exceeded");
		% 		end
		% 	end
		%
		% 	% Scale circuit
		% 	obj.scaleComponents(synth_f_scale, synth_Z0_scale)
		%
		% end %============================ END genCauer1() =================
		%
		% function genCauer2(obj, p) %============= genCauer2() =============
		%
		% 	maxEval = p.Results.MaxEval;
		% 	synth_f_scale = p.Results.f_scale;
		% 	synth_Z0_scale = p.Results.Z0_scale;
		%
		% 	% Run cauer synthesis until entire circuit is extracted
		% 	count = 0;
		% 	while ~obj.finished % Check if completely extracted
		%
		% 		% Rerun Cauer-1 algorithm
		% 		obj.cauer2();
		%
		% 		% Increment counter
		% 		count = count +1;
		% 		if  count > maxEval
		% 			error("Maximum number of Cauer executions exceeded");
		% 		end
		% 	end
		%
		% 	% Scale circuit
		% 	obj.scaleComponents(synth_f_scale, synth_Z0_scale)
		%
		% end %=================== END genCauer2() ==========================
		%
		% function genFoster1(obj, p) %================== genFoster1() ======
		%
		% 	maxEval = p.Results.MaxEval;
		% 	synth_f_scale = p.Results.f_scale;
		% 	synth_Z0_scale = p.Results.Z0_scale;
		%
		% 	% Run cauer synthesis until entire circuit is extracted
		% 	count = 0;
		% 	while ~obj.finished % Check if completely extracted
		%
		% 		% Rerun Cauer-1 algorithm
		% 		obj.foster1();
		%
		% 		% Increment counter
		% 		count = count +1;
		% 		if  count > maxEval
		% 			error("Maximum number of Cauer executions exceeded");
		% 		end
		% 	end
		%
		% 	% Scale circuit
		% 	obj.scaleComponents(synth_f_scale, synth_Z0_scale)
		%
		% end %======================= genFoster2() =========================
		%
		% function genFoster2(obj, p) %================= genFoster2() =======
		%
		% 	maxEval = p.Results.MaxEval;
		% 	synth_f_scale = p.Results.f_scale;
		% 	synth_Z0_scale = p.Results.Z0_scale;
		%
		% 	% Run cauer synthesis until entire circuit is extracted
		% 	count = 0;
		% 	while ~obj.finished % Check if completely extracted
		%
		% 		% Rerun Cauer-1 algorithm
		% 		obj.foster2();
		%
		% 		% Increment counter
		% 		count = count +1;
		% 		if  count > maxEval
		% 			error("Maximum number of Cauer executions exceeded");
		% 		end
		% 	end
		%
		% 	% Scale circuit
		% 	obj.scaleComponents(synth_f_scale, synth_Z0_scale)
		%
		% end %========================== END genFoster2() ==================

		function reset(obj)

			obj.num = obj.num_orig;
			obj.den = obj.den_orig;

			obj.circ = Netlist([]);
			obj.finished = false;

			obj.is_admit = false;
			obj.node_iterator = 1;
			obj.current_node = "IN";
			obj.input_node = obj.current_node;
			obj.output_node = "?";

			obj.msg = [""];


		end

		function scaleComponents(obj, synth_f_scale, synth_Z0_scale)

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

	end

end
