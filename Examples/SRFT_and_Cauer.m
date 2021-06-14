%
%
%
%

%=========================================================================%
%							SRFT Algorithm								  %
%=========================================================================%

% SParam_Q = sparameters("JB_Ch2_Ex_Q.s2p"); % Read transistor S-parameter data
% 
% force_h0 = true;
% 
% s_raw = sqrt(-1).*[18, 19, 20, 21].*1e9;
% f_scale = 21e9;
% s_vec = s_raw./f_scale;
% 
% % Create network object
% net = Network(4);
% net.setSPQ(SParam_Q); % Set all transistor S-parameters
% net.setFreqs(s_vec, s_raw);
% net.reset();
% net.showErrors = true;
% net.vswr_in_t = 2;
% net.vswr_out_t = 2;
% net.ZL = 50;
% net.Z0 = 50;
% 
% % Create initial h(s) guess
% h_coef = [1,1,0];
% if force_h0
% 	h_coef = [1, 1];
% 	net.forceCoef(0, 0);
% end
% net.setHGuess(h_coef);
% 
% % Set error function
% net.setEvalFunc(@error_fn);
% 
% % Set weights in evaluation functions for ea. stage
% net.getStg(1).weights = [1, 5, 0];
% net.getStg(2).weights = [2, 3, 0];
% net.getStg(3).weights = [1, 0, 0];
% net.getStg(4).weights = [1, 0, 0];
% net.getStg(5).weights = [0, 0, 1];
% 
% % Prepare the Levenberg-Marquardt optimization options
% default_tol = 1e-6;
% default_iter = 400;
% default_funceval = 100*numel(net.getStg(1).h_init_guess);
% options = optimoptions('lsqcurvefit','Algorithm','levenberg-marquardt', 'FunctionTolerance', default_tol/100/100);
% options.UseParallel = false;
% options.MaxIterations = default_iter*100;
% options.MaxFunctionEvaluations = default_funceval*100;
% options.Display = 'none';
% 
% %TODO: Build this in as default options, getOptOptions() to modify
% net.setOptOptions(options);
% 
% % Run through each stage and optimize
% for k=1:5
% 	net.optimize(k, 'simple');
% end
% 
% % Plot results
% net.plotGain(1e9, 2);
% disp(' ');
% net.optimSummary();


%=========================================================================%
%							Cauer Synthesis								  %
%=========================================================================%

%Generate Z from 
Z_num = [.794, 1];
Z_den = [.668, 1.239, 1];

% Generate network synthesizer
synth = NetSynth(Z_num, Z_den);
% synth.c_isadm(1);

synth.cauer1();
synth.cauer1();
synth.cauer1();

displ("Circuit Output:");
for c=synth.circ
	displ("  ", c.str());
end















function error_sum = error_fn(net, k)
	
	stg = net.getStg(k);

	gain_term = stg.weights(1) * (stg.gain./stg.gain_t - 1).^2;
	vswr_in_term = stg.weights(2) * (net.vswr_in./net.vswr_in_t - 1).^2;
	vswr_out_term = stg.weights(3) * (net.vswr_out./net.vswr_out_t - 1).^2;
	
	error_sum = sum( gain_term + vswr_in_term + vswr_out_term );

end



















































