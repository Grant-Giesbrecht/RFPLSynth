classdef Network < handle
	
	properties 
		
		stages
		
		weights
		objfuncs
		
		no_stg
		
		showErrors
	end
	
	methods
		
		function obj = Network(k)
			obj.stages = [];
			for i=1:k+1
				obj.stages = addTo(obj.stages, Stage());
			end
			
			obj.weights = [];
			obj.no_stg = k;
			
			obj.showErrors = false;
		end
		
		function setStg(obj, k, stg)
			
			obj.stages(k+1) = stg;
			
		end
		
		function tf = hasFreq(k, s)
			
			% Get stage
			stg = obj.stages(k);
			
			% Look for frequency
			idx = find(stg.freqs == imag(s), 1);
			tf = ~isempty(idx);
			
		end
		
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
			
			w = obj.weights(k, c);
			
		end %====================================== W() ===================
		
	end
	
end