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

			obj.msg = [""];

		end

		function forms = realizable(obj)

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

			%=============== Evaluate Network Realizability ===============

			% Evaluate Foster Realizability
			if lpd
				forms = addTo(forms, "Foster1");
				forms = addTo(forms, "Foster2");
			end

			% Cauer I-form
			if lpd && np.order() > dp.order()
				forms = addTo(forms, "Cauer1");
			end

			% Cauer II-form
			if lpd && rem(np.order(), 2) == 0 && rem(dp.order(), 2) == 1
				forms = addTo(forms, "Cauer2");
			end



		end

		function tf = foster1(obj)

			tf = true;

			% Check realizability criteria
			formats = obj.realizable();
			if ~any(formats == "Foster1")
				tf = false;
				msg = addTo(msg, "Cannot synthesize form 'Foster1' from current polynomial.")
				return;
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
				Z_num = td;
				Z_den = tn;
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
			formats = obj.realizable();
			if ~any(formats == "Foster2")
				tf = false;
				msg = addTo(msg, "Cannot synthesize form 'Foster2' from current polynomial.")
				return;
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
			formats = obj.realizable();
			if ~any(formats == "Cauer1")
				tf = false;
				msg = addTo(msg, "Cannot synthesize form 'Cauer1' from current polynomial.")
				return;
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
			formats = obj.realizable();
			if ~any(formats == "Cauer2")
				tf = false;
				msg = addTo(msg, "Cannot synthesize form 'Cauer2' from current polynomial.")
				return;
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

			expectedRoutines = {'Automatic', 'Cauer1', 'Cauer2', 'Foster1', 'Foster2'};

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
						if ~obj.cauer1();
							tf = false;
							return
						end
					case "Cauer2"
						if ~obj.cauer2();
							tf = false;
							return
						end
					case "Foster1"
						if ~obj.foster1();
							tf = false;
							return
						end
					case "Foster2"
						if ~obj.foster2();
							tf = false;
							return
						end
					otherwise
						error("Unexpected value for routine");
						tf = false;
						return;
				end

				% Increment counter
				count = count +1;
				if  count > maxEval
					error("Maximum number of synthesis actions exceeded");
					tf = false;
				end

			end

			% Scale circuit
			obj.scaleComponents(synth_f_scale, synth_Z0_scale)


		end %==================== END generate() ==========================

		function genCauer1(obj, p) %========== genCauer1() ================

			maxEval = p.Results.MaxEval;
			synth_f_scale = p.Results.f_scale;
			synth_Z0_scale = p.Results.Z0_scale;

			% Run cauer synthesis until entire circuit is extracted
			count = 0;
			while ~obj.finished % Check if completely extracted

				% Rerun Cauer-1 algorithm
				obj.cauer1();

				% Increment counter
				count = count +1;
				if  count > maxEval
					error("Maximum number of Cauer executions exceeded");
				end
			end

			% Scale circuit
			obj.scaleComponents(synth_f_scale, synth_Z0_scale)

		end %============================ END genCauer1() =================

		function genCauer2(obj, p) %============= genCauer2() =============

			maxEval = p.Results.MaxEval;
			synth_f_scale = p.Results.f_scale;
			synth_Z0_scale = p.Results.Z0_scale;

			% Run cauer synthesis until entire circuit is extracted
			count = 0;
			while ~obj.finished % Check if completely extracted

				% Rerun Cauer-1 algorithm
				obj.cauer2();

				% Increment counter
				count = count +1;
				if  count > maxEval
					error("Maximum number of Cauer executions exceeded");
				end
			end

			% Scale circuit
			obj.scaleComponents(synth_f_scale, synth_Z0_scale)

		end %=================== END genCauer2() ==========================

		function genFoster1(obj, p) %================== genFoster1() ======

			maxEval = p.Results.MaxEval;
			synth_f_scale = p.Results.f_scale;
			synth_Z0_scale = p.Results.Z0_scale;

			% Run cauer synthesis until entire circuit is extracted
			count = 0;
			while ~obj.finished % Check if completely extracted

				% Rerun Cauer-1 algorithm
				obj.foster1();

				% Increment counter
				count = count +1;
				if  count > maxEval
					error("Maximum number of Cauer executions exceeded");
				end
			end

			% Scale circuit
			obj.scaleComponents(synth_f_scale, synth_Z0_scale)

		end %======================= genFoster2() =========================

		function genFoster2(obj, p) %================= genFoster2() =======

			maxEval = p.Results.MaxEval;
			synth_f_scale = p.Results.f_scale;
			synth_Z0_scale = p.Results.Z0_scale;

			% Run cauer synthesis until entire circuit is extracted
			count = 0;
			while ~obj.finished % Check if completely extracted

				% Rerun Cauer-1 algorithm
				obj.foster2();

				% Increment counter
				count = count +1;
				if  count > maxEval
					error("Maximum number of Cauer executions exceeded");
				end
			end

			% Scale circuit
			obj.scaleComponents(synth_f_scale, synth_Z0_scale)

		end %========================== END genFoster2() ==================

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
