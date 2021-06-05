% This is the example data we are matching
freqs = [1, 1.6, 2.3, 3];
R = [28, 30, 25, 20]./27;
X = [19, 8, 5, 8]./27;
Zin = R + sqrt(-1).*X;

% Here we convert them to the format expected by the Network class
s_raw = sqrt(-1).*freqs;
f_scale = 1;
s_vec = s_raw./f_scale;

% Create network object
net = Network(0);
% net.setSPQ(SParam_Q); % Set all transistor S-parameters
net.setFreqs(s_vec, s_raw);
net.reset();
net.showErrors = true;
net.vswr_in_t = 2; % Not used in this example
net.vswr_out_t = 2; % Not used in this example
net.ZL = 1; % Load impedance
net.Z0 = 1; % Intermediate terminating impedance
net.getStg(1).targets('ZIN') = Zin;

% Initialize h-guess
h_coef = [-1, 1, -1, 1, 0];
net.setHGuess(h_coef);

net.setEvalFunc(@error_fn_zin);

% Set weights in evaluation functions for ea. stage
net.getStg(1).weights = 1e6;


% Prepare the Levenberg-Marquardt optimization algorithm
default_tol = 1e-6;
default_iter = 400;
default_funceval = 100*numel(net.getStg(1).h_init_guess);
options = optimoptions('lsqcurvefit','Algorithm','levenberg-marquardt', 'FunctionTolerance', default_tol/100/100);
% options.MaxFunctionEvaluations = 6e3;
% options.MaxIterations = 4e3;
options.MaxIterations = default_iter*100;
options.MaxFunctionEvaluations = default_funceval*100;
options.Display = 'none';

net.setOptOptions(options);

net.optimize(1, 'simple');

net.optimSummary();

stg = net.getStg(1);

figure(4);
yyaxis left;
hold off;
plot(freqs, real(stg.evaluation_parameters('ZIN')), 'Color', [0, 0, .8], 'LineStyle', '--', 'LineWidth', 1);
hold on;
plot(freqs, R, 'Color', [0, 0, .8], 'LineStyle', ':', 'LineWidth', 1.8);
ylabel('Re\{Zin\} (Ohms)');
yyaxis right;
hold off;
plot(freqs, imag(stg.evaluation_parameters('ZIN')), 'Color', [.8, 0, 0], 'LineStyle', '--', 'LineWidth', 1);
hold on;
plot(freqs, X, 'Color', [.8, 0, 0], 'LineStyle', ':', 'LineWidth', 1.8);
ylabel('Im\{Zin\} (Ohms)');
xlabel('Freq (GHz)');
title("Optimization Match Quality");
legend("Optimized, Real" ,"Target, Real", "Optimized, Imag", "Target, Real", 'Location', 'West')
grid on;
set(gca,'FontSize',12)

function error_sum = error_fn_zin(net, k)
	
	stg = net.getStg(k);
	
	Zin = (1 + flatten(stg.e(1,1,:))) ./ (1 - flatten(stg.e(1,1,:)));
	stg.evaluation_parameters('ZIN') = Zin;

	net.setStg(k, stg);
	
	zin_term = stg.weights(1) * (Zin ./ stg.targets('ZIN') - 1).^2;

	error_sum = sum(zin_term);

end



















































