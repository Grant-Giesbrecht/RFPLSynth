classdef Network < handle
% NETWORK Model a network for Simplified Real Frequency Technique (SRFT)
%	Models a network for using SRFT.
%
% NETWORK Properties:
%	stages - List of Stage items
%	objfuncs - TODO: Unused
%	s_vec - Vector of scaled frequencies
%	freqs - Vector of not-scaled freqeuncies. Imaginary component must be
%	present in the S-parameter objects of the various stages.
%	vswr_in - Input VSWR
%	vswr_out - Output VSWR
%	showErrors - Allow or prevent error messages from displaying to console
%	null_stage - Stage object for properly handing first stage
%	stage_end - TODO: Unused
%
%
%
	
	properties 
		
		stages
		
		objfuncs
		
		s_vec
		freqs
		
		vswr_in
		vswr_out
		vswr_in_t
		vswr_out_t
				
		showErrors
		
		null_stage
		stage_end
	end
	
	methods
		
		function obj = Network(k) %========== Initializer =================
			obj.stages = [];
			for i=1:k+1
				obj.stages = addTo(obj.stages, Stage());
			end
						
			obj.showErrors = false;
			
			obj.null_stage = Stage();
			
		end %======================= End Initializer ======================
		
		function initNullStage(obj)
			% Initialize 'null_stage' with the correct values for
			% calculating the first stage's parameters.
			
			obj.null_stage.S(1,1,:) = 0;
			obj.null_stage.S(2,1,:) = 1;
			obj.null_stage.S(1,2,:) = 1;
			obj.null_stage.S(2,2,:) = 0;
			
			obj.null_stage.eh(2,2,:) = 0;
			
			obj.null_stage.gain(:) = 1;
			obj.null_stage.gain_m(:) = 1;
			
		end
		
		function reset(obj) %===================== reset() ================
			% Reset the 'recompute' flags for all stages.
			
			% For each stage...
			for s=obj.stages
				s.recompute = true; % Mark as out of date
			end
			
		end %================================ End reset() =================
		
		function setSPQ(obj, Sparams) %=============== setSPQ() ===========
			% Set the sparameters object for the transistor in every stage
			
			% For each stage...
			for s=obj.stages
				s.SPQ = Sparams; %Update the SParam variable
			end
			obj.null_stage.SPQ = Sparams;
			
		end %=============================== End setSPQ() =================
		
		function setEvalFunc(obj, fnh) %================ setEvalFunc() ====
			% Set the evaluation function for every stage.
			
			% For each stage...
			for s=obj.stages
				s.eval_func = fnh; %Update the SParam variable
			end
			
		end %=============================== End setEvalFunc() ============
		
		function setFreqs(obj, s_vec, s_raw) %====== setFreqs() =====
			% Set the raw and scaled frequencies for the network and every
			% stage.
			
			% Update frequency for Network class
			obj.s_vec = s_vec;
			obj.freqs = imag(s_raw);
			
			% For each stage...
			for s=obj.stages
				s.setFreqs(s_vec, s_raw); % Update stage frequency variables
			end
			obj.null_stage.setFreqs(s_vec, s_raw);
			obj.initNullStage();
			
			% Update network-wide variables
			m = length(obj.s_vec);
			obj.vswr_in = setLength(obj.vswr_in, m);
			obj.vswr_out = setLength(obj.vswr_out, m);
			obj.vswr_in_t = setLength(obj.vswr_in_t, m);
			obj.vswr_out_t = setLength(obj.vswr_out_t, m);
			
			
			
		end %============================= End setFreqs() ==============
		
		function setStg(obj, k, stg) %=========== setStg() ================
			% Sets the k-th order stage object
			
			obj.stages(k) = stg;
			
		end %============================= End setStg() ===================
		
		function idx = fscidx(obj, s) %=============== fidx() ====================
			% Gets the index corresponding to the scaled frequency 's'
			
			% Find frequency
			idx = find(obj.s_vec == (s), 1);
			if isempty(idx)
				idx = [];
				if obj.showErrors
					displ("Failed to find frequency ", imag(s) ," Hz");
				end
				return;
			end
			
		end %========================= End fidx() =========================
		
		function tf = hasFreq(obj, k, s) %=============== hasFreq() ============
			% Checks if the non-scaled frequency 's' is present in the
			% network.
			
			% Get stage
			stg = obj.stages(k);
			
			% Look for frequency
			idx = find(stg.freqs == imag(s), 1);
			tf = ~isempty(idx);
			
		end %================================= End hasFreq() ==============
			
		function stg = getStg(obj, k) %=========== getStg() ===============
			% Gets the k-th order stage object
			
			stg = obj.stages(k);
			
		end %=================================== End getStg() =============
		
		function kr = numReady(obj) %============= numRead() ==============
			% Gets the number of stages that have been assigned
			% polynomials.
			
			% Determine number of stages that are ready for recursive
			% computation.
			k_ready = 0;
			for stg = obj.stages
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
			
			% Catch if s_vec not initialized
			if isempty(obj.s_vec)
				error("Cannot perform recursive computation. No frequencies given.");
			end
			
			kr = k_ready;
			
		end %============================= End numRead() ==================
		
		function plotGain(obj, f_scale, figNo) %========= plotGain() ======
			% Plots the gain of each stage. f_scale allows you to scale the
			% frequency on the x-axis, and figNo allows you pick the 
			
			if ~exist('f_scale','var')
				f_scale = 1;
			end
			
			if exist('figNo','var')
				figure(figNo);
			end
			
			% Determine number of stages that are ready for recursive
			% computation.
			k_ready = obj.numReady();
			
			% For each prepared stage, plot frequency
			hold off;
			legend_array = [];
			for k = 1:k_ready
				plot(obj.freqs./f_scale, lin2dB(obj.getStg(k).gain)./2);
				hold on;
				if k ~= 1
					legend_array = addTo(legend_array, strcat("Stages 1-", num2str(k)));
				else
					legend_array = addTo(legend_array, strcat("Stage 1"));
				end
			end
			
			% Prepare axes
			title("Network Gain by Stage");
			ylabel("Gain (dB)");
			legend(legend_array);
			if f_scale == 1e-3
				ustr = "mHz";
			elseif f_scale == 1
				ustr = "Hz";
			elseif f_scale == 1e3
				ustr = "kHz";
			elseif f_scale == 1e6
				ustr = "MHz";
			elseif f_scale == 1e9
				ustr = "GHz";
			elseif f_scale == 1e12
				ustr = "THz";
			else
				ustr = "?";
			end
			xlabel(strcat("Frequency (", ustr, ")"));
			grid on;
			
			
			
		end %============================ End plotGain() ==================
		
		function compute_rcsv(obj) %============ compute_rcsv() ===========
			% Recursively calculates the S-parameters, gain, and VSWR of
			% each stage.
			
			% Determine number of stages that are ready for recursive
			% computation.
			k_ready = obj.numReady();
			
			% Recursively, go through each stage
			for k = 1:k_ready

				%======================================================

				% Prepare local variables for accessing and modifying
				% stage data
				stgk = obj.getStg(k); % Stage 'k'
				if k == 1
					stgk_ = obj.null_stage;
				else
					stgk_ = obj.getStg(k-1); % Stage 'k-1'
				end
				
				% New definitions

				stgk.SG(:) = stgk_.S(2,2,:) + ( stgk_.S(1,2,:) .* stgk_.S(2,1,:) .* stgk_.eh(2,2,:) ) ./ ( 1 - stgk_.S(1,1,:) .* stgk_.eh(2,2,:));

				stgk.eh(2,2,:) = flatten(stgk.e(2,2,:)) + ( flatten(stgk.e(2,1,:)).^2 .* flatten(stgk.SG(:)) ) ./ ( 1 - flatten(stgk.e(1,1,:)) .* flatten(stgk.SG(:)) );

				stgk.gain(:) = flatten(stgk_.gain(:)) .* ( flatten(abs(stgk.e(2,1,:))).^2 .* flatten(abs(stgk.S(2,1,:))).^2 ) ./ ( abs( 1- flatten(stgk.e(1,1,:)) .* flatten(stgk.SG(:)) ).^2 .* abs( 1 - flatten(stgk.eh(2,2,:)) .* flatten(stgk.S(1,1,:)) ).^2 );

				gain_m_frac1 = abs(flatten(stgk_.S(2,1,:))).^2 ./ ( abs(1 - flatten(abs(stgk_.S(1,1,:))).^2) .* abs( 1 - abs( flatten(stgk_.S(2,2,:)) ).^2 ) );
				gain_m_frac2_inv = abs(1 - flatten(stgk_.S(1,2,:)) .* flatten(stgk_.S(2,1,:)) .* conj(flatten(stgk_.S(1,1,:))) .* conj(flatten(stgk_.S(2,2,:))) ./ ( abs(1 - abs(flatten(stgk_.S(1,1,:))).^2) .* abs( 1 - abs( flatten(stgk_.S(2,2,:))).^2 ) )).^2;
				stgk_.gain_m(:) = gain_m_frac1 ./ gain_m_frac2_inv; % broken into two parts for readability

				% NOTE: This should not change between iterations. It's
				% constant over freq.
				% TODO: Is there a better place to put this?
				stgk.gain_t(:) = min( flatten(stgk_.gain_m(:)) .* abs( flatten(stgk.S(2,1,:)) ).^2 ./ abs( 1 - abs( flatten(stgk.S(1,1,:)) ).^2 ) );

				stgk.SL(:) = stgk.S(1,1,:);
				stgk.eh(1,1,:) = flatten(stgk.e(1,1,:)) + flatten(stgk.e(2,1,:)).^2 .* flatten(stgk.SL(:)) ./ ( 1 - flatten(stgk.e(2,2,:)) .* flatten(stgk.SL(:)));

				% Redefinitions
				if k ~= 1
					stgk_.SL(:) = stgk_.S(1,1,:) + stgk_.S(1,2,:) .* stgk_.S(2,1,:) .* stgk.eh(1,1,:) ./ ( 1 - stgk_.S(2,2,:) .* stgk.eh(1,1,:) ) ;
					stgk_.eh(1,1,:) = flatten(stgk_.e(1,1,:)) + flatten(stgk_.e(2,1,:)).^2 .* flatten(stgk_.SL(:)) ./( 1 - flatten(stgk_.e(2,2,:)) .* flatten(stgk_.SL(:))) ;
				end
				obj.vswr_in(:) = ( 1 + flatten(abs(obj.getStg(1).eh(1,1,:))) ) ./ ( 1 - flatten(abs(obj.getStg(1).eh(1,1,:))) ); %TODO: This always uses stage 1 for calculation. Verify this is correct.


				% Save new values back to network
				obj.setStg(k, stgk); % Stage 'k'
				if k ~= 1
					obj.setStg(k-1, stgk_); % Stage 'k-1'
				end
			
			end
			
			
		end %=============================== End compute_rcsv() ===========
	end
	
end