classdef Network < handle
	
	properties 
		
		stages
		
		weights
		objfuncs
		
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