classdef Network < handle
	
	properties 
		
		stages
		
		weights
		objfuncs
		
		s_vec
		freqs
		
		vswr_in
		vswr_out
		
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
		
		function idx = fidx(s) %=============== fidx() ====================
			
			% Find frequency
			idx = find(stg.freqs == imag(s), 1);
			if isempty(idx)
				idx = [];
				if obj.showErrors
					displ("Failed to find frequency ", imag(s) ," Hz");
				end
				return;
			end
			
		end %========================= End fidx() =========================
		
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
		
		function s_l = SG(obj, k, s) %============= SG() ==================
			
			% Get stage
			stg = obj.stages(k);
			
			
			
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
					
					% Prepare local variables for accessing and modifying
					% stage data
					stgk = obj.getStg(k); % Stage 'k'
					stgk_ = obj.getStg(k-1); % Stage 'k-1'
					si = obj.fidx(s); % 's' (ie. freq) index
					
					% New definitions
					
					stgk.SG(si) = stgk_.S(2,2,si) + ( stgk_.S(1,2,si) .* stk_.S(2,1,si) .* stk_.eh(2,2,si) ) ./ ( 1 - stk_.S(1,1,si) .* stk_.eh(2,2,si));
					
					stkg.eh(2,2,si) = stgk.e(2,2,si) + ( stgk.e(2,1,si).^2 .* stgk.SG(si) ) ./ ( 1 - stgk.e(1,1,) .* stgk.SG(si) );
					
					stgk.gain(si) = stgk_.gain(si) .* ( abs(stgk.e(2,1,si)).^2 abs(stgk.S(2,1,si)).^2 ) ./ ( abs( 1- stgk.e(1,1,si) .* stgk.SG(si) ).^2 .* abs( 1 - stgk.eh(2,2,si) .* stgk.S(1,1,si) ).^2 );
					
					gain_m_frac1 = abs(stgk_.S(2,1,si)).^2 ./ ( abs(1 - abs(stgk_.S(1,1,si)).^2) .* abs( 1 - abs( stgk_.S(2,2,si) ).^2 ) );
					gain_m_frac2_inv = abs(1 - stgk_.S(1,2,si) .* stgk_.S(2,1,si) .* conj(stgk_.S(1,1,si)) .* conj(stgk_.S(2,2,si)) ./ ( abs(1 - abs(stgk_.S(1,1,si)).^2) .* abs( 1 - abs( stgk_.S(2,2,si) ).^2 ) )).^2;
					stgk_.gain_m(si) = gain_m_frac1 ./ gain_m_frac2_inv; % broken into two parts for readability
					
					% NOTE: This should not change between iterations. It's
					% constant over freq.
					% TODO: Is there a better place to put this?
					stgk.gain_t(si) = min( stgk_.gain_m(:).* abs( stgk.S(2,1,:) ).^2 ./ abs( 1 - abs( stgk.S(1,1,:) ).^2 ) );
					
					stgk.SL(si) = stgk.S(1,1,si);
					stgk.eh(1,1,si) = stgk.e(1,1,si) + stgk.e(2,1,si).^2 .* stgk.SL(si) ./ ( 1 - stgk.e(2,2,si) .* stgk.SL(si) );
					
					% Redefinitions
					stgk_.SL(si) = stgk_.S(1,1,si) + stgk_.S(1,2,si) .* stgk_.S(2,1,si) .* stgk.eh(1,1,si) ./ ( 1 - stgk_.S(2,2,si) .* stgk.eh(1,1,si) ) ;
					stgk_.eh(1,1,si) = stgk_.e(1,1,si) + stgk_.e(2,1,si).^2 .* stgk_.SL(si) ./( 1 - stgk_.e(2,2,si) .* stgk_.SL(si) ) ;
					obj.vswr_in(si) = ( 1 + abs(obj.getStg(1).eh(1,1,si)) ) ./ ( 1 - abs(obj.getStg(1).eh(1,1,si)) ); %TODO: This always uses stage 1 for calculation. Verify this is correct.
					
					
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