MultiStageclassdef MultiStage < handle
% MultiStage Model a MultiStage for Simplified Real Frequency Technique (SRFT)
%	Models a MultiStage for using SRFT.
%
% MultiStage Properties:
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

		ZL
		Z0
		%ZG? TODO: Add ZG?
	end

	methods

		function obj = MultiStage(k) %========== Initializer =================
			obj.stages = [];
			for i=1:k+1
				obj.stages = addTo(obj.stages, Stage());
			end

			obj.showErrors = false;

			obj.null_stage = Stage();


		end %======================= End Initializer ======================

		function forceCoef(obj, order, value)

			for s=obj.stages
				s.forceCoef(order, value);
			end

		end

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

		function setHGuess(obj, h_init)

			% For each stage...
			for s=obj.stages
				s.h_init_guess = h_init; %Update the SParam variable
			end

		end

		function setEvalFunc(obj, fnh) %================ setEvalFunc() ====
			% Set the evaluation function for every stage.

			% For each stage...
			for s=obj.stages
				s.eval_func = fnh; %Update the SParam variable
			end

		end %=============================== End setEvalFunc() ============

		function setOptOptions(obj, opt)

			% For each stage...
			for s=obj.stages
				s.opt_options = opt; %Update the optimoptions variable
			end

		end

		function setFreqs(obj, s_vec, s_raw) %====== setFreqs() =====
			% Set the raw and scaled frequencies for the MultiStage and every
			% stage.

			% Update frequency for MultiStage class
			obj.s_vec = s_vec;
			obj.freqs = imag(s_raw);

			% For each stage...
			for s=obj.stages
				s.setFreqs(s_vec, s_raw); % Update stage frequency variables
			end
			obj.null_stage.setFreqs(s_vec, s_raw);
			obj.initNullStage();

			% Update MultiStage-wide variables
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
			% MultiStage.

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

			kr = k_ready;

		end %============================= End numRead() ==================

		function plotE(obj, f_scale, figNo)

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
			subplot(1,2,1);
			hold off;
			legend_array = [];
			for k = 1:k_ready
				plot(obj.freqs./f_scale, abs(flatten(lin2dB(obj.getStg(k).e(2,1,:))))./2);
				hold on;
				legend_array = addTo(legend_array, strcat("Stage ", num2str(k)));
			end
			forceZeroY();

			% Prepare axes
			title("Equalizer S_{21} by Stage");
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

			subplot(1,2,2);
			hold off;
			legend_array = [];
			for k = 1:k_ready
				plot(obj.freqs./f_scale, abs(flatten(lin2dB(obj.getStg(k).S(2,1,:))))./2);
				hold on;
				legend_array = addTo(legend_array, strcat("Stage ", num2str(k)));
			end

			% Prepare axes
			title("Equalizer $\hat{S}_{21}$ by Stage",'Interpreter','latex');
			ylabel("Gain (dB)");
			legend(legend_array);
			xlabel(strcat("Frequency (", ustr, ")"));
			forceZeroY();
			grid on;


		end

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
			subplot(1,3,1);
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
			title("MultiStage Gain by Stage");
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
			forceZeroY();
			grid on;

			subplot(1,3,2);
			hold off;
			legend_array = [];
			for k = 1:k_ready
				plot(obj.freqs./f_scale, lin2dB(obj.getStg(k).gain_t)./2);
				hold on;
				if k ~= 1
					legend_array = addTo(legend_array, strcat("Target Gain: Stages 1-", num2str(k)));
				else
					legend_array = addTo(legend_array, strcat("Target Gain: Stage 1"));
				end
			end

			% Prepare axes
			title("Target Gain by Stage");
			ylabel("Gain (dB)");
			legend(legend_array);
			xlabel(strcat("Frequency (", ustr, ")"));
			forceZeroY();
			grid on;

			subplot(1,3,3);
			hold off;
			legend_array = [];
			for k = 1:k_ready
				plot(obj.freqs./f_scale, obj.getStg(k).vswr_in_opt);
				hold on;
				if k ~= 1
					legend_array = addTo(legend_array, strcat("Target Gain: Stages 1-", num2str(k)));
				else
					legend_array = addTo(legend_array, strcat("Target Gain: Stage 1"));
				end
			end

			% Prepare axes
			title("Input VSWR Seen During Optimization of ea. Stage");
			ylabel("VSWR");
			legend(legend_array);
			xlabel(strcat("Frequency (", ustr, ")"));
			forceZeroY();
			grid on;

		end %============================ End plotGain() ==================

		function erVal = manualOpt(obj, k, h_vec)

			optimizer_function = @(h, s_data) default_opt(h, obj, k);

			% Run Optimizer for Stage k
			erVal = default_opt(h_vec, obj, k);

			% Perform Stage-k computations
			obj.getStg(k).compute_fsimple(h_vec);
			obj.compute_rcsv(k);

		end

		function optimize(obj, k, showResults)

			% Check for optional argument
			if ~exist('showResults','var')
				showResults = 'warnings';
			end

			% Ensure acceptable argument value provieded
			if ~strcmp(showResults, 'none') && ~strcmp(showResults, 'simple') && ~strcmp(showResults, 'detailed') && ~strcmp(showResults, 'warnings')
				showResults = 'warnings';
			end

			optimizer_function = @(h, s_data) default_opt(h, obj, k);

			% Run Optimizer for Stage k
			tic; % Start timer
			[h_opt,resnorm,residual,exitflag,obj.getStg(k).optim_out] = lsqcurvefit(optimizer_function, obj.getStg(k).h_init_guess, obj.s_vec, [0], obj.getStg(k).lower_bounds, obj.getStg(k).upper_bounds, obj.getStg(k).opt_options); % Run optimizer
			obj.getStg(k).optim_out.optTime = toc; % End timer

			% Save additional optimizer outputs
			obj.getStg(k).optim_out.optResidual = residual;
			obj.getStg(k).optim_out.optResNorm = resnorm;
			obj.getStg(k).optim_out.exitflag = exitflag;

			% Perform Stage-k computations
			obj.getStg(k).compute_fsimple(h_opt);
			obj.compute_rcsv();

			% Print warnings
			if strcmp(showResults, 'warnings') || strcmp(showResults, 'simple') || strcmp(showResults, 'detailed')
				if exitflag == 0
					warning(strcat("[Stage ", num2str(k), "] Optimizer Exit Status 0: Maximum Number of Iterations Exceeded."));
				elseif exitflag == -1
					warning(strcat("[Stage ", num2str(k), "] Optimizer Exit Status -1: Plot or output function stopped solver."));
				elseif exitflag == -2
					warning(strcat("[Stage ", num2str(k), "] Optimizer Exit Status -2: Problem is infeasible - inconsistent bounds."));
				end
			end

			% Print simple output
			if strcmp(showResults, 'simple') || strcmp(showResults, 'detailed')
				displ(newline, "Stage ", k, " Polynomials:      (", obj.getStg(k).optim_out.optTime, " sec)" , newline, obj.getStg(k).polystr());
			end

			% Print detailed output
			if strcmp(showResults, 'detailed')
				disp(obj.getStg(k).optim_out)
			end

		end

		function optimSummary(obj)

			k_ready = obj.numReady();

			for k = 1:k_ready
				displ("Stage ", k, " Optimization Summary:");
				displ("    ", "Target Gain: ", obj.getStg(k).gain_t);
				displ("    ", "Maximum Gain: ", obj.getStg(k).gain_m);
				displ("    ", "Gain: ", obj.getStg(k).gain);
				displ("    ", "Iterations: ", obj.getStg(k).optim_out.iterations);
				displ("    ", "Exit FLag: ", obj.getStg(k).optim_out.exitflag);
				displ("    ", "Residual: ", obj.getStg(k).optim_out.optResidual);
				displ("    ", "Residual Norm: ", obj.getStg(k).optim_out.optResNorm);
				displ(newline);

			end

		end

		function compute_rcsv(obj, k_ready_ovrd) %============ compute_rcsv() ===========
			% Recursively calculates the S-parameters, gain, and VSWR of
			% each stage.

			% Determine number of stages that are ready for recursive
			% computation.
			k_ready = obj.numReady();

			% Check for optional argument
			if exist('k_ready_ovrd','var')
				k_ready = k_ready_ovrd;
			end

			a = [];
			b = [];
			c = [];

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

				if k ~= length(obj.stages) %For all but last stage...
					stgk.gain(:) = flatten(stgk_.gain(:)) .* ( flatten(abs(stgk.e(2,1,:))).^2 .* flatten(abs(stgk.S(2,1,:))).^2 ) ./ ( abs( 1- flatten(stgk.e(1,1,:)) .* flatten(stgk.SG(:)) ).^2 .* abs( 1 - flatten(stgk.eh(2,2,:)) .* flatten(stgk.S(1,1,:)) ).^2 );
				else % Special case for last stage (because no active device present)

					rho_L = flatten((obj.ZL - obj.Z0)./(obj.ZL + obj.Z0));

					stgk.gain(:) = flatten(stgk_.gain(:)) .* ( flatten(abs(stgk.e(2,1,:))).^2 .* ( 1 - abs(rho_L).^2 ) ./ ( abs( 1- flatten(stgk.e(1,1,:)) .* flatten(stgk.SG(:)) ).^2 .* abs( 1 - flatten(stgk.eh(2,2,:)) .* rho_L.^2 )));

				end

				gain_m_frac1 = abs(flatten(stgk_.S(2,1,:))).^2 ./ ( abs(1 - flatten(abs(stgk_.S(1,1,:))).^2) .* abs( 1 - abs( flatten(stgk_.S(2,2,:)) ).^2 ) );
				gain_m_frac2_inv = abs(1 - flatten(stgk_.S(1,2,:)) .* flatten(stgk_.S(2,1,:)) .* conj(flatten(stgk_.S(1,1,:))) .* conj(flatten(stgk_.S(2,2,:))) ./ ( abs(1 - abs(flatten(stgk_.S(1,1,:))).^2) .* abs( 1 - abs( flatten(stgk_.S(2,2,:))).^2 ) )).^2;
				stgk_.gain_m(:) = gain_m_frac1 ./ gain_m_frac2_inv; % broken into two parts for readability

				if k ~= length(obj.stages) %For all but last stage...

					product = 1;
					for sk = 1:k-1
						product = product .* obj.getStg(sk).gain_m;
					end

					a = addTo(a, smush(flatten(stgk_.gain_m(:))));
					b = addTo(b, smush(abs( flatten(stgk.S(2,1,:)) ).^2));
					c = addTo(c, smush(abs( flatten(stgk.S(1,1,:)) ).^2));
					stgk.gain_t(:) = min( flatten(product) .* abs( flatten(stgk.S(2,1,:)) ).^2 ./ abs( 1 - abs( flatten(stgk.S(1,1,:)) ).^2 ) );
				else % Special case for last stage (because no active device present)
					product = 1;
					for sk = 1:length(obj.stages)-1
						product = product .* obj.getStg(sk).gain_m;
					end

					stgk.gain_t(:) = min( product );
				end

% 				stgk.SL(:) = stgk.S(1,1,:);
% 				stgk.eh(1,1,:) = flatten(stgk.e(1,1,:)) + flatten(stgk.e(2,1,:)).^2 .* flatten(stgk.SL(:)) ./ ( 1 - flatten(stgk.e(2,2,:)) .* flatten(stgk.SL(:)));
%
% 				% Redefinitions
% 				%
% 				% TODO: I think the eh(1,1,:) and SL calculations might be
% 				% wrong - they might need to chain backwards (ie. calc.
% 				% SL(k), then eh(1,1)(k), then SL(k-)... eh(1,1)(1). Not
% 				% clear to me. P. 53
% 				%
%

% 				if k ~= 1
% 					stgk_.SL(:) = stgk_.S(1,1,:) + stgk_.S(1,2,:) .* stgk_.S(2,1,:) .* stgk.eh(1,1,:) ./ ( 1 - stgk_.S(2,2,:) .* stgk.eh(1,1,:) ) ;
% 					stgk_.eh(1,1,:) = flatten(stgk_.e(1,1,:)) + flatten(stgk_.e(2,1,:)).^2 .* flatten(stgk_.SL(:)) ./( 1 - flatten(stgk_.e(2,2,:)) .* flatten(stgk_.SL(:))) ;
% 				end
% 				obj.vswr_in(:) = ( 1 + flatten(abs(obj.getStg(1).eh(1,1,:))) ) ./ ( 1 - flatten(abs(obj.getStg(1).eh(1,1,:))) ); %TODO: This always uses stage 1 for calculation. Verify this is correct.
% 				obj.vswr_out(:) = (1 + abs(flatten(stgk.eh(2,2,:)))) ./ ( 1 - abs(flatten(stgk.eh(2,2,:))) );
% 				obj.vswr_in(:) = [1,2,3,4];
% 				obj.vswr_out(:) = [1,2,3,4];

				% Save VSWR to stage that used this VSWR for optimization
% 				if k == k_ready
% 					stgk.vswr_in_opt = obj.vswr_in(:);
% 					stgk.vswr_out_opt = obj.vswr_out(:);
% 				end

				% Save new values back to MultiStage
				obj.setStg(k, stgk); % Stage 'k'
				if k ~= 1
					obj.setStg(k-1, stgk_); % Stage 'k-1'
				end

			end

			% Recursively, go through each stage - Backwards
			for k = k_ready:-1:1

				% Prepare local variables for accessing and modifying
				% stage data
				stgk_ = obj.getStg(k); % Stage 'k-1'
				if k < k_ready
					stgk = obj.getStg(k+1); % Stage 'k'
				end

				% If all stages optimzied, and recursively at end
				% (load-side)
				if k_ready == length(obj.stages) && k == k_ready

					rho_L = flatten((obj.ZL - obj.Z0)./(obj.ZL + obj.Z0));

					stgk_.eh(1,1,:) = flatten(stgk_.e(1,1,:)) + flatten(stgk_.e(2,1,:)).^2 .* rho_L ./ ( 1 - flatten(stgk_.e(2,2,:)) .* rho_L );

				else % Every other case...

% 				if k == 1
% 					stgkp = obj.null_stage;
% 				else
% 					stgkp = obj.getStg(k-1); % Stage 'k-1'
% 				end

					if k == k_ready
						stgk_.SL(:) = stgk_.S(1,1,:);
					else
						stgk_.SL(:) = stgk_.S(1,1,:) + stgk_.S(1,2,:) .* stgk_.S(2,1,:) .* stgk.eh(1,1,:) ./ ( 1 - stgk_.S(2,2,:) .* stgk.eh(1,1,:) ) ;
					end

					stgk_.eh(1,1,:) = flatten(stgk_.e(1,1,:)) + flatten(stgk_.e(2,1,:)).^2 .* flatten(stgk_.SL(:)) ./ ( 1 - flatten(stgk_.e(2,2,:)) .* flatten(stgk_.SL(:)));

				end

				% Redefinitions
				%
				% TODO: I think the eh(1,1,:) and SL calculations might be
				% wrong - they might need to chain backwards (ie. calc.
				% SL(k), then eh(1,1)(k), then SL(k-)... eh(1,1)(1). Not
				% clear to me. P. 53
				%


% 				if k ~= 1
% 					stgk_.SL(:) = stgk_.S(1,1,:) + stgk_.S(1,2,:) .* stgk_.S(2,1,:) .* stgk.eh(1,1,:) ./ ( 1 - stgk_.S(2,2,:) .* stgk.eh(1,1,:) ) ;
% 					stgk_.eh(1,1,:) = flatten(stgk_.e(1,1,:)) + flatten(stgk_.e(2,1,:)).^2 .* flatten(stgk_.SL(:)) ./( 1 - flatten(stgk_.e(2,2,:)) .* flatten(stgk_.SL(:))) ;
% 				end
% 				obj.vswr_in(:) = ( 1 + flatten(abs(obj.getStg(1).eh(1,1,:))) ) ./ ( 1 - flatten(abs(obj.getStg(1).eh(1,1,:))) );
% 				obj.vswr_out(:) = (1 + abs(flatten(stgk.eh(2,2,:)))) ./ ( 1 - abs(flatten(stgk.eh(2,2,:))) );

				% Save VSWR to stage that used this VSWR for optimization
% 				if k == k_ready
% 					stgk.vswr_in_opt = obj.vswr_in(:);
% 					stgk.vswr_out_opt = obj.vswr_out(:);
% 				end

				% Save new values back to MultiStage
				obj.setStg(k, stgk_); % Stage 'k'
				if k ~= k_ready
					obj.setStg(k+1, stgk); % Stage 'k+1'
				end

			end

			% TODO: Computing VSWR_out at anything other than last stage
			% might not be valid. I'm computing it to prevent errors. Is
			% there a better solution?
			obj.vswr_in(:) = ( 1 + flatten(abs(obj.getStg(1).eh(1,1,:))) ) ./ ( 1 - flatten(abs(obj.getStg(1).eh(1,1,:))) );
			obj.vswr_out(:) = ( 1 + flatten(abs(obj.getStg(k_ready).eh(2,2,:))) ) ./ ( 1 - flatten(abs(obj.getStg(k_ready).eh(2,2,:))) );
			obj.getStg(k_ready).vswr_in_opt = obj.vswr_in(:);
			obj.getStg(k_ready).vswr_out_opt = obj.vswr_out(:);


		end %=============================== End compute_rcsv() ===========
	end

end
