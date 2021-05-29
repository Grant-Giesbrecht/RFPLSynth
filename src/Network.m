classdef Network < handle
	
	properties 
		
		stages
		
		weights
		objfuncs
		
		s_vec
		freqs
		
		vswr_input
		vswr_output
		
		no_stg
		
		showErrors
	end
	
	methods
		
		function obj = Network(k) %========== Initializer =================
			obj.stages = [];
			for i=1:k+1
				obj.stages = addTo(obj.stages, Stage());
			end
			
			obj.weights = [];
			obj.no_stg = k;
			
			obj.showErrors = false;
		end %======================= End Initializer ======================
		
		function reset(obj) %===================== reset() ================
			
			% For each stage...
			for s=obj.stages
				s.recompute = true; % Mark as out of date
			end
			
		end %================================ End reset() =================
		
		function setSPQ(obj, Sparams) %=============== setSPQ() ===========
			
			% For each stage...
			for s=obj.stages
				s.SPQ = Sparams; %Update the SParam variable
			end
			
		end %=============================== End setSPQ() =================
		
		function setEvalFunc(obj, fnh) %================ setEvalFunc() ====
			
			% For each stage...
			for s=obj.stages
				s.eval_func = fnh; %Update the SParam variable
			end
			
		end %=============================== End setEvalFunc() ============
		
		function updateFreqs(obj, s_vec, s_raw) %====== updateFreqs() =====
			
			% Update frequency for Network class
			obj.s_vec = s_vec;
			obj.freqs = imag(s_raw);
			
			% For each stage...
			for s=obj.stages
				s.updateFreqs(s_vec, s_raw); % Update stage frequency variables
			end
			
			% Update network-wide variables
			m = length(obj.s_vec);
			setLength(obj.vswr_in, m);
			setLength(obj.vswr_out, m);
			
		end %============================= End updateFreqs() ==============
		
		function setStg(obj, k, stg) %=========== setStg() ================
			
			obj.stages(k+1) = stg;
			
		end %============================= End setStg() ===================
		
		function tf = hasFreq(k, s) %=============== hasFreq() ============
			
			% Get stage
			stg = obj.stages(k);
			
			% Look for frequency
			idx = find(stg.freqs == imag(s), 1);
			tf = ~isempty(idx);
			
		end %================================= End hasFreq() ==============
		
		function exy = e(obj, r, c, k, s) %======== e() ===================
			
			% Get stage
			stg = obj.stages(k);
			
			% Find frequency
			idx = find(stg.freqs == imag(s), 1);
			if isempty(idx)
				exy = [];
				if obj.showErrors
					displ("Failed to find frequency ", imag(s) ," Hz");
				end
				return;
			end
			
			% Convert r, c to correct e-matrix, pick out value
			if r == 1 && c == 1
				exy = stg.e_11(idx);
			elseif r == 2 && c == 1
				exy = stg.e_21(idx);
			elseif r == 1 && c == 2
				exy = stg.e_12(idx);
			elseif r == 2 && c == 2
				exy = stg.e_22(idx);
			else
				exy = [];
				if obj.showErrors
					displ("Failed to find element e_", r, ",", c);
				end
				return
			end
		end %============================= End e() ========================
		
		function exy = S(obj, r, c, k, s) %============= S() ==============
			
			% Get stage
			stg = obj.stages(k);
			
			% Find frequency
			idx = find(stg.freqs == imag(s), 1);
			if isempty(idx)
				exy = [];
				if obj.showErrors
					displ("Failed to find frequency ", imag(s) ," Hz");
				end
				return;
			end
			
			% Convert r, c to correct e-matrix, pick out value
			exy = stg.SPQ.Parameters(r, c, idx);
		end %=============================== End S() ======================
		
		function s_l = SL(obj, k, s) %============= SL() ==================
			
			% Get stage
			stg = obj.stages(k);
			
			% Find frequency
			idx = find(stg.freqs == imag(s), 1);
			if isempty(idx)
				s_l = [];
				if obj.showErrors
					displ("Failed to find frequency ", imag(s) ," Hz");
				end
				return;
			end
			
			s_l = stg.S_L(idx);
			
		end %=============================== End SL() =====================
		
		function a = gain(obj, k, s) %============= gain() ==================
			
			% Get stage
			stg = obj.stages(k);
			
			% Find frequency
			idx = find(stg.freqs == imag(s), 1);
			if isempty(idx)
				a = [];
				if obj.showErrors
					displ("Failed to find frequency ", imag(s) ," Hz");
				end
				return;
			end
			
			a = stg.gain(idx);
			
		end %=============================== End gain() ===================
		
		function a = gain_t(obj, k, s) %============= gain_t() ============
			
			% Get stage
			stg = obj.stages(k);
			
			% Find frequency
			idx = find(stg.freqs == imag(s), 1);
			if isempty(idx)
				a = [];
				if obj.showErrors
					displ("Failed to find frequency ", imag(s) ," Hz");
				end
				return;
			end
			
			a = stg.gain_t(idx);
			
		end %=============================== End gain_t() =================
		
		function a = gain_m(obj, k, s) %============= gain_m() ============
			
			% Get stage
			stg = obj.stages(k);
			
			% Find frequency
			idx = find(stg.freqs == imag(s), 1);
			if isempty(idx)
				a = [];
				if obj.showErrors
					displ("Failed to find frequency ", imag(s) ," Hz");
				end
				return;
			end
			
			a = stg.gain_m(idx);
			
		end %=============================== End gain_m() =================
		
		function v = vswr_in(obj, s) %=========== vswr_in() ============
			
			% Find frequency
			idx = find(net.freqs == imag(s), 1);
			if isempty(idx)
				v = [];
				if obj.showErrors
					displ("Failed to find frequency ", imag(s) ," Hz");
				end
				return;
			end
			
			v = obj.vswr_input(idx);
			
		end %============================== End vswr_in() =================
		
		function v = vswr_out(obj, s) %========= vswr_out() ============
			
			% Find frequency
			idx = find(net.freqs == imag(s), 1);
			if isempty(idx)
				v = [];
				if obj.showErrors
					displ("Failed to find frequency ", imag(s) ," Hz");
				end
				return;
			end
			
			v = obj.vswr_output(idx);
			
		end %============================= End vswr_out() =================
		
		function s_l = SG(obj, k, s) %============= SG() ==================
			
			% Get stage
			stg = obj.stages(k);
			
			% Find frequency
			idx = find(stg.freqs == imag(s), 1);
			if isempty(idx)
				s_l = [];
				if obj.showErrors
					displ("Failed to find frequency ", imag(s) ," Hz");
				end
				return;
			end
			
			s_l = stg.S_G(idx);
			
		end %=============================== End SG() =====================
		
		function exy = eh(obj, r, c, k, s) %========== eh?() ===============
			
			% Get stage
			stg = obj.stages(k);
			
			% Find frequency
			idx = find(stg.freqs == imag(s), 1);
			if isempty(idx)
				exy = [];
				if obj.showErrors
					displ("Failed to find frequency ", imag(s) ," Hz");
				end
				return;
			end
			
			% Convert r, c to correct e-matrix, pick out value
			if r == 1 && c == 1
				exy = stg.eh_11(idx);
			elseif r == 2 && c == 1
				exy = stg.eh_21(idx);
			elseif r == 1 && c == 2
				exy = stg.eh_12(idx);
			elseif r == 2 && c == 2
				exy = stg.eh_22(idx);
			else
				exy = [];
				if obj.showErrors
					displ("Failed to find element e_", r, ",", c);
				end
				return
			end
		end %========================= End eh?() ==========================
		
		function stg = getStg(obj, k) %=========== getStg() ===============
			
			stg = obj.stages(k);
			
		end %=================================== End getStg() =============
		
		function w = W(obj, k, c) %================ W() ===================
			
			% Get stage
			stg = obj.stages(k);
			
			w = stg.weights(c);
			
% 			w = obj.weights(k, c);
			
		end %====================================== W() ===================
		
		function compute_rcsv(obj) %============ compute_rcsv() ===========
			
			% Determine number of stages that are ready for recursive
			% computation.
			k_ready = 0;
			for stg = 1:obj.stages
				if ~stg.recompute
					k_ready = k_ready + 1;
				else
					break;
				end
			end
			
			% Catch if no stages ready
			if k_ready == 0
				error("Cannot perform recursive computation. No stages have been prepared.");
			end
			
			% Perform recursive computation (over stage No.) for each frequency point
			for s = obj.s_vec
				
				% Recursively, go through each stage
				for k = 1:length(obj.stages)
					
					%======================================================
					
					% New definitions
					
					obj.SG(k, s) = obj.S(2,2,k-1,s) + (obj.S(1,2,k-1,s) .* obj.S(2,1,k-1,s) .* obj.eh(2,2,k-1,s)) ./ ( 1 - obj.S(1,1,k-1,s) .* obj.eh(2,2,k-1,s) );
					
					
					obj.eh(2,2,k,s) = ?;
					obj.gain(k, s) = ?;
					obj.gain_m(k,s) = ?;
					obj.gain_t(k,s) = ?;
					obj.SL(k,s) = ?;
					obj.eh(1,1,k,s) = ?;
					
					% Redefinitions
					obj.SL(k-1,s) = ?;
					obj.eh(1,1,k-1,s) = ?;
					obj.vswr_in(s) = ?;
					
					
					%======================================================
					
					if k == k_ready % If last stage, S_L gets a special definition
						obj.SL(k, s) = obj.S(1, 1, k);
					else % Standard S_L rule 
						obj.SL(k-1, s) = obj.S(1,1,k,s) + ( obj.S(1,2,k,s) .* obj.S(2,1,k,s) .* obj.eh(1,1,k+1,s)) ./ ( 1 - obj.S(2,2,k,s) .* obj.eh() );
					end
					
					
					obj.eh(1, 1, k, s) = 

					obj.e(1, 1, k, s) = 

					S_L

					eh_11_2 = e_11_2

				end
			
			end
			
			% Compute eh_xy
			% TODO: This is stage-recursive and should be moved to being a
			% function in 'Network'.
			obj.eh_11 = obj.e11 + obj.e21.^2 .* obj.S_L ./ (1 - obj.e22 .* obj.S_L); %TODO: Is this fully general?	(from p.51)
			% TODO: eh_11 and others update for each stage as other stages
			% are added because they modify S_L (and S_G if not starting at
			% k=1).
			obj.eh_22 = obj.e22 + obj.e21.^2 .* obj.S_G ./ (1 - obj.e11 .* obj.S_G); %TODO: Is this fully general? (from p.53)
			
			% Compute VSWR_in
			obj.vswr_in = 1 + abs(eh_11)
			
		end %=============================== End compute_rcsv() ===========
	end
	
end