function error_sum = default_opt(h_vec, net, k)

	stg = net.getStg(k);
	stg.compute_fsimple(h_vec);
	net.setStg(k, stg);
	
	net.compute_rcsv();

	error_sum = net.getStg(k).eval_func(net, k);

end