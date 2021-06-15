function error_sum = default_opt(h_vec, net, k)
% DEFAULT_OPT Default optimization function for MultiStage class
%
%	error_sum = DEFAULT_OPT(H_VEC, NET, K) Evaluates the coefficients H_VEC
%	in the MultiStage NET for stage K and returns the error value, as
%	calculated by the stage's eval_func parameter.

	stg = net.getStg(k);
	stg.compute_fsimple(h_vec);
	net.setStg(k, stg);

	net.compute_rcsv();

	error_sum = net.getStg(k).eval_func(net, k);

end
